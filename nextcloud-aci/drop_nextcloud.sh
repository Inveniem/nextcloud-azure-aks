#!/usr/bin/env bash

##
# This script drops the Azure container instance, resource group, and database
# that are created for Nextcloud by `create_nextcloud.sh`.
#
# See README.md for more details.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -u
set -e

source 'config.env'

EXISTING_GROUP=$(az group list --query "[?name=='${RESOURCE_GROUP}']")

if [[ "${EXISTING_GROUP}" != '[]' ]]; then
    echo "Deleting existing resource group '${RESOURCE_GROUP}'..."
    az group delete --name "${RESOURCE_GROUP}"
    echo ""
fi

echo "Dropping existing database '${MYSQL_DATABASE}' (if it exists)..."
mysql \
    --host="${MYSQL_HOST}" \
    --user="${MYSQL_USER}" \
    --password="${MYSQL_PASSWORD}" \
    --database="${MYSQL_DATABASE}" \
    --execute="DROP DATABASE IF EXISTS ${MYSQL_DATABASE}; CREATE DATABASE ${MYSQL_DATABASE}"
echo ""
