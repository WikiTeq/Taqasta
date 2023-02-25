#!/bin/bash

set -x

# Run extra post-init scripts if any
if [ -f "/post-init.sh" ]; then
    chmod +x /post-init.sh
    echo >&2 Running post-init.sh script..
    /bin/bash /post-init.sh
fi
