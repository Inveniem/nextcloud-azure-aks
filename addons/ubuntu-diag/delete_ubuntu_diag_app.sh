#!/usr/bin/env bash

##
# This script removes the Ubuntu diagnostic application from Kubernetes.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

../../set_context.sh

echo "Un-deploying SFTP application..."
kubectl delete -f "configs/app-ubuntu-diag.yaml"
echo "Done."
echo ""
