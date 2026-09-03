#!/bin/bash

# Bootstrap shared between the Apache entrypoint (run-apache.sh) and the
# php-fpm entrypoint (run-apache-fpm.sh, WIK-2139): everything up to but not
# including starting a web server. Splitting it out keeps both paths running
# identical initialization code.

if [ "$ENABLE_BASH_XTRACE" = "true" ]; then
    date=$(date -u +%Y%m%d_%H%M%S)
    BOOTSTRAP_LOGFILE="$MW_LOG/_bootstrap_$date.log"
    export BOOTSTRAP_LOGFILE
    echo "==== STARTING $date ===="
    echo "See Bash XTrace in the $BOOTSTRAP_LOGFILE file"
fi

echo "Checking permissions of Mediawiki log dir $MW_LOG..."
if ! mountpoint -q -- "$MW_LOG"; then
    mkdir -p "$MW_VOLUME/log/mediawiki"
    rsync -avh --ignore-existing "$MW_LOG/" "$MW_VOLUME/log/mediawiki/"
    mv "$MW_LOG" "${MW_LOG}_old"
    ln -s "$MW_VOLUME/log/mediawiki" "$MW_LOG"
    chmod -R o=rwX "$MW_VOLUME/log/mediawiki"
else
    chgrp -R "$WWW_GROUP" "$MW_LOG"
    chmod -R go=rwX "$MW_LOG"
fi

if [ "$ENABLE_BASH_XTRACE" = "true" ]; then
    # Open file descriptor 3 for logging xtrace output
    exec 3> >(stdbuf -oL tee -a "$BOOTSTRAP_LOGFILE" >/dev/null)
    # Redirect stdout and stderr to the log file using tee,
    # with stdbuf to handle buffering issues
    exec > >(stdbuf -oL tee -a "$BOOTSTRAP_LOGFILE") 2>&1
    # Enable xtrace and Redirect the xtrace output to log file only
    BASH_XTRACEFD=3
    set -x
fi

. /functions.sh

if ! mountpoint -q -- "$MW_VOLUME"; then
    echo "Folder $MW_VOLUME contains important data and must be mounted to persistent storage!"
    if ! isTrue "$MW_ALLOW_UNMOUNTED_VOLUME"; then
        exit 1
    fi
    echo "You allowed to continue because MW_ALLOW_UNMOUNTED_VOLUME is set as true"
fi

# Soft sync contents from $MW_ORIGIN_FILES directory to $MW_VOLUME
# The goal of this operation is to copy over all the files generated
# by the image to bind-mount points on host which are bind to
# $MW_VOLUME (./extensions, ./skins, ./config, ./images),
# note that this command will also set all the necessary permissions
echo "Syncing files..."
rsync --inplace --ignore-existing \
  -og --chown="$WWW_GROUP:$WWW_USER" --chmod=Fg=rw,Dg=rwx \
  "$MW_ORIGIN_FILES"/ "$MW_VOLUME"/

# Expose the document root inside $MW_VOLUME so an external nginx container
# can serve static files from the same content (WIK-2139). The mirror is
# created once; later runs refresh it with --delete so wiki code updates
# reach nginx even when the volume already exists. Permissions are widened
# (world-readable) because the stock nginx image runs workers as its own
# unprivileged "nginx" user, outside the www-data group.
mkdir -p "$MW_VOLUME/docroot"
rsync --inplace --delete \
  -og --chown="$WWW_GROUP:$WWW_USER" \
  --chmod=Fu=rw,Fg=rw,Fo=r,Du=rwx,Dg=rwx,Do=rx \
  --exclude '/images/' \
  "$WWW_ROOT"/ "$MW_VOLUME/docroot"/

# Create needed directories
mkdir -p "$MW_VOLUME"/extensions/SemanticMediaWiki/config
mkdir -p "$MW_VOLUME"/extensions/GoogleLogin/cache
mkdir -p "$MW_VOLUME"/l10n_cache

echo "PHP_ERROR_REPORTING environment variable is set to: $PHP_ERROR_REPORTING"
# Update PHP configuration files with error reporting settings
# First remove any existing error_reporting line, then add the new one
sed -i '/^error_reporting/d' /etc/php/8.3/cli/conf.d/php_cli_error_reporting.ini
sed -i '/; error_reporting will be added below by the run-apache.sh script/a error_reporting = '"$PHP_ERROR_REPORTING" /etc/php/8.3/cli/conf.d/php_cli_error_reporting.ini
sed -i '/^error_reporting/d' /etc/php/8.3/apache2/conf.d/php_apache2_error_reporting.ini
sed -i '/; error_reporting will be added below by the run-apache.sh script/a error_reporting = '"$PHP_ERROR_REPORTING" /etc/php/8.3/apache2/conf.d/php_apache2_error_reporting.ini

printf "\nCheck wiki settings for errors... "
if ! php /getMediawikiSettings.php --version MediaWiki; then
    printf "\n===================================== ERROR ======================================\n\n"
    echo "An error occurred while checking the wiki settings."
    echo "There is an error in the wiki settings files, or you missed to run the \"git submodule update --init --recursive\" command"
    printf "\n==================================================================================\n\n"
    exit 1
else
    printf " OK\n\n"
fi

/update-docker-gateway.sh

# Write log files to $MW_VOLUME/log directory if target folders are not mounted
echo "Checking permissions of Apache log dir $APACHE_LOG_DIR..."
if ! mountpoint -q -- "$APACHE_LOG_DIR/"; then
    mkdir -p "$MW_VOLUME/log/httpd"
    rsync -avh --ignore-existing "$APACHE_LOG_DIR/" "$MW_VOLUME/log/httpd/"
    mv "$APACHE_LOG_DIR" "${APACHE_LOG_DIR}_old"
    ln -s "$MW_VOLUME/log/httpd" "$APACHE_LOG_DIR"
else
    chgrp -R "$WWW_GROUP" "$APACHE_LOG_DIR"
    chmod -R g=rwX "$APACHE_LOG_DIR"
fi

# Check permissions for sqlite database file in case if sqlite is used
WG_DB_TYPE=$(get_mediawiki_variable wgDBtype)
WG_SQLITE_DATA_DIR=$(get_mediawiki_variable wgSQLiteDataDir)
if [ "$WG_DB_TYPE" = "sqlite" ]; then
    echo "Checking permissions of sqlite database dir $WG_SQLITE_DATA_DIR..."
    mkdir -p "$WG_SQLITE_DATA_DIR"
    chgrp -R "$WWW_GROUP" "$WG_SQLITE_DATA_DIR"
    chmod -R g=rwX "$WG_SQLITE_DATA_DIR"
fi

echo "Checking permissions of Mediawiki volume dir $MW_VOLUME except $MW_VOLUME/images..."
make_dir_writable "$MW_VOLUME" -not '(' -path "$MW_VOLUME/images" -prune ')'

# Check and update permissions of wiki images in background.
# It can take a long time and should not block Apache from starting.
/update-images-permissions.sh &

# Run maintenance scripts in background.
# The flag is created in both docroots: $WWW_ROOT for Apache/mod_php setups
# and the $MW_VOLUME/docroot mirror read by the external nginx service,
# whose filesystem view cannot resolve app-container paths (WIK-2139).
touch "$WWW_ROOT/.maintenance"
if [ -d "$MW_VOLUME/docroot" ]; then
    touch "$MW_VOLUME/docroot/.maintenance"
fi
/run-maintenance-scripts.sh &
