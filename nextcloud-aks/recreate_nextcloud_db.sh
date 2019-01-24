#!/usr/bin/env bash

##
# This script drops and recreates the Nextcloud database, so that it's empty and
# ready for a reinstall.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -u
set -e

source './config.env'

echo "Dropping existing database '${MYSQL_DATABASE}' (if it exists)..."
mysql \
    --host="${MYSQL_HOST}" \
    --user="${MYSQL_USER}" \
    --password="${MYSQL_PASSWORD}" \
    --execute="DROP DATABASE IF EXISTS ${MYSQL_DATABASE}" \
    --verbose
echo ""

echo "Re-creating database '${MYSQL_DATABASE}'..."
mysql \
    --host="${MYSQL_HOST}" \
    --user="${MYSQL_USER}" \
    --password="${MYSQL_PASSWORD}" \
    --execute="CREATE DATABASE ${MYSQL_DATABASE}" \
    --verbose
echo ""
