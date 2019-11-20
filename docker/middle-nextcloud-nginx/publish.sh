#!/usr/bin/env bash

##
# This script publishes the Nginx reverse proxy and static content server to an
# Azure Container Registry instance.
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
CONTAINER_NAME="inveniem/nextcloud-nginx-middleware:${CONTAINER_VERSION}"

docker build -t "${CONTAINER_NAME}" .
docker tag "${CONTAINER_NAME}" "${REGISTRY_HOST}/${CONTAINER_NAME}"

az acr login --name "${REGISTRY_NAME}"
docker push "${REGISTRY_HOST}/${CONTAINER_NAME}"
