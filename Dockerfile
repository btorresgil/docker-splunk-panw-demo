FROM splunk/splunk:6.6.2

MAINTAINER Brian Torres-Gil <btorresgil@dralth.com>

ENV SPLUNK_USER root
ENV REFRESHED_AT 2017-07-07
ENV APP_VERSION 5.4.1
ENV ADDON_VERSION 3.8.1 

RUN apt-get update && apt-get install -y wget

RUN mkdir /panw-apps

# Download the latest stable Palo Alto Networks App for Splunk

RUN wget -qO /SplunkforPaloAltoNetworks.tar.gz https://github.com/PaloAltoNetworks/SplunkforPaloAltoNetworks/archive/${APP_VERSION}.tar.gz
RUN tar -xvf /SplunkforPaloAltoNetworks.tar.gz -C /panw-apps/
RUN mv /panw-apps/SplunkforPaloAltoNetworks-${APP_VERSION} /panw-apps/SplunkforPaloAltoNetworks
RUN rm -f /SplunkforPaloAltoNetworks.tar.gz

# Download the latest stable Palo Alto Networks Add-on for Splunk
RUN wget -qO /Splunk_TA_paloalto.tar.gz https://github.com/PaloAltoNetworks/Splunk_TA_paloalto/archive/${ADDON_VERSION}.tar.gz
RUN tar -xzf /Splunk_TA_paloalto.tar.gz -C /panw-apps/
RUN mv /panw-apps/Splunk_TA_paloalto-${ADDON_VERSION} /panw-apps/Splunk_TA_paloalto

RUN rm -f /Splunk_TA_paloalto.tar.gz

# Download the latest stable Palo Alto Networks data generator app for Splunk
#RUN wget -qO /pan_datagen.tar.gz https://github.com/PaloAltoNetworks/Splunk-App-Data-Generator/archive/v3.0.tar.gz
#RUN tar -xzf /pan_datagen.tar.gz -C /panw-apps/
#RUN mv /panw-apps/Splunk-App-Data-Generator-3.0 /panw-apps/pan_datagen
#RUN rm -f /pan_datagen.tar.gz

# Download the latest stable Eventgen
RUN wget -qO /eventgen.tar.gz https://github.com/btorresgil/eventgen/archive/develop.tar.gz
RUN tar -xzf /eventgen.tar.gz -C /panw-apps/
RUN mv /panw-apps/eventgen-develop /panw-apps/SA-Eventgen
RUN rm -f /eventgen.tar.gz

# Add 514/udp syslog input to app
RUN mkdir /panw-apps/SplunkforPaloAltoNetworks/local
RUN mkdir /panw-apps/Splunk_TA_paloalto/local
RUN mkdir /panw-apps/SA-Eventgen/local
COPY inputs.conf /inputs.conf

RUN apt-get purge -y --auto-remove wget

COPY demo_entrypoint.sh /sbin/demo_entrypoint.sh
RUN chmod +x /sbin/demo_entrypoint.sh

# Ports Splunk Web, Splunk Daemon, KVStore, Splunk Indexing Port, Network Input, HTTP Event Collector
EXPOSE 8000/tcp 8089/tcp 8191/tcp 9997/tcp 1514 8088/tcp

WORKDIR /opt/splunk

# Configurations folder, var folder for everything (indexes, logs, kvstore)
VOLUME [ "/opt/splunk/etc", "/opt/splunk/var" ]

ENTRYPOINT ["/sbin/demo_entrypoint.sh"]
CMD ["start-service"]
