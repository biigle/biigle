FROM biigle/app-dist as intermediate

FROM biigle/web
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

ARG TIMEZONE
COPY --from=intermediate /etc/localtime /etc/localtime
RUN echo "${TIMEZONE}" > /etc/timezone

COPY --from=intermediate /var/www/public /var/www/public
