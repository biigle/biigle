FROM biigle/build-dist AS intermediate

FROM docker.pkg.github.com/biigle/gpus/gpus-worker
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
COPY --from=intermediate /var/www /var/www
