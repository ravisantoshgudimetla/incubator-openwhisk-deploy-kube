These instructions assumed you have the kube-container branch of
https://github.com/projectodd/incubator-openwhisk/ checked out at
~/src/openwhisk.

```
minikube start
minikube ssh
  su
  ip link set docker0 promisc on
  exit
  exit
cd ~/src/openwhisk
./gradlew :core:invoker:distDocker -PdockerImageTag=123
cd ~/src/incubator-openwhisk-deploy-kube
eval $(minikube docker-env)
docker/build.sh projectodd ~/src/openwhisk
kubectl create -f configure/openwhisk_kube_namespace.yml
kubectl create -f configure/configure_whisk.yml
watch kubectl -n openwhisk get all
```


sometimes a cold kube cluster seems to take a few tries to get
everything deploying correctly - until those issues get fixed, just
blow it away and try again:

```
./configure/cleanup.sh
kubectl create -f configure/configure_whisk.yml
```

to roundtrip invoker changes:

```
cd ~/src/openwhisk
./gradlew :core:invoker:distDocker -PdockerImageTag=123
cd ~/src/incubator-openwhisk-deploy-kube
./configure/cleanup.sh 
kubectl create -f configure/configure_whisk.yml
```



to use the running system:

```
export PATH=~/src/openwhisk/bin:$PATH
export AUTH_SECRET=$(kubectl -n openwhisk get secret openwhisk-auth-tokens -o yaml | grep 'auth_whisk_system:' | awk '{print $2}' | base64 --decode)
export WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
wsk property set --auth $AUTH_SECRET --apihost https://$(minikube ip):$WSK_PORT
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```
