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
FROM nextcloud:16.0.6-fpm

ENV NEXTCLOUD_CONFIG_READ_ONLY "false"

# Eliminate default APCu configuration (we're using Redis)
RUN rm /usr/src/nextcloud/config/apcu.config.php

# Eliminate stock Redis config (we provide our own config)
RUN rm -f /usr/src/nextcloud/config/redis.config.php

COPY nextcloud-common/entrypoint.sh /
COPY nextcloud-common/config/* /usr/src/nextcloud/config/

# Setup New Relic (if configured)
COPY nextcloud-common/generated/setup_newrelic.sh /
RUN /setup_newrelic.sh && rm /setup_newrelic.sh

# Supply all custom apps via Docker image; app store is disabled
COPY nextcloud-common/custom_apps/. /usr/src/nextcloud/custom_apps/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
