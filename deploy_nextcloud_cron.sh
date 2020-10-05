#!/usr/bin/env bash

##
# This script deploys Cron jobs for the Nextcloud application to Kubernetes.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2020, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

FILES=('cronjob-nextcloud-file-scan.yaml')

./set_context.sh

source ./generate_cronjob_share_mount_lines.sh

echo "Deploying Nextcloud cron job..."
for file in "${FILES[@]}"; do
    ./preprocess_config.sh "configs/${file}" | kubectl apply -f -
done
echo "Done."
echo ""
