FROM biigle/build-dist AS intermediate

FROM quay.io/soketi/soketi:1.4-16-alpine
LABEL org.opencontainers.image.authors="Martin Zurowietz <m.zurowietz@uni-bielefeld.de>"
LABEL org.opencontainers.image.source="https://github.com/biigle/biigle"

ARG SOKETI_DEFAULT_APP_ID
ARG SOKETI_DEFAULT_APP_KEY
ARG SOKETI_DEFAULT_APP_SECRET

ENV SOKETI_DEFAULT_APP_ID=${SOKETI_DEFAULT_APP_ID}
ENV SOKETI_DEFAULT_APP_KEY=${SOKETI_DEFAULT_APP_KEY}
ENV SOKETI_DEFAULT_APP_SECRET=${SOKETI_DEFAULT_APP_SECRET}
ENV SOKETI_DEFAULT_APP_USER_AUTHENTICATION=1
ENV SOKETI_SHUTDOWN_GRACE_PERIOD=3000
ENV SOKETI_METRICS_ENABLED=0
ENV SOKETI_DEBUG=0

COPY --from=intermediate /etc/localtime /etc/localtime
COPY --from=intermediate /etc/timezone /etc/timezone
