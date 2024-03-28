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
# @copyright Copyright (c) 2019-2022, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -eu

################################################################################
# High-level Functions
################################################################################

##
# Initializes the container for running Nextcloud.
#
# @param $1
#   The type of container ("apache" or "php-fpm") being run.
#
initialize_container() {
    container_type="${1}"

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
        acquire_initialization_lock
        identify_run_as_user_and_group "${container_type}"
        configure_new_relic
        deploy_nextcloud_release
        configure_redis
        tune_php

        echo "The installed version of Nextcloud is ${installed_version} and" \
            "the running Nextcloud image is version ${image_version}."

        if version_greater "${image_version}" "${installed_version}"; then
            if [ "${NEXTCLOUD_CONFIG_READ_ONLY}" = "true" ]; then
                echo "Nextcloud cannot be installed or updated because it" \
                    "has been deployed with a read-only config." >&2
                exit 1
            fi

            capture_existing_app_list "${installed_version}"

            if [ "${installed_version}" = "0.0.0.0" ]; then
                install_nextcloud "${image_version}"
            else
                upgrade_nextcloud "${installed_version}" "${image_version}"
            fi

            capture_installed_version
        fi

        configure_web_server "${container_type}"
        release_initialization_lock

        invoke_hooks_for_stage "before-starting"
    fi
}

##
# Acquires a lock by creating a file in the Nextcloud config folder.
#
# This employs a different mechanism than the upstream entrypoint script, since
# flock() doesn't work on SMB-mounted volumes across pods.
#
acquire_initialization_lock() {
    # If another process is syncing the html folder, wait for it to be done,
    # then escape initialization.
    #
    # You need to define the NEXTCLOUD_INIT_LOCK environment variable
    initialization_lock_file=/var/www/html/nextcloud-init-sync.lock
    count=0
    limit=10

    if [ -f "${initialization_lock_file}" ] && [ "${NEXTCLOUD_INIT_LOCK:-}" = "true" ]; then
        until [ ! -f "${initialization_lock_file}" ] || [ "$count" -gt "${limit}" ]; do
            count=$((count+1))
            wait=$((count*10))

            echo "Another process is initializing Nextcloud. Waiting ${wait} seconds..."
            sleep $wait
        done

        if [ "${count}" -gt "${limit}" ]; then
            echo "Timeout while waiting for an ongoing initialization"
            exit 1
        fi

        echo "The other process is done, assuming complete initialization"
    else
        # Prevent multiple pods from syncing simultaneously.
        touch "${initialization_lock_file}"

        # Ensure lock is released if script exits abnormally.
        trap release_initialization_lock EXIT
    fi
}

##
# Releases any initialization lock on the Nextcloud configuration folder.
#
release_initialization_lock() {
    if [ -n "${initialization_lock_file:-}" ] &&
       [ -f "${initialization_lock_file}" ]; then
        rm "${initialization_lock_file}"
    fi
}

##
# Configures New Relic, if installed and configured by the environment.
#
configure_new_relic() {
    if [ -n "${NEW_RELIC_KEY}" ]; then
        NEW_RELIC_APP="${NEW_RELIC_APP:-Nextcloud}"
        new_relic_config_file="/usr/local/etc/php/conf.d/newrelic.ini"

        if [ ! -f "${new_relic_config_file}" ]; then
            {
                echo "A New Relic subscription key was provided but New Relic"
                echo "was not included in this image at publishing time."
            } >&2
            exit 1
        fi

        sed -i -e "s/\"REPLACE_WITH_REAL_KEY\"/\"${NEW_RELIC_KEY}\"/" \
            -e "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"${NEW_RELIC_APP}\"/" \
            "${new_relic_config_file}"
    fi
}

##
# Applies miscellaneous configuration tuning for the web server being run.
#
# @param $1
#   The type of container ("apache" or "php-fpm") being run.
#
configure_web_server() {
    container_type="${1}"

    if [ "${container_type}" = "apache" ]; then
        if [ -n "${APACHE_DISABLE_REWRITE_IP+x}" ]; then
            a2disconf remoteip
        fi

        chown "${user}:${group}" /var/www/html/.htaccess

        # From https://help.nextcloud.com/t/apache-rewrite-to-remove-index-php/658
        echo "Updating .htaccess for proper rewrites..."
        run_as "php /var/www/html/occ maintenance:update:htaccess"

        chown "root:${group}" /var/www/html/.htaccess
    fi
}

