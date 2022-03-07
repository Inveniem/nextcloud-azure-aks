##
# Settings for building and publishing Nextcloud Docker images.
#
# This is an EXAMPLE file. Customize for your environment! If you have multiple
# environments, you can create multiple copies of the containing, sample overlay
# folder and customize manifests in each one to match your environments.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019-2021, Inveniem
# @license GNU AGPL version 3 or any later version
#

################################################################################
# Docker Registry (ACR) Settings
################################################################################

##
# The name and hostname of your Docker registry or ACR instance.
#
# This only affects publishing. You will also need to update kustomization.yaml
# to point to the same registry host for deployments to be able to pull the
# image.
#
REGISTRY_NAME="your-acr-instance"
REGISTRY_HOST="${REGISTRY_NAME}.azurecr.io"

##
# The name of the engine used for building and publishing images.
#
# The default is Docker, but Podman is also supported.
#
CONTAINER_ENGINE="docker"

################################################################################
# Nextcloud Apps
################################################################################
# The download URLs from the Nextcloud App Store to any custom apps you want in
# available in the deployed image.
#
NEXTCLOUD_CUSTOM_APPS=(
    'https://github.com/westberliner/checksum/releases/download/v1.1.3/checksum.tar.gz'
    'https://github.com/nextcloud/files_antivirus/releases/download/v3.2.2/files_antivirus.tar.gz'
    'https://github.com/nextcloud-releases/files_automatedtagging/releases/download/v1.13.0/files_automatedtagging-v1.13.0.tar.gz'
    'https://github.com/nextcloud-releases/files_downloadactivity/releases/download/v1.12.0/files_downloadactivity-v1.12.0.tar.gz'
    'https://github.com/nextcloud/files_rightclick/releases/download/v0.15.1/files_rightclick.tar.gz'
    'https://github.com/gino0631/nextcloud-metadata/releases/latest/download/metadata.tar.gz'
    'https://github.com/owncloud/music/releases/download/v1.5.1/music_1.5.1_for_nextcloud.tar.gz'
    'https://github.com/nextcloud-releases/previewgenerator/releases/download/v4.0.0/previewgenerator.tar.gz'
    'https://github.com/nextcloud/user_external/releases/download/v2.1.0/user_external-2.1.0.tar.gz'
    'https://github.com/nextcloud/user_saml/releases/download/v4.1.1/user_saml-4.1.1.tar.gz'
)

################################################################################
# New Relic Monitoring Settings (Optional)
################################################################################

##
# Your New Relic subscription key.
#
# Leave blank if you do not use New Relic monitoring.
#
NEW_RELIC_KEY=""

##
# The URL to the New Relic PHP agent (optional).
#
# The default downloads NR PHP agent 9.19.0.309 for PHP 5+. Use the latest shown
# here: https://download.newrelic.com/php_agent/release/
#
# Leave blank if you do not use New Relic monitoring.
#
NEW_RELIC_AGENT_URL="https://download.newrelic.com/php_agent/release/newrelic-php5-9.19.0.309-linux.tar.gz"

##
# The name by which you would like Nextcloud to identify itself in New Relic.
#
# Leave blank if you do not use New Relic monitoring.
#
NEW_RELIC_APP="Nextcloud"

################################################################################
# Deployment Macros
################################################################################
# Use this section to declare any commands that need to be run when an image is
# being built and published (e.g., authenticating with ACR).

# Uncomment the command below to automate having Docker authenticate with ACR
# before publishing an image.
#
#az acr login --name "${REGISTRY_NAME}"

# Uncomment the command below to automate having Podman authenticate with ACR
# before publishing an image.
#acr_token=$(
#  az acr login --name "${REGISTRY_NAME}" --expose-token | \
#    jq .accessToken | \
#    tr -d '"'
#)
#
#podman login "${REGISTRY_HOST}" \
#  -u "00000000-0000-0000-0000-000000000000" \
#  -p "${acr_token}"
