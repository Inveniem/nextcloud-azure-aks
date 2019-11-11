#!/usr/bin/env bash

##
# This is a top-level script to remove all traces of Nextcloud from Azure and
# Kubernetes, after they were deployed by other scripts within this repository.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

./delete_nextcloud_app.sh
./delete_nextcloud_volumes.sh
./delete_storage_account.sh
./delete_redis_app.sh
./delete_clamav.sh
./recreate_nextcloud_db.sh
