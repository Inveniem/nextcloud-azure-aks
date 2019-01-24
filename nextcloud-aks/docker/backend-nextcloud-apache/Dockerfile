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
FROM nextcloud:15-apache

COPY nextcloud-common/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
