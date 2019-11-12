#!/usr/bin/env bash

##
# This script removes the ClamAV daemon and its service from Kubernetes.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

FILES=(
    'app-clamav.template.yaml'
)

./set_context.sh

echo "Un-deploying ClamAV Daemon..."
for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl delete -f -
done
echo "Done."
echo ""
