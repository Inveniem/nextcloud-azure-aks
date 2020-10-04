#!/usr/bin/env bash

##
# This script dynamically generates the portions of a Kubernetes container
# configuration that specify mounts for every file share defined in the
# configuration.
#
# - The `volumeMount` lines are exported in `FILE_SHARE_VOLUME_MOUNT_LINES`.
# - The `volume` lines are exported in `FILE_SHARE_VOLUME_LINES`.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019-2020, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source './config.env'

generate_volume_mount_lines() {
    # Ensure we end the comment on the prior line of the YAML file.
    echo ""

    for file_share_name in "${STORAGE_FILE_SHARES[@]}"; do
        if [[ "${file_share_name}" = "nextcloud-data" ]]; then
            mount_path="/var/www/html/data"
            read_only="false"
        elif [[ "${file_share_name}" = "nextcloud-config" ]]; then
            mount_path="/var/www/html/config"
            read_only="${NEXTCLOUD_CONFIG_READ_ONLY}"
        else
            mount_path="/mnt/share/${file_share_name}"
            read_only="false"
        fi

        cat <<EOF
              - mountPath: "${mount_path}"
                name: "volume-nextcloud-${file_share_name}"
                readOnly: ${read_only}
EOF
    done
}

generate_volume_lines() {
    # Ensure we end the comment on the prior line of the YAML file.
    echo ""

    for file_share_name in "${STORAGE_FILE_SHARES[@]}"; do
        cat <<EOF
            - name: "volume-nextcloud-${file_share_name}"
              persistentVolumeClaim:
                claimName: "claim-nextcloud-${file_share_name}"
EOF
    done
}

export FILE_SHARE_VOLUME_MOUNT_LINES=$(generate_volume_mount_lines)
export FILE_SHARE_VOLUME_LINES=$(generate_volume_lines)
