#!/bin/bash
####################################################################################
#Copyright 2015 ARRIS Enterprises, Inc. All rights reserved.
#This program is confidential and proprietary to ARRIS Enterprises, Inc. (ARRIS),
#and may not be copied, reproduced, modified, disclosed to others, published or used,
#in whole or in part, without the express prior written permission of ARRIS.
####################################################################################
# This script unconditionally inserts ELK health key into etcd
# to make it actually be static. The KeyManager will use the health
# key to determine whether to keep the data key, in this case both
# keys will statically present in etcd. 

LOGGING_INTERVAL=30
LOGFILE="/var/log/elk/manageHealthKey.log"

timestamp() {
  date --rfc-3339=seconds
}

echo "$(timestamp) - ======= Start Managing ELK Health Key ====== " >> $LOGFILE

initialSleep=$1
periodicity=$2
if [ -z "$initialSleep" ]
then
  initialSleep=60
fi

if [ -z "$periodicity" ]
then
  periodicity=60
fi

keyname=`echo $HOST_IP | cut -f2 -d: | cut -f2-4 -d.`
etcdEndPoint=`host etcdCluster | cut -d " " -f4`:4001

echo "$(timestamp) - HOST_IP=$HOST_IP, keyname=$keyname, etcdEndPoint=$etcdEndPoint, initialSleep=$initialSleep, periodicity=$periodicity" >> $LOGFILE

etcdctl -no-sync -peers $etcdEndPoint set /health/laas/elk/elk$keyname $HOST_IP -ttl `expr $initialSleep + 5`
sleep $initialSleep

numOfPolls=0

while :
do
  etcdctl -no-sync -peers $etcdEndPoint set /health/laas/elk/elk$keyname $HOST_IP -ttl `expr $periodicity + 5`
  numOfPolls=$((numOfPolls + 1))

  if [[ $(($numOfPolls % $LOGGING_INTERVAL )) -eq 0 ]]; then
    echo "$(timestamp) - setting health key: /health/laas/elk/elk$keyname" >> $LOGFILE
    numOfPolls=0
  fi
 
  sleep $periodicity
done
