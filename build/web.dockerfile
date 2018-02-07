FROM biigle/app-dist as intermediate

FROM biigle/web
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

COPY --from=intermediate /var/www/public /var/www/public
