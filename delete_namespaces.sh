#!/usr/bin/env bash

##
# This optional script removes all Nextcloud namespaces.
#
# This only works if Namespaces were previously deployed via:
# ```
# ./deploy_namespaces.sh
# ```
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'
source './functions.sh'

FILES=(
    'namespace-nextcloud-dev.yaml'
    'namespace-nextcloud-live.yaml'
)

./set_context.sh

{
    echo "This will attempt to remove ALL Nextcloud deployment information for"
    echo "ALL NEXTCLOUD NAMESPACES (dev, live, etc) from your Kubernetes"
    echo "infrastructure, which may result in loss of settings information"
    echo "(access keys, database credentials, etc)."
    echo ""
} >&2

confirmation_prompt "Are you sure"

if [[ "${confirmed}" -eq 1 ]]; then
    echo "Removing Nextcloud namespaces..."
    for file in "${FILES[@]}"; do
        kubectl delete -f "configs/${file}"
    done
    echo "Done."
    echo ""
fi