##
# Applies fix-ups to environment variable values before being interpreted.
#
sanitize_environment_vars() {
    touch_file="/var/www/html/config/.writable"

    if touch "${touch_file}" 1>/dev/null 2>&1; then
        rm "${touch_file}"
    else
        # Force environment variable to `true` whenever the config folder is mounted
        # read-only, even if the var was not explicitly set as such.
        export NEXTCLOUD_CONFIG_READ_ONLY="true"
    fi
}

##
# Execute any scripts included in the Docker image for a given stage of startup.
#
# @param $1
#   The stage of Nextcloud initialization. Must be one of:
#     - "pre-installation"
#     - "post-installation"
#     - "pre-upgrade"
#     - "post-upgrade"
#     - "before-starting"
#
invoke_hooks_for_stage() {
    stage="${1}"
    hook_folder_path="/docker-entrypoint-hooks.d/${stage}"
    return_code=0

    if ! [ -d "${hook_folder_path}" ]; then
        echo "=> Skipping the folder \"${hook_folder_path}\", because it doesn't exist"
        return 0
    fi

    echo "=> Searching for scripts (*.sh) to run, located in the folder: ${hook_folder_path}"

    (
        find "${hook_folder_path}" -type f -maxdepth 1 -iname '*.sh' -print | \
          sort | \
          while read -r script_file_path; do
            if ! [ -x "${script_file_path}" ]; then
                echo "==> The script \"${script_file_path}\" was skipped, because it didn't have the executable flag"
                continue
            fi

            echo "==> Running the script (cwd: $(pwd)): \"${script_file_path}\""

            run_as "${script_file_path}" || return_code="$?"

            if [ "${return_code}" -ne "0" ]; then
                echo "==> Failed at executing \"${script_file_path}\". Exit code: ${return_code}"
                exit 1
            fi

            echo "==> Finished the script: \"${script_file_path}\""
        done
    )
}

##
# Identifies what user and group ID the image should run processes as.
#
# This populates the following global variables:
#  - uid: The ID of the user under which this script is currently running.
#  - user: The name or ID of the user under which Nextcloud should run. Defaults
#    to "www-data".
#  - gid: The ID of the group security context under which this script is
#    currently running.
#  - group: The name or ID of the group security context under which Nextcloud
#    should run. Defaults to "www-data".
#
# @param $1
#   The type of container ("apache" or "php-fpm") being run.
#
identify_run_as_user_and_group() {
    container_type="${1}"

    uid="$(id -u)"
    gid="$(id -g)"

    if [ "${uid}" = '0' ]; then
        case "${container_type}" in
            apache2*)
                user="${APACHE_RUN_USER:-www-data}"
                group="${APACHE_RUN_GROUP:-www-data}"

                # strip off any '#' symbol ('#1000' is valid syntax for Apache)
                user="${user#'#'}"
                group="${group#'#'}"
                ;;
            *) # php-fpm
                user='www-data'
                group='www-data'
                ;;
        esac
    else
        user="${uid}"
        group="${gid}"
    fi
}

##
# Runs the given command under the appropriate user for Nextcloud.
#
# This depends on identify_run_as_user_and_group() having run first.
#
# @param $1
#   The command to invoke under the Nextcloud user.
#
run_as() {
    if [ "${uid}" = 0 ]; then
        # We are root, so we can "su" into the appropriate account.
        su -p "${user}" -s /bin/sh -c "${1}" || exit 1
    else
        # We're stuck running as the user who launched us.
        sh -c "${1}" || exit 1
    fi
}

