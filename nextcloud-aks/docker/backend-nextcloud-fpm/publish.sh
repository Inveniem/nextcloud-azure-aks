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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${SCRIPT_DIR}"

source '../../config.env'

CONTAINER_VERSION="${CONTAINER_VERSION:-latest}"
CONTAINER_NAME="inveniem/nextcloud-fpm:${CONTAINER_VERSION}"

../nextcloud-common/generate_nr_setup_command.sh

docker build -t "${CONTAINER_NAME}" -f Dockerfile ..
docker tag "${CONTAINER_NAME}" "${REGISTRY_HOST}/${CONTAINER_NAME}"

az acr login --name "${REGISTRY_NAME}"
docker push "${REGISTRY_HOST}/${CONTAINER_NAME}"
