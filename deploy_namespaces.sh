#!/usr/bin/env bash

##
# This optional script sets up namespaces for maintaining separate Nextcloud
# environments.
#
# Once created, see this article for how to setup your local Kubernetes client
# so you can switch between them:
#
# https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/#create-pods-in-each-namespace
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

FILES=(
    'namespace-nextcloud-dev.yaml'
    'namespace-nextcloud-live.yaml'
)

./set_context.sh

echo "Deploying Nextcloud namespaces..."
for file in "${FILES[@]}"; do
    kubectl apply -f "configs/${file}"
done
echo "Done."
echo ""
