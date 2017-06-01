These instructions assumed you have the kube-container branch of
https://github.com/projectodd/incubator-openwhisk/ checked out at
~/src/openwhisk.


```
minishift start (--vm-driver virtualbox if you use virtualbox)
minishift ssh
  sudo ip link set docker0 promisc on
  exit
eval $(minishift docker-env)
cd ~/src/openwhisk
./gradlew :core:invoker:distDocker -PdockerImageTag=123
cd ~/src/incubator-openwhisk-deploy-kube
docker/build.sh projectodd ~/src/openwhisk
docker pull openwhisk/nodejs6action && docker pull openwhisk/dockerskeleton && docker pull openwhisk/python2action && docker pull openwhisk/python3action && docker pull openwhisk/swift3action && docker pull openwhisk/java8action
oc new-project openwhisk
oc create serviceaccount openwhisk
oc login -u system:admin
oc adm policy add-scc-to-user anyuid -z openwhisk
oc adm policy add-scc-to-user privileged -z openwhisk
oc login -u developer -p a
oc create -f configure/configure_whisk.yml
watch oc get all
```



sometimes a cold openshift cluster seems to take a few tries to get
everything deploying correctly - until those issues get fixed, just
blow it away and try again:

```
./configure/cleanup.sh
oc create -f configure/configure_whisk.yml
```

to roundtrip invoker changes:

```
cd ~/src/openwhisk
./gradlew :core:invoker:distDocker -PdockerImageTag=123
cd ~/src/incubator-openwhisk-deploy-kube
./configure/cleanup.sh 
oc create -f configure/configure_whisk.yml
```



to use the running system:

```
export PATH=~/src/openwhisk/bin:$PATH
export AUTH_SECRET=$(oc -n openwhisk get secret openwhisk-auth-tokens -o yaml | grep 'auth_whisk_system:' | awk '{print $2}' | base64 --decode)
export WSK_PORT=$(oc -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
wsk property set --auth $AUTH_SECRET --apihost https://$(minishift ip):$WSK_PORT
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```
