#!/bin/sh

##
# Custom Nextcloud Docker entrypoint script for Nextcloud cron runs.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2020, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -eu

initialize_container() {
    installed_version="0.0.0.0"

    if [ -f /var/www/html/config/version.php ]; then
        # shellcheck disable=SC2016
        installed_version="$(php -r 'require "/var/www/html/config/version.php"; echo implode(".", $OC_Version);')"
    fi

    # shellcheck disable=SC2016
    image_version="$(php -r 'require "/usr/src/nextcloud/version.php"; echo implode(".", $OC_Version);')"

    ensure_compatible_image "${installed_version}" "${image_version}"
    deploy_nextcloud_release
    setup_redis
}

ensure_compatible_image() {
    local installed_version="${1}"
    local image_version="${2}"

    if [ "$installed_version" != "$image_version" ]; then
        {
            echo "This image of Nextcloud cannot be used because the installed version ($installed_version)"
            echo "does not match the version of this docker image ($image_version)"
        } >&2
        exit 1
    fi
}

setup_redis() {
    if [ "${REDIS_HOST:-}" = "" ]; then
        return
    fi

    REDIS_PORT="${REDIS_PORT:-6379}"

    if [ "${REDIS_KEY:-}" != "" ]; then
        # We have to escape special characters like equals signs and plus signs
        # that Azure customarily includes in auth keys.
        URL_SAFE_REDIS_KEY=$(uri_encode "${REDIS_KEY:-}")

        REDIS_QUERY_STRING="?auth=${URL_SAFE_REDIS_KEY}"
    else
        REDIS_QUERY_STRING=""
    fi

    echo "Configuring Nextcloud to use Redis-based session storage."
    {
        echo 'session.save_handler = redis'
        echo "session.save_path = \"tcp://${REDIS_HOST}:${REDIS_PORT}${REDIS_QUERY_STRING}\""
        echo 'session.lazy_write = 0'
        echo ''

        # Locks are only allowed for up to 60 seconds.
        echo 'redis.session.locking_enabled = 0'
        echo 'redis.session.lock_expire = 60'

        # Wait up to 5 seconds for a lock before giving up.
        # NOTE: lock_wait_time is in usecs, not msecs.
        echo 'redis.session.lock_wait_time = 100000'
        echo 'redis.session.lock_retries = 50'
    } > /usr/local/etc/php/conf.d/redis-sessions.ini
}

deploy_nextcloud_release() {
    echo "Deploying Nextcloud ${image_version}..."

    if [ "$(id -u)" = 0 ]; then
        rsync_options="-rlDog --chown www-data:root"
    else
        rsync_options="-rlD"
    fi

    rsync $rsync_options --delete --exclude-from=/upgrade.exclude /usr/src/nextcloud/ /var/www/html/

    # Copy version.php last, per https://github.com/nextcloud/docker/pull/660
    #
    # NOTE: We have to do this separately since recent images added version.php
    # to the "upgrade.exclude" list. However, we aren't affected by the upstream
    # issue that this workaround was intended for because NC code is not
    # persisted from container to container -- we keep it in an ephemeral,
    # emptyDir volume within each pod, so we always sync version.php at startup.
    #
    rsync $rsync_options --include '/version.php' --exclude '/*' /usr/src/nextcloud/ /var/www/html/

    # Explicitly sync 'custom_apps' in this Docker image
    rsync $rsync_options --delete /usr/src/nextcloud/custom_apps/ /var/www/html/custom_apps/

    echo "Deployment finished."
    echo ""
}

uri_encode() {
  php -r "echo urlencode('${1}');"
}

initialize_container

set -x
su -p www-data -s /var/www/html/occ -- "$@"
