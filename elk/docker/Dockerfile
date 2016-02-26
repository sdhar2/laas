####################################################################################
#Copyright 2015 ARRIS Enterprises, Inc. All rights reserved.
#This program is confidential and proprietary to ARRIS Enterprises, Inc. (ARRIS),
#and may not be copied, reproduced, modified, disclosed to others, published or used,
#in whole or in part, without the express prior written permission of ARRIS.
####################################################################################

# The docker image that contains Elasticsearch, Logstash and Kibana to support ACP
# logging services
#

# Pull base image
FROM arrs/arrs-cloud-base-java1-8:2.0.0.1
MAINTAINER ARRIS

# Install wget
RUN yum install -y wget

# Retrieve and install the archives of Elasticsearch, Logstash and Kibana
RUN wget -q -P /opt http://areopagus/binaries/elasticsearch-2.1.1.tar.gz && cd /opt && tar -zxf elasticsearch-2.1.1.tar.gz && rm -rf elasticsearch-2.1.1.tar.gz && mv elasticsearch-2.1.1 elasticsearch

RUN wget -q -P /opt http://areopagus/binaries/logstash-2.1.1.tar.gz && cd /opt && tar -zxf logstash-2.1.1.tar.gz && rm -rf logstash-2.1.1.tar.gz && mv logstash-2.1.1 logstash

RUN wget -q -P /opt http://areopagus/binaries/kibana-4.3.1-linux-x64.tar.gz && cd /opt && tar -zxf kibana-4.3.1-linux-x64.tar.gz && rm -rf kibana-4.3.1-linux-x64.tar.gz && mv kibana-4.3.1-linux-x64 kibana

RUN yum install -y bc
RUN yum install -y python-pip
RUN pip install --upgrade setuptools

RUN wget -q -P /opt http://areopagus/binaries/elasticsearch-curator-3.4.0.tar.gz && cd /opt && pip install elasticsearch-curator-3.4.0.tar.gz && tar -zxf elasticsearch-curator-3.4.0.tar.gz && rm -rf elasticsearch-curator-3.4.0.tar.gz && mv elastic-curator-9844675 curator

RUN wget -q -P /opt http://areopagus/binaries/elasticsearch-kopf-2.1.2.zip && /opt/elasticsearch/bin/plugin install file:///opt/elasticsearch-kopf-2.1.2.zip && rm -rf /opt/elasticsearch-kopf-2.1.2.zip

# Add local files
ADD fs /

# Create ELK folders
RUN mkdir -p /etc/elk/keys
RUN chmod 666 /etc/elk/keys
RUN mkdir -p /var/log/elk
RUN chmod 777 /var/log/elk

WORKDIR /
RUN chmod +x /opt/bin/initElasticsearch.sh
RUN chmod +x /opt/bin/initLogstash.sh
RUN chmod +x /opt/bin/initKibana.sh
RUN chmod +x /opt/bin/createConfig.sh
RUN chmod +x /opt/bin/manageHealthKey.sh
RUN chmod +x /opt/bin/startup.sh
RUN chmod +x /opt/bin/curator.sh
RUN chmod +x /etc/curator/curator.conf
RUN chmod +x /usr/local/bin/etcdctl

# Default environment variables for elasticsearch
ENV ES_MIN_MASTER_NODES 2
ENV ES_MASTER_ELIGIBLE true
ENV ES_DATA_ELIGIBLE true
ENV ES_DATACENTER default

# Heap allocated to elasticsearch
ENV ES_HEAP_SIZE 4g

# Heap allocated to logstash
ENV LS_HEAP_SIZE 2g

# Copy modified kibana UI request handler to resolve the kopf access issue
RUN cp /etc/kibana/index.js /opt/kibana/src/ui/.

CMD ./opt/bin/startup.sh
