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
source './functions.sh'

./set_context.sh

if [[ "${DELETE_PROMPT:-1}" -eq 1 ]]; then
    {
        echo "This will attempt to REMOVE the Azure storage account that this"
        echo "instance of Nextcloud uses to store ALL FILES."
        echo ""
        echo "THIS WILL RESULT IN DATA LOSS."
        echo ""
    } >&2

    confirmation_prompt "Are you sure"
else
    confirmed=1
fi

if [[ "${confirmed}" -eq 1 ]]; then
    echo "Removing Azure Files Kubernetes Secret for '${KUBE_FILES_STORAGE_ACCOUNT_SECRET}'..."
    kubectl delete secret "${KUBE_FILES_STORAGE_ACCOUNT_SECRET}" \
        || echo "Already deleted."
    echo "Done."
    echo ""

    echo "Removing Storage Account '${STORAGE_ACCOUNT_NAME}'..."
    az storage account delete \
        --name "${STORAGE_ACCOUNT_NAME}" \
        --resource-group "${STORAGE_RESOURCE_GROUP}" \
        --yes \
        && echo "Done." || echo "Skipped."
    echo ""
fi
