#!/usr/bin/env bash

##
# This script generates a certificate authority for use issuing Helm client and
# server certificates.
#
# You should only run this script ONCE. The certificate and private key are
# generated to last 7300 days (20 years), so you should not need to generate it
# again. Once you have configured Helm with this CA trusted, it is crucial that
# you backup the certificate and key so that you can continue issuing
# certificates in the future.
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
source "functions.sh"

mkdir -p "${OUTPUT_PATH}"

if [[ -f "${CA_KEY_PATH}" ]]; then
    echo "CA certificate private key already exists: ${CA_KEY_PATH}"
    confirmation_prompt "Overwrite"

    if [[ "${confirmed}" -ne 1 ]]; then
        echo "Not overwriting existing file."
        echo ""
        exit 1
    fi
fi

echo "Generating CA private key..."
openssl genrsa -out "${CA_KEY_PATH}" 4096
echo "Done."
echo ""

echo "Generating CA certificate..."
openssl req \
    -new \
    -x509 \
    -sha256 \
    -days 7300 \
    -extensions v3_ca \
    -subj "${CA_CERT_SUBJECT}" \
    -key "${CA_KEY_PATH}" \
    -out "${CA_CERT_PATH}"
echo "Done."
echo ""
