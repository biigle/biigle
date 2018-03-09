FROM biigle/app-dist:arm64v8 as intermediate

FROM biigle/web:arm64v8
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

ARG TIMEZONE
COPY --from=intermediate /etc/localtime /etc/localtime
RUN echo "${TIMEZONE}" > /etc/timezone

COPY --from=intermediate /var/www/public /var/www/public
