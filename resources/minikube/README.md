# Deploying OpenWhisk to Minikube

These instructions have been tested successfully with minikube version
0.21.0. Later releases should also work. Earlier ones might not.

First, start minikube and fix a networking bug in current releases:

```
minikube start
minikube ssh -- sudo ip link set docker0 promisc on
```

Then, deploy OpenWhisk from this directory:

```
kubectl create ns openwhisk
kubectl -n openwhisk create -f .
watch kubectl -n openwhisk get all
```

Make sure all pods enter the Running state before moving on. If not,
something is broken. Start troubleshooting by looking in the logs of
the failing pods.

Then, wait until the controller recognizes the invoker as healthy:

```
kubectl -n openwhisk logs -f controller-0 | grep "invoker status changed"
```

You're looking for a message like `invoker status changed to 0 -> Healthy`

You can get the url for the service with:

```
kubectl -n openwhisk describe service nginx
```

To test the system, first make sure you have a `wsk` binary in your
$PATH (download from
https://github.com/apache/incubator-openwhisk-cli/releases/), then:

```
AUTH_SECRET=$(kubectl -n openwhisk get secret openwhisk -o yaml | grep "system:" | awk '{print $2}' | base64 -d)
WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
wsk property set --auth $AUTH_SECRET --apihost https://$(minikube ip):$WSK_PORT
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```

Without the `-i` option, you will get a certificate validation error
due to the self-signed cert the nginx service is using.

If that worked, try a more complex example involving triggers and
rules. First, install the alarms package:

```
kubectl -n openwhisk create -f packages/alarms.yml
```

Once the `alarmprovider` pod enters the Running state, try the
following:

```
wsk -i trigger create every-5-seconds \
    --feed  /whisk.system/alarms/alarm \
    --param cron '*/5 * * * * *' \
    --param maxTriggers 25 \
    --param trigger_payload "{\"name\":\"Odin\",\"place\":\"Asgard\"}"
wsk -i rule create \
    invoke-periodically \
    every-5-seconds \
    /whisk.system/samples/greeting
wsk -i activation poll
```

You can delete all of the OpenWhisk resources by deleting the
namespace:

```
kubectl delete ns openwhisk
```

## Sensitive Data

Authentication credentials are stored in Kubernetes
[secrets](https://kubernetes.io/docs/concepts/configuration/secret/),
by default in the [insecure-secrets.yml](insecure-secrets.yml)
resource in this directory. This is convenient for development, but at
some point you'll want to create your own credentials.

The username and password for CouchDB are set in the `couchdb` secret:

```
kubectl -n openwhisk create secret generic couchdb \
    --from-literal=username=YOURUSERNAME --from-literal=password=YOURPASSWORD
```

The tokens used for authentication between *system* components and
*guest* users are set in the `openwhisk` secret. OpenWhisk requires
these tokens to be a specific format: a UUID and a key separated by a
colon. The key must contain exactly 64 alphanumeric characters. For
example, here's one way of creating a valid token on Linux:

```
UUID=$(cat /proc/sys/kernel/random/uuid)
KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
TOKEN="${UUID}:${KEY}"
```

You'll need one token for the *system* and one for *guest* users. Both
should be set in the `openwhisk` secret like so:

```
kubectl -n openwhisk create secret generic openwhisk \
    --from-literal=system="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)" \
    --from-literal=guest="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
```
