# Deploying to minishift via a single yml file

First, start minishift and fix a networking bug in current releases:

```
minishift start
minishift ssh -- sudo ip link set docker0 promisc on
eval $(minishift oc-env)
```

Then, deploy OpenWhisk:

```
oc new-project openwhisk
oc create -f configure/openwhisk_openshift.yml
watch oc get all
```

Make sure all pods enter the Running state before moving on. If not,
something broken and start troubleshooting by looking in the logs of
the failing pods.

Then, wait until the controller recognizes the invoker as healthy:

```
oc logs -f controller-0 | grep "invoker status changed"
```

You're looking for a message like `invoker status changed to invoker0:
Healthy`

This doesn't yet include the nginx container, it just exposes the
controller service. You can get the url for the service with:

```
oc get route/openwhisk --template={{.spec.host}}
```

TODO: use secrets for auth, not the configmap

To test the system, first make sure you have a `wsk` binary in your
$PATH (download from
https://github.com/apache/incubator-openwhisk-cli/releases/), then:

```
export AUTH_SECRET=$(oc get configmap openwhisk-config -o yaml | grep 'AUTH_WHISK_SYSTEM=' | awk -F '=' '{print $2}')
wsk property set --auth $AUTH_SECRET --apihost http://$(oc get route/openwhisk --template={{.spec.host}})
wsk list
wsk action invoke /whisk.system/utils/echo -p message hello -b
```

If that's successful, try a more complex example involving triggers
and rules. First, install the alarms package:

```
oc create -f configure/alarms_openshift.yml
```

Once the `alarmprovider` pod enters the Running state, try the
following:

```
wsk trigger create every-5-seconds \
    --feed  /whisk.system/alarms/alarm \
    --param cron '*/5 * * * * *' \
    --param maxTriggers 25 \
    --param trigger_payload "{\"name\":\"Odin\",\"place\":\"Asgard\"}"
wsk rule create \
    invoke-periodically \
    every-5-seconds \
    /whisk.system/samples/greeting
wsk activation poll
```


## Rebuilding the images locally:

```
eval $(minishift docker-env)
docker build --tag projectodd/whisk_couchdb:openshift-latest docker/couchdb
docker build --tag projectodd/whisk_zookeeper:openshift-latest docker/zookeeper
docker build --tag projectodd/whisk_kafka:openshift-latest docker/kafka
docker build --tag projectodd/whisk_nginx:openshift-latest docker/nginx
docker build --tag projectodd/whisk_catalog:openshift-latest docker/catalog
docker build --tag projectodd/whisk_alarms:openshift-latest docker/alarms
```

## Public Docker Images

The projectodd/whisk_* images above are automatically built by
DockerHub on every push of this repository.

The OpenShift-specific OpenWhisk images
(projectodd/controller:openshift-latest and friends) are built from
https://github.com/projectodd/incubator-openwhisk/tree/kube-container-openshift
(note the `kube-container-openshift` branch) with the command:

```
export SHORT_COMMIT=$(git rev-parse HEAD | cut -c 1-7)
./gradlew distDocker -PdockerImagePrefix=projectodd -PdockerImageTag=openshift-latest
./gradlew distDocker -PdockerImagePrefix=projectodd -PdockerImageTag=openshift-${SHORT_COMMIT}
```

To publish the above images, add `-PdockerRegistry=docker.io` to each of those commands.