##
# Syncs the Nextcloud release, apps, and themes from image into the web root.
#
# If the configuration directory is writable, this will also update all
# configuration snippets other than the config.php itself.
#
deploy_nextcloud_release() {
    echo "Deploying Nextcloud ${image_version}..."

    if [ "${uid}" = 0 ]; then
        rsync_options="-rlDog --chown root:${group}"
    else
        rsync_options="-rlD"
    fi

    rsync $rsync_options --delete --exclude-from=/upgrade.exclude /usr/src/nextcloud/ /var/www/html/

    # Ensure that config, data, custom apps, and themes exist.
    #
    for dir in config data custom_apps themes; do
        dir_path="/var/www/html/${dir}"

        # We explicitly force updates to custom apps and themes from this Docker
        # image.
        if [ ! -d "${dir_path}" ] || directory_empty "${dir_path}" ||
           [ "${dir_path}" = "custom_apps" ] || [ "${dir_path}" = "themes" ]; then
            mkdir -p "${dir_path}"
            chmod 0750 "${dir_path}"
            chown "root:${group}" "${dir_path}"

            # Avoid accidentally bashing data in the data folder.
            if [ "${dir}" = "data" ]; then
                rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
            else
                rsync $rsync_options --delete --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
            fi
        fi
    done

    # Copy version.php last, per https://github.com/nextcloud/docker/pull/660
    #
    # NOTE: We have to do this separately since recent images added version.php
    # to the "upgrade.exclude" list. However, we aren't affected by the upstream
    # issue that this workaround was intended for because NC code is not
    # persisted from container to container -- we keep it in an ephemeral,
    # emptyDir volume within each pod, so we always sync version.php at startup.
    #
    rsync $rsync_options --include '/version.php' --exclude '/*' /usr/src/nextcloud/ /var/www/html/

    if [ "${NEXTCLOUD_CONFIG_READ_ONLY:-false}" = "false" ]; then
        echo "'config' directory is writable."
        echo "Sync-ing configuration snippets:"
        cp -v /usr/src/nextcloud/config/*.config.php /var/www/html/config/
        cp -v /usr/src/nextcloud/config/*.pem /var/www/html/config/
        echo ""
    else
        echo "'config' directory is not writable."
        echo "Configuration snippets will not be synced."
        echo ""
    fi

    echo "Deployment finished."
    echo ""
}

##
# Configures connectivity for Redis session storage, if enabled.
#
configure_redis() {
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

        # From:
        # https://github.com/nextcloud/docker/commit/9b057aafb0c41bab63870277c53307d3d6dc572b
        echo 'redis.session.locking_enabled = 1'
        echo 'redis.session.lock_retries = -1'

        # redis.session.lock_wait_time is specified in microseconds.
        # Wait 10ms before retrying the lock rather than the default 2ms.
        echo "redis.session.lock_wait_time = 10000"
    } > /usr/local/etc/php/conf.d/redis-sessions.ini
}

##
# Tweaks performance-related settings for PHP and the PHP opcache.
#
# This disables timestamp checking on the opcache, since we do not except the
# code for Nextcloud to ever change at run time.
#
tune_php() {
    echo "Tuning PHP performance."
    {
        # Disable assertions since this is a production-like environment
        echo 'assert.active = 0'
        echo ''

        # Code is static; no need to validate timestamps
        echo 'opcache.validate_timestamps = 0'

        # Save opcode cache on-disk for higher performance during low memory
        # conditions.
        echo 'opcache.file_cache = /mnt/php-file-cache'
    } > /usr/local/etc/php/conf.d/perf-tuning.ini
}

##
# Captures the list of all apps that are enabled.
#
# This is run before an upgrade so that an admin can be notified if an upgrade
# has disabled any apps.
#
capture_existing_app_list() {
    installed_version="${1}"

    if [ "$installed_version" != "0.0.0.0" ]; then
        run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
    fi
}

##
# Installs Nextcloud for the first time on this environment.
#
# @param $1
#   The version of Nextcloud being installed (the version of this image).
#
install_nextcloud() {
    image_version="${1}"

    invoke_hooks_for_stage "pre-installation"

    echo "This is a new installation of Nextcloud."
    echo ""

    # NOTE: This populates `database_type` and `install_options`
    if capture_install_options; then
        echo "Installing Nextcloud using settings provided by container environment..."
        echo ""

        echo "Database type: ${database_type}"
        echo ""

        set +e

        if ! run_installer "${install_options}"; then
            echo "Installation of Nextcloud has failed!"
            exit 1
        fi

        set -e

        configure_trusted_domains

        echo "Installation finished."
    else
        echo "Run the web-based installer to complete installation."
    fi

    echo ""

    invoke_hooks_for_stage "post-installation"
}


##
# Checks to ensure that the given installed version is compatible with an image.
#
# @param $1
#   The version of Nextcloud that is installed.
# @param $2
#   The version of Nextcloud that is in the loaded Docker image.
#
ensure_compatible_image() {
    installed_version="${1}"
    image_version="${2}"

    if version_greater "${installed_version}" "${image_version}"; then
        {
            echo "This image of Nextcloud cannot be used because the data was last used with version (${installed_version}),"
            echo "which is higher than the docker image version (${image_version}) and downgrading is not supported."
            echo "Are you sure you have pulled the newest image version?"
        } >&2
    fi

    if [ "${image_version%%.*}" -gt "$((${installed_version%%.*} + 1))" ]; then
        {
            echo "Nextcloud cannot be upgraded from ${installed_version} directly to ${image_version}."
            echo "It is only possible to upgrade one major version at a time."
            echo "For example, if you want to upgrade from version 24 to 26, you"
            echo "will have to upgrade from version 24 to 25, then from 25 to 26."
        } >&2
        exit 1
    fi
}

##
# Upgrades an existing installation of Nextcloud to the version in this image.
#
# @param $1
#   The version of Nextcloud that is installed.
# @param $2
#   The version of Nextcloud that is in the loaded Docker image.
#
upgrade_nextcloud() {
    installed_version="${1}"
    image_version="${2}"

    invoke_hooks_for_stage "pre-upgrade"

    echo "Nextcloud will be upgraded from ${installed_version} to ${image_version}."
    echo ""

    echo "Running upgrade..."
    run_as 'php /var/www/html/occ upgrade'
    run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after

    echo "Upgrade finished."
    echo ""

    echo "The following apps have been disabled:"
    diff /tmp/list_before /tmp/list_after | grep '<' | cut -d- -f2 | cut -d: -f1

    rm -f /tmp/list_before /tmp/list_after

    invoke_hooks_for_stage "post-upgrade"
}

##
# Captures what options should be passed to the Nextcloud installer.
#
# This populates the following global variables:
#  - install_options: The command-line arguments to pass to the installer.
#  - database_type: The type of database on which Nextcloud is being installed.
#    (Currently, only MySQL/MariaDB are supported by this image).
#
capture_install_options() {
    if [ -z "${NEXTCLOUD_ADMIN_USER+x}" ] || [ -z "${NEXTCLOUD_ADMIN_PASSWORD+x}" ]; then
        return 1
    fi

    # shellcheck disable=SC2016
    install_options='-n --admin-user "$NEXTCLOUD_ADMIN_USER" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD"'

    if [ -n "${NEXTCLOUD_DATA_DIR+x}" ]; then
        # shellcheck disable=SC2016
        install_options=$install_options' --data-dir "$NEXTCLOUD_DATA_DIR"'
    fi

    file_env MYSQL_DATABASE
    file_env MYSQL_PASSWORD
    file_env MYSQL_USER

    database_type="None"

    if [ -n "${MYSQL_DATABASE+x}" ] && [ -n "${MYSQL_USER+x}" ] && \
       [ -n "${MYSQL_PASSWORD+x}" ] && [ -n "${MYSQL_HOST+x}" ]; then
        if [ -n "${MYSQL_PORT+x}" ]; then
            # Nextcloud bakes the port into the host for some reason.
            MYSQL_HOST="${MYSQL_HOST}:${MYSQL_PORT}"
        fi

        # shellcheck disable=SC2016
        install_options=$install_options' --database mysql --database-name "$MYSQL_DATABASE" --database-user "$MYSQL_USER" --database-pass "$MYSQL_PASSWORD" --database-host "$MYSQL_HOST"'
        database_type="MySQL"
    fi

    if [ "${database_type}" = "None" ]; then
        return 1
    else
        return 0
    fi
}

##
# Runs the Nextcloud installer with the given options.
#
# @param $1
#   The space-separated command-line arguments to pass to the installer.
#
run_installer() {
    install_options="${1}"

    run_as "php /var/www/html/occ maintenance:install ${install_options}"

    return $?
}

##
# Configures the domains that this installation of Nextcloud trusts traffic for.
#
configure_trusted_domains() {
    if [ -n "${NEXTCLOUD_TRUSTED_DOMAINS+x}" ]; then
        echo "Configuring trusted domains..."
        NC_TRUSTED_DOMAIN_IDX=1

        for DOMAIN in $NEXTCLOUD_TRUSTED_DOMAINS ; do
            DOMAIN=$(echo "$DOMAIN" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

            run_as "php /var/www/html/occ config:system:set trusted_domains $NC_TRUSTED_DOMAIN_IDX --value=$DOMAIN"

            NC_TRUSTED_DOMAIN_IDX=$((NC_TRUSTED_DOMAIN_IDX+1))
        done
    fi
}

##
# Records the installed Docker image version number into the config volume.
#
# This is used to perform sanity checks at startup to confirm that the running
# image is either the same version as what's installed, or a version to which
# the installed version can be upgraded (no downgrades, and no skipping major
# versions).
#
capture_installed_version() {
    # Capture the only file needed from a distribution to properly spin up a
    # new instance and/or upgrade an existing one
    cp /usr/src/nextcloud/version.php /var/www/html/config/version.php
}

##
# Starts capturing output from the Nextcloud application and audit logs.
#
# The output is written to the standard output of the container so that it can
# be picked up by Azure Log Analytics or similar container log capture.
#
start_log_capture() {
    app_log="/var/log/nextcloud.log"
    audit_log="/var/log/nextcloud-audit.log"

    # Application log
    touch "${app_log}"
    chown "${user}:${group}" "${app_log}"
    tail -F "${app_log}" &

    # Audit log
    touch "${audit_log}"
    chown "${user}:${group}" "${audit_log}"

    run_as "php /var/www/html/occ config:app:set admin_audit logfile '--value=${audit_log}'"

    tail -F "${audit_log}" &
}

################################################################################
# Utility Functions
################################################################################
##
# Compares two version numbers and returns if first is greater than second.
#
# @param $1
#   The first version number.
# @param $2
#   The second version number.
#
# @return
#   - 0 (success) if the first version is greater than the second.
#   - 1 (failure) if the first version is less than or equal to the second.
#
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

##
# Determine if the given directory is empty.
#
# This differs from Nextcloud's stock implementation because we have to ignore
# specific dotfiles and special system folders (like lost+found).
#
# @param $1
#   The directory to check.
#
# @return
#   - 0 (success) if the specified path is empty or contains only files we can
#     safely ignore.
#   - 1 (failure) if the specified path is not empty or contains more than just
#     files we can safely ignore.
#
directory_empty() {
    dir_contents=$(\
        find "${1}/" \
            -mindepth 1 \
            -maxdepth 1 \
            -type f \
            -o \( \
                -type d \
                -a -not -name lost\+found \
                -a -not -name .snapshot \
                -a -not -name . \
            \) \
    )

    [ -z "${dir_contents}" ]
}

##
# Uses PHP to URI-encodes special characters in the given string.
#
# The function echoes the result on its standard out.
#
# @param $1
#   The string to URL-encode.
#
uri_encode() {
    php -r "echo urlencode('${1}');"
}

##
# Load the value of an environment variable from environment or an env file.
#
# For example: file_env 'XYZ_DB_PASSWORD' 'example'
#
# This would allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
# "$XYZ_DB_PASSWORD" from a file, especially when being used with Docker's
# secrets volume feature.
#
# @param $1
#   The name of the variable to load.
# @param $2 [optional]
#   An optional default value for the variable, if it has not been provided by
#   the environment.
#
file_env() {
    var="$1"
    fileVar="${var}_FILE"
    def="${2:-}"
    varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")

    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both ${var} and ${fileVar} are set (but are exclusive)"
        exit 1
    fi

    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}")"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi

    unset "$fileVar"
}

################################################################################
# Main script
################################################################################
container_type="${1:-none}"

sanitize_environment_vars
initialize_container "${container_type}"
start_log_capture

exec "$@"
