#!/usr/bin/env bash

##
# This script is used to setup AKS with credentials to an Azure AD service
# principal that has access to the ACR repo where images are stored.
#
# This script only needs to be run once per AKS context. The name of each
# ACR service principal must be unique within an AD tenant.
#
# This script is based on:
# https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-aci
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

./set_context.sh

# Obtain the full registry ID for subsequent command args
ACR_REGISTRY_ID=$(az acr show --name "${REGISTRY_NAME}" --query id --output tsv)

echo "Creating Azure AD service principal for ACR access..."
# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
SP_PASSWD=$(
    az ad sp create-for-rbac \
        --name "http://${REGISTRY_SERVICE_PRINCIPLE_NAME}" \
        --scopes "${ACR_REGISTRY_ID}" \
        --role acrpull \
        --query password \
        --output tsv
)

SP_APP_ID=$(
    az ad sp show \
        --id "http://${REGISTRY_SERVICE_PRINCIPLE_NAME}" \
        --query appId \
        --output tsv
)
echo "Done."
echo ""

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $SP_APP_ID"
echo "Service principal password: $SP_PASSWD"
echo ""

export DOCKER_USER="${SP_APP_ID}"
export DOCKER_PASSWORD="${SP_PASSWD}"

# See https://github.com/MicrosoftDocs/azure-docs/issues/12925
export DOCKER_EMAIL="placeholder@example.com"

echo "Creating Docker Registry Secret for '${REGISTRY_SERVICE_PRINCIPLE_NAME}' as '${ACR_DOCKER_CREDS_SECRET}'..."
kubectl create secret docker-registry \
    "${ACR_DOCKER_CREDS_SECRET}" \
    --docker-server="${REGISTRY_HOST}" \
    --docker-username="${DOCKER_USER}" \
    --docker-password="${DOCKER_PASSWORD}" \
    --docker-email="${DOCKER_EMAIL}"
echo "Done."
echo ""
