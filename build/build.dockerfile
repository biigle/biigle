FROM ghcr.io/biigle/app:latest
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

# Configure the timezone.
ARG TIMEZONE
RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && apk del tzdata

# Required to generate the REST API documentation.
RUN apk add --no-cache npm nghttp2-dev \
    && npm install apidoc@"^0.17.0" -g

# Enable rate limiting with Redis.
# see: https://laravel.com/docs/9.x/routing#throttling-with-redis
RUN sed -i 's/ThrottleRequests/ThrottleRequestsWithRedis/' app/Http/Kernel.php

# Ignore platform reqs because the app image is stripped down to the essentials
# and doens't meet some of the requirements. We do this for the worker, though.
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && COMPOSER_SIGNATURE=$(curl -s https://composer.github.io/installer.sig) \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '$COMPOSER_SIGNATURE') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && rm composer-setup.php

ENV COMPOSER_NO_INTERACTION 1
ENV COMPOSER_ALLOW_SUPERUSER 1

# Include the Composer cache directory to speed up the build.
COPY cache /root/.composer/cache

ARG GITHUB_OAUTH_TOKEN
ARG LARGO_VERSION=">=1.0"
ARG REPORTS_VERSION=">=1.0"
ARG GEO_VERSION=">=1.0"
ARG COLOR_SORT_VERSION=">=1.0"
ARG LASERPOINTS_VERSION=">=1.0"
ARG ANANAS_VERSION=">=1.0"
ARG SYNC_VERSION=">=1.0"
RUN COMPOSER_AUTH="{\"github-oauth\":{\"github.com\":\"${GITHUB_OAUTH_TOKEN}\"}}" \
    php -d memory_limit=-1 composer.phar require \
        biigle/largo:${LARGO_VERSION} \
        biigle/reports:${REPORTS_VERSION} \
        biigle/geo:${GEO_VERSION} \
        biigle/color-sort:${COLOR_SORT_VERSION} \
        biigle/laserpoints:${LASERPOINTS_VERSION} \
        biigle/ananas:${ANANAS_VERSION} \
        biigle/sync:${SYNC_VERSION} \
        --prefer-dist --update-no-dev --ignore-platform-reqs

RUN sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Largo\\LargoServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Reports\\ReportsServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Geo\\GeoServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\ColorSort\\ColorSortServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Laserpoints\\LaserpointsServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Ananas\\AnanasServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Sync\\SyncServiceProvider::class,' config/app.php

RUN php composer.phar dump-autoload -o && rm composer.phar

RUN php artisan vendor:publish --tag=public

ARG MIX_PUSHER_APP_KEY
# Compile assets. npm is installed above.
RUN echo "//npm.pkg.github.com/:_authToken=${GITHUB_OAUTH_TOKEN}" > .npmrc \
    && npm install \
    && MIX_PUSHER_APP_KEY=${MIX_PUSHER_APP_KEY} \
        npm run prod \
    && rm -r .npmrc node_modules

# Generate the REST API documentation.
RUN cd /var/www && php artisan apidoc &> /dev/null

# Generate the server API documentation
RUN curl -O https://doctum.long-term.support/releases/latest/doctum.phar \
    && php doctum.phar update --ignore-parse-errors doctum.php &> /dev/null \
    && rm -r doctum.phar

# Add custom configs.
COPY config/filesystems.php /var/www/config/filesystems.php

RUN php /var/www/artisan route:cache

COPY .env /var/www/.env
RUN php /var/www/artisan config:cache && rm /var/www/.env
