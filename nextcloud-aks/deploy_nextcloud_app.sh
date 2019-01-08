#!/usr/bin/env bash

##
# This script deploys the Nextcloud application to Kubernetes.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

echo "Setting up pod preset for dynamic file shares..."
./generate_share_mount_pod_preset.sh | kubectl apply -f -
echo "Done."
echo ""

FILES=(
    'configmap.yaml'
    'secrets.yaml'
)

if [[ "${POD_TYPE:-apache}" = "php-fpm" ]]; then
    FILES+=('nextcloud-fpm-nginx.yaml')
else
    FILES+=('nextcloud-apache.yaml')
fi

echo "Deploying Nextcloud core application..."
for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl apply -f -
done
echo "Done."
echo ""
