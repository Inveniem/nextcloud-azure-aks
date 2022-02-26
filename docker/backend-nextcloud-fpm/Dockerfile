##
# Custom Nextcloud Dockerfile for a PHP-FPM-based Nextcloud installation that
# does not store the Nextcloud distribution on persistent storage.
#
# NOTE: All COPY paths are relative to the parent folder (../docker).
#
# This is a multi-stage build.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

################################################################################
# musl Library Build
################################################################################
# Patch Alpine musl to work around this issue:
# https://gitlab.alpinelinux.org/alpine/aports/issues/10960
#
FROM alpine:3.10 as musl_compile

RUN set -eux;\
    apk add --update \
        make \
        gcc \
        musl-dev \
        curl \
        gnupg\
    ; \
    mkdir /build; \
    cd /build; \
    \
    for key in \
        836489290BB6B70F99FFDA0556BCDB593020450F \
    ; do \
        gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key" || \
        gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
        gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
    done; \
    \
    curl -O https://www.musl-libc.org/releases/musl-1.1.24.tar.gz; \
    curl -O https://www.musl-libc.org/releases/musl-1.1.24.tar.gz.asc; \
    \
    gpg --batch --verify musl-1.1.24.tar.gz.asc musl-1.1.24.tar.gz; \
    \
    tar -xvzf musl-1.1.24.tar.gz; \
    cd ./musl-1.1.24; \
    sed -i 's/char buf\[2048\]/char buf\[8192\]/' ./src/dirent/__dirent.h; \
    \
    ./configure; \
    make; \
    make install

################################################################################
# Build Nextcloud container
################################################################################
# This is the container that actually gets pushed.
#
FROM nextcloud:21.0.9-fpm-alpine

ENV NEXTCLOUD_CONFIG_READ_ONLY "false"

# Fix-up www-data UID from 82 to 33.
#
# www-data MUST be UID 33 to match Azure Files SMB Mounts.
# But first, we have to remove the XFS user account because it's occupying
# UID 33.
#
RUN set -eux; \
    apk --update --no-cache add shadow && \
    deluser xfs && \
    find '/var/www' -user 'www-data' -exec 'chown' 33 '{}' ';' && \
    usermod -u 33 www-data && \
    groupmod -g 33 www-data && \
    apk del shadow

# Tune PHP-FPM process manager
RUN set -eu; \
    { \
        echo '[www]'; \
        echo 'pm = dynamic'; \
        echo 'pm.max_children = 20'; \
        echo 'pm.start_servers = 10'; \
        echo 'pm.min_spare_servers = 5'; \
        echo 'pm.max_spare_servers = 10'; \
        echo 'pm.max_requests = 50'; \
    } >/usr/local/etc/php-fpm.d/www.pm-tuning.conf

# Eliminate default APCu configuration (we're using Redis)
# and stock Redis config (we provide our own config)
RUN rm /usr/src/nextcloud/config/apcu.config.php && \
    rm /usr/src/nextcloud/config/redis.config.php

# Setup New Relic (if configured)
COPY nextcloud-common/generated/setup_newrelic.sh /
RUN /setup_newrelic.sh && rm /setup_newrelic.sh

COPY nextcloud-common/entrypoint.sh /
COPY nextcloud-common/config/* /usr/src/nextcloud/config/

# Supply all custom apps via Docker image; app store is disabled
COPY nextcloud-common/custom_apps/. /usr/src/nextcloud/custom_apps/

# Apply custom musl library
COPY --from="musl_compile" /usr/local/musl/lib/libc.so /lib/ld-musl-x86_64.so.1

# Apply custom patches
COPY nextcloud-common/apply_patches.sh /
COPY nextcloud-common/bundled-patches/ /usr/src/nextcloud/bundled-patches
RUN /apply_patches.sh

ARG XDEBUG_ENABLED="false"

# Give developers an ability to attach to a running container with XDebug.
#
# To take advantage of this, this requires forwarding a port on the local
# (developer) machine to a port listening inside the container by combining
# netcat (nc) running locally with `tcpserver` in the container.
#
# See ../../launch_xdebug_proxy.sh for more information.
#
RUN set -eu; \
    if [ "${XDEBUG_ENABLED}" = "true" ]; then \
        apk add --update --no-cache \
            --virtual build-dependencies \
            $PHPIZE_DEPS \
        ; \
        pecl install xdebug; \
        apk del build-dependencies; \
        \
        docker-php-ext-enable xdebug; \
        \
        { \
            echo 'xdebug.remote_host="xdebug-tunnel"'; \
            echo 'xdebug.remote_port=9001'; \
            echo 'xdebug.remote_enable=on'; \
            echo 'xdebug.remote_autostart=off'; \
            echo 'xdebug.remote_connect_back=off'; \
        } >>/usr/local/etc/php/conf.d/xdebug.ini; \
    fi

# Install additional utilities for CLI-based utilization
RUN apk add --update --no-cache \
        zip \
        unzip \
        p7zip \
    ;

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
