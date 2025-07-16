#!/bin/bash

# Validates values.yml against that values.schema.json schema

docker run --rm -i \
    -v "${PWD}/values.yml":/build/values.yml:ro \
    -v "${PWD}/values.schema.json":/build/values.schema.json:ro \
    -w "/build" \
    theroozbeh/jsonschema-tools:latest /build/values.schema.json /build/values.yml
