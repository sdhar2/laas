####################################################################################
#Copyright 2015 ARRIS Enterprises, Inc. All rights reserved.
#This program is confidential and proprietary to ARRIS Enterprises, Inc. (ARRIS),
#and may not be copied, reproduced, modified, disclosed to others, published or used,
#in whole or in part, without the express prior written permission of ARRIS.
####################################################################################

# A docker image that includes
#
# - status and performance monitor for ELK

# Pull base image
FROM arrs/arrs-cloud-base-nodejs7-1:1.0.0.2
MAINTAINER ARRIS

# Install NodeJS packages
RUN npm install xmlbuilder

# Add local files
ADD fs /

# Move NodeJS source files and executables to installed locations 
WORKDIR /opt
RUN cp src/*.js /opt/webservice/routes
RUN cp bin/* /bin 

# Add start scripts run permission
RUN chmod +x /bin/start_perf_monitor.sh

CMD /bin/start_perf_monitor.sh
