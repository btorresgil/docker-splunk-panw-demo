#/bin/sh

##
## How to use this installer (and upgrader)
##

# Check that docker is installed
command -v docker >/dev/null 2>&1 || { echo >&2 "Docker is not installed yet.  Aborting."; exit 1; }

# Create a blank license file if none exists
touch $PWD/license.lic

# Shut down any current splunk-demo
docker rm -fv splunk-demo >/dev/null

# docker pull latest version of demo
docker pull btorresgil/splunk-panw-demo

# docker rmi <none> images
docker rmi $(docker images -f "dangling=true" -q) >/dev/null 2>&1

# docker run w/ many volumes in the local directory
docker run -d --name splunk-demo -p 8000:8000 -p 514:514/udp -e SPLUNK_PW=paloalto -v $PWD/license.lic:/license.lic -v $PWD/db:/opt/splunk/var/lib/splunk -v $PWD/system-local:/opt/splunk/etc/system/local -v $PWD/users-local:/opt/splunk/etc/users -v $PWD/app-local:/opt/splunk/etc/apps/SplunkforPaloAltoNetworks/local btorresgil/splunk-panw-demo
