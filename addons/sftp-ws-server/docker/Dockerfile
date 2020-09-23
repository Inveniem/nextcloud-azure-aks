FROM node:12.18.4

COPY app/ /app/

WORKDIR /app
VOLUME /app/files

ENV SFTP_WS_HOST="localhost"
ENV SFTP_WS_PORT="4002"
ENV SFTP_WS_APP_HOST="localhost:4002"
ENV SFTP_WS_ORIGIN_RESTRICTIONS="{}"

RUN yarn install

USER 33

CMD ["server.js"]

ARG PROJECT_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vendor="Inveniem" \
    org.label-schema.url="https://github.com/Inveniem/nextcloud-azure-aks" \
    org.label-schema.name="Nextcloud SFTP-WS Server Add-on" \
    org.label-schema.description="An add-on service for Nextcloud that allows web applications to access the volumes backing a Nextcloud installation over the SFTP-WS protocol." \
    org.label-schema.version=$PROJECT_VERSION \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.build-date=$BUILD_DATE
