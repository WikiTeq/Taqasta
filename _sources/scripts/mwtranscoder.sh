#!/bin/bash

. /functions.sh

logfileName=mwtranscoder_log

echo_log() {
    local log_ts
    log_ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$log_ts] $*" >> "$logfileNow" 2>&1
}

echo "Starting transcoder (in 180 seconds)..."
# Wait three minutes after the server starts up to give other processes time to get started
sleep 180
echo Transcoder started.
while true; do
    logFilePrev="$logfileNow"
    logfileNow="$MW_LOG/$logfileName"_$(date +%Y%m%d)
    if [ -n "$logFilePrev" ] && [ "$logFilePrev" != "$logfileNow" ]; then
        /rotatelogs-compress.sh "$logfileNow" "$logFilePrev" &
    fi

    run_jobs_on_demand "webVideoTranscodePrioritized" 10
    sleep 1
    run_jobs_on_demand "webVideoTranscode" 1

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    echo_log "mwtranscoder waits for $MW_JOB_TRANSCODER_PAUSE seconds.."
    sleep "$MW_JOB_TRANSCODER_PAUSE"
done
