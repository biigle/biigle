FROM biigle/app-dist:arm32v6 as intermediate

FROM biigle/worker:arm32v6
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

ARG TIMEZONE
COPY --from=intermediate /etc/localtime /etc/localtime
RUN echo "${TIMEZONE}" > /etc/timezone

COPY --from=intermediate /var/www /var/www
