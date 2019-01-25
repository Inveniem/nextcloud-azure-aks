#!/usr/bin/env bash

##
# This script removes secrets for the Nextcloud Redis cache from Kubernetes,
# then deletes the Redis cache (pending user confirmation).
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -u
set -e

source './config.env'

echo "Removing Redis Connection Secret for '${KUBE_REDIS_KEY_SECRET}'..."
kubectl delete secret "${KUBE_REDIS_KEY_SECRET}"
echo "Done."
echo ""

echo "Removing Redis Cache '${STORAGE_ACCOUNT_NAME}'..."
echo ""
az redis delete \
    --name "${REDIS_CACHE_NAME}" \
    --resource-group "${REDIS_RESOURCE_GROUP}" \
    && echo "Done." || echo "Skipped."
echo "Done."
echo ""
