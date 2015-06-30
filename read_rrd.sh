#!/bin/sh

#define directories
SCRIPT_DIRECTORY=$PWD
TEMP_DIR="/tmp"
TEMP_DATA_FILE="$TEMP_DIR/temp_rrd.txt"
TEMP_PORTS_FILE="$TEMP_DIR/temp_ports.txt"
OBSERVIUM_PATH="/opt/observium"
RRDDATA_PATH="$OBSERVIUM_PATH/rrd"

#include hostname of all the network devices to be monitored
NETWORK_DEVICES=("qabigip1.mmt.com")

# import data from rrdfile
for (( index=0; index<${#NETWORK_DEVICES[@]}; index++ ))
do
  cd $RRDDATA_PATH/${NETWORK_DEVICES[$index]}
  ls -l port* > $TEMP_PORTS_FILE

  #operation on one interface
  (cat $TEMP_PORTS_FILE)|while read LINE
  do

    #grab file name
    FILE=`echo $LINE | awk '{print $9}'`

    #fetch rrd data for last 5 minutes
    rrdtool fetch $FILE AVERAGE  -r 5m -s -300s > $TEMP_DATA_FILE

    #clean up file
    sed -i -e '1,2d' $TEMP_DATA_FILE
    sed -i -e '$d' $TEMP_DATA_FILE
    
    #parsing file
    LINE=`cat $TEMP_DATA_FILE`
    # TIME=`echo $LINE | awk '{print $1}' | rev | cut -c 2- | rev`
    # TIME=`date -d @$TIME`
    IN_OCTET=`echo $LINE | awk '{print $2}' | awk '{$0 = sprintf ("%.2f", $0) ;print}'`
    OUT_OCTET=`echo $LINE | awk '{print $3}' | awk '{$0 = sprintf ("%.2f", $0) ;print}'`

    #pushing data to Opentsdb
    echo "python call for inoctet will be : $: python metricstoopentsdb.py --push_method=diamond --group_name=network_device --metric_name=IN_OCTET --metric_value=$IN_OCTET --tags=hostname=qabigip1.mmt.com,report=hourly"
    echo "python call for outoctet will be : $: python metricstoopentsdb.py --push_method=diamond --group_name=network_device --metric_name=OUT_OCTET --metric_value=$OUT_OCTET --tags=hostname=qabigip1.mmt.com,report=hourly"
  done
done

#cleanup temp data
rm -rf $TEMP_DATA_FILE
rm -rf $TEMP_PORTS_FILE
