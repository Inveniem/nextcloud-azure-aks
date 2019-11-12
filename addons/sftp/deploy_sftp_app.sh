#!/usr/bin/env bash

##
# This script deploys the SFTP application and its load balancer to Kubernetes.
#
# NOTE: You MUST run `./setup_host_keys.sh` BEFORE running this script.
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

../../set_context.sh

# HACK: Until AKS supports pod presets, we have to kludge the dynamic mounts in
# via a variable expansions instead.
source ./generate_share_mount_lines.sh

echo "Deploying SFTP application..."
for file in "${FILES[@]}"; do
    ../../preprocess_config.sh "configs/${file}" | kubectl apply -f -
done
echo "Done."
echo ""
