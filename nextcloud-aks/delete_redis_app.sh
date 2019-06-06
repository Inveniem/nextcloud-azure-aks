#!/usr/bin/env bash

##
# This script removes Redis and its service from Kubernetes.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

FILES=(
    'app-redis.template.yaml'
)

echo "Un-deploying Redis..."
for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl delete -f -
done
echo "Done."
echo ""
