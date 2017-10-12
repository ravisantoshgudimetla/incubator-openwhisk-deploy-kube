Beneath this directory are the Kubernetes (k8s) resource files
necessary to deploy a working OpenWhisk environment to various k8s
flavors, including
[minikube](https://github.com/kubernetes/minikube/),
[minishift](https://github.com/minishift/minishift/) and
[Google Container Engine (GKE)](https://cloud.google.com/container-engine/).

Most of the required resources are beneath the `k8s/` directory,
though OpenShift variants, e.g. minishift, require slight
modifications found beneath `openshift/`.

# Installation

The instructions for `minikube` should work for any similar Kubernetes
cluster accessed via the `kubectl` CLI. And the instructions for
`minishift` should work for any OpenShift cluster accessed via its
`oc` CLI.

## kubectl (minikube)

First, start minikube and fix a networking bug in current releases:

```
minikube start
minikube ssh -- sudo ip link set docker0 promisc on
```

Then, from this directory, deploy OpenWhisk in its own namespace:

```
kubectl create ns openwhisk
kubectl -n openwhisk create -f k8s/
```

Pass `-R` if you want to deploy the [alarms](#alarms) package as well.

This will take a few minutes. Verify that all pods eventually enter
the `Running` state:

```
watch kubectl -n openwhisk get all
```

The system is ready when the controller recognizes the invoker as
healthy:

```
kubectl -n openwhisk logs -f controller-0 | grep "invoker status changed"
```

You should see a message like `invoker status changed to 0 ->
Healthy`, at which point you can test the system with your `wsk`
binary (download from
https://github.com/apache/incubator-openwhisk-cli/releases/):

```
AUTH_SECRET=$(kubectl -n openwhisk get secret openwhisk -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
wsk property set --auth $AUTH_SECRET --apihost https://$(minikube ip):$WSK_PORT
```

That configures `wsk` to use your OpenWhisk. Use the `-i` option to
avoid the validation error triggered by the self-signed cert in the
`nginx` service.

```
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```

Finally, all of the OpenWhisk resources can be shutdown by simply
deleting the namespace:

```
kubectl delete ns openwhisk
```

## oc (minishift)

First, start minishift and fix a networking bug in current releases:

```
minishift start
minishift ssh -- sudo ip link set docker0 promisc on
eval $(minishift oc-env)
```

Then, from this directory, deploy OpenWhisk in its own project:

```
oc new-project openwhisk
oc create -f openshift/ -f k8s/
```

Pass `-R` if you want to deploy the [alarms](#alarms) package as well.

Note that we are passing two directories and the order is important:
the `openshift/` dir is first, and you will see "already exist" errors
from those files beneath `k8s/` that are "overridden" in `openshift/`.
This is expected.

This will take a few minutes. Verify that all pods eventually enter
the `Running` state:

```
watch oc get all
```

The system is ready when the controller recognizes the invoker as
healthy:

```
oc logs -f controller-0 | grep "invoker status changed"
```

You should see a message like `invoker status changed to 0 ->
Healthy`, at which point you can test the system with your `wsk`
binary (download from
https://github.com/apache/incubator-openwhisk-cli/releases/):

```
AUTH_SECRET=$(oc get secret openwhisk -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template={{.spec.host}})
```

That configures `wsk` to use your OpenWhisk. Use the `-i` option to
avoid the validation error triggered by the self-signed cert in the
`nginx` service.

```
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```

Finally, all of the OpenWhisk resources can be shutdown by simply
deleting the project:

```
oc delete project openwhisk
```

# Sensitive Data

Authentication credentials are stored in two
[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/),
maintained in [insecure-secrets.yml](k8s/insecure-secrets.yml). This
is convenient for development, but at some point you'll want to create
your own credentials.

One secret, named `couchdb`, contains the username and password for
CouchDB. The other, named `openwhisk`, contains two tokens: one used
for authentication between *system* components and the other for
authenticating *guest* users. OpenWhisk requires these tokens to be a
specific format: a UUID and a key separated by a colon. The key must
contain exactly 64 alphanumeric characters. For example, here's one
way of creating a valid token on Linux:

```
UUID=$(cat /proc/sys/kernel/random/uuid)
KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
TOKEN="${UUID}:${KEY}"
```

The commands to create these secrets follow:

## kubectl (minikube)

```
kubectl -n openwhisk create secret generic couchdb \
    --from-literal=username=YOURUSERNAME --from-literal=password=YOURPASSWORD
```

```
kubectl -n openwhisk create secret generic openwhisk \
    --from-literal=system="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)" \
    --from-literal=guest="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
```

## oc (minishift)

```
oc create secret generic couchdb --from-literal=username=YOURUSERNAME --from-literal=password=YOURPASSWORD
```

```
oc create secret generic openwhisk \
    --from-literal=system="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)" \
    --from-literal=guest="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
```

# Alarms

The
[alarms](https://github.com/apache/incubator-openwhisk-package-alarms)
package is not technically a part of the default OpenWhisk catalog,
but since it's a simple way of experimenting with triggers and rules,
we include a resource specification for it here. Once you have
OpenWhisk running, adding the alarms package is simple:

Using kubectl (minikube):

```
kubectl -n openwhisk create -f k8s/packages/alarms.yml
```

Or using oc (minishift):

```
oc create -f openshift/packages/alarms.yml
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
