FROM btorresgil/splunk

MAINTAINER Brian Torres-Gil <btorresgil@dralth.com>

ENV REFRESHED_AT 2015-10-02

# Install unzip
RUN yum install -y unzip

# Download the latest stable Palo Alto Networks app for Splunk
RUN wget -O /SplunkforPaloAltoNetworks.zip https://github.com/PaloAltoNetworks-BD/SplunkforPaloAltoNetworks/archive/master.zip
RUN unzip /SplunkforPaloAltoNetworks.zip -d /opt/splunk/etc/apps/
RUN mv /opt/splunk/etc/apps/SplunkforPaloAltoNetworks-master /opt/splunk/etc/apps/SplunkforPaloAltoNetworks
RUN rm -f /SplunkforPaloAltoNetworks.zip

# Download the latest stable Palo Alto Networks data generator app for Splunk
RUN wget -O /pan_datagen.zip https://github.com/PaloAltoNetworks-BD/Splunk-App-Data-Generator/archive/master.zip
RUN unzip /pan_datagen.zip -d /opt/splunk/etc/apps/
RUN mv /opt/splunk/etc/apps/Splunk-App-Data-Generator-master /opt/splunk/etc/apps/pan_datagen
RUN rm -f /pan_datagen.zip

# Add data generator user
RUN echo './bin/splunk add user pan -password pan -role pan -auth admin:${_SPLUNK_PW}'

# Add 514/udp syslog input to app
RUN mkdir /opt/splunk/etc/apps/SplunkforPaloAltoNetworks/local
COPY inputs.conf /opt/splunk/etc/apps/SplunkforPaloAltoNetworks/local/inputs.conf

VOLUME /opt/splunk/var/lib/splunk

EXPOSE 8000 8089 9997 514/udp

ENTRYPOINT ["/bin/bash", "-e", "/init/start"]
CMD ["run"]
