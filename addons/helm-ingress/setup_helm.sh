#!/usr/bin/env bash

##
# This script deploys Helm to the cluster, using TLS to authenticate clients.
#
# The CA certificate; server certificate; and client certificate and key are
# copied into the Helm home folder for the current user, so that Helm commands
# do not always have to provide certificate information.
#
# Regardless, Helm commands still must be suffixed with the `--tls` option to
# prevent this error from appearing:
# ```
# Error: transport is closing
# ```
#
# SSL certificates must be generated with the following two commands BEFORE
# running this command:
# - ./generate_ca_cert.sh
# - ./generate_helm_client_cert.sh
# - ./generate_tiller_server_cert.sh
#
# Commands based on:
# https://helm.sh/docs/using_helm/#using-ssl-between-helm-and-tiller
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

if [[ ! -f "${CA_CERT_PATH}" ]]; then
    echo "CA certificate is missing: ${CA_CERT_PATH}" >&2
    exit 2
fi

if [[ ! -f "${SERVER_CERT_PATH}" ]]; then
    echo "Tiller server certificate is missing: ${SERVER_CERT_PATH}" >&2
    exit 2
fi

if [[ ! -f "${SERVER_KEY_PATH}" ]]; then
    echo "Tiller server certificate key is missing: ${SERVER_KEY_PATH}" >&2
    exit 2
fi

if [[ ! -f "${CLIENT_CERT_PATH}" ]]; then
    echo "Helm client certificate is missing: ${CLIENT_CERT_PATH}" >&2
    exit 2
fi

if [[ ! -f "${CLIENT_KEY_PATH}" ]]; then
    echo "Helm client certificate key is missing: ${CLIENT_KEY_PATH}" >&2
    exit 2
fi

kubectl apply -f "${KUBE_CONFIG_PATH}/helm-rbac.yaml"

helm init \
    --service-account=tiller \
    --tiller-tls \
    --tiller-tls-verify \
    --tiller-tls-cert "${SERVER_CERT_PATH}" \
    --tiller-tls-key "${SERVER_KEY_PATH}" \
    --tls-ca-cert "${CA_CERT_PATH}"

# Translates paths from C:\ to /mnt/c for compatibility with WLS
HELM_HOME=$(
    helm home | \
    sed 's!\\!/!g' | \
    sed 's!C:/!/mnt/c/!g'
)

cp "${CA_CERT_PATH}" "${HELM_HOME}/ca.pem"
cp "${CLIENT_CERT_PATH}" "${HELM_HOME}/cert.pem"
cp "${CLIENT_KEY_PATH}" "${HELM_HOME}/key.pem"
