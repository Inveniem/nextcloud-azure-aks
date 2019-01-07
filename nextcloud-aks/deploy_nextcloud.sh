#!/usr/bin/env bash

##
# This is a top-level script to deploy Nextcloud and its storage dependencies to
# Azure and AKS.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

./setup_blob_storage.sh

FILES=(
    'configmap.yaml'
    'secrets.yaml'
    'persistence-volumes.yaml'
    'persistence-claims.yaml'
)

if [[ "${POD_TYPE:-apache}" = "php-fpm" ]]; then
    FILES+=('nextcloud-fpm-nginx.yaml')
else
    FILES+=('nextcloud-apache.yaml')
fi

for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl apply -f -
done
