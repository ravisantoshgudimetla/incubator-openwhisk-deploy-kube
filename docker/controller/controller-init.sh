#!/bin/bash

# enable job control
set -m

# Export all environment variables from the env file
set -a
source /openwhisk_config/env

echo "Waiting for couchdb to be available"
until $(curl --output /dev/null --silent --head --fail http://${DB_HOST}:${DB_PORT}/_all_dbs); do printf '.'; sleep 1; done

/controller/bin/controller &

echo "Waiting for controller to be available"
until $(curl --output /dev/null --silent --head --fail http://localhost:${PORT}/ping); do printf '.'; sleep 1; done

echo "Running postdeploy"
pushd /openwhisk/ansible
ansible-playbook setup.yml postdeploy.yml \
                 -e api_host=http://localhost:${PORT} \
                 -e catalog_auth_key=$AUTH_WHISK_SYSTEM \
                 -e openwhisk_home=/openwhisk
popd

fg
