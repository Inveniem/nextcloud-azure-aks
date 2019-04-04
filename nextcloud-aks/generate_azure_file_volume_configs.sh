#!/usr/bin/env bash

##
# This script dynamically generates a Kubernetes configuration that defines a
# persistent volume claim and persistent volume for every file share defined in
# the configuration.
#
# The configuration is written to standard out.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

for file_share_name in "${STORAGE_FILE_SHARES[@]}"; do
    export file_share_name

    # We use `grep -o` to skip Bash comment lines
    ./preprocess_config.sh './configs/vol-file-share.template.yaml' | \
        grep -o '^[^#]*'
done
