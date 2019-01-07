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

DIRS=(
    'backend-nextcloud-apache'
    'backend-nextcloud-fpm'
    'middle-nextcloud-nginx'
)

for dir in "${DIRS[@]}"; do
    cd "./${dir}"
    ./publish.sh
    cd "../"
done
