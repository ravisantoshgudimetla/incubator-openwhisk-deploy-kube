#!/bin/bash

# Export all environment variables from the env file
set -a
source /openwhisk_config/env

TEMP_PORT=5914

# set admin user 
printf "[admins]\n%s = %s\n" "$DB_USERNAME" "$DB_PASSWORD" > /usr/local/etc/couchdb/local.d/admin.ini
printf "[httpd]\nport = %s\n" "$TEMP_PORT" > /usr/local/etc/couchdb/local.d/port.ini
chown couchdb:couchdb /usr/local/etc/couchdb/local.d/admin.ini

echo $AUTH_GUEST > /openwhisk/ansible/files/auth.guest
echo $AUTH_WHISK_SYSTEM > /openwhisk/ansible/files/auth.whisk.system

echo "Starting couchdb for internal config"
couchdb -b

echo "Waiting for couchdb to be available"
until $(curl --output /dev/null --silent --head --fail http://localhost:${TEMP_PORT}/_all_dbs); do printf '.'; sleep 1; done

echo "Initializing database"
pushd /openwhisk/ansible
ansible-playbook setup.yml initdb.yml \
                 -e db_host=localhost \
                 -e db_prefix=$DB_PREFIX \
                 -e db_username=$DB_USERNAME \
                 -e db_password=$DB_PASSWORD \
                 -e db_port=$TEMP_PORT \
                 -e openwhisk_home=/openwhisk

curl -q http://localhost:${TEMP_PORT}/_all_dbs | grep $DB_WHISK_ACTIVATIONS
if [ $? -ne 0 ]; then
    echo "Wiping database"
    ansible-playbook wipe.yml \
                 -e db_host=localhost \
                 -e db_prefix=$DB_PREFIX \
                 -e db_username=$DB_USERNAME \
                 -e db_password=$DB_PASSWORD \
                 -e db_port=$TEMP_PORT \
                 -e openwhisk_home=/openwhisk
fi
popd

couchdb -d

rm /usr/local/etc/couchdb/local.d/port.ini

echo "Starting couchdb for external use"

tini -s -- /docker-entrypoint.sh couchdb
