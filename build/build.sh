#!/bin/bash
set -e

source .env

VERSION=${1:-latest}

# This is the image which is used during build only. It stores and updates the
# Composer cache which should not be included in the production images.
# It serves as an intermediate base image for the app, worker and web images.
docker build -f build.dockerfile -t biigle/build-dist \
    --secret id=github_token,env=GITHUB_OAUTH_TOKEN \
    --build-arg TIMEZONE=${APP_TIMEZONE} \
    --build-arg GEO_VERSION="^1.7" \
    --build-arg COLOR_SORT_VERSION="^2.0" \
    --build-arg LASERPOINTS_VERSION="^2.0" \
    --build-arg ANANAS_VERSION="^1.0" \
    --build-arg PUSHER_APP_KEY=${PUSHER_APP_KEY} \
    --build-arg FORCE_TIMESTAMP=$(date +%s) \
    .

docker build -f app.dockerfile -t biigle/app-dist:$VERSION .
docker build -f worker.dockerfile -t biigle/worker-dist:$VERSION .
docker build -f web.dockerfile -t biigle/web-dist:$VERSION .

docker build -f websockets.dockerfile -t biigle/websockets-dist:$VERSION .

docker image prune -f
