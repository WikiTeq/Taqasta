#!/bin/bash

RJ=$MW_HOME/maintenance/runJobs.php
logfileName=mwtranscoder_log

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

    php "$RJ" --type webVideoTranscodePrioritized --maxjobs=10 | grep -v "^Job queue is empty.$" >> "$logfileNow" 2>&1
    sleep 1
    php "$RJ" --type webVideoTranscode --maxjobs=1 | grep -v "^Job queue is empty.$" >> "$logfileNow" 2>&1

    # Wait some seconds to let the CPU do other things, like handling web requests, etc
    sleep "$MW_JOB_TRANSCODER_PAUSE"
done
