#!/bin/bash

# compiles a Dockerfile out of Dockerfile.tmpl

touch "${PWD}/Dockerfile"
touch "${PWD}/_sources/configs/composer.wikiteq.json"

docker run --rm \
    -v "${PWD}/Dockerfile:/build/Dockerfile" \
    -v "${PWD}/_sources/configs/composer.wikiteq.json:/build/_sources/configs/composer.wikiteq.json" \
    -v "${PWD}/_sources/configs/composer.wikiteq.json.tmpl:/build/_sources/configs/composer.wikiteq.json.tmpl:ro" \
    -v "${PWD}/templates:/build/templates:ro" \
    -v "${PWD}/Dockerfile.tmpl:/build/Dockerfile.tmpl:ro" \
    -v "${PWD}/.gomplate.yml:/build/.gomplate.yml:ro" \
    -v "${PWD}/values.yml:/build/values.yml:ro" \
    -w "/build" \
    hairyhenderson/gomplate:alpine --config .gomplate.yml --template templates/
