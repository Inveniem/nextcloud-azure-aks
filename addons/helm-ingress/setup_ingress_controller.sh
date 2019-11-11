#!/usr/bin/env bash

##
# This script deploys an ingress controller on the cluster and assigns it a
# hostname, to make it easier to setup CNAME DNS records.
#
# BEFORE running this script, Helm must be installed on the cluster. You can
# perform this installation via the following command:
# ```
# ./setup_helm.sh
# ```
#
# Known limitation: this script only works with a cluster that has one ingress
# controller. You will need to be more hands-on if you have a cluster with
# multiple ingress controllers.
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

helm install --tls \
    stable/nginx-ingress \
    --namespace "${INGRESS_NAMESPACE}" \
    --set 'controller.replicaCount=2' \
    --set 'controller.service.externalTrafficPolicy=Local' \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set-string controller.config.proxy-body-size="2G"

# Public IP address of your ingress controller
for attempt in {1..20}; do
    echo "Waiting for public IP of ingress controller (attempt ${attempt})..."
    sleep 5

    IP=$(
        kubectl get service \
            --namespace "${INGRESS_NAMESPACE}" \
            --selector 'app=nginx-ingress' \
            -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}'
    )

    if [[ ! -z "${IP:-}" ]]; then
        break
    fi
done

IP_ADDRESSES=( ${IP:-} )
IP_COUNT="${#IP_ADDRESSES[@]}"

if [[ "${IP_COUNT}" -eq 0 ]]; then
    {
        echo ""
        echo "ERROR: Failed to get IP of ingress controller."
        echo ""
        echo "Cannot proceed."
    } >&2
    exit 1
fi

if [[ "${IP_COUNT}" -gt 1 ]]; then
    {
        echo ""
        echo "ERROR: Got more than one ingress controller IP:"
        echo "  ${IP_ADDRESSES[@]}"
        echo ""
        echo "Cannot proceed (known limitation)."
    } >&2

    exit 2
fi

# Get the resource-id of the public ip
PUBLIC_IP_ID=$(\
    az network public-ip list \
        --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" \
        --output tsv
)

 Update public ip address with DNS name
az network public-ip update \
    --ids "${PUBLIC_IP_ID}" \
    --dns-name "${INGRESS_DNS_NAME}"
