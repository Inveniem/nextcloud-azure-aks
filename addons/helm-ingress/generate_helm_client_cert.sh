#!/usr/bin/env bash

##
# This script generates the certificates used by the Helm client.
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

if [[ -f "${CLIENT_KEY_PATH}" ]]; then
    echo "Client certificate private key already exists: ${CLIENT_KEY_PATH}" >&2
    confirmation_prompt "Overwrite"

    if [[ "${confirmed}" -ne 1 ]]; then
        echo "Not overwriting existing file." >&2
        echo "" >&2
        exit 1
    fi
fi

echo "Generating client private key..."
openssl genrsa -out "${CLIENT_KEY_PATH}" 4096
echo "Done."
echo ""

echo "Generating client certificate request..."
openssl req \
    -new \
    -sha256 \
    -subj "${CLIENT_CERT_SUBJECT}" \
    -key "${CLIENT_KEY_PATH}" \
    -out "${CLIENT_CSR_PATH}"
echo "Done."
echo ""

echo "Generating client certificate..."
openssl x509 \
    -req \
    -days 365 \
    -CAcreateserial \
    -CA "${CA_CERT_PATH}" \
    -CAkey "${CA_KEY_PATH}" \
    -CAserial "${CA_SERIAL_PATH}" \
    -in "${CLIENT_CSR_PATH}" \
    -out "${CLIENT_CERT_PATH}"
echo "Done."
echo ""
