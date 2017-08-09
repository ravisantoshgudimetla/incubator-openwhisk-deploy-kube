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

TODO: use secrets for auth, not the configmap

To test the system, first make sure you have a `wsk` binary in your
$PATH (download from
https://github.com/apache/incubator-openwhisk-cli/releases/), then:

```
export AUTH_SECRET=$(kubectl -n openwhisk get configmap openwhisk-config -o yaml | grep 'AUTH_WHISK_SYSTEM=' | awk -F '=' '{print $2}')
export WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
wsk property set --auth $AUTH_SECRET --apihost https://$(minikube ip):$WSK_PORT
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```

Without the `-i` option, you will get certificate validation error due
to the self-signed cert the nginx service is using.

If that's successful, try a more complex example involving triggers
and rules. First, install the alarms package:

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
