#!/bin/bash

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
SRC="$SCRIPTDIR/../openshift/*.yml"
TGT="$SCRIPTDIR/../openshift/extras/template.yml"
TMP=$(mktemp)

sed '/objects:/q' $TGT >$TMP

sed "s/^/  /" $SRC | grep -v -- "---" | sed "s/ \( apiV\)/-\1/" | cat $TMP - >$TGT

rm $TMP
