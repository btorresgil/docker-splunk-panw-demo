FROM splunk/splunk:8.0.2.1
LABEL authors "Brian Torres-Gil <brian@ixi.us>,Paul Nguyen <panguyen@paloaltonetworks.com>"

# Versions
ENV SPLUNK_USER root
ENV REFRESHED_AT 2020-04-03
ENV APP_VERSION 6.2.0
ENV ADDON_VERSION 6.2.0 
ENV EVENTGEN_VERSION develop

USER root
RUN mkdir /panw-apps

# Download the latest stable Palo Alto Networks App for Splunk

RUN wget -qO /SplunkforPaloAltoNetworks.tar.gz https://github.com/PaloAltoNetworks/SplunkforPaloAltoNetworks/archive/${APP_VERSION}.tar.gz
RUN tar -xvf /SplunkforPaloAltoNetworks.tar.gz -C /panw-apps/
RUN mv /panw-apps/SplunkforPaloAltoNetworks-${APP_VERSION} /panw-apps/SplunkforPaloAltoNetworks
RUN rm -f /SplunkforPaloAltoNetworks.tar.gz
RUN mkdir /panw-apps/SplunkforPaloAltoNetworks/local
COPY datamodels.conf /panw-apps/SplunkforPaloAltoNetworks/local/datamodels.conf
COPY inputs.conf /panw-apps/SplunkforPaloAltoNetworks/local/inputs.conf
RUN cd /panw-apps; tar czvf /panw-apps/SplunkforPaloAltoNetworks.tgz SplunkforPaloAltoNetworks

# Download the latest stable Palo Alto Networks Add-on for Splunk
RUN wget -qO /Splunk_TA_paloalto.tar.gz https://github.com/PaloAltoNetworks/Splunk_TA_paloalto/archive/${ADDON_VERSION}.tar.gz
RUN tar -xzf /Splunk_TA_paloalto.tar.gz -C /panw-apps/
RUN mv /panw-apps/Splunk_TA_paloalto-${ADDON_VERSION} /panw-apps/Splunk_TA_paloalto
RUN rm -f /Splunk_TA_paloalto.tar.gz
COPY samples /panw-apps/Splunk_TA_paloalto/samples
COPY files/eventgen.conf /panw-apps/Splunk_TA_paloalto/default/eventgen.conf
COPY files/eventgen.conf.spec /panw-apps/Splunk_TA_paloalto/README/eventgen.conf.spec
COPY files/eventgen_kvstore_loader.py /panw-apps/Splunk_TA_paloalto/bin/eventgen_kvstore_loader.py
RUN cd /panw-apps; tar czvf /panw-apps/Splunk_TA_paloalto.tgz Splunk_TA_paloalto

# Download the latest stable Eventgen
RUN wget -qO /eventgen.tar.gz https://github.com/btorresgil/eventgen/archive/${EVENTGEN_VERSION}.tar.gz
# RUN wget -qO /eventgen.tar.gz https://github.com/splunk/eventgen/archive/${EVENTGEN_VERSION}.tar.gz
RUN tar -xzf /eventgen.tar.gz -C /panw-apps/
RUN mv /panw-apps/eventgen-${EVENTGEN_VERSION} /panw-apps/SA-Eventgen
RUN rm -f /eventgen.tar.gz
RUN cd /panw-apps; tar czvf /panw-apps/eventgen.tgz SA-Eventgen

# Add 514/udp syslog input to app
RUN mkdir /panw-apps/Splunk_TA_paloalto/local

COPY demo_entrypoint.sh /sbin/demo_entrypoint.sh
RUN chmod +x /sbin/demo_entrypoint.sh

# Ports Splunk Web, Splunk Daemon, KVStore, Splunk Indexing Port, Network Input, HTTP Event Collector
EXPOSE 8000/tcp 8089/tcp 8191/tcp 9997/tcp 1514 8088/tcp

WORKDIR /opt/splunk

# Splunk configuration
ENV SPLUNK_HOME /opt/splunk
ENV SPLUNK_START_ARGS --accept-license
ENV SPLUNK_PASSWORD paloalto
# ENV SPLUNK_LICENSE_URI Free
ENV SPLUNK_APPS_URL "/panw-apps/SplunkforPaloAltoNetworks.tgz,/panw-apps/Splunk_TA_paloalto.tgz,/panw-apps/eventgen.tgz"

# Configurations folder, var folder for everything (indexes, logs, kvstore)
VOLUME [ "/opt/splunk/etc", "/opt/splunk/var" ]

ENTRYPOINT ["/sbin/demo_entrypoint.sh"]
CMD ["start-service"]
