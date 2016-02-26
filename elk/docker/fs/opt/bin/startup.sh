#!/bin/sh

# Cluster node discovery parameters
NODE_DISCOVERY_POLLING_TIMEOUT=180
NODE_DISCOVERY_POLLING_INTERVAL=1
NODE_DISCOVERY_LOGGING_INTERVAL=5
ELK_KEY_DIR="/etc/elk/keys"
ELK_KEY_FILE="/etc/elk/keys/server-private-key-nopassphrase.pem"
ELK_CERT_FILE="/etc/elk/keys/server-cert.pem"

LOGFILE="/var/log/elk/startup.log"
CURATORLOGFILE="/var/log/elk/curator.log"

timestamp() {
  date --rfc-3339=seconds
}

echo "$(timestamp) - ======= Start up Arris ELK ====== " >> $LOGFILE
echo "$(timestamp) - Passed in environments: ES_HEAP_SIZE=$ES_HEAP_SIZE, LS_HEAP_SIZE=$LS_HEAP_SIZE, HOST_IP=$HOST_IP, HOST_NAME=$HOST_NAME, NUM_CLUSTER_NODES=$NUM_CLUSTER_NODES" >> $LOGFILE 

# Move the key file and start the health key management
cp /etcd/config/*.json /opt/etcd/config/

/opt/bin/manageHealthKey.sh 60 60 &

/opt/bin/createConfig.sh

# Validate that SSL keys and certificates exist
if [ ! -d $ELK_KEY_DIR ] ||
   [ ! -e $ELK_CERT_FILE ] ||
   [ ! -e $ELK_KEY_FILE ]; then
  echo "Required SSL keys and certificates are missing, aborting"
  exit 1
fi

# Poll etcd to wait until either all elk nodes are discovered or timeout
etcdEndPoint=`host etcdCluster | cut -d " " -f4`:4001
numOfElkNodes=0
numOfPolls=0

while [ $numOfElkNodes -ne $NUM_CLUSTER_NODES ] && [ $numOfPolls -le $NODE_DISCOVERY_POLLING_TIMEOUT ]
do
  numOfElkNodes=`etcdctl -no-sync -peers $etcdEndPoint ls /laas/elk | wc -l`
  sleep $NODE_DISCOVERY_POLLING_INTERVAL
  numOfPolls=$((numOfPolls + 1))

  if [[ $(($numOfPolls % $NODE_DISCOVERY_LOGGING_INTERVAL )) -eq 0 ]]; then
    echo "$(timestamp) - Polling etcdCluster ($etcdEndPoint), number of ELK nodes: $numOfElkNodes" >> $LOGFILE
    numOfPolls=0
  fi
done

if [[ $numOfElkNodes -ne $NUM_CLUSTER_NODES ]]; then
  echo "$(timestamp) - Number of ELK nodes: $numOfElkNodes. No enough nodes discovered to form ELK cluster after the timeout period, aborting" >> $LOGFILE
  exit 1
else
  echo "$(timestamp) - Number of ELK nodes: $numOfElkNodes, all nodes in the cluster are discovered" >> $LOGFILE
fi

# Build the ES_CLUSTER_HOSTS string
elkNodeKeys=`etcdctl -no-sync -peers $etcdEndPoint ls /laas/elk`
esClusterHosts=""
for elkNodeKey in $elkNodeKeys; do
  elkNodeValue=`etcdctl -no-sync -peers $etcdEndPoint get $elkNodeKey`
  esClusterHosts="$elkNodeValue,$esClusterHosts"
done

esClusterHosts=`echo "${esClusterHosts%?}"`

echo "$(timestamp) - Host IP: $HOST_IP, Host IP List in Cluster: $esClusterHosts" >> $LOGFILE

/opt/bin/initElasticsearch.sh $esClusterHosts $NUM_CLUSTER_NODES &

sleep 10 

/opt/bin/initKibana.sh &

sleep 10

/opt/bin/curator.sh  >> $CURATORLOGFILE 2>&1 &

sleep 10

/opt/bin/initLogstash.sh 
