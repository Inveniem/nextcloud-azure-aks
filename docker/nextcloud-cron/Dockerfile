##
# Custom Nextcloud Dockerfile for Nextcloud cron tasks.
#
# NOTE: All COPY paths are relative to the parent folder (../docker).
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019-2020, Inveniem
# @license GNU AGPL version 3 or any later version
#
FROM nextcloud:18.0.7-apache

ENV NEXTCLOUD_CONFIG_READ_ONLY "true"

# Eliminate default APCu configuration (we're using Redis)
#
# NOTE: This removes a config added by the base image.
RUN rm /usr/src/nextcloud/config/apcu.config.php

# Eliminate stock Redis config (we provide our own config)
#
# NOTE: This removes a config added by the base image.
RUN rm -f /usr/src/nextcloud/config/redis.config.php

COPY nextcloud-cron/entrypoint.sh /
COPY nextcloud-common/config/* /usr/src/nextcloud/config/

# Apply custom patches
COPY nextcloud-common/apply_patches.sh /
COPY nextcloud-common/bundled-patches/ /usr/src/nextcloud/bundled-patches
RUN /apply_patches.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
