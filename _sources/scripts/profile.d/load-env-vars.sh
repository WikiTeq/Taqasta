#!/bin/bash

if [ -f /etc/environment ]; then
    export "$(grep -v "^#" /etc/environment | xargs)"
fi
