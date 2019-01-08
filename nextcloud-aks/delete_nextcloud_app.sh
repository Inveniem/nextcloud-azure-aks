#!/usr/bin/env bash

##
# This script removes the Nextcloud application, its load balancer, its config,
# and its secrets from Kubernetes.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

if [[ "${POD_TYPE:-apache}" = "php-fpm" ]]; then
    FILES=('nextcloud-fpm-nginx.yaml')
else
    FILES=('nextcloud-apache.yaml')
fi

FILES+=(
    'secrets.yaml'
    'configmap.yaml'
)

echo "Un-deploying Nextcloud core application..."
for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl delete -f -
done
echo "Done."
echo ""

echo "Removing pod preset for dynamic file shares..."
./generate_share_mount_pod_preset.sh | kubectl delete -f -
echo "Done."
echo ""

