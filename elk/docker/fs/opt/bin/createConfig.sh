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
ELK_REPO_DIR="/service-scripts/certificates/ELK"
ELK_LOCAL_DIR="deployment$ELK_REPO_DIR"
LOGFILE="/var/log/elk/startup.log"

timestamp() {
  date --rfc-3339=seconds
}

echo "$(timestamp) - ======= Create ELK Running Environment Configurations ====== " >> $LOGFILE

wget -r -np -nH -R "index.*" -P deployment http://$DOCKER_REPO$ELK_REPO_DIR/

if [[ `find $ELK_LOCAL_DIR/keys/ -type f  | wc -l` -gt 0 ]];
then
  echo "$(timestamp) - Found ELK key and certificate files in repository, copying" >> $LOGFILE
  rm -rf /etc/elk/keys/*
  mv $ELK_LOCAL_DIR/keys/* /etc/elk/keys/.
  echo "$(timestamp) - Complete copying ELK key and certificate files" >> $LOGFILE
else
  echo "$(timestamp) - Initial launch, ELK key and certificate files not found in repository" >> $LOGFILE
fi

echo "$(timestamp) - Copying configuration files from repository" >> $LOGFILE
mv $ELK_LOCAL_DIR/logstash-config/* /etc/logstash
mv $ELK_LOCAL_DIR/curator/curator.conf /etc/curator
chmod +x /etc/curator/curator.conf

rm -rf deployment

echo "$(timestamp) - ======= Complete Create ELK Running Environment Configurations =======" >> $LOGFILE
