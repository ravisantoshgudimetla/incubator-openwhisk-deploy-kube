#!/bin/bash
set -ex

pushd /openwhisk

  # Fake our UID because OpenShift runs with random uids
  export LD_PRELOAD=/usr/lib/libuid_wrapper.so
  export UID_WRAPPER=1
  export UID_WRAPPER_ROOT=1

  # if auth guest overwrite file
  if [ -n "$AUTH_GUEST" ]; then
    echo "$AUTH_GUEST" > /openwhisk/ansible/files/auth.guest
  fi

  # if auth whisk system overwrite file
  if [ -n "$AUTH_WHISK_SYSTEM" ]; then
    echo "$AUTH_WHISK_SYSTEM" > /openwhisk/ansible/files/auth.whisk.system
  fi

  # start couchdb with a background process
  couchdb -b -o /tmp/couchdb.stdout -e /tmp/couchdb.stderr

  # wait for couchdb to be up and running
  echo "Waiting for couchdb to be available"
  until $(curl --output /dev/null --silent --head --fail http://localhost:${DB_PORT}/_all_dbs); do printf '.'; sleep 1; done

  # setup and initialize DB
  pushd ansible
    ansible-playbook -i environments/local setup.yml \
      -e db_host=$DB_HOST \
      -e db_prefix=$DB_PREFIX \
      -e db_username=$COUCHDB_USER \
      -e db_password=$COUCHDB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk
  popd

  # create the admin user
  curl -X PUT http://$DB_HOST:$DB_PORT/_config/admins/$COUCHDB_USER -d "\"$COUCHDB_PASSWORD\""

  # disable reduce limits on views
  curl -X PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@$DB_HOST:$DB_PORT/_config/query-server_config/reduce_limit -d '"false"'

  pushd ansible
    # initialize the DB
    ansible-playbook -i environments/local initdb.yml \
      -e db_host=$DB_HOST \
      -e db_prefix=$DB_PREFIX \
      -e db_username=$COUCHDB_USER \
      -e db_password=$COUCHDB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk

    # wipe the DB
    ansible-playbook -i environments/local wipe.yml \
      -e db_host=$DB_HOST \
      -e db_prefix=$DB_PREFIX \
      -e db_username=$COUCHDB_USER \
      -e db_password=$COUCHDB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk
  popd

  # stop the CouchDB background process
  couchdb -d

  # Unfake the UID
  unset LD_PRELOAD UID_WRAPPER UID_WRAPPER_ROOT
popd

# start couchdb that has been setup
tini -s -- couchdb
