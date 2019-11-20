#!/usr/bin/env bash

##
# This script generates the certificates used by the Helm server.
#
# The CA certificate must be generated with the following command BEFORE running
# this command:
# ```
# ./generate_ca_cert.sh
# ```
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
source "../../functions.sh"

mkdir -p "${OUTPUT_PATH}"

if [[ ! -f "${CA_CERT_PATH}" ]]; then
    echo "CA certificate is missing: ${CA_CERT_PATH}" >&2
    exit 2
fi

if [[ -f "${SERVER_KEY_PATH}" ]]; then
    echo "Server certificate private key already exists: ${SERVER_KEY_PATH}" >&2
    confirmation_prompt "Overwrite"

    if [[ "${confirmed}" -ne 1 ]]; then
        echo "Not overwriting existing file." >&2
        echo "" >&2
        exit 1
    fi
fi

echo "Generating server private key..."
openssl genrsa -out "${SERVER_KEY_PATH}" 4096
echo "Done."
echo ""

echo "Generating server certificate request..."
openssl req \
    -new \
    -sha256 \
    -subj "${SERVER_CERT_SUBJECT}" \
    -key "${SERVER_KEY_PATH}" \
    -out "${SERVER_CSR_PATH}"
echo "Done."
echo ""

echo "Generating server certificate..."
openssl x509 \
    -req \
    -days 365 \
    -CAcreateserial \
    -CA "${CA_CERT_PATH}" \
    -CAkey "${CA_KEY_PATH}" \
    -CAserial "${CA_SERIAL_PATH}" \
    -in "${SERVER_CSR_PATH}" \
    -out "${SERVER_CERT_PATH}"
echo "Done."
echo ""
