#!/bin/bash

# Validates values.yml against that values.schema.json schema

docker run --rm \
    -v "${PWD}/values.yml":/build/values.yml:ro \
    -v "${PWD}/values.schema.json":/build/values.schema.json:ro \
    -w "/build" \
    weibeld/ajv-cli:5.0.0 ajv \
    --spec draft7 \
    -c ajv-formats \
    -s /build/values.schema.json \
    -d /build/values.yml
