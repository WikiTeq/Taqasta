#!/bin/bash

# Entrypoint for running php-fpm instead of Apache inside the Taqasta image.
# Used when the stack runs with an external nginx service (WIK-2139); nginx
# serves static files and forwards PHP requests to this container.

set -euo pipefail

. /run-apache-pre.sh

# Render the php-fpm pool from its template with a restricted envsubst call:
# only the MPM_PREFORK_* placeholders are expanded, so "$" characters coming
# from other environment variables stay untouched.
envsubst '${MPM_PREFORK_START_SERVERS} ${MPM_PREFORK_MIN_SPARE_SERVERS} ${MPM_PREFORK_MAX_SPARE_SERVERS} ${MPM_PREFORK_MAX_REQUEST_WORKERS} ${MPM_PREFORK_MAX_REQUESTS_PER_CHILD}' \
    < /etc/php/8.3/fpm/pool.d/www.conf.template \
    > /etc/php/8.3/fpm/pool.d/www.conf

printf "\n\n==================================================================================\n\n"

exec /usr/sbin/php-fpm8.3 -F
