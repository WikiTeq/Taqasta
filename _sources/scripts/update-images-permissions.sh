#!/bin/bash

# Check if BOOTSTRAP_LOGFILE is defined and not empty
if [ -n "$BOOTSTRAP_LOGFILE" ]; then
    # If BOOTSTRAP_LOGFILE is defined, set up logging
    # Open file descriptor 3 for logging xtrace output
    exec 3>>"$BOOTSTRAP_LOGFILE"

    # Redirect stdout and stderr through tee to the console and log file
    exec > >(stdbuf -oL tee -a "$BOOTSTRAP_LOGFILE") 2>&1

    # Enable xtrace. Redirect the xtrace output to log file only
    BASH_XTRACEFD=3
fi

set -x

. /functions.sh

echo "Checking permissions of images in Mediawiki volume dir $MW_VOLUME/images..."
make_dir_writable "$MW_VOLUME/images"
