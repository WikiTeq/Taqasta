#!/bin/bash

# read variables from LocalSettings.php
get_mediawiki_variable () {
    php /getMediawikiSettings.php --variable="$1" --format="${2:-string}"
}

isTrue() {
    case $1 in
        "True" | "TRUE" | "true" | 1)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_hostname_with_port () {
    port=$(echo "$1" | grep ":" | cut -d":" -f2)
    echo "$1:${port:-$2}"
}

make_dir_writable() {
    find "$@" '(' -type f -o -type d ')' \
       -not '(' '(' -user "$WWW_USER" -perm -u=w ')' -o \
           '(' -group "$WWW_GROUP" -perm -g=w ')' -o \
           '(' -perm -o=w ')' \
         ')' \
         -exec chgrp "$WWW_GROUP" {} \; -exec chmod g=rwX {} \;
}

calculate_php_error_reporting() {
  php -r "error_reporting($1); echo error_reporting();"
}

run_jobs_on_demand() {
    local JOB_TYPE=$1
    local MAX_JOBS=${2:-10}
    local JOB_COUNT=0
    if [ -z "$JOB_TYPE" ]; then
        echo_log "Looking if there are any pending jobs.."
        JOB_COUNT=$(php $MW_HOME/maintenance/run.php showJobs)
    else
        echo_log "Looking if there are any pending jobs of type $JOB_TYPE.."
        JOB_COUNT=$(php $MW_HOME/maintenance/run.php showJobs --type="$JOB_TYPE")
    fi
    if [ "$JOB_COUNT" -gt "0" ]; then
        echo_log "Found $JOB_COUNT jobs of type $JOB_TYPE pending, starting the runner.."
        php $MW_HOME/maintenance/run.php runJobs \
          --memory-limit="$MW_JOB_RUNNER_MEMORY_LIMIT" \
          --type="$JOB_TYPE" \
          --maxjobs="$MAX_JOBS" >> "$logfileNow" 2>&1
    else
        echo_log "No jobs found, nothing to do"
    fi
}
