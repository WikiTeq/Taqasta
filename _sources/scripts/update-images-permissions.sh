#!/bin/bash

# Open file descriptor 3 for logging xtrace output
exec 3>>"$LOGFILE"

# Redirect stdout and stderr through tee to the console and log file
exec > >(stdbuf -oL tee -a "$LOGFILE") 2>&1

sleep 0.01
printf "\n\n===== update-images-permissions.sh =====\n\n\n"

# Enable xtrace. Redirect the xtrace output to log file only
BASH_XTRACEFD=3
set -x

. /functions.sh

echo "Checking permissions of images in Mediawiki volume dir $MW_VOLUME/images..."
make_dir_writable "$MW_VOLUME/images"
