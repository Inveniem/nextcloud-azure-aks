#!/usr/bin/env bash

##
# This script removes Azure-Blob-storage-backed Nextcloud persisted volume
# claims and persisted volumes from Kubernetes.
#
# This does not remove file shares provisioned on Azure files.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

FILES=(
    'blob-volumes.yaml'
    'blob-claims.yaml'
)

echo "Removing Nextcloud persisted volumes for Azure Blob Storage..."
for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl delete -f -
done
