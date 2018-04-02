#!/bin/sh

set -e

signal_handler() {

    echo "Stopping container"
    # stop the webspeed, name server and adminserver
    #echo "Stopping webspeed wsbroker1"
    #asbman -stop -name wsbroker1
    #echo "Stopping name server NS1"
    #nsman -stop -name NS1
    #echo "Stopping admin server"
    #proadsv -stop

    # graceful shutdown so exit with 0
    exit 0
}
# trap SIGTERM and call the handler to cleanup processes
trap 'kill ${!}; signal_handler' SIGTERM SIGINT

# replace values in ubroker.properties file
sed  "s|3055|${WEBSPEED_PORT}|g;s|wsbroker1|${WEBSPEED_SERVICE}|g;s|3202|${WEBSPEED_MINPORT}|g;s|3502|${WEBSPEED_MAXPORT}|g;s|-p web\/objects\/web-disp.p -weblogerror|${WEBSPEED_STARTUP}|g;s|PROPATH=\${PROPATH}:\${WRKDIR}|PROPATH=${PROPATH}|g;s|5162|${NAMESERVER_PORT}|g;s|srvrLoggingLevel=2|srvrLoggingLevel=${LOGGING_LEVEL}|g;s|srvrLogEntryTypes=DB.Connects|srvrLogEntryTypes=${LOG_ENTRY_TYPES}|g;s|workDir=\$WRKDIR|workDir=\/var\/lib\/openedge\/code\/|g;s|initialSrvrInstance=5|initialSrvrInstance=1|g;s|maxSrvrInstance=10|maxSrvrInstance=2|g" /usr/dlc/properties/ubroker.properties > /usr/dlc/properties/ubroker.properties.new
mv /usr/dlc/properties/ubroker.properties.new /usr/dlc/properties/ubroker.properties

# first start the admin server
echo "Starting admin server"
proadsv -port ${ADMINSERVER_PORT} -start

# let the nameserver auto start with the admin server
# then the nameserver NS1
#echo "Starting name server NS1"
#nsman -port ${ADMINSERVER_PORT} -start -name NS1

# next start webspeed broker
echo "Starting webspeed ${WEBSPEED_SERVICE}"
wtbman -port ${ADMINSERVER_PORT} -start -name ${WEBSPEED_SERVICE}

# get appserver pid 
pid=`ps aux|grep '[I]D=WebSpeed'|awk '{print $2}'`
if [ -z "${pid}" ]
then
  echo "ERROR: Webspeed failed to start!"
  exit 1
fi
echo "Webspeed running as pid: ${pid}"

# keep tailing log file until webspeed process exits
tail --pid=${pid} -f /usr/wrk/${WEBSPEED_SERVICE}.server.log & wait ${!}

# things didn't go well
exit 1
