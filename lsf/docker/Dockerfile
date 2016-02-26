####################################################################################
#Copyright 2015 ARRIS Enterprises, Inc. All rights reserved.
#This program is confidential and proprietary to ARRIS Enterprises, Inc. (ARRIS),
#and may not be copied, reproduced, modified, disclosed to others, published or used,
#in whole or in part, without the express prior written permission of ARRIS.
####################################################################################

# A docker image that extends LSF and has all the mounted files reside inside of the docker container 
#

# Pull base image
FROM ccadllc/baseos-java-supervisor-logstash-forwarder:1.0.2
MAINTAINER ARRIS

ADD fs /
WORKDIR /
RUN chmod +x /opt/bin/createConfig.sh

CMD ./opt/bin/createConfig.sh && supervisord -c /etc/supervisord.conf
