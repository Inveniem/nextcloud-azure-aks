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

# Sadly, PHP Redis is not compatible with TLS/SSL on the Redis connection
echo "Creating Redis Cache '${REDIS_CACHE_NAME}'..."
az redis create \
    --name "${REDIS_CACHE_NAME}" \
    --location "${LOCATION}" \
    --resource-group "${REDIS_RESOURCE_GROUP}" \
    --sku "${REDIS_SKU}" \
    --vm-size "${REDIS_SIZE}" \
    --enable-non-ssl-port
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
# Unfortunately, the PHP Redis extension does not support TLS/SSL for Redis
# connections, yet. So, we have to use the non-SSL port.
#
REDIS_PORT="6379"

echo "Creating Redis Key Secret for '${KUBE_REDIS_KEY_SECRET}'..."
kubectl create secret generic "${KUBE_REDIS_KEY_SECRET}" \
    --from-literal hostname="${REDIS_HOST}" \
    --from-literal port="${REDIS_PORT}" \
    --from-literal key="${REDIS_ACCESS_KEY}"
echo "Done."
echo ""
