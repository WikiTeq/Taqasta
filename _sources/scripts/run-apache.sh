#!/bin/bash

if [ "$ENABLE_BASH_XTRACE" = "true" ]; then
    date=$(date -u +%Y%m%d_%H%M%S)
    BOOTSTRAP_LOGFILE="$MW_LOG/_bootstrap_$date.log"
    export BOOTSTRAP_LOGFILE
    echo "==== STARTING $date ===="
    echo "See Bash XTrace in the $BOOTSTRAP_LOGFILE file"
fi

. /run-apache-pre.sh

# Allow for envs in the prefork config file
envsubst < /etc/apache2/mods-available/mpm_prefork.conf.template > /etc/apache2/mods-available/mpm_prefork.conf || exit 1

############### Run Apache ###############
# Make sure we're not confused by old, incompletely-shutdown Apache
# context after restarting the container.  Apache won't start correctly
# if it thinks it is already running.
rm -rf /run/apache2/* /tmp/apache2*

printf "\n\n==================================================================================\n\n\n"

exec /usr/sbin/apachectl -DFOREGROUND
