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

parse_args() {
    if [[ $# -eq 1 ]]; then
        if [[ "${1}" == "--with-xdebug" ]]; then
            BUILD_ARGS="--build-arg XDEBUG_ENABLED=true"
        else
            print_usage_and_exit
        fi
    elif [[ $# -gt 1 ]]; then
        print_usage_and_exit
    fi
}

print_usage_and_exit() {
    {
        echo "Usage: ${0} [--with-xdebug]"
        echo ""

    } >&2

    exit 1
}

configure_new_relic() {
    ../nextcloud-common/generate_nr_setup_command.sh
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${SCRIPT_DIR}"

source '../../config.env'

CONTAINER_VERSION="${CONTAINER_VERSION:-latest}"
CONTAINER_NAME="inveniem/nextcloud-fpm:${CONTAINER_VERSION}"

parse_args "$@"
configure_new_relic

docker build -t "${CONTAINER_NAME}" -f Dockerfile .. ${BUILD_ARGS:-}
docker tag "${CONTAINER_NAME}" "${REGISTRY_HOST}/${CONTAINER_NAME}"

az acr login --name "${REGISTRY_NAME}"
docker push "${REGISTRY_HOST}/${CONTAINER_NAME}"
