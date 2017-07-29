#!/bin/bash

echo "Waiting for controller to be available"
until $(curl --output /dev/null --silent --head --fail http://${CONTROLLER_HOST}:${CONTROLLER_PORT}/ping); do printf '.'; sleep 1; done

cd /openwhisk-package-alarms
./installCatalog.sh $AUTH_WHISK_SYSTEM http://${CONTROLLER_HOST}:${CONTROLLER_PORT} http://${DB_HOST} whisk_alarms_ ${ROUTER_HOST}
