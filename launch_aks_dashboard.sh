#!/usr/bin/env bash

##
# This script launches a tunnel from localhost port 8090 to the AKS Kubernetes
# Dashboard.
#
# This script enhances the `az aks browse` command by automatically relaunching
# the tunnel if it dies (typically due to the tunnel being left idle).
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

source './config.env'

# Loop to restore tunnel if it dies due to inactivity
while true; do
    PREVIOUS_CONTEXT=$(kubectl config current-context)

    # NOTE: This changes to the "default" Kube context
    az aks get-credentials \
        --resource-group "${KUBE_RESOURCE_GROUP}" \
        --name "${KUBE_NAME}" \

    # Restore context
    kubectl config use-context "${PREVIOUS_CONTEXT}"

    echo "Open http://localhost:8090 in your browser to connect to the Kubernetes dashboard."
    az aks browse \
        --resource-group "${KUBE_RESOURCE_GROUP}" \
        --name "${KUBE_NAME}" \
        --listen-port=8090 \
        --disable-browser

    # Restore context
    kubectl config use-context "${PREVIOUS_CONTEXT}"

    echo "Relaunching tunnel in 2 seconds (CTRL+C to cancel)..."
    sleep 2
done
