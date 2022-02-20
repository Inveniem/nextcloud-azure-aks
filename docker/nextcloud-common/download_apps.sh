#!/usr/bin/env bash

##
# This script downloads all of the custom apps in the config and puts them
# in ./custom_apps.
#
# This is optional. This script only downloads and configures apps if the
# following environment variable is set:
#
# - NEXTCLOUD_CUSTOM_APPS
#
# These variables are typically set via publish.env in an overlay, and then this
# script is invoked automatically by `./rigger publish` within the overlay.
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
##
# Error thrown when a bad command-line argument has been provided.
#
error_bad_arguments=1

script_path="${BASH_SOURCE[0]}"
script_dirname="$( cd "$( dirname "${script_path}" )" >/dev/null 2>&1 && pwd )"

################################################################################
# Overridable Environment Variables
################################################################################
# All of the variables below can be specified on the command line to override
# them at run-time.
if [[ -z "${NEXTCLOUD_CUSTOM_APPS:-}" ]]; then
  NEXTCLOUD_CUSTOM_APPS=()

elif [[ ! "$(declare -p NEXTCLOUD_CUSTOM_APPS)" =~ "declare -a" ]]; then
  # Top-level scripts cannot export an array as an environment variable, so they
  # have to delimit the values with spaces. To fix this, we have Bash split on
  # the spaces.

  # shellcheck disable=SC2128
  # shellcheck disable=SC2206
  NEXTCLOUD_CUSTOM_APPS=( ${NEXTCLOUD_CUSTOM_APPS} )
fi

################################################################################
# Main Script Body
################################################################################
cd "${script_dirname}"

rm -rf ./custom_apps
mkdir -p ./custom_apps

echo "Downloading apps..."

for custom_app_url in "${NEXTCLOUD_CUSTOM_APPS[@]}"; do
  app_name=$(basename "${custom_app_url}")

  echo "- Downloading and extracting ${app_name}."

  if ! wget -qO- "${custom_app_url}" | tar -xz -C ./custom_apps >/dev/null 2>&1; then
    {
      echo ""
      echo "Failed to download '${custom_app_url}' (check URL)."
      echo ""
    } >&2

    exit "${error_bad_arguments}"
  fi
done

echo ""
echo "Done. Custom apps are in '${script_dirname}/custom_apps'."
echo ""
