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
source './functions.sh'

if [[ "${DELETE_PROMPT:-1}" -eq 1 ]]; then
    {
        echo "This will attempt to remove the Nextcloud database, which will"
        echo "result in the loss of Nextcloud configuration information, user"
        echo "information, audit logs, etc."
        echo ""
    } >&2

    confirmation_prompt "Are you sure"
else
    confirmed=1
fi

if [[ "${confirmed}" -eq 1 ]]; then
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
fi
