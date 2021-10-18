#!/usr/bin/env bash

##
# This script publishes the Apache-PHP-based version of Nextcloud to an Azure
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
CONTAINER_NAME="inveniem/nextcloud-apache:${CONTAINER_VERSION}"

../nextcloud-common/generate_nr_setup_command.sh


$CONTAINER_ENGINE build -t "${CONTAINER_NAME}" -f Dockerfile ..
$CONTAINER_ENGINE tag "${CONTAINER_NAME}" "${REGISTRY_HOST}/${CONTAINER_NAME}"


case $CONTAINER_ENGINE in

  docker | Docker)
    az acr login --name "${REGISTRY_NAME}"
    ;;

  podman | Podman)
    GET_REGISTRY_TOKEN=`az acr login --name ${REGISTRY_NAME} --expose-token | jq .accessToken |tr -d '"'`
    $CONTAINER_ENGINE login ${REGISTRY_HOST} -u 00000000-0000-0000-0000-000000000000 -p $GET_REGISTRY_TOKEN
    ;;
esac

$CONTAINER_ENGINE push "${REGISTRY_HOST}/${CONTAINER_NAME}"


