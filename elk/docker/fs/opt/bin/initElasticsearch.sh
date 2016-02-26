#!/bin/sh

# Elasticsearch recommended configurations variables
ES_USER="elasticsearch"
ES_GROUP="elasticsearch"
ES_HOME="/opt/elasticsearch"
MAX_OPEN_FILES=65535
MAX_LOCKED_MEMORY=unlimited
MAX_MAP_COUNT=262144
LOG_DIR="/var/log/elk/elasticsearch"
DATA_DIR="/var/lib/elasticsearch"
CONF_DIR="/etc/elasticsearch"
PID_DIR="/var/run/elasticsearch"
PLUGIN_DIR="/opt/elasticsearch/plugins"
SCRIPT_DIR="/etc/elasticsearch/scripts"

exec="$ES_HOME/bin/elasticsearch"
prog="elasticsearch"
pidfile="$PID_DIR/${prog}.pid"

LOGFILE="/var/log/elk/startup.log"

timestamp() {
  date --rfc-3339=seconds
}

echo "$(timestamp) - ======= Initialize Elasticsearch ====== " >> $LOGFILE

# Calculate minimum_master_nodes
minNodes=$(($2 / 2 + 1))

echo "$(timestamp) - Passed in arguments: Cluster Hosts=$1, Number of Cluster Nodes=$2, Minimum Master Nodes=$minNodes" >> $LOGFILE 

# Add specified user and group
groupadd $ES_GROUP
useradd -g $ES_GROUP $ES_USER

# Configure OS level parameters 
ulimit -n $MAX_OPEN_FILES
ulimit -l $MAX_LOCKED_MEMORY
sysctl -q -w vm.max_map_count=$MAX_MAP_COUNT

# Add folders and assign permissions
chown -R $ES_USER:$ES_GROUP $ES_HOME

chown -R $ES_USER:$ES_GROUP $CONF_DIR

mkdir -p $DATA_DIR
chown $ES_USER:$ES_GROUP $DATA_DIR

mkdir -p $LOG_DIR
chown $ES_USER:$ES_GROUP $LOG_DIR

mkdir -p $PLUGIN_DIR
chown $ES_USER:$ES_GROUP $PLUGIN_DIR

mkdir -p $SCRIPT_DIR
chown $ES_USER:$ES_GROUP $SCRIPT_DIR
 
# Ensure that the PID_DIR exists (it is cleaned at OS startup time)
if [ -n $PID_DIR ] && [ ! -e $PID_DIR ]; then
  mkdir -p $PID_DIR && chown $ES_USER:$ES_GROUP $PID_DIR
fi
if [ -n $pidfile ] && [ ! -e $pidfile ]; then
  touch $pidfile && chown $ES_USER:$ES_GROUP $pidfile
fi

# Start the Elasticsearch as specified user
runuser -s /bin/bash $ES_USER -c "$exec -p $pidfile -Des.default.path.home=$ES_HOME -Des.default.path.logs=$LOG_DIR -Des.default.path.data=$DATA_DIR -Des.default.path.conf=$CONF_DIR --discovery.zen.ping.unicast.hosts=$1 --discovery.zen.minimum_master_nodes=$minNodes" >> $LOGFILE 2>&1
