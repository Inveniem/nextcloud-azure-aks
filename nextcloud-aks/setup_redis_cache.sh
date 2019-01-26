#!/usr/bin/env bash

##
# This script creates an Azure Redis Cache for use by a Nextcloud cluster.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -u
set -e

source './config.env'

echo "Creating Redis Cache '${REDIS_CACHE_NAME}'..."
az redis create \
    --name "${REDIS_CACHE_NAME}" \
    --location "${LOCATION}" \
    --resource-group "${REDIS_RESOURCE_GROUP}" \
    --sku "${REDIS_SKU}" \
    --vm-size "${REDIS_SIZE}"
echo "Done."
echo ""

REDIS_ACCESS_KEY=$(
    az redis list-keys \
        --name "${REDIS_CACHE_NAME}" \
        --resource-group "${REDIS_RESOURCE_GROUP}" \
        --query "primaryKey" \
        --output=tsv
)

REDIS_HOST="${REDIS_CACHE_NAME}.redis.cache.windows.net"

# This appears to be hard-coded on the Microsoft side.
#
# Note that it *cannot* be specified when creating the cache:
# https://docs.microsoft.com/en-us/cli/azure/redis?view=azure-cli-latest#required-parameters
#
# Since Azure supports TLS/SSL but Redis clients don't typically do, "stunnel"
# is used to locally proxy (insecure) port 6379 to the secure remote port
# specified below.
#
REDIS_PORT="6380"

echo "Creating Redis Key Secret for '${KUBE_REDIS_KEY_SECRET}'..."
kubectl create secret generic "${KUBE_REDIS_KEY_SECRET}" \
    --from-literal hostname="${REDIS_HOST}" \
    --from-literal port="${REDIS_PORT}" \
    --from-literal key="${REDIS_ACCESS_KEY}"
echo "Done."
echo ""
