#!/bin/sh

##
# Nextcloud Docker script to clean up failed uploads for Nextcloud cron runs.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @author Brandon McWhirter (brandon.mcwhirter@inveniem.com)
# @copyright Copyright (c) 2022, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -eu

find /var/www/html/data/ \
  -mindepth 3 \
  -maxdepth 3 \
  -type d \
  -wholename '/var/www/html/data/*/uploads/web-file-upload*' \
  -mtime +7 \
  '(' ! -wholename '*/.snapshot/*' ')' \
  -exec rm -rvf '{}' ';'
