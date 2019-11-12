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

FILES=(
    'namespace-nextcloud-dev.yaml'
    'namespace-nextcloud-live.yaml'
)

./set_context.sh

echo "Removing Nextcloud namespaces..."
for file in "${FILES[@]}"; do
    kubectl delete -f "${file}"
done
echo "Done."
echo ""
