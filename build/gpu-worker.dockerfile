FROM biigle/build-dist AS intermediate

FROM pytorch/pytorch:2.2.2-cuda11.8-cudnn8-runtime
LABEL org.opencontainers.image.authors="Martin Zurowietz <m.zurowietz@uni-bielefeld.de>"
LABEL org.opencontainers.image.source="https://github.com/biigle/biigle"

RUN LC_ALL=C.UTF-8 apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common gnupg-agent \
    && add-apt-repository -y ppa:ondrej/php \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        php8.2-cli \
        php8.2-curl \
        php8.2-xml \
        php8.2-pgsql \
        php8.2-mbstring \
        php8.2-redis \
    && apt-get purge -y software-properties-common gnupg-agent \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgl1 libglib2.0-0 \
        build-essential \
        git \
        libvips \
    && pip3 install --no-cache-dir -r /tmp/requirements.txt \
    # Use --no-dependencies so torch is not installed again.
    && pip3 install --no-dependencies --index-url https://download.pytorch.org/whl/cu118 xformers==0.0.25.post1 \
    && apt-get purge -y \
        build-essential \
        git \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/* \
    && rm -r /tmp/*

RUN echo "memory_limit=1G" > "/etc/php/8.2/cli/conf.d/memory_limit.ini"

# Ensure compatibility with default paths of bigle/largo.
RUN ln -s /opt/conda/bin/python3 /usr/bin/python3
RUN ln -s /opt/conda/bin/python /usr/bin/python

WORKDIR /var/www

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
COPY --from=intermediate /var/www /var/www
