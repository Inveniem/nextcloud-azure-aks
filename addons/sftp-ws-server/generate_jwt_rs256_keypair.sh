#!/usr/bin/env bash

PRIVATE_KEY_DEST="jwt_private.pem"
PUBLIC_KEY_DEST="jwt_public.pem"

echo "Writing private RS256 key out to '${PRIVATE_KEY_DEST}'"
openssl genrsa -out "${PRIVATE_KEY_DEST}" 4096

echo "Writing public RS256 key out to '${PUBLIC_KEY_DEST}'"
openssl rsa -in "${PRIVATE_KEY_DEST}" -pubout -out "${PUBLIC_KEY_DEST}"