#!/usr/bin/env bash

##
# This script removes the SFTP application and its load balancer from
# Kubernetes.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

FILES+=(
    'app-sftp.template.yaml'
)

# HACK: Until AKS supports pod presets, we have to kludge the dynamic mounts in
# via a variable expansions.
source ./generate_share_mount_lines.sh

echo "Un-deploying SFTP application..."
for file in "${FILES[@]}"; do
    ../../preprocess_config.sh "configs/${file}" | kubectl delete -f -
done
echo "Done."
echo ""
