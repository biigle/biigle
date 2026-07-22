FROM biigle/build-dist AS intermediate

FROM pytorch/pytorch:2.13.0-cuda12.6-cudnn9-runtime
LABEL org.opencontainers.image.authors="Martin Zurowietz <m.zurowietz@uni-bielefeld.de>"
LABEL org.opencontainers.image.source="https://github.com/biigle/biigle"

RUN LC_ALL=C.UTF-8 apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common gnupg-agent \
    && add-apt-repository -y ppa:ondrej/php \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        php8.5-cli \
        php8.5-curl \
        php8.5-xml \
        php8.5-pgsql \
        php8.5-mbstring \
        php8.5-redis \
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
    && pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt \
    # Use --no-dependencies so torch is not installed again.
    && pip3 install --no-dependencies --break-system-packages xformers>=0.0.34 \
    && apt-get purge -y \
        build-essential \
        git \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/* \
    && rm -r /tmp/*

RUN echo "memory_limit=1G" > "/etc/php/8.5/cli/conf.d/memory_limit.ini"

# Ensure compatibility with old env configs.
RUN mkdir -p /opt/conda/bin && ln -s /usr/bin/python3 /opt/conda/bin/python3
RUN mkdir -p /opt/conda/bin && ln -s /usr/bin/python /opt/conda/bin/python

WORKDIR /var/www

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
COPY --from=intermediate /var/www /var/www
