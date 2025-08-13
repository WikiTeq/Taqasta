#!/bin/bash

. /functions.sh

logfileName=mwjobrunner_log

echo_log() {
    local log_ts
    log_ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$log_ts] $*" >> "$logfileNow" 2>&1
}

echo "Starting job runner (in 10 seconds)..."
# Wait 10 seconds after the server starts up to give other processes time to get started
sleep 10
echo "Job runner started."
while true; do
    logFilePrev="$logfileNow"
    logfileNow="$MW_LOG/$logfileName"_$(date +%Y%m%d)
    if [ -n "$logFilePrev" ] && [ "$logFilePrev" != "$logfileNow" ]; then
        /rotatelogs-compress.sh "$logfileNow" "$logFilePrev" &
    fi

    # Job types that need to be run ASAP no matter how many of them are in the queue
    # Those jobs should be very "cheap" to run
    run_jobs_on_demand "enotifNotify"
    run_jobs_on_demand "createPage"
    run_jobs_on_demand "htmlCacheUpdate" 500
    run_jobs_on_demand "refreshLinks" 25
    # Rest of the jobs in the queue
    run_jobs_on_demand "" 10

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    echo_log "mwjobrunner waits for $MW_JOB_RUNNER_PAUSE seconds..."
    sleep "$MW_JOB_RUNNER_PAUSE"
done
