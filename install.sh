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

# Create an upgrade script
echo "#!/bin/sh" > ${PWD}/upgrade.sh
echo "cd ${PWD}" >> ${PWD}/upgrade.sh
echo "curl -sSL http://bit.ly/splunk-panw-demo | sudo sh" >> ${PWD}/upgrade.sh
chmod +x ${PWD}/upgrade.sh

# Create an start script
echo "#!/bin/sh" > ${PWD}/start.sh
echo "service docker start" >> ${PWD}/start.sh
echo "docker start splunk-demo" >> ${PWD}/start.sh
chmod +x ${PWD}/start.sh

# Get the Splunk icon
curl --silent -o ${PWD}/splunk_icon.png "https://github.com/btorresgil/docker-splunk-panw-demo/blob/master/splunk_icon.png"

# Create an upgrade and start script on the desktop if there is a desktop

if [ -d "${HOME}/Desktop" ]; then
    SHORTCUT="${HOME}/Desktop/upgrade-splunk.desktop"
    echo "[Desktop Entry]" > ${SHORTCUT}
    echo "Type=Application" >> ${SHORTCUT}
    echo "Name=Upgrade Splunk" >> ${SHORTCUT}
    echo "Exec=${PWD}/upgrade.sh" >> ${SHORTCUT}
    echo "Icon=${PWD}/splunk_icon.png" >> ${SHORTCUT}
    echo "Terminal=true" >> ${SHORTCUT}
    echo "Comment=Created by Splunk PANW Demo Installer" >> ${SHORTCUT}
    chmod +x ${SHORTCUT}

    SHORTCUT="${HOME}/Desktop/start-splunk.desktop"
    echo "[Desktop Entry]" > ${SHORTCUT}
    echo "Type=Application" >> ${SHORTCUT}
    echo "Name=Start Splunk" >> ${SHORTCUT}
    echo "Exec=${PWD}/start.sh" >> ${SHORTCUT}
    echo "Icon=${PWD}/splunk_icon.png" >> ${SHORTCUT}
    echo "Terminal=true" >> ${SHORTCUT}
    echo "Comment=Created by Splunk PANW Demo Installer" >> ${SHORTCUT}
    chmod +x ${SHORTCUT}
fi

