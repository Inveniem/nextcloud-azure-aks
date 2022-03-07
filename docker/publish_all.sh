#!/usr/bin/env bash

##
# This script attempts to publish all of the Docker images inside this folder
# to Container Registry.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019-2022, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

################################################################################
# Constants
################################################################################
script_path="${BASH_SOURCE[0]}"
script_dirname="$( cd "$( dirname "${script_path}" )" >/dev/null 2>&1 && pwd )"

################################################################################
# Main Script Body
################################################################################
cd "${script_dirname}"

dirs=$(find . -mindepth 1 -maxdepth 1 -type d -not -name '*common')

./nextcloud-common/download_apps.sh

echo "${dirs[@]}" | while read -r dir; do
  echo "Building '${dir}':"
  echo ""

  "${dir}/publish.sh" "$@"

  echo ""
  echo ""
done
