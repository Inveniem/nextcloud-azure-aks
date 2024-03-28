##
# Settings for building and publishing Nextcloud Docker images.
#
# This is an EXAMPLE file. Customize for your environment! If you have multiple
# environments, you can create multiple copies of the containing, sample overlay
# folder and customize manifests in each one to match your environments.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019-2024, Inveniem
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
    'https://github.com/westberliner/checksum/releases/download/v1.2.3/checksum.tar.gz'
    'https://github.com/nextcloud-releases/files_antivirus/releases/download/v5.3.1/files_antivirus-v5.3.1.tar.gz'
    'https://github.com/nextcloud-releases/files_automatedtagging/releases/download/v1.14.2/files_automatedtagging-v1.14.2.tar.gz'
    'https://github.com/nextcloud-releases/files_downloadactivity/releases/download/v1.16.0/files_downloadactivity-v1.16.0.tar.gz'
    'https://github.com/Inveniem/nextcloud-files-excludedirs/releases/download/v1.0.1-beta/nextcloud_files_excludedirs-v1.0.1-beta.tar.gz'
    'https://github.com/nextcloud/files_rightclick/releases/download/v0.15.1/files_rightclick.tar.gz'
    'https://github.com/gino0631/nextcloud-metadata/releases/download/v0.19.0/metadata.tar.gz'
    'https://github.com/owncloud/music/releases/download/v1.10.0/music_1.10.0_for_nextcloud.tar.gz'
    'https://github.com/nextcloud-releases/previewgenerator/releases/download/v5.2.4/previewgenerator-v5.2.4.tar.gz'
    'https://github.com/nextcloud-releases/user_external/releases/download/v3.1.0/user_external-v3.1.0.tar.gz'
    'https://github.com/nextcloud-releases/user_saml/releases/download/v5.1.5/user_saml-v5.1.5.tar.gz'
)

################################################################################
# New Relic Monitoring Settings (Optional)
################################################################################

##
# The URL to the New Relic PHP agent (optional).
#
# Use the latest shown here: https://download.newrelic.com/php_agent/release/
#
# Leave this blank if you do not want New Relic support in your image. The
# subscription key and application name are specified through run-time
# environment variables that are controlled by "config-environment.yaml" in the
# Kustomization overlay.
#
# The image MUST have New Relic support baked in if you specify a New Relic
# subscription key in the "config-environment.yaml" file, or Nextcloud will fail
# to start.
#
NEW_RELIC_AGENT_URL="https://download.newrelic.com/php_agent/release/newrelic-php5-10.19.0.9-linux.tar.gz"

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
