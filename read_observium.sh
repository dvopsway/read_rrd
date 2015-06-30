#!/bin/sh

#define directories
SCRIPT_DIRECTORY=$PWD
TEMP_DIR="/tmp"
TEMP_DATA_FILE="$TEMP_DIR/temp_rrd.txt"
TEMP_FILE_LIST="$TEMP_DIR/temp_rrd_files.txt"
OBSERVIUM_PATH="/opt/observium"
RRDDATA_PATH="$OBSERVIUM_PATH/rrd"

#include hostname of all the network devices to be monitored
NETWORK_DEVICES=("qabigip1.mmt.com")

# import data from rrdfile
for (( index=0; index<${#NETWORK_DEVICES[@]}; index++ ))
do
  cd $RRDDATA_PATH/${NETWORK_DEVICES[$index]}
  ls -l > $TEMP_FILE_LIST

  #operation on one interface
  (cat $TEMP_FILE_LIST)|while read LINE
  do

    #echo $LINE

    #grab file name
    FILE=`echo $LINE | awk '{print $9}'`

    #fetch rrd data for last 5 minutes
    rrdtool fetch $FILE AVERAGE  -r 5m -s -300s > $TEMP_DATA_FILE

    HEADER=`head -1 $TEMP_DATA_FILE`
    HEADER_ARRAY=(`echo $HEADER | cut -d " "  --output-delimiter=" " -f 1-`)

    #clean up file
    sed -i -e '1,2d' $TEMP_DATA_FILE
    sed -i -e '$d' $TEMP_DATA_FILE

    DATA=`cat $TEMP_DATA_FILE`

    for (( index=0; index<${#HEADER_ARRAY[@]}; index++ ))
    do
      num=`expr $index + 2`
      PARAM_VALUE=`echo $DATA | awk -v var="$num" '{print $var}'| awk '{$0 = sprintf ("%.2f", $0) ;print}'`
      echo "python call for ${HEADER_ARRAY[$index]} will be : $: python metricstoopentsdb.py --push_method=own --group_name=network_device --metric_name=${HEADER_ARRAY[$index]} --metric_value=$PARAM_VALUE --tags=hostname=${NETWORK_DEVICES[$index]},report=hourly"
    done
  done
done

#cleanup temp data
rm -rf $TEMP_DATA_FILE
rm -rf $TEMP_PORTS_FILE
