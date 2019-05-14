#!/usr/bin/env bash

##
# This script removes secrets for the Nextcloud storage account from Kubernetes,
# then deletes the storage account (pending user confirmation).
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

echo "Removing Azure Files Kubernetes Secret for '${KUBE_FILES_STORAGE_ACCOUNT_SECRET}'..."
kubectl delete secret "${KUBE_FILES_STORAGE_ACCOUNT_SECRET}"
echo "Done."
echo ""

echo "Removing Storage Account '${STORAGE_ACCOUNT_NAME}'..."
echo ""
echo "WARNING: This will delete ALL files Nextcloud has stored on Azure."
az storage account delete \
    --name "${STORAGE_ACCOUNT_NAME}" \
    --resource-group "${STORAGE_RESOURCE_GROUP}" \
    && echo "Done." || echo "Skipped."
echo ""
