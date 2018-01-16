Beneath this directory are the resource files necessary to deploy a
working OpenWhisk environment to OpenShift, specifically
[minishift](https://github.com/minishift/minishift/).

# Installation

First, start minishift and fix a networking bug in current releases:

```
minishift start --memory 8GB
minishift ssh -- sudo ip link set docker0 promisc on
eval $(minishift oc-env)
```

Then deploy OpenWhisk in its own project.

```
oc new-project openwhisk
oc create -f openshift/
```

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
AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
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
maintained in [secrets.yml](secrets.yml). This is
convenient for development, but at some point you'll want to create
your own credentials.

One secret, named `db.auth`, contains the username and password for
CouchDB. The other, named `whisk.auth`, contains two tokens: one used
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

```
oc create secret generic db.auth --from-literal=db_username=YOURUSERNAME --from-literal=db_password=YOURPASSWORD
```

```
oc create secret generic whisk.auth \
    --from-literal=system="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)" \
    --from-literal=guest="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
```
