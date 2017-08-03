#!/usr/bin/env bash

# this script is used to cleanup the OpenWhisk deployment

set -x

kubectl delete namespace openwhisk
