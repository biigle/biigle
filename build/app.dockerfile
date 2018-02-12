FROM biigle/app
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

# Ignore platform reqs because the app image is stripped down to the essentials
# and doens't meet some of the requirements. We do this for the worker, though.
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && COMPOSER_SIGNATURE=$(curl -s https://composer.github.io/installer.sig) \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '$COMPOSER_SIGNATURE') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --version=1.6.2 \
    && rm composer-setup.php

ARG GITHUB_OAUTH_TOKEN
# The COMPOSER_AUTH env variable did not work somehow.
RUN php composer.phar config -g github-oauth.github.com ${GITHUB_OAUTH_TOKEN}

ENV COMPOSER_NO_INTERACTION 1
ENV COMPOSER_ALLOW_SUPERUSER 1

# Include the Composer cache directory to speed up the build.
COPY cache /root/.composer/cache

ARG PROJECTS_VERSION=">=1.0"
RUN php composer.phar config repositories.projects vcs https://github.com/BiodataMiningGroup/biigle-projects \
    && php composer.phar require biigle/projects:${PROJECTS_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Projects\\ProjectsServiceProvider::class,' config/app.php \
    && php artisan projects:publish

ARG LABEL_TREES_VERSION=">=1.0"
RUN php composer.phar config repositories.label-trees vcs https://github.com/BiodataMiningGroup/biigle-label-trees \
    && php composer.phar require biigle/label-trees:${LABEL_TREES_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\LabelTrees\\LabelTreesServiceProvider::class,' config/app.php \
    && php artisan label-trees:publish

ARG VOLUMES_VERSION=">=1.0"
RUN php composer.phar config repositories.volumes vcs https://github.com/BiodataMiningGroup/biigle-volumes \
    && php composer.phar require biigle/volumes:${VOLUMES_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Volumes\\VolumesServiceProvider::class,' config/app.php \
    && php artisan volumes:publish

ARG ANNOTATIONS_VERSION=">=1.0"
RUN php composer.phar config repositories.annotations vcs https://github.com/BiodataMiningGroup/biigle-annotations \
    && php composer.phar require biigle/annotations:${ANNOTATIONS_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Annotations\\AnnotationsServiceProvider::class,' config/app.php \
    && php artisan annotations:publish

ARG LARGO_VERSION=">=1.0"
RUN php composer.phar config repositories.largo vcs https://github.com/BiodataMiningGroup/biigle-largo \
    && php composer.phar require biigle/largo:${LARGO_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Largo\\LargoServiceProvider::class,' config/app.php \
    && php artisan largo:publish

ARG EXPORT_VERSION=">=1.0"
RUN php composer.phar config repositories.export vcs https://github.com/BiodataMiningGroup/biigle-export \
    && php composer.phar require biigle/export:${EXPORT_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Export\\ExportServiceProvider::class,' config/app.php \
    && php artisan export:publish

ARG GEO_VERSION=">=1.0"
RUN php composer.phar config repositories.geo vcs https://github.com/BiodataMiningGroup/biigle-geo \
    && php composer.phar require biigle/geo:${GEO_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Geo\\GeoServiceProvider::class,' config/app.php \
    && php artisan geo:publish

ARG COLOR_SORT_VERSION=">=1.0"
RUN php composer.phar config repositories.color-sort vcs https://github.com/BiodataMiningGroup/biigle-color-sort \
    && php composer.phar require biigle/color-sort:${COLOR_SORT_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\ColorSort\\ColorSortServiceProvider::class,' config/app.php \
    && php artisan color-sort:publish

ARG LASERPOINTS_VERSION=">=1.0"
RUN php composer.phar config repositories.laserpoints vcs https://github.com/BiodataMiningGroup/biigle-laserpoints \
    && php composer.phar require biigle/laserpoints:${LASERPOINTS_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Laserpoints\\LaserpointsServiceProvider::class,' config/app.php \
    && php artisan laserpoints:publish

ARG ANANAS_VERSION=">=1.0"
RUN php composer.phar config repositories.ananas vcs https://github.com/BiodataMiningGroup/biigle-ananas \
    && php composer.phar require biigle/ananas:${ANANAS_VERSION} --prefer-dist --update-no-dev --ignore-platform-reqs \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Ananas\\AnanasServiceProvider::class,' config/app.php \
    && php artisan ananas:publish

RUN rm composer.phar

RUN php /var/www/artisan route:cache
