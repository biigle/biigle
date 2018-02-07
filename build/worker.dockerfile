FROM biigle/app-dist as intermediate

FROM biigle/worker
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

COPY --from=intermediate /var/www /var/www
