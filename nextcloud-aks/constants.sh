#!/usr/bin/env bash

##
# Constants for the scripts in this folder.
#
# These values typically do not need to be customized.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

##
# The default container version to publish and pull down.
#
# This is typically controlled by the VERSION file in this folder, but can be
# overridden on the command-line by prefixing each command with it.
# For example:
# ```
# CONTAINER_VERSION=1.2.0 ./publish_container_images.sh
# CONTAINER_VERSION=1.2.0 ./deploy_nextcloud_app.sh
# ```
#
if [[ "${CONTAINER_VERSION:-UNSET}" == "UNSET" ]]; then
    if [[ -f "${SCRIPT_DIR}/VERSION" ]]; then
        CONTAINER_VERSION=$(head -n1 "${SCRIPT_DIR}/VERSION")
    else
        CONTAINER_VERSION="latest"
    fi
fi
