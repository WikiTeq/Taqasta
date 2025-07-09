#!/bin/bash

# compiles a Dockerfile out of Dockerfile.tmpl

docker run -it --rm \
    --user "$(id -u)":"$(id -g)" \
    -v "${PWD}:/build" \
    -w "/build" \
    hairyhenderson/gomplate:alpine --config .gomplate.yml --template templates/
