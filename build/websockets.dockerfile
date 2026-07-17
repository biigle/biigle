FROM biigle/build-dist AS intermediate

FROM quay.io/soketi/soketi:1.4-16-alpine
LABEL org.opencontainers.image.authors="Martin Zurowietz <m.zurowietz@uni-bielefeld.de>"
LABEL org.opencontainers.image.source="https://github.com/biigle/biigle"

ENV SOKETI_DEFAULT_APP_USER_AUTHENTICATION=1
ENV SOKETI_SHUTDOWN_GRACE_PERIOD=3000
ENV SOKETI_METRICS_ENABLED=0
ENV SOKETI_DEBUG=0

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
