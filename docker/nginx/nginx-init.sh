#!/bin/bash

source /openwhisk_config/env

echo "Waiting for controller to be available"
until $(curl --output /dev/null --silent --head --fail http://${CONTROLLER_HOST}:${CONTROLLER_HOST_PORT}/ping); do printf '.'; sleep 1; done
echo "ready! starting nginx"

exec nginx -g "daemon off;"
