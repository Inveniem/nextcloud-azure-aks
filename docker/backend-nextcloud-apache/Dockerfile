##
# Custom Nextcloud Dockerfile for an Apache-based Nextcloud installation that
# does not store the Nextcloud distribution on persistent storage.
#
# NOTE: All COPY paths are relative to the parent folder (../docker).
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#
FROM nextcloud:16.0.6-apache

ENV NEXTCLOUD_CONFIG_READ_ONLY "false"

# Eliminate default APCu configuration (we're using Redis)
#
# NOTE: This removes a config added by the base image.
RUN rm /usr/src/nextcloud/config/apcu.config.php

# Eliminate stock Redis config (we provide our own config)
#
# NOTE: This removes a config added by the base image.
RUN rm -f /usr/src/nextcloud/config/redis.config.php

# Allow detection of HTTPS from behind SSL-enabled ingress
#
# NOTE: This has security implications if the Nextcloud service is exposed
# directly to the internet via a LoadBalancer service type instead of being
# an internal service behind an HTTPS-only ingress. Normally, it is only
# safe to trust HTTP_X_FORWARDED_* headers from known proxies. However,
# within a cluster that is only accessible through HTTPS-only ingress, it
# should not be possible to access this internal Apache server directly.
#
RUN {\
     echo 'SetEnvIf X-Forwarded-Proto "https" HTTPS=on' ;\
    } > /etc/apache2/conf-available/forwarded-https.conf;\
    a2enconf forwarded-https

# Properly log real client IP address when behind ingress.
#
RUN {\
     echo 'LogFormat "%v:%p %a %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined' ;\
     echo 'LogFormat "%a %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined' ;\
     echo 'LogFormat "%a %l %u %t \"%r\" %>s %O" common' ;\
    } > /etc/apache2/conf-available/forwarded-client-ip.conf;\
    a2enconf forwarded-client-ip

COPY nextcloud-common/entrypoint.sh /
COPY nextcloud-common/config/* /usr/src/nextcloud/config/

# Setup New Relic (if configured)
COPY nextcloud-common/generated/setup_newrelic.sh /
RUN /setup_newrelic.sh && rm /setup_newrelic.sh

# Supply all custom apps via Docker image; app store is disabled
COPY nextcloud-common/custom_apps/. /usr/src/nextcloud/custom_apps/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
