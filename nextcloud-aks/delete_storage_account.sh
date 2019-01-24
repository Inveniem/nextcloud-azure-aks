#!/usr/bin/env bash

##
# This script first removes the resource group that's created to hold the
# storage account for Nextcloud, and then purges the secret for that account
# from Kubernetes.
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

echo "Removing BlobFUSE Kubernetes Secret for '${KUBE_BLOB_STORAGE_ACCOUNT_SECRET}'..."
kubectl delete secret "${KUBE_BLOB_STORAGE_ACCOUNT_SECRET}"
echo "Done."
echo ""

echo "Deleting resource group '${STORAGE_RESOURCE_GROUP}'..."
echo ""
echo "WARNING: This will delete ALL files Nextcloud has stored on Azure."
az group delete --name "${STORAGE_RESOURCE_GROUP}" && echo "Done." || echo "Skipped."
echo ""
