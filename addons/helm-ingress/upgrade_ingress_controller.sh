#!/usr/bin/env bash

##
# This script upgrades an existing ingress controller on the cluster to the
# latest configuration supported by this resource kit.
#
# This command is idempotent. If the Helm release is already up-to-date, nothing
# gets done. There is little harm in running this command multiple times.
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

read -p "Name of existing 'nginx-ingress' chart: " CHART_NAME

if [[ -z "${CHART_NAME:-}" ]]; then
    exit 1
fi

backup_old_release() {
    local backup_timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
    local backup_filename="backups/nginx-ingress.chart-backup.${backup_timestamp}.log"

    mkdir -p backups

    helm get --tls "${CHART_NAME}" > "${backup_filename}"
    echo "Previous release and chart info from BEFORE upgrade was saved to: "
    echo "${backup_filename}"
    echo ""
}

print_old_release_values() {
    echo "Release values BEFORE upgrade:"
    helm get values --tls "${CHART_NAME}"
    echo ""
}

update_local_helm_chart() {
    helm repo update

    echo "Target chart for upgrade:"
    helm inspect chart stable/nginx-ingress
    echo ""
}

upgrade_remote_release() {
    helm upgrade --tls \
        "${CHART_NAME}" stable/nginx-ingress \
        --namespace "${INGRESS_NAMESPACE}" \
        --set 'controller.replicaCount=2' \
        --set 'controller.service.externalTrafficPolicy=Local' \
        --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
        --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
        --set-string controller.config.proxy-body-size="2G"
}

print_new_release_values() {
    echo ""
    echo "Release values AFTER upgrade:"
    helm get values --tls "${CHART_NAME}"
    echo ""
}

backup_old_release
print_old_release_values
update_local_helm_chart
upgrade_remote_release
print_new_release_values
