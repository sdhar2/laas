#!/bin/sh

LS_HOME="/opt/logstash"
exec="$LS_HOME/bin/logstash"
LS_CONFDIR="/etc/logstash/"

LOGFILE="/var/log/elk/startup.log"
LS_LOGFILE="/var/log/elk/logstash.log"

timestamp() {
  date --rfc-3339=seconds
}

echo "$(timestamp) - ======= Initialize Logstash ====== " >> $LOGFILE
echo "$(timestamp) - ======= Logstash version 2.1.1 Started ====== " >> $LS_LOGFILE

$exec -f $LS_CONFDIR -l $LS_LOGFILE >> $LOGFILE 2>&1
