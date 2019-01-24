#!/usr/bin/env bash

##
# This script launches the MySQL interactive shell using credentials from the
# configuration file.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -u
set -e

source './config.env'

mysql \
    --host="${MYSQL_HOST}" \
    --user="${MYSQL_USER}" \
    --password="${MYSQL_PASSWORD}" \
    --database="${MYSQL_DATABASE}"
echo ""
