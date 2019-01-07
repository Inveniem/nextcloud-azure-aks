#!/usr/bin/env bash

##
# This script publishes the PHP-FPM-based version of Nextcloud to an Azure
# Container Registry instance.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source '../../config.env'

CONTAINER_NAME="inveniem/nextcloud-fpm:latest"

docker build -t "${CONTAINER_NAME}" .
docker tag "${CONTAINER_NAME}" "${REGISTRY_HOST}/${CONTAINER_NAME}"

az acr login --name "${REGISTRY_NAME}"
docker push "${REGISTRY_HOST}/${CONTAINER_NAME}"
