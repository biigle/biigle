#!/bin/bash
set -e

# Load GITHUB_OAUTH_TOKEN and SERVER_NAME.
source ../.env

docker build -f app.dockerfile -t biigle/app-dist \
    --build-arg GITHUB_OAUTH_TOKEN=${GITHUB_OAUTH_TOKEN} \
    --build-arg LABEL_TREES_VERSION="^1.0" \
    --build-arg PROJECTS_VERSION="^1.0" \
    --build-arg VOLUMES_VERSION="^2.0" \
    --build-arg ANNOTATIONS_VERSION="^3.0" \
    --build-arg LARGO_VERSION="^2.0" \
    --build-arg EXPORT_VERSION="^3.0" \
    --build-arg GEO_VERSION="^1.7" \
    --build-arg COLOR_SORT_VERSION="^2.0" \
    --build-arg LASERPOINTS_VERSION="^2.0" \
    --build-arg ANANAS_VERSION="^1.0" \
    .

# Use -s to skip updating the cache.
if [ "$1" != "-s" ]; then
    # Update the composer cache directory for faster builds.
    ID=$(docker create biigle/app-dist)
    docker cp ${ID}:/root/.composer/cache .
    docker rm ${ID}
fi

# Perform these last because they uses the new biigle/app-dist as intermediate.
docker build -f worker.dockerfile -t biigle/worker-dist .
docker build -f web.dockerfile -t biigle/web-dist .
