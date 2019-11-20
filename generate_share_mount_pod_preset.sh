#!/usr/bin/env bash

##
# This script dynamically generates a Kubernetes configuration that defines a
# a pod preset containing mounts for every file share defined in the
# configuration.
#
# This frees users from having to edit shares directly in
# `app-nextcloud-apache.template.yaml` or `app-nextcloud-fpm-nginx.template.yaml`.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

cat <<EOF
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: has-nextcloud-data-shares
spec:
  selector:
    matchLabels:
      role: nextcloud-backend
  volumeMounts:
EOF

for file_share_name in "${STORAGE_FILE_SHARES[@]}"; do
    if [[ "${file_share_name}" = "nextcloud-data" ]]; then
        mount_path="/var/www/html/data"
    else
        mount_path="/mnt/share/${file_share_name}"
    fi

    cat <<EOF
    - mountPath: "${mount_path}"
      name: "volume-nextcloud-${file_share_name}"
EOF
done

cat <<EOF
  volumes:
EOF

for file_share_name in "${STORAGE_FILE_SHARES[@]}"; do
    cat <<EOF
    - name: "volume-nextcloud-${file_share_name}"
      persistentVolumeClaim:
        claimName: "claim-nextcloud-${file_share_name}"
EOF
done

echo ""
