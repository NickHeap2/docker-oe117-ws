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

# replace the tags in the template file into ubroker.properties
#sed  's|<WEBSPEED_PORT>|'"${WEBSPEED_PORT}"'|;s|<WEBSPEED_SERVICE>|'"${WEBSPEED_SERVICE}"'|;s|<WEBSPEED_MINPORT>|'"${WEBSPEED_MINPORT}"'|;s|<WEBSPEED_MAXPORT>|'"${WEBSPEED_MAXPORT}"'|;s|<WEBSPEED_STARTUP>|'"${WEBSPEED_STARTUP}"'|;s|<PROPATH>|'"${PROPATH}"'|' /usr/dlc/properties/template.ubroker.properties > /usr/dlc/properties/ubroker.properties
sed  "s|<WEBSPEED_PORT>|${WEBSPEED_PORT}|;s|<WEBSPEED_SERVICE>|${WEBSPEED_SERVICE}|;s|<WEBSPEED_MINPORT>|${WEBSPEED_MINPORT}|;s|<WEBSPEED_MAXPORT>|${WEBSPEED_MAXPORT}|;s|<WEBSPEED_STARTUP>|${WEBSPEED_STARTUP}|;s|<PROPATH>|${PROPATH}|;s|<NAMESERVER_PORT>|${NAMESERVER_PORT}|" /usr/dlc/properties/template.ubroker.properties > /usr/dlc/properties/ubroker.properties

# first start the admin server
echo "Starting admin server"
proadsv -port 20932 -start

# let the nameserver auto start with the admin server
# then the nameserver NS1
#echo "Starting name server NS1"
#nsman -start -name NS1

# next start asbroker1
echo "Starting webspeed wsbroker1"
wtbman -port 20932 -start -name wsbroker1

# get appserver pid 
pid=`ps aux|grep '[I]D=WebSpeed'|awk '{print $2}'`
if [ -z "${pid}" ]
then
  echo "ERROR: Webspeed failed to start!"
  exit 1
fi
echo "Webspeed running as pid: ${pid}"

# keep tailing log file until webspeed process exits
tail --pid=${pid} -f wsbroker1.server.log & wait ${!}

# things didn't go well
exit 1
