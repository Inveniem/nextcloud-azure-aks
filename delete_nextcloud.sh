#!/usr/bin/env bash

##
# This is a top-level script to remove all traces of Nextcloud from Azure and
# Kubernetes, after they were deployed by other scripts within this repository.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

source "./functions.sh"

{
    echo "This will attempt to remove Nextcloud from your infrastructure, "
    echo "resulting in data loss."
    echo ""
} >&2

confirmation_prompt "Are you sure"

if [[ "${confirmed}" -eq 1 ]]; then
    export DELETE_PROMPT=0

    ./delete_nextcloud_app.sh
    ./delete_nextcloud_volumes.sh
    ./delete_storage_account.sh
    ./delete_redis_app.sh
    ./delete_clamav.sh
    ./recreate_nextcloud_db.sh

    {
        echo "NOTE: Namespaces are intentionally NOT deleted during this"
        echo "process. This is because the namespace list includes"
        echo "'nextcloud-live', which you likely do not want to lose if you are"
        echo "running this command for a different environment."
        echo ""
        echo "If you really want to destroy all Nextcloud Kubernetes"
        echo "namespaces, run:"
        echo "./delete_namespaces.sh."
        echo ""
    } >&2
fi
