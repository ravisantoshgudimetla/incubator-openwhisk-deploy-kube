#!/usr/bin/env bash

# this script is used to cleanup the OpenWhisk deployment

set -x

# delete jobs
kubectl -n openwhisk delete job preload-openwhisk-runtimes
kubectl -n openwhisk delete job install-openwhisk-catalog

# delete deployments
kubectl -n openwhisk delete deployment couchdb
kubectl -n openwhisk delete deployment zookeeper
kubectl -n openwhisk delete deployment kafka
kubectl -n openwhisk delete statefulsets controller
kubectl -n openwhisk delete statefulsets invoker
kubectl -n openwhisk delete deployment nginx
kubectl -n openwhisk delete deployment alarmprovider

# delete configmaps
kubectl -n openwhisk delete cm controller
kubectl -n openwhisk delete cm invoker
kubectl -n openwhisk delete cm openwhisk-config
kubectl -n openwhisk delete cm nginx
kubectl -n openwhisk delete cm alarmprovider

# delete secrets
kubectl -n openwhisk delete secret nginx

# delete services
kubectl -n openwhisk delete service couchdb
kubectl -n openwhisk delete service zookeeper
kubectl -n openwhisk delete service kafka
kubectl -n openwhisk delete service controller
kubectl -n openwhisk delete service nginx
