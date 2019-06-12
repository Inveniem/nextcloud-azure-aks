#!/bin/sh

##
# Custom Nextcloud Docker entrypoint script that does not store the Nextcloud
# distribution (located at /var/www/html) on persistent storage.
#
# Instead, `version.php` is the only file from the distribution that is
# persisted. It gets saved to `/var/www/html/config/version.php` so that the
# startup version check functions as required.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -eu

initialize_container() {
    local container_type="${1}"

    if expr "${container_type}" : "apache" 1>/dev/null \
        || [ "${container_type}" = "php-fpm" ] \
        || [ "${NEXTCLOUD_UPDATE:-0}" -eq 1 ]; then
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

        if version_greater "$image_version" "$installed_version"; then
            capture_existing_app_list "$installed_version"
            populate_instance_dirs

            if [ "$installed_version" = "0.0.0.0" ]; then
                install_nextcloud "${image_version}"
            else
                upgrade_nextcloud "${installed_version}" "${image_version}"
            fi

            capture_instance_state
        fi

        update_htaccess
    fi
}

ensure_compatible_image() {
    local installed_version="${1}"
    local image_version="${2}"

    if version_greater "$installed_version" "$image_version"; then
        echo "This image of Nextcloud cannot be used because the data was last used with version ($installed_version)," >&2
        echo "which is higher than the docker image version ($image_version) and downgrading is not supported." >&2
        echo "Are you sure you have pulled the newest image version?" >&2
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
        echo ''
        echo 'redis.session.locking_enabled = 1'
        echo 'redis.session.lock_wait_time = 25000'
        echo 'redis.session.lock_retries = 4000'
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

    if [ -w "/var/www/html/config" ]; then
        echo "'config' directory is writable."
        echo "Sync-ing configuration snippets:"
        cp -v /usr/src/nextcloud/config/*.config.php /var/www/html/config/
        echo ""
    else
        echo "'config' directory is not writable."
        echo "Configuration snippets will not be synced."
        echo ""
    fi

    echo "Deployment finished."
    echo ""
}

capture_existing_app_list() {
    local installed_version="${1}"

    if [ "$installed_version" != "0.0.0.0" ]; then
        run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
    fi
}

populate_instance_dirs() {
    for dir in config data themes; do
        if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
            rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
        fi
    done
}

capture_instance_state() {
    # Capture the only file needed from a distribution to properly spin up a
    # new instance and/or upgrade an existing one
    cp /usr/src/nextcloud/version.php /var/www/html/config/version.php
}

install_nextcloud() {
    local image_version="${1}"

    echo "This is a new installation of Nextcloud."
    echo ""

    # NOTE: This populates `install_type` and `install_options`
    if capture_install_options; then
        echo "Installing Nextcloud using settings provided by container environment..."
        echo ""

        echo "Database type: ${install_type}"
        echo ""

        max_retries=10
        try=0

        set +e

        until run_installer "${install_options}" || [ "$try" -gt "$max_retries" ]; do
            echo "Retrying installation..."
            try=$((try+1))
            sleep 3s
        done

        set -e

        if [ "$try" -gt "$max_retries" ]; then
            echo "Installation of nextcloud has failed!"
            exit 1
        fi

        configure_trusted_domains

        echo "Installation finished."
    else
        echo "Run the web-based installer to complete installation."
    fi

    echo ""
}

upgrade_nextcloud() {
    local installed_version="${1}"
    local image_version="${2}"

    echo "Nextcloud will be upgraded from $installed_version to $image_version."
    echo ""

    echo "Running upgrade..."
    run_as 'php /var/www/html/occ upgrade'
    run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after

    echo "Upgrade finished."
    echo ""

    echo "The following apps have been disabled:"
    diff /tmp/list_before /tmp/list_after | grep '<' | cut -d- -f2 | cut -d: -f1

    rm -f /tmp/list_before /tmp/list_after
}

capture_install_options() {
    if [ ! -n "${NEXTCLOUD_ADMIN_USER+x}" ] || [ ! -n "${NEXTCLOUD_ADMIN_PASSWORD+x}" ]; then
        return 1
    fi

    # shellcheck disable=SC2016
    install_options='-n --admin-user "$NEXTCLOUD_ADMIN_USER" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD"'

    if [ -n "${NEXTCLOUD_TABLE_PREFIX+x}" ]; then
        # shellcheck disable=SC2016
        install_options=$install_options' --database-table-prefix "$NEXTCLOUD_TABLE_PREFIX"'
    else
        install_options=$install_options' --database-table-prefix ""'
    fi

    if [ -n "${NEXTCLOUD_DATA_DIR+x}" ]; then
        # shellcheck disable=SC2016
        install_options=$install_options' --data-dir "$NEXTCLOUD_DATA_DIR"'
    fi

    install_type="None"

    if [ -n "${SQLITE_DATABASE+x}" ]; then
        # shellcheck disable=SC2016
        install_options=$install_options' --database-name "$SQLITE_DATABASE"'
        install_type="SQLite"
    elif [ -n "${MYSQL_DATABASE+x}" ] && [ -n "${MYSQL_USER+x}" ] && [ -n "${MYSQL_PASSWORD+x}" ] && [ -n "${MYSQL_HOST+x}" ]; then
        # shellcheck disable=SC2016
        install_options=$install_options' --database mysql --database-name "$MYSQL_DATABASE" --database-user "$MYSQL_USER" --database-pass "$MYSQL_PASSWORD" --database-host "$MYSQL_HOST"'
        install_type="MySQL"
    elif [ -n "${POSTGRES_DB+x}" ] && [ -n "${POSTGRES_USER+x}" ] && [ -n "${POSTGRES_PASSWORD+x}" ] && [ -n "${POSTGRES_HOST+x}" ]; then
        # shellcheck disable=SC2016
        install_options=$install_options' --database pgsql --database-name "$POSTGRES_DB" --database-user "$POSTGRES_USER" --database-pass "$POSTGRES_PASSWORD" --database-host "$POSTGRES_HOST"'
        install_type="PostgreSQL"
    fi

    if [ "${install_type}" = "None" ]; then
        return 1
    else
        return 0
    fi
}

run_installer() {
    local install_options="${1}"

    run_as "php /var/www/html/occ maintenance:install ${install_options}" \
    && configure_trusted_domains

    return $?
}

configure_trusted_domains() {
    if [ -n "${NEXTCLOUD_TRUSTED_DOMAINS+x}" ]; then
        echo "Configuring trusted domains..."
        NC_TRUSTED_DOMAIN_IDX=1

        for DOMAIN in $NEXTCLOUD_TRUSTED_DOMAINS ; do
            DOMAIN=$(echo "$DOMAIN" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

            run_as "php /var/www/html/occ config:system:set trusted_domains $NC_TRUSTED_DOMAIN_IDX --value=$DOMAIN"

            NC_TRUSTED_DOMAIN_IDX=$(($NC_TRUSTED_DOMAIN_IDX+1))
        done
    fi
}

update_htaccess() {
    # From https://help.nextcloud.com/t/apache-rewrite-to-remove-index-php/658
    echo "Updating .htaccess for proper rewrites..."
    run_as "php /var/www/html/occ maintenance:update:htaccess"
}

start_log_capture() {
    touch /var/log/nextcloud.log
    chown www-data:root /var/log/nextcloud.log
    tail -F /var/log/nextcloud.log &
}

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    dir_contents=$(\
        find "${1}/" \
            -mindepth 1 \
            -maxdepth 1 \
            -type f \
            -o \( \
                -type d \
                -a -not -name lost\+found \
                -a -not -name . \
            \) \
    )

    [ -z "${dir_contents}" ]
}

uri_encode() {
  php -r "echo urlencode('${1}');"
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p www-data -s /bin/sh -c "$1"
        return $?
    else
        sh -c "$1"
        return $?
    fi
}

container_type="${1:-none}"
initialize_container "${container_type}"
start_log_capture

exec "$@"
