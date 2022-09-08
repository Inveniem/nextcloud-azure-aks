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

cd /var/www/html/

find . -wholename "*uploads/web-file-upload*" -type d ! -mtime 7 -exec rm -rvf "{}" ";"
