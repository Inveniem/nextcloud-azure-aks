#!/usr/bin/env bash

##
# This script creates an Azure Storage account for use with Nextcloud deployed
# on AKS.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -u
set -e

source './config.env'

./set_context.sh

echo "Creating resource group '${STORAGE_RESOURCE_GROUP}'..."
az group create \
    --name "${STORAGE_RESOURCE_GROUP}" \
    --location "${LOCATION}"
echo "Done."
echo ""

echo "Creating '${STORAGE_SKU}' storage account '${STORAGE_ACCOUNT_NAME}'..."
az storage account create \
    --resource-group "${STORAGE_RESOURCE_GROUP}" \
    --name "${STORAGE_ACCOUNT_NAME}" \
    --kind "${STORAGE_KIND}" \
    --sku "${STORAGE_SKU}" \
    --location "${LOCATION}"
echo "Done."
echo ""

export AZURE_STORAGE_CONNECTION_STRING=$( \
    az storage account show-connection-string \
        --name "${STORAGE_ACCOUNT_NAME}" \
        --query "connectionString" \
        --output=tsv
)

echo "Creating file shares..."
for file_share_name in "${STORAGE_FILE_SHARES[@]}"; do
    echo "- '${file_share_name}'."
    az storage share create --name "${file_share_name}"
done
echo "Done."
echo ""

export STORAGE_ACCOUNT_KEY=$( \
    az storage account keys list \
        --account-name "${STORAGE_ACCOUNT_NAME}" \
        --query "[0].value" \
        --output=tsv
)

echo "Creating Azure Files Kubernetes Secret for '${KUBE_FILES_STORAGE_ACCOUNT_SECRET}'..."
./preprocess_config.sh "configs/secret-azure-storage-account.yaml" | \
    kubectl apply -f -
echo "Done."
echo ""
