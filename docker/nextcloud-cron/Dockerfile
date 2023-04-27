##
# Custom Nextcloud Dockerfile for Nextcloud cron tasks.
#
# NOTE: All COPY paths are relative to the parent folder (../docker).
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019-2020, Inveniem
# @license GNU AGPL version 3 or any later version
#
FROM nextcloud:23.0.10-apache

ENV NEXTCLOUD_CONFIG_READ_ONLY "true"

# Eliminate stock Redis config (we provide our own config)
#
# NOTE: This removes a config added by the base image.
RUN rm -f /usr/src/nextcloud/config/redis.config.php

COPY nextcloud-cron/entrypoint.sh /
COPY nextcloud-common/config/* /usr/src/nextcloud/config/

# Create combined CA file, per:
# https://learn.microsoft.com/en-us/azure/mariadb/concepts-certificate-rotation
COPY nextcloud-common/ssl/azure_ca/ /tmp/azure_ca
RUN cat /tmp/azure_ca/*.pem >/usr/src/nextcloud/config/azure_ca.pem

COPY nextcloud-cron/cleanup_uploads.sh /

# Ensure custom apps are available during cron runs.
# We supply all custom apps via Docker image; app store is disabled
COPY nextcloud-common/custom_apps/. /usr/src/nextcloud/custom_apps/

# Apply custom patches
COPY nextcloud-common/apply_patches.sh /
COPY nextcloud-common/bundled-patches/ /usr/src/nextcloud/bundled-patches
RUN /apply_patches.sh

ENTRYPOINT ["/entrypoint.sh"]
