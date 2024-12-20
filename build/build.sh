#!/bin/bash
set -e

source .env

VERSION=${1:-latest}

# This is the image which is used during build only. It stores and updates the
# Composer cache which should not be included in the production images.
# It serves as an intermediate base image for the app, worker and web images.
docker build -f build.dockerfile -t biigle/build-dist \
    --build-arg TIMEZONE=${APP_TIMEZONE} \
    --build-arg GITHUB_OAUTH_TOKEN=${GITHUB_OAUTH_TOKEN} \
    --build-arg LARGO_VERSION="^2.0" \
    --build-arg REPORTS_VERSION="^4.0" \
    --build-arg GEO_VERSION="^1.7" \
    --build-arg COLOR_SORT_VERSION="^2.0" \
    --build-arg LASERPOINTS_VERSION="^2.0" \
    --build-arg ANANAS_VERSION="^1.0" \
    --build-arg MIX_PUSHER_APP_KEY=${MIX_PUSHER_APP_KEY} \
    .

# Update the composer cache directory for much faster builds.
# Use -s to skip updating the cache directory.
ID=$(docker create biigle/build-dist)
docker cp ${ID}:/root/.composer/cache .
docker rm ${ID}

docker build -f app.dockerfile -t biigle/app-dist:$VERSION .
docker build -f worker.dockerfile -t biigle/worker-dist:$VERSION .
docker build -f web.dockerfile -t biigle/web-dist:$VERSION .

docker build -f websockets.dockerfile -t biigle/websockets-dist:$VERSION \
    --build-arg SOKETI_DEFAULT_APP_ID=${SOKETI_DEFAULT_APP_ID} \
    --build-arg SOKETI_DEFAULT_APP_KEY=${SOKETI_DEFAULT_APP_KEY} \
    --build-arg SOKETI_DEFAULT_APP_SECRET=${SOKETI_DEFAULT_APP_SECRET} \
    .

docker image prune -f
