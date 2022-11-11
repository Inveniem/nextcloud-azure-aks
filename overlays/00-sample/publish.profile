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
    'https://github.com/westberliner/checksum/releases/download/v1.1.4/checksum.tar.gz'
    'https://github.com/nextcloud/files_antivirus/releases/download/v3.3.1/files_antivirus.tar.gz'
    'https://github.com/nextcloud-releases/files_automatedtagging/releases/download/v1.13.0/files_automatedtagging-v1.13.0.tar.gz'
    'https://github.com/nextcloud-releases/files_downloadactivity/releases/download/v1.15.0/files_downloadactivity-v1.15.0.tar.gz'
    'https://github.com/Inveniem/nextcloud-files-excludedirs/releases/download/v1.0.1-beta/nextcloud_files_excludedirs-v1.0.1-beta.tar.gz'
    'https://github.com/nextcloud/files_rightclick/releases/download/v0.15.1/files_rightclick.tar.gz'
    'https://github.com/gino0631/nextcloud-metadata/releases/download/v0.16.0/metadata.tar.gz'
    'https://github.com/owncloud/music/releases/download/v1.6.0/music_1.6.0_for_nextcloud.tar.gz'
    'https://github.com/nextcloud-releases/previewgenerator/releases/download/v5.1.0/previewgenerator-v5.1.0.tar.gz'
    'https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v2.3.3/oidc_login.tar.gz'
    'https://github.com/nextcloud-releases/user_external/releases/download/v3.0.0/user_external-v3.0.0.tar.gz'
    'https://github.com/nextcloud-releases/user_saml/releases/download/v5.0.3/user_saml-v5.0.3.tar.gz'
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
# Use the latest shown here: https://download.newrelic.com/php_agent/release/
#
# Leave blank if you do not use New Relic monitoring.
#
NEW_RELIC_AGENT_URL="https://download.newrelic.com/php_agent/release/newrelic-php5-10.3.0.315-linux.tar.gz"

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
