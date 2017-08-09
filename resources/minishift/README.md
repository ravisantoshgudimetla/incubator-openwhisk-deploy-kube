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

TODO: use secrets for auth, not the configmap

To test the system, first make sure you have a `wsk` binary in your
$PATH (download from
https://github.com/apache/incubator-openwhisk-cli/releases/), then:

```
export AUTH_SECRET=$(oc get configmap openwhisk-config -o yaml | grep 'AUTH_WHISK_SYSTEM=' | awk -F '=' '{print $2}')
wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template={{.spec.host}})
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
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
