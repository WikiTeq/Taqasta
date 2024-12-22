#!/bin/bash
# loaded for the `docker-compose exec web bash -cl '...'` command

if [ -f /etc/environment_secrets ]; then
    # Get the system start time and environment secrets modification time
    CONTAINER_START_TIME=$(stat -c %Y /proc/1)
    ENV_SECRETS_MOD_TIME=$(stat -c %Y /etc/environment_secrets)

    # Compare timestamps
    if [ "$ENV_SECRETS_MOD_TIME" -ge "$CONTAINER_START_TIME" ]; then
        # The file was created after the system started, we can use it
        # Read and export each line (ignoring comments) individually
        while IFS= read -r line; do
            # Skip empty lines and lines starting with '#'
            if [[ -n "$line" && "$line" != \#* ]]; then
                declare -x "$line"
            fi
        done < /etc/environment_secrets
    fi
fi
