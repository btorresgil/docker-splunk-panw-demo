#!/bin/sh

##
## How to use this installer (and upgrader)
##

# Check that docker is installed
command -v docker >/dev/null 2>&1 || { echo >&2 "Docker is not installed yet.  Aborting."; exit 1; }

# Check if a system-local directory exists
# This determines if fresh install or existing install
if [ -d "$PWD/system-local" ]; then
    echo "Found existing Splunk config in local directory. Performing upgrade."
    if [ -d "$PWD/auth-local" ]; then
        UPGRADE="-e SPUNK_EXISTING_CONFIG=true"
    else
        echo "No auth-local directory, upgrade impossible. Resetting image and upgrading."
        UPGRADE=""
        rm -rf db system-local users-local auth-local
    fi
else
    echo "No existing Splunk config. Performing fresh install."
    UPGRADE=""
fi

# Create a blank license file if none exists
touch $PWD/license.lic

# Destroy any current splunk-demo
docker rm -fv splunk-demo >/dev/null 2>&1

# docker pull latest version of demo
docker pull btorresgil/splunk-panw-demo

# docker rmi <none> images
docker rmi $(docker images -f "dangling=true" -q) >/dev/null 2>&1

# docker run w/ many volumes in the local directory
docker run -d --name splunk-demo \
    -e SPLUNK_PW=paloalto \
    ${UPGRADE} \
    -p 8000:8000 \
    -p 514:514/udp \
    -p 514:514 \
    -v $PWD/license.lic:/license.lic \
    -v $PWD/db:/opt/splunk/var/lib/splunk \
    -v $PWD/system-local:/opt/splunk/etc/system/local \
    -v $PWD/users-local:/opt/splunk/etc/users \
    -v $PWD/auth-local:/opt/splunk/etc/auth \
    -v $PWD/app-local:/opt/splunk/etc/apps/SplunkforPaloAltoNetworks/local \
    -v $PWD/datagen-local:/opt/splunk/etc/apps/pan_datagen/local \
    -v /etc/localtime:/etc/localtime:ro \
    btorresgil/splunk-panw-demo
