FROM biigle/build-dist AS intermediate

FROM ghcr.io/biigle/worker:latest
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

RUN echo "memory_limit=1G" > "$PHP_INI_DIR/conf.d/memory_limit.ini"

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
COPY --from=intermediate /var/www /var/www
