#!/bin/sh

set -e

signal_handler() {

    echo "Stopping container"
    # stop the webspeed, name server and adminserver
    echo "Stopping webspeed wsbroker1"
    asbman -stop -name wsbroker1
    echo "Stopping name server NS1"
    nsman -stop -name NS1
    echo "Stopping admin server"
    proadsv -stop

    # graceful shutdown so exit with 0
    exit 0
}
# trap SIGTERM and call the handler to cleanup processes
trap 'signal_handler' SIGTERM SIGINT

# replace values in ubroker.properties file
sed  "s|3055|${WEBSPEED_PORT}|g;s|wsbroker1|${WEBSPEED_SERVICE}|g;s|3202|${WEBSPEED_MINPORT}|g;s|3502|${WEBSPEED_MAXPORT}|g;s|-p web\/objects\/web-disp.p -weblogerror|${WEBSPEED_STARTUP}|g;s|PROPATH=\${PROPATH}:\${WRKDIR}|PROPATH=${PROPATH}|g;s|5162|${NAMESERVER_PORT}|g;s|srvrLoggingLevel=2|srvrLoggingLevel=${LOGGING_LEVEL}|g;s|srvrLogEntryTypes=DB.Connects|srvrLogEntryTypes=${LOG_ENTRY_TYPES}|g;s|workDir=\$WRKDIR|workDir=\/var\/lib\/openedge\/code\/|g;s|initialSrvrInstance=5|initialSrvrInstance=${WEBSPEED_INITIAL_AGENTS}|g;s|minSrvrInstance=1|minSrvrInstance=${WEBSPEED_MIN_AGENTS}|g;s|maxSrvrInstance=10|maxSrvrInstance=${WEBSPEED_MAX_AGENTS}|g" /usr/dlc/properties/ubroker.properties > /usr/dlc/properties/ubroker.properties.new
mv /usr/dlc/properties/ubroker.properties.new /usr/dlc/properties/ubroker.properties

# are we using an external nameserver?
# if [ ! -z "${NAMESERVER_HOST}" ]
# then
#   sed  "s|autoStart=1|autoStart=0|g;s|localhost|${NAMESERVER_HOST}|g" /usr/dlc/properties/ubroker.properties > /usr/dlc/properties/ubroker.properties.new
#   mv /usr/dlc/properties/ubroker.properties.new /usr/dlc/properties/ubroker.properties
# fi

# first start the admin server
echo "Starting admin server"
proadsv -port ${ADMINSERVER_PORT} -start

RETRIES=0
while true
do
  if [ "${RETRIES}" -gt 10 ]
  then
    echo "$(date +%F_%T) ERROR: AdminServer didn't start so exiting."
    exit 1
  fi

  if proadsv -query; then
    break;
  fi

  sleep 1
  RETRIES=$((RETRIES+1))
done

# let the nameserver auto start with the admin server
# then the nameserver NS1
echo "Starting name server NS1"
nsman -port ${ADMINSERVER_PORT} -start -name NS1

RETRIES=0
while true
do
  if [ "${RETRIES}" -gt 10 ]
  then
    echo "$(date +%F_%T) ERROR: NameServer didn't start so exiting."
    exit 1
  fi

  if nsman -query -name NS1; then
    break;
  fi

  sleep 1
  RETRIES=$((RETRIES+1))
done

# next start webspeed broker
echo "Starting webspeed ${WEBSPEED_SERVICE}"
wtbman -port ${ADMINSERVER_PORT} -start -name ${WEBSPEED_SERVICE}

# get webspeed pid 
echo "Waiting for webspeed to start..."

RETRIES=0
while true
do
  if [ "${RETRIES}" -gt 10 ]
  then
    break
  fi

  pid=`ps aux|grep '[I]D=WebSpeed'|awk '{print $2}'`
  if [ ! -z "${pid}" ]
  then
    case "${pid}" in
      ''|*[!0-9]*) continue ;;
      *) break ;;
    esac
  fi
  sleep 1
  RETRIES=$((RETRIES+1))
done
# did we get the pid?
if [ -z "${pid}" ]
then
  echo "$(date +%F_%T) ERROR: Webspeed process not found exiting."
  exit 1
fi

echo "Webspeed running as pid: ${pid}"

# keep tailing log file until webspeed process exits
tail --pid=${pid} -f /usr/wrk/${WEBSPEED_SERVICE}.server.log & wait ${!}

# things didn't go well
exit 1
