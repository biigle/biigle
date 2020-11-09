FROM biigle/build-dist AS intermediate

FROM tensorflow/tensorflow:1.15.4-gpu-py3
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

# Install PHP 7.4 because this time we start from the TensorFlow base image.
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        php7.4-cli \
        php7.4-curl \
        php7.4-pgsql \
        php7.4-json \
        php7.4-mbstring \
        php-redis \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*

# Set this library path to the Python modules are linked correctly.
# See: https://github.com/python-pillow/Pillow/issues/1763#issuecomment-204252397
ENV LIBRARY_PATH=/lib:/usr/lib
COPY .docker/requirements.txt /tmp/requirements.txt
# Install Python dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        libfreetype6 \
        liblapack3 \
        libstdc++6 \
        libjpeg62 \
        libpng16-16 \
        libsm6 \
        libxext6 \
        libxrender1 \
        zlib1g \
        libhdf5-100 \
        build-essential \
        python3-dev \
        python3-pip \
        python3-setuptools \
        libfreetype6-dev \
        liblapack-dev \
        gfortran \
        libjpeg-dev \
        libpng-dev \
        zlib1g-dev \
        libhdf5-dev \
        libvips \
    && pip3 install --no-cache-dir -r /tmp/requirements.txt \
    && apt-get purge -y \
        build-essential \
        python3-dev \
        python3-pip \
        python3-setuptools \
        libfreetype6-dev \
        liblapack-dev \
        gfortran \
        libjpeg-dev \
        libpng-dev \
        zlib1g-dev \
        libhdf5-dev \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/* \
    && rm -r /tmp/*

WORKDIR /var/www

# This is required to run php artisan tinker in the worker container. Do this for
# debugging purposes.
RUN mkdir -p /.config/psysh && chmod o+w /.config/psysh

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
COPY --from=intermediate /var/www /var/www
