# Deploying to kube via a single yml file

First, start minikube and fix a networking bug in current releases:

```
minikube start
minikube ssh -- sudo ip link set docker0 promisc on
```

Then, deploy OpenWhisk:

```
kubectl create -f https://raw.githubusercontent.com/projectodd/incubator-openwhisk-deploy-kube/simplify-deployment/configure/openwhisk.yml
watch kubectl -n openwhisk get all
```

Make sure all pods enter the Running state before moving on. If not,
something broken and start troubleshooting by looking in the logs of
the failing pods.

This doesn't yet include the nginx container, it just exposes the
controller service. If using `minikube`, you can get the url for the
service with:

```
minikube -n openwhisk service controller --url
```

TODO: use secrets for auth, not the configmap

To test the system, first make sure you have a `wsk` binary in your
$PATH (download from
https://github.com/apache/incubator-openwhisk-cli/releases/), then:

```
export AUTH_SECRET=$(kubectl -n openwhisk get configmap openwhisk-config -o yaml | grep 'AUTH_WHISK_SYSTEM=' | awk -F '=' '{print $2}')
wsk property set --auth $AUTH_SECRET --apihost $(minikube -n openwhisk service controller --url)
wsk list
wsk action invoke /whisk.system/utils/echo -p message hello -b
```


## Rebuilding the images locally:

```
eval $(minikube docker-env)
docker build --tag projectodd/whisk_controller:latest docker/controller
docker build --tag projectodd/whisk_couchdb:latest docker/couchdb
```

## Public Docker Images

Docker Hub is configured to automatically rebuild
projectodd/whisk_controller and projectodd/whisk_couchdb on every push
to this branch.
