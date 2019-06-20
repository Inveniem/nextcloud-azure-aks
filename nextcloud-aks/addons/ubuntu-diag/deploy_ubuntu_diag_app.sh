#!/usr/bin/env bash

##
# This script deploys the Ubuntu diagnostic application to Kubernetes.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source '../../config.env'

echo "Deploying Ubuntu diagnostic application..."
kubectl apply -f "configs/app-ubuntu-diag.yaml"
echo "Done."
echo ""
