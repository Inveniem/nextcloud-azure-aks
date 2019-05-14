#!/usr/bin/env bash

##
# This script deploys an ingress routing configuration for Nextcloud.
#
# BEFORE running this script, Helm, a "Let's Encrypt" certificate manager, and
# an ingress controller must already be configured, with the following commands:
# ```
# ./setup_helm.sh
# ./setup_cert_manager.sh
# ./deploy_certmanager_issuer.sh
# ./setup_ingress_controller.sh
# ```
#
# Commands based on:
# https://docs.microsoft.com/en-us/azure/aks/ingress-tls
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source "constants.env"
source "config.env"

../../preprocess_config.sh "${KUBE_CONFIG_PATH}/ingress-nextcloud.template.yaml" |
    kubectl apply -f -
