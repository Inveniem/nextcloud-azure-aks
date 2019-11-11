#!/usr/bin/env bash

##
# This script attempts to publish all of the Docker images inside this folder
# to an Azure Container Registry instance.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

DIRS=$(find . -mindepth 1 -maxdepth 1 -type d -not -name '*common')

./nextcloud-common/download_apps.sh

echo "${DIRS[@]}" | while read -r dir; do
  "${dir}/publish.sh"
done
