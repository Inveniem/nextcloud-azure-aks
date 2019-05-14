#!/usr/bin/env bash

##
# This script deploys the certificate manager issuer to the cluster.
#
# BEFORE running this script, Helm and the "Let's Encrypt" certificate manager
# extensions must already be configured, with the following commands:
# ```
# ./setup_helm.sh
# ./setup_cert_manager.sh
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

../../preprocess_config.sh "${KUBE_CONFIG_PATH}/certmanager-issuer.template.yaml" | \
    kubectl apply -f -
