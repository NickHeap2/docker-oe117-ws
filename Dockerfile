# as install using install files
FROM oe117-setup:latest AS as_install

# copy our response.ini in from our test install
COPY conf/response.ini /install/openedge/

#do a background progress install with our response.ini
RUN /install/openedge/proinst -b /install/openedge/response.ini -l silentinstall.log

# add in which & zip utility
RUN yum install -y\
  which \
  zip 

###############################################

# actual ws server image
FROM centos:7.3.1611

LABEL maintainer="Nick Heap (nickheap@gmail.com)" \
 version="0.1" \
 description="Webspeed Image for OpenEdge 11.7.2" \
 oeversion="11.7.2"

# Add Tini
ENV TINI_VERSION v0.17.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# copy openedge files in
COPY --from=as_install /usr/dlc/ /usr/dlc/
COPY --from=as_install /usr/bin/which /usr/bin/
COPY --from=as_install /usr/bin/zip /usr/bin/

# the directories for the appserver code
RUN mkdir -p /var/lib/openedge/base/ && mkdir -p /var/lib/openedge/code/

# add startup script
WORKDIR /var/lib/openedge/code/

COPY scripts/ /var/lib/openedge/

# set required vars
ENV \
 TERM="xterm" \
 JAVA_HOME="/usr/dlc/jdk/bin" \
 PATH="$PATH:/usr/dlc/bin:/usr/dlc/jdk/bin" \
 DLC="/usr/dlc" \
 WRKDIR="/usr/wrk" \
 PROCFG="" \
 NAMESERVER_HOST="localhost" \ 
 NAMESERVER_PORT="5162" \
 NAMESERVER_NAME="NS1" \ 
 WEBSPEED_PORT="3055" \
 WEBSPEED_SERVICE="wsbroker1" \
 WEBSPEED_MINPORT="3202" \
 WEBSPEED_MAXPORT="3502" \
 ADMINSERVER_PORT="20931" \
 WEBSPEED_STARTUP="-p web/objects/web-disp.p -weblogerror" \
 PROPATH="/var/lib/openedge/base/:/var/lib/openedge/code/" \
 WEBSPEED_INITIAL_AGENTS="1" \
 WEBSPEED_MIN_AGENTS="1" \
 WEBSPEED_MAX_AGENTS="2" \
 LOGGING_LEVEL="2" \
 LOG_ENTRY_TYPES="DB.Connects"

# volume for application code
VOLUME /var/lib/openedge/code/
VOLUME /usr/wrk/

EXPOSE $ADMINSERVER_PORT $NAMESERVER_PORT/udp $WEBSPEED_PORT $WEBSPEED_MINPORT-$WEBSPEED_MAXPORT

# Run start.sh under Tini
CMD ["/var/lib/openedge/start.sh"]

