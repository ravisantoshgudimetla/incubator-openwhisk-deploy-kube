# Deploying OpenWhisk to Minishift

First, start minishift and fix a networking bug in current releases:

```
minishift start
minishift ssh -- sudo ip link set docker0 promisc on
eval $(minishift oc-env)
```

Then, deploy OpenWhisk from this directory:

```
oc new-project openwhisk
oc create -f .
watch oc get all
```

Make sure all pods enter the Running state before moving on. If not,
something is broken. Start troubleshooting by looking in the logs of
the failing pods.

Then, wait until the controller recognizes the invoker as healthy:

```
oc logs -f controller-0 | grep "invoker status changed"
```

You're looking for a message like `invoker status changed to 0 -> Healthy`

You can get the url for the service with:

```
oc get route/openwhisk --template={{.spec.host}}
```

To test the system, first make sure you have a `wsk` binary in your
$PATH (download from
https://github.com/apache/incubator-openwhisk-cli/releases/), then:

```
export AUTH_SECRET=$(oc get secret openwhisk -o yaml | grep "system:" | awk '{print $2}' | base64 -d)
wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template={{.spec.host}})
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```

Without the `-i` option, you will get a certificate validation error
due to the self-signed cert the nginx service is using.

If the `wsk` command seems to hang, cancel it and try bouncing the
nginx pod, since its IP addresses for any restarted controllers may be
stale:

```
oc delete pod -l name=nginx
```

If that's successful, try a more complex example involving triggers
and rules. First, install the alarms package:

```
oc create -f packages/alarms.yml
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

You can delete all the OpenWhisk resources by deleting the project:

```
oc delete project openwhisk
```

## Sensitive Data

Authentication credentials are stored in OpenShift
[secrets](https://docs.openshift.com/container-platform/3.5/dev_guide/secrets.html),
by default in the [insecure-secrets.yml](insecure-secrets.yml)
resource in this directory. This is convenient for development, but at
some point you'll want to create your own credentials.

The username and password for CouchDB are set in the `couchdb` secret:

```
oc create secret generic couchdb --from-literal=username=YOURUSERNAME --from-literal=password=YOURPASSWORD
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
oc create secret generic openwhisk \
    --from-literal=system="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)" \
    --from-literal=guest="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
```
