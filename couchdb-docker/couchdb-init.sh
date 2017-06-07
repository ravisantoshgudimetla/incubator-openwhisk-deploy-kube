#!/bin/bash

# enable job control
set -m

source /openwhisk_config/env
# set admin user 
printf "[admins]\n%s = %s\n" "$DB_USERNAME" "$DB_PASSWORD" > /usr/local/etc/couchdb/local.d/admin.ini
chown couchdb:couchdb /usr/local/etc/couchdb/local.d/admin.ini

# TODO: start up on a non-exposed port and configure, then restart
tini -s -- /docker-entrypoint.sh couchdb &

echo "Waiting for couchdb to be available"
until $(curl --output /dev/null --silent --head --fail http://localhost:${DB_PORT}/_all_dbs); do printf '.'; sleep 1; done

echo "Initializing database"
pushd /openwhisk/ansible
ansible-playbook setup.yml initdb.yml wipe.yml \
                 -e db_host=localhost \
                 -e db_prefix=$DB_PREFIX \
                 -e db_username=$DB_USERNAME \
                 -e db_password=$DB_PASSWORD \
                 -e db_port=$DB_PORT \
                 -e openwhisk_home=/openwhisk
popd

fg



