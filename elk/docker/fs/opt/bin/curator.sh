#!/bin/bash
###
# ES Data Retention Policy
#
# ELK container needs to run in a lights-out environment. To this end, it needs to account for the growth of search
# indices over time. The container should make every attempt to not run of disk space by pruning older indexes.
#
# Mechanism
# A process will wake up at a configured period and make sure that the used disk space is less than a user-configured
# percentage 90%, If the disk space is greater than 75%, we write a warning message to a log file, if the disk space is
# greater than 90%, we write an critical alart message to log, file and we attempt to purge the data,
# stopping as soon as  we free space and the used disk space is less than 75% again
#
#
###
# Default configuration.  User-provided configuration may be specified at /etc/curator/curator.conf

# Period to run at, example NUMBER[SUFFIX].  Where SUFFIX is: s -> seconds (default), m -> minutes, h -> hours, d -> days.
WAKE_UP_PERIOD=10m

# Minimum days of dev log data
MIN_DAYS_DEVLOG=7


# Humanized used disk space
humanized_space=""
space_used_percentage=0
space_used_percentage_in_string=""
critical_disk_space=0.90
warning_disk_space=0.75

# Converts a humanize space string (2g) and converts into bytes integer
function toPercentage() {
  hum=$1
  len=${#hum}
  num=${hum:0:len-1}
  space_used_percentage=$(bc -l <<<$num/100)
}
# Computes the space used (in percentage) to elasticsearch
function space_used() {
  space_used_percentage_in_string=`df -k --direct /var/lib/elasticsearch/ | tail -n +2 | awk '{print $5}'`
  toPercentage $space_used_percentage_in_string
}

# Computes the space avaibile (in humanized form) to elastic search
function space_humanized() {
  humanized_space=`df -h --direct /var/lib/elasticsearch/ | tail -n +2 | awk '{print $4}'`
}

# Issues curator delete commands until either retention limits are hit
# or enough disk space is freed
function delete_with_extended_retention() {
  # index prefix
  prefix=$1
  # time pattern of the index
  time_string=$2
  # configured period to keep
  period=$3

  # We start pruning at 4x the configured period and continue
  # pruning down to the configured period until we free up the desired space.
  retention=4


  while [[  $retention -gt 0 &&  $(bc <<< "$space_used_percentage > $warning_disk_space") -eq 1 ]];
  do
    older_than=$((period * retention))

    # delete indexes older than (period * retention)
    echo "$(date --utc +%FT%TZ) Deleting indexes with older than $older_than days"
    #curator --master-only delete --older-than $older_than --timestring "$time_string"
    /opt/curator/run_curator.py --master-only delete indices --older-than $older_than --time-unit days --timestring "$time_string"

    # decrement retention period
    ((retention--))
    # recompute available disk space
    space_used
    space_humanized
    echo "$(date --utc +%FT%TZ) Current available disk = $humanized_space and space_used_percentage_in_string is $space_used_percentage_in_string"
  done

  # If the used space is still greater than 75%
  remaining_days=$period
  while [[  $remaining_days -gt 1 && $(bc <<< "$space_used_percentage > $warning_disk_space") -eq 1 ]];
  do
    ((remaining_days--))

    # delete indexes older than (remaining_days -1)
   echo "$(date --utc +%FT%TZ) Deleting indexes with prefix '$prefix' and older than $remaining_days days"
   #curator --master-only delete --older-than $remaining_days --timestring "$time_string"
   /opt/curator/run_curator.py --master-only delete indices --older-than $remaining_days --time-unit days --timestring "$time_string"

   # recompute available disk space
    space_used
    space_humanized
    echo "$(date --utc +%FT%TZ) Current available disk = $humanized_space and space_used_percentage_in_string is $space_used_percentage_in_string"
  done

  if [ $(bc <<< "$space_used_percentage > $warning_disk_space") -eq 1 ]
  then
    echo "$(date --utc +%FT%TZ) CRITICAL: after curator, the disk space used by the logging system exceeds 75% of capacity!!! "
  fi
}


function curate() {
  space_used
  space_humanized
  echo "$(date --utc +%FT%TZ) Current available disk = $humanized_space and space used in percentage = $space_used_percentage_in_string"


  if [ $(bc <<< "$space_used_percentage > $critical_disk_space") -eq 1 ]
  then
     echo "$(date --utc +%FT%TZ) CRITICAL: Before curator, the disk space used by the logging system exceeds 90% of capacity!!!"
  elif [ $(bc <<< "$space_used_percentage > $warning_disk_space") -eq 1 ]
  then
    echo "$(date --utc +%FT%TZ) WARN:  Before curator, the disk space used by the logging system exceeds 75% of capacity!!!"
  fi

  # Disable bloom filters on all indexes older than 2 days.
  # This essentially closes the index for writing, freeing up resources, but is still available for searches.
  echo "$(date --utc +%FT%TZ) Disabling bloom filters on older indexes"
  #curator --master-only bloom --older-than 2
  /opt/curator/run_curator.py --master-only bloom indices --older-than 2 --time-unit days --timestring '%Y.%m.%d'

  if [ $(bc <<< "$space_used_percentage > $critical_disk_space") -eq 1 ]
  then
    # delete logstash-{date} indexes with retention fallback. i.e. min_period times retention period with decrementing retention period
    # trying to keep as much data as possible
    echo "$(date --utc +%FT%TZ) Removing older dev log indexes"
    delete_with_extended_retention "logstash-" "%Y.%m.%d" $MIN_DAYS_DEVLOG

    space_humanized
    space_used
    echo "$(date --utc +%FT%TZ) After deleting all old dev log index, current available disk = $humanized_space and space_used_percentage_in_string is $space_used_percentage_in_string"
  fi
}

# curate repeatedly
while true
do
  # load external configuration. must be an executable bash shell script that can override above mentioned attributes.
  if [ -f /etc/curator/curator.conf ]; then
    . /etc/curator/curator.conf
  fi

  echo "$(date --utc +%FT%TZ) About to curate logs"
  curate
  echo "$(date --utc +%FT%TZ) Curation done. Sleeping for $WAKE_UP_PERIOD"
  sleep ${WAKE_UP_PERIOD}
done

