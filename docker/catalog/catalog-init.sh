#!/bin/bash

# Export all environment variables from the env file
set -a
source /openwhisk_config/env

# Ensure the random OpenShift uid has a corresponding user name
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /passwd.template > /tmp/passwd
export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

echo "Waiting for controller to be available"
until $(curl --output /dev/null --silent --head --fail http://${CONTROLLER_HOST}:${CONTROLLER_HOST_PORT}/ping); do printf '.'; sleep 1; done

cd /openwhisk-catalog/packages

./installCatalog.sh $AUTH_WHISK_SYSTEM http://${CONTROLLER_HOST}:${CONTROLLER_HOST_PORT} /openwhisk/bin/wsk
