#!/usr/bin/env bash

##
# This script generates SSH host keys for the SFTP container.
#
# This ensures users do not get a security error upon connecting over SFTP after
# containers have cycled.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

mkdir -p ./host_keys/
ssh-keygen -t ed25519 -f ./host_keys/ssh_host_ed25519_key -N ''
ssh-keygen -t rsa -b 4096 -f ./host_keys/ssh_host_rsa_key -N ''
