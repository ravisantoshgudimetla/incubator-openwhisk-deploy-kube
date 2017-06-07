# Deploying to kube via a single yml file

First, you'll need to build the custom couchdb image against the
docker in your kube (this image self-configures the db for whisk):

```
cd couchdb-docker
docker build --tag projectodd/whisk_couchdb:dev .
```

Then, apply the combined yml:

```
kubectl create -f configure/openwhisk.yml
```

This doesn't yet include the nginx container, it just exposes the
controller service. If using `minikube`, you can get the url for the
service with:

```
minikube -n openwhisk service controller --url
```

This also doesn't yet apply the OpenWhisk catalog.

