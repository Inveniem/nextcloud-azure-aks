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

echo "Deleting resource group '${STORAGE_RESOURCE_GROUP}'..."
az group delete --name "${STORAGE_RESOURCE_GROUP}" --yes
echo ""

echo "Removing BlobFUSE Kubernetes Secret for '${KUBE_STORAGE_ACCOUNT_SECRET}'..."
kubectl delete secret "${KUBE_STORAGE_ACCOUNT_SECRET}"
