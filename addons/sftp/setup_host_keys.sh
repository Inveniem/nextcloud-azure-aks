#!/usr/bin/env bash

##
# This script generates SSH host keys for the SFTP container, then saves them
# to a Kubernetes secret.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

../../set_context.sh

./generate_host_keys.sh

kubectl create secret generic "${KUBE_SFTP_CREDS_SECRET}" \
    --from-file=./host_keys/ssh_host_ed25519_key \
    --from-file=./host_keys/ssh_host_rsa_key
