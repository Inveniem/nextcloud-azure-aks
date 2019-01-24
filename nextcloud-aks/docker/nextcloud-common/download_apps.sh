#!/usr/bin/env bash

##
# This script downloads all of the custom apps in the config and puts them
# in ./custom_apps.
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

rm -rf ./custom_apps
mkdir -p ./custom_apps

echo "Downloading apps..."

for custom_app in "${NEXTCLOUD_CUSTOM_APPS[@]}"; do
    app_name=$(basename "${custom_app}")
    echo "- Downloading and extracting ${app_name}."
    wget -qO- $custom_app | tar -xz -C ./custom_apps
done

echo ""
echo "Done. Custom apps are in '${SCRIPT_DIR}/custom_apps'."
