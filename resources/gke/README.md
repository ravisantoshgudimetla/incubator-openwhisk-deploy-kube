# Deploying OpenWhisk to Google Container Engine (GKE)

Although, you probably would not choose to deploy OpenWhisk to GKE for a production environment, it is often useful for testing OpenWhisk or your FaaS functions.

## Preparing a GKE Kubernetes container cluster

### Set up gcloud configuration

Before proceeding make sure you have a Google Cloud Platform project umbrella to work under and the correct `gcloud` configuration setup so that any subsequent commands you run will default to the correct project, zone, etc. This can easily be done by running the `gcloud init` command. See [https://cloud.google.com/sdk/docs/initializing](https://cloud.google.com/sdk/docs/initializing) for more details. Here's an example of what it should look like to match the commands in the rest of this demo:

```
gcloud config list
Your active configuration is: [default]

[compute]
region = us-west1
zone = us-west1-a
[core]
account = you@example.com
project = openwhisk-gke
```
If it doesn't match this, then make sure you make the appropriate changes in the `gcloud container create` command below. Otherwise, run `gcloud init` or the commands below to set it up correctly:

```
gcloud config configurations activate default
gcloud config set compute/region us-west1
Updated property [compute/region].
gcloud config set compute/zone us-west1-a
Updated property [compute/zone].
gcloud config set core/account you@example.com
Updated property [core/account].
gcloud config set project openwhisk-gke
Updated property [core/project].
```

### Create GKE Kubernetes container cluster

Now we need to set up a GKE Kubernetes container cluster. We will start with a 4 node cluster.  You may adjust the options in the command below to your specific use case.

```
gcloud beta container --project "openwhisk-gke" clusters create "openwhisk-cluster" --zone "us-west1-a" --username="admin" --cluster-version "1.7.5" --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "4" --network "default" --enable-cloud-logging --no-enable-cloud-monitoring --enable-legacy-authorization

Creating cluster openwhisk-cluster...done.                                               
Created [https://container.googleapis.com/v1/projects/openwhisk-gke/zones/us-west1-a/clusters/openwhisk-cluster].
kubeconfig entry generated for openwhisk-cluster.
NAME               ZONE        MASTER_VERSION  MASTER_IP      MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
openwhisk-cluster  us-west1-a  1.7.5           104.198.5.180  n1-standard-2  1.7.5         4          RUNNING
```

Then configure `kubectl` on your local machine to access the cluster. If you don't have `kubectl` installed, then install it with `gcloud components install kubectl` or download the right binary version of it to match the version of Kubernetes on the cluster. See [http://kubernetes.io/docs/getting-started-guides/kubectl/](http://kubernetes.io/docs/getting-started-guides/kubectl/) for more details. Once `kubectl` is installed, configure it to access the cluster:

```
gcloud container clusters get-credentials openwhisk-cluster --zone us-west1-a --project openwhisk-gke
Fetching cluster endpoint and auth data.
kubeconfig entry generated for openwhisk-cluster.
```

Verify the container cluster nodes are ready:

```
kubectl get nodes
NAME                                               STATUS    AGE       VERSION
gke-openwhisk-cluster-default-pool-b9b119ec-0t6b   Ready     14m       v1.7.5
gke-openwhisk-cluster-default-pool-b9b119ec-14vm   Ready     14m       v1.7.5
gke-openwhisk-cluster-default-pool-b9b119ec-j0k8   Ready     14m       v1.7.5
gke-openwhisk-cluster-default-pool-b9b119ec-lnfd   Ready     14m       v1.7.5
```

Create the namespace:

```
kubectl create ns openwhisk
namespace "openwhisk" created
```

Then, deploy OpenWhisk from this directory:

```
kubectl -n openwhisk create -f .
configmap "openwhisk-config" created
service "controller" created
configmap "controller" created
statefulset "controller" created
job "install-openwhisk-catalog" created
service "couchdb" created
deployment "couchdb" created
secret "openwhisk" created
secret "couchdb" created
configmap "invoker" created
statefulset "invoker" created
job "preload-openwhisk-runtimes" created
service "kafka" created
deployment "kafka" created
service "nginx" created
configmap "nginx" created
deployment "nginx" created
secret "nginx" created
service "zookeeper" created
deployment "zookeeper" created
```

Wait for the system to stablize.  It will take about 5 mins and some pods may crash and restart.  Use the following command to watch the pods:

```
kubectl -n openwhisk get pods -w
```

Make sure all pods enter the Running state before moving on. If not,
something is broken. Start troubleshooting by looking in the logs of
the failing pods.

Then, wait until the controller recognizes the invoker as healthy:

```
kubectl -n openwhisk logs -f controller-0 | grep "invoker status changed"
```

You're looking for a message like `invoker status changed to 0 -> Healthy`

It may take a while for the EXTERNAL-IP address for nginx to become available.  Use the following command to see when there is a valid EXTERNAL-IP:

```
kubectl -n openwhisk get service nginx
NAME      CLUSTER-IP      EXTERNAL-IP     PORT(S)                                     AGE
nginx     10.11.241.204   35.199.151.15   80:30111/TCP,443:31128/TCP,8443:31044/TCP   50m
```

To test the system, first make sure you have a `wsk` binary in your
$PATH (download from
https://github.com/apache/incubator-openwhisk-cli/releases/), then:

```
AUTH_SECRET=$(kubectl -n openwhisk get secret openwhisk -o yaml | grep "system:" | awk '{print $2}' | base64 --decode)
WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep -v NodePort | awk '{print $3}' | cut -d'/' -f1)
WSK_IP=$(kubectl -n openwhisk describe service nginx | grep Ingress | awk '{print $3}')
wsk property set --auth $AUTH_SECRET --apihost https://$WSK_IP:$WSK_PORT
wsk -i list
wsk -i action invoke /whisk.system/utils/echo -p message hello -b
```

Without the `-i` option, you will get a certificate validation error
due to the self-signed cert the nginx service is using.

Assuming that worked, try a more complex example involving triggers
and rules. First, install the alarms package:

```
kubectl -n openwhisk create -f packages/alarms.yml
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

## Sensitive Data

Authentication credentials are stored in Kubernetes
[secrets](https://kubernetes.io/docs/concepts/configuration/secret/),
by default in the [insecure-secrets.yml](insecure-secrets.yml)
resource in this directory. This is convenient for development, but at
some point you'll want to create your own credentials.

The username and password for CouchDB are set in the `couchdb` secret:

```
kubectl -n openwhisk create secret generic couchdb \
    --from-literal=username=YOURUSERNAME --from-literal=password=YOURPASSWORD
```

The tokens used for authentication between *system* components and
*guest* users are set in the `openwhisk` secret. OpenWhisk requires
these tokens to be a specific format: a UUID and a key separated by a
colon. The key must contain exactly 64 alphanumeric characters. For
example, here's one way of creating a valid token on Linux:

```
UUID=$(cat /proc/sys/kernel/random/uuid)
KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
TOKEN="${UUID}:${KEY}"
```

You'll need one token for the *system* and one for *guest* users. Both
should be set in the `openwhisk` secret like so:

```
kubectl -n openwhisk create secret generic openwhisk \
    --from-literal=system="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)" \
    --from-literal=guest="$(cat /proc/sys/kernel/random/uuid):$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
```

## Cleaning Up

You can delete your GKE cluster from the Google Cloud console or use the cli with:

```
gcloud container clusters delete openwhisk-cluster --project "openwhisk-gke" --zone "us-west1-a"
The following clusters will be deleted.
 - [openwhisk-cluster] in [us-west1-a]

Do you want to continue (Y/n)?  Y

Deleting cluster openwhisk-cluster...done.
```

If your cluster was using persistent volumes (which it is for the stateful sets) these may not be deleted automatically when you delete the cluster above.  Using the Google Cloud console, navigate to the Compute Engine->Disks and verify that no persistent disks are still around (you will get charged a very small amount if you leave these disks around for a while).
