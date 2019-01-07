#!/usr/bin/env bash

##
# This script removes persistent volumes and persistent volume claims from
# Kubernetes.
#
# This does not necessarily remove the underlying storage, especially storage
# that was not deployed via Kubernetes Dynamic Volumes. File storage provisioned
# elsewhere on Azure typically has to be removed with other scripts, such as
# `delete_blob_storage.sh`.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

FILES=(
    'persistence-volumes.yaml'
    'persistence-claims.yaml'
)

for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl delete -f -
done
