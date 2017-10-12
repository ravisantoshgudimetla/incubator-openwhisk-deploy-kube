## Deploying OpenWhisk

There are [specific instructions and resource files](resources/) for
deploying OpenWhisk to both
[minikube](https://github.com/kubernetes/minikube/) and
[minishift](https://github.com/minishift/minishift/)

## Rebuilding the images locally:

```
eval $(minishift docker-env)
docker build --tag projectodd/whisk_couchdb:openshift-latest kubernetes/couchdb/docker
docker build --tag projectodd/whisk_zookeeper:openshift-latest kubernetes/zookeeper/docker
docker build --tag projectodd/whisk_kafka:openshift-latest kubernetes/kafka/docker
docker build --tag projectodd/whisk_nginx:openshift-latest kubernetes/nginx/docker
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
