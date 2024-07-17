FROM biigle/build-dist AS intermediate

FROM ghcr.io/biigle/worker:latest
LABEL org.opencontainers.image.authors="Martin Zurowietz <m.zurowietz@uni-bielefeld.de>"
LABEL org.opencontainers.image.source="https://github.com/biigle/biigle"

RUN echo "memory_limit=1G" > "$PHP_INI_DIR/conf.d/memory_limit.ini"

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
COPY --from=intermediate /var/www /var/www
