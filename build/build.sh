#!/bin/bash
set -e

source .env

# This is the image which is used during build only. It stores and updates the
# Composer cache which should not be included in the production images.
# It serves as an intermediate base image for the app, worker and web images.
docker build -f build.dockerfile -t biigle/build-dist \
    --build-arg TIMEZONE=${APP_TIMEZONE} \
    --build-arg GITHUB_OAUTH_TOKEN=${GITHUB_OAUTH_TOKEN} \
    --build-arg LABEL_TREES_VERSION="^1.0" \
    --build-arg PROJECTS_VERSION="^1.0" \
    --build-arg VOLUMES_VERSION="^2.0" \
    --build-arg ANNOTATIONS_VERSION="^3.0" \
    --build-arg LARGO_VERSION="^2.0" \
    --build-arg REPORTS_VERSION="^4.0" \
    --build-arg GEO_VERSION="^1.7" \
    --build-arg COLOR_SORT_VERSION="^2.0" \
    --build-arg LASERPOINTS_VERSION="^2.0" \
    --build-arg ANANAS_VERSION="^1.0" \
    .

# Update the composer cache directory for much faster builds.
# Use -s to skip updating the cache directory.
if [ "$1" != "-s" ]; then
    ID=$(docker create biigle/build-dist)
    docker cp ${ID}:/root/.composer/cache .
    docker rm ${ID}
fi

docker build -f app.dockerfile -t biigle/app-dist .
docker build -f worker.dockerfile -t biigle/worker-dist .
docker build -f web.dockerfile -t biigle/web-dist .
