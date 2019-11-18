##
# Custom Nextcloud Dockerfile for a PHP-FPM-based Nextcloud installation that
# does not store the Nextcloud distribution on persistent storage.
#
# NOTE: All COPY paths are relative to the parent folder (../docker).
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#
FROM nextcloud:16.0.6-fpm-alpine

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

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
