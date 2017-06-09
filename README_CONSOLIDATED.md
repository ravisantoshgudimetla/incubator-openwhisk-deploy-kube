# Deploying to kube via a single yml file

First, start minikube and fix a networking bug in current releases:

```
minikube start
minikube ssh -- sudo ip link set docker0 promisc on
```

Then, deploy OpenWhisk:

```
kubectl create -f configure/openwhisk.yml
```

This doesn't yet include the nginx container, it just exposes the
controller service. If using `minikube`, you can get the url for the
service with:

```
minikube -n openwhisk service controller --url
```

TODO: use secrets for auth, not the configmap

To test the system:

```
export PATH=~/src/openwhisk/bin:$PATH
export AUTH_SECRET=$(kubectl -n openwhisk get configmap openwhisk-config -o yaml | grep 'AUTH_WHISK_SYSTEM=' | awk -F '=' '{print $2}')
wsk property set --auth $AUTH_SECRET --apihost $(minikube -n openwhisk service controller --url)
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```


## Rebuilding the images locally:

To build the custom images against the docker in your minikube, edit
`configure/openwhisk.yml` and change the tag of all projectodd/whisk_*
images to `dev`, then:

```
eval $(minikube docker-env)
docker build --tag projectodd/whisk_controller:dev docker/controller
docker build --tag projectodd/whisk_couchdb:dev docker/couchdb
```

## Public Docker Images

Docker Hub is configured to automatically rebuild
projectodd/whisk_controller and projectodd/whisk_couchdb on every push
to this branch.

Don't forget to update the tags in `configure/openwhisk.yml` if you
want to pull in newer Docker image versions.
