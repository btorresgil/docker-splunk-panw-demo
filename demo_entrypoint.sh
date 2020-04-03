#!/bin/bash

export APPS_HOME=${SPLUNK_HOME}/etc/apps
export APP_HOME=$APPS_HOME/SplunkforPaloAltoNetworks
export ADDON_HOME=$APPS_HOME/Splunk_TA_paloalto
export DATAGEN_HOME=$APPS_HOME/SA-Eventgen


if [ "$1" = 'start-service' ]; then
  # If these files are different override etc folder (possible that this is upgrade or first start cases)
  # Also override ownership of these files to splunk:splunk
  # if ! cmp --silent /var/opt/splunk/etc/splunk.version "${SPLUNK_HOME}/etc/splunk.version"; then

    if [ ! -f "${SPLUNK_HOME}/etc/system/local/web.conf" ]; then
      mkdir -p "${SPLUNK_HOME}/etc/system/local"
      echo -e "[default]\n\n[settings]\n" >> "${SPLUNK_HOME}/etc/system/local/web.conf"
      echo "updateCheckerBaseURL = 0" >> "${SPLUNK_HOME}/etc/system/local/web.conf"
    fi
    if [ ! -f "${APPS_HOME}/splunk_instrumentation/local/telemetry.conf" ]; then
      mkdir -p "${APPS_HOME}/splunk_instrumentation/local"
      echo -e "[general]\nsendAnonymizedUsage = 0\nsendLicenseUsage = 0\nshowOptInModal = 0" > "${APPS_HOME}/splunk_instrumentation/local/telemetry.conf"
    fi

    # Upgrade the Palo Alto Networks app, even if a config exists already
    # Delete everything but the local directory itself
    # find ${APP_HOME}/* -type d ! -name local -exec rm -rf {} + &2>1 > /dev/null
    # rm -f ${APP_HOME}/*
    # cp -fR /panw-apps/SplunkforPaloAltoNetworks ${APPS_HOME}
    # if [ -d "${APP_HOME}" ]; then
    #   echo "SplunkforPaloAltoNetworks Copied"
    # fi

    # Upgrade the Splunk_TA_paloalto Add-on, even if a config exists already
    # Delete everything but the local directory itself
    # find ${ADDON_HOME}/* -type d ! -name local -exec rm -rf {} + &2>1 > /dev/null
    # rm -f ${ADDON_HOME}/*
    # cp -fR /panw-apps/Splunk_TA_paloalto ${APPS_HOME}
    # if [ -d "${ADDON_HOME}" ]; then
    #   echo "Splunk_TA_paloalto Copied"
    # fi

    # Upgrade the SA-Eventgen app, even if a config exists already
    # Delete everything but the local directory itself
    # find ${DATAGEN_HOME}/* -type d ! -name local -exec rm -rf {} + &2>1 > /dev/null
    # rm -f ${DATAGEN_HOME}/*
    # cp -fR /panw-apps/SA-Eventgen ${APPS_HOME}
    # if [ ! -f ${DATAGEN_HOME}/local/app.conf ]; then
    #   echo -e "[ui]\nis_visible = false\n" > ${DATAGEN_HOME}/local/app.conf
    # fi
    # if [ -d "${DATAGEN_HOME}" ]; then
    #   echo "SA-Eventgen Copied"
    # fi



    # Copy the default inputs.conf for the Palo Alto Networks App, if one
    # doesn't exist already.
    # mkdir ${SPLUNK_HOME}/etc/local
    # cp -n /inputs.conf ${SPLUNK_HOME}/etc/local/inputs.conf
    # rm -f /inputs.conf

    # Copy the datamodel.conf for the Palo Alto Networks App, if one
    # doesn't exist already.
    # cp -n /datamodels.conf ${APP_HOME}/local/datamodels.conf
    # rm -f /datamodels.conf
    # if [ -f "${APP_HOME}/local/datamodels.conf" ]; then
    #   echo "DataModel Copied"
    # fi


    # touch etc/.ui_login # Disable the "first time signing in" message

    # chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME}/etc
    # chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME}/var

    # Add data generator user
    # sudo -HEu "${SPLUNK_USER}" sh -c "${SPLUNK_HOME}/bin/splunk add user pan -password pan -role pan -auth admin:changeme --accept-license --answer-yes"

    # if [ -e /license.lic ]; then
    #   echo "Installing license"
    #   sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk add licenses /license.lic --accept-license"
    # else
    #   echo "Setting to free demo mode"
    #   sudo -HEu ${SPLUNK_USER} sh -c "${SPLUNK_HOME}/bin/splunk edit licenser-groups Free -is_active 1 --accept-license"
    # fi

  # fi
fi

# export SPLUNK_START_ARGS="${SPLUNK_START_ARGS} --accept-license"
# export SPLUNK_PASSWORD="paloalto"

/sbin/entrypoint.sh $@
