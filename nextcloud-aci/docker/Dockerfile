##
# Custom Nextcloud Dockerfile for working with the proof-of-concept for a
# version of Nextcloud that does not check the ownership of the `config.php`
# file.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

FROM nextcloud:15-apache

RUN set -ex; \
    fetchDeps=" \
        git \
    "; \
    apt-get update; \
    apt-get install -y --no-install-recommends $fetchDeps; \
    \
    mkdir -p /tmp/nextcloud; \
    git clone --branch feature/skip-owner-checks https://github.com/GuyPaddock/nextcloud-server.git /tmp/nextcloud; \
    rsync -av --no-i-r --exclude=.git /tmp/nextcloud/ /usr/src/nextcloud; \
    \
    rm -rf /tmp/nextcloud; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps;

COPY *.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
