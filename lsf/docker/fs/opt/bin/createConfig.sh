#!/bin/sh
#
######################################################################################
# Copyright 2009-2014 ARRIS Enterprises, Inc. All rights reserved.
# This program is confidential and proprietary to ARRIS Enterprises, Inc. (ARRIS),
# and may not be copied, reproduced, modified, disclosed to others, published
# or used, in whole or in part, without the express prior written permission of ARRIS.
######################################################################################
#
DOCKER_REPO=dockerrepo
REPO_DIR="/service-scripts/certificates/LSF"
LOCAL_DIR="deployment$REPO_DIR"
LOGFILE="/var/log/supervisor/createConfig.log"

timestamp() {
  date --rfc-3339=seconds
}

echo "$(timestamp) - DOCKER_REPO=$DOCKER_REPO" >> $LOGFILE
wget -r -np -nH -R "index.*" -P deployment http://$DOCKER_REPO$REPO_DIR/

if [[ `find $LOCAL_DIR/keys/ -type f  | wc -l` -gt 0 ]];
then
  echo "$(timestamp) - Found LSF key and certificate files in repository, copying" >> $LOGFILE
  rm -rf /etc/elk-keys/*
  mv $LOCAL_DIR/keys/* /etc/elk-keys
else
  echo "$(timestamp) - Initial launch, LSF key and certificate files not found in repository" >> $LOGFILE
fi

mv $LOCAL_DIR/conf/* /etc/logstash-forwarder

rm -rf deployment
