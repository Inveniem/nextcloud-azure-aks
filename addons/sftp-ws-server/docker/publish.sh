#!/usr/bin/env bash

##
# This script publishes the SFTP-WS Server Nextcloud Add-on to an Azure
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

source '../../../config.env'

CONTAINER_VERSION="${CONTAINER_VERSION:-latest}"
CONTAINER_NAME="inveniem/sftp-ws-server:${CONTAINER_VERSION}"

docker build -t "${CONTAINER_NAME}" -f Dockerfile . ${BUILD_ARGS:-}
docker tag "${CONTAINER_NAME}" "${REGISTRY_HOST}/${CONTAINER_NAME}"

az acr login --name "${REGISTRY_NAME}"
docker push "${REGISTRY_HOST}/${CONTAINER_NAME}"
