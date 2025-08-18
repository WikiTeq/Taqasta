#!/bin/bash

# builds a multiplatform image out of Dockerfile re-using the multiplatform builder
# builds the image with `taqasta` tag, you can re-tag if you need to push to the repo

if ! docker buildx ls | grep -q "multiplatform-builder"; then
    echo "Creating new builder instance..."
    docker buildx create --name multiplatform-builder --use
else
    echo "Builder 'multiplatform-builder' already exists, using existing one..."
    docker buildx use multiplatform-builder
fi

# Build and push multi-architecture image
docker buildx build --platform linux/amd64,linux/arm64 \
    -t taqasta \
    .
