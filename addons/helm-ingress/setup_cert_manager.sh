#!/usr/bin/env bash

##
# This script deploys the Kubernetes certificate manager extensions to the
# cluster.
#
# BEFORE running this script, Helm must be installed on the cluster. You can
# perform this installation via the following command:
# ```
# ./setup_helm.sh
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

../../set_context.sh

kubectl label namespace \
    "${CERTMANAGER_NAMESPACE}" \
    --overwrite \
    'certmanager.k8s.io/disable-validation=true'

kubectl apply \
    -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install jetstack/cert-manager \
    --tls \
    --namespace "${CERTMANAGER_NAMESPACE}" \
    --set ingressShim.defaultIssuerName=letsencrypt-prod \
    --set ingressShim.defaultIssuerKind=ClusterIssuer \
    --version v0.8.1
