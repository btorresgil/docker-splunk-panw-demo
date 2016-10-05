#!/bin/bash

export APPS_HOME=/opt/splunk/etc/apps
export APP_HOME=$APPS_HOME/SplunkforPaloAltoNetworks
export ADDON_HOME=$APPS_HOME/Splunk_TA_paloalto
export DATAGEN_HOME=$APPS_HOME/SA-Eventgen


if [ "$1" = 'start-service' ]; then
  # If these files are different override etc folder (possible that this is upgrade or first start cases)
  # Also override ownership of these files to splunk:splunk
  if ! $(cmp --silent /var/opt/splunk/etc/splunk.version ${SPLUNK_HOME}/etc/splunk.version); then

    cp -fR /var/opt/splunk/etc ${SPLUNK_HOME}

    # Upgrade the Palo Alto Networks app, even if a config exists already
    # Delete everything but the local directory itself
    find ${APP_HOME}/* -type d ! -name local -exec rm -rf {} + &2>1 > /dev/null
    rm -f ${APP_HOME}/*
    cp -fR /panw-apps/SplunkforPaloAltoNetworks ${APPS_HOME}

    # Upgrade the Splunk_TA_paloalto Add-on, even if a config exists already
    # Delete everything but the local directory itself
    find ${ADDON_HOME}/* -type d ! -name local -exec rm -rf {} + &2>1 > /dev/null
    rm -f ${ADDON_HOME}/*
    cp -fR /panw-apps/Splunk_TA_paloalto ${APPS_HOME}

    # Upgrade the pan_datagen app, even if a config exists already
    # Delete everything but the local directory itself
    #find ${DATAGEN_HOME}/* -type d ! -name local -exec rm -rf {} +
    #rm -f ${DATAGEN_HOME}/*
    #cp -fR /panw-apps/pan_datagen ${APPS_HOME}

    # Upgrade the SA-Eventgen app, even if a config exists already
    # Delete everything but the local directory itself
    find ${DATAGEN_HOME}/* -type d ! -name local -exec rm -rf {} + &2>1 > /dev/null
    rm -f ${DATAGEN_HOME}/*
    cp -fR /panw-apps/SA-Eventgen ${APPS_HOME}
    if [ ! -f ${DATAGEN_HOME}/local/app.conf ]; then
      echo -e "[ui]\nis_visible = false\n" > ${DATAGEN_HOME}/local/app.conf
    fi

    # Copy the default inputs.conf for the Palo Alto Networks App, if one
    # doesn't exist already.
    cp -n /inputs.conf ${APP_HOME}/local/inputs.conf
    rm -f /inputs.conf

    if [ ! -f ${SPLUNK_HOME}/etc/system/local/web.conf ]; then
      mkdir -p ${SPLUNK_HOME}/etc/system/local
      echo -e "[default]\n\n[settings]\n" >> ${SPLUNK_HOME}/etc/system/local/web.conf
      echo "updateCheckerBaseURL = 0" >> ${SPLUNK_HOME}/etc/system/local/web.conf
    fi
    if [ ! -f ${APPS_HOME}/splunk_instrumentation/local/telemetry.conf ]; then
      mkdir -p ${APPS_HOME}/splunk_instrumentation/local
      echo -e "[general]\nsendAnonymizedUsage = 0\nsendLicenseUsage = 0\nshowOptInModal = 0" > ${APPS_HOME}/splunk_instrumentation/local/telemetry.conf
    fi

    touch etc/.ui_login # Disable the "first time signing in" message

    chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME}/etc
    chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME}/var

    # Add data generator user
    #sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk add user pan -password pan -role pan -auth admin:changeme --accept-license --answer-yes"

    if [ -e /license.lic ]; then
      echo "Installing license"
      sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk add licenses /license.lic -auth admin:changeme --accept-license --answer-yes"
    else
      echo "Setting to free demo mode"
      sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk edit licenser-groups Free -is_active 1 -auth admin:changeme --accept-license --answer-yes"
    fi

  fi
fi

export SPLUNK_START_ARGS="${SPLUNK_START_ARGS} --accept-license --answer-yes"

/sbin/entrypoint.sh $@

sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk edit user admin -password paloalto -auth admin:changeme"
