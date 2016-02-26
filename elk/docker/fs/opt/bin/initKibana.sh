#!/bin/sh

KB_HOME="/opt/kibana"
exec="$KB_HOME/bin/kibana"
KB_CONFFILE="/etc/kibana/kibana.yml"

LOGFILE="/var/log/elk/startup.log"
KB_LOGFILE="/var/log/elk/kibana.log"

timestamp() {
  date --rfc-3339=seconds
}

echo "$(timestamp) - ======= Initialize Kibana ====== " >> $LOGFILE

$exec -c $KB_CONFFILE -l $KB_LOGFILE >> $LOGFILE 2>&1
