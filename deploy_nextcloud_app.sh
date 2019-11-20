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

# NOTE: This is commented out for now because we can't yet use pod presets on
# AKS. Vote for the feature here:
# https://feedback.azure.com/forums/914020-azure-kubernetes-service-aks/suggestions/35054089-support-podpreset-alpha-feature

#echo "Setting up pod preset for dynamic file shares..."
#./generate_share_mount_pod_preset.sh | kubectl apply -f -
#echo "Done."
#echo ""

FILES=(
    'configmap.template.yaml'
    'secrets.template.yaml'
)

if [[ "${POD_TYPE:-apache}" = "fpm-nginx" ]]; then
    FILES+=('app-nextcloud-fpm-nginx.template.yaml')
else
    FILES+=('app-nextcloud-apache.template.yaml')
fi

./set_context.sh

# HACK: Until AKS supports pod presets, we have to kludge the dynamic mounts in
# via a variable expansions instead.
source ./generate_backend_share_mount_lines.sh

echo "Deploying Nextcloud core application..."
for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl apply -f -
done
echo "Done."
echo ""

if [[ "${1:-}" == "--cycle-pods" ]]; then
    if [[ "${POD_TYPE:-apache}" = "fpm-nginx" ]]; then
        export POD_SUFFIX="fpm"
    else
        export POD_SUFFIX="apache"
    fi

    export LAST_RESTART=$(date +%s)

    REDEPLOY_PATCH=$(./preprocess_config.sh "configs/redeploy-pods.template.yaml")
    kubectl patch deployment "nextcloud" -p "${REDEPLOY_PATCH}"
fi
