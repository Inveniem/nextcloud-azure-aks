#!/usr/bin/env bash

##
# @file
# This script publishes the SFTP-WS Server Nextcloud Add-on to a Container
# Registry.
#
# Usage:
#   ./publish.sh <container registry> [docker image tag]
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019-2022, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

################################################################################
# Constants
################################################################################

##
# Error thrown when a bad command-line argument has been provided.
#
error_bad_arguments=1

##
# The name of the container that this script publishes.
#
container_name="inveniem/sftp-ws-server"

script_path="${BASH_SOURCE[0]}"
script_dirname="$( cd "$( dirname "${script_path}" )" >/dev/null 2>&1 && pwd )"

################################################################################
# Overridable Environment Variables
################################################################################
# All of the variables below can be specified on the command line to override
# them at run-time.

##
# Additional arguments to pass to the Docker build.
#
# Overridable with BUILD_ARGS environment variable.
#
build_args="${BUILD_ARGS:-}"

################################################################################
# Command-line Arguments
################################################################################
# Each of these variables is parsed out of the command line in the order they
# appear below.

##
# The URL of the Docker container registry (required).
#
container_repository=""

##
# The tag for the Docker image to publish (optional).
#
# Defaults to "latest".
#
container_tag=""

################################################################################
# Functions
################################################################################

##
# Prints the usage statement for this script and then exits with the given code.
#
# @param $1 [optional]
#   The exit code to return to the calling process. If not provided, defaults to
#   0 (success).
#
print_usage_and_exit() {
  local exit_code="${1:-0}"

  {
    echo "Usage: ${0} <container registry> [docker image tag] [--with-xdebug]"
    echo ""
  } >&2

  exit "${exit_code}"
}

##
# Parses the command-line arguments passed to this script.
#
# The first non-option argument is interpreted to be the docker container
# repository (required) and the second one is interpreted as the docker image
# tag (optional; defaults to "latest").
#
parse_args() {
  declare -g error_bad_arguments
  declare -g container_repository
  declare -g container_tag
  declare -g build_args

  if [[ $# -gt 3 ]]; then
    print_usage_and_exit "${error_bad_arguments}"
  fi

  for argument in "$@"; do
    if [[ "${argument}" == "--help" || "${argument}" == "--h" ||
          "${argument}" == --* ]]; then
      print_usage_and_exit

    elif [[ -z "${container_repository}" ]]; then
      container_repository="${argument}"

    elif [[ -z "${container_tag}" ]]; then
      container_tag="${argument}"

    else
      print_usage_and_exit "${error_bad_arguments}"
    fi
  done

  container_tag="${container_tag:-latest}"
}

##
# Checks to ensure the version being built and tagged does not already exist.
#
# This will halt the script if the version being built already exists in the
# remote repository.
#
# @param $1
#   The remote container image tag (registry host, image, and tag).
#
require_no_image_overwrite() {
  declare -g DOCKER_IMAGE_ALLOW_OVERWRITE

  local remote_container_url="${1}"

  if docker manifest inspect "${remote_container_url}" >/dev/null 2>&1; then
    if [[ "${DOCKER_IMAGE_ALLOW_OVERWRITE:-0}" -eq 1 ]]; then
      {
        echo "The specified version of this Docker image"
        echo "(${remote_container_url}) already exists remotely. It will be"
        echo "overwritten since DOCKER_IMAGE_ALLOW_OVERWRITE=1."
        echo ""
      } >&2
    else
      {
        echo "The specified version of this Docker image"
        echo "(${remote_container_url}) already exists remotely. For safety,"
        echo "it will not be overwritten."
        echo ""
        echo "If you really want to republish this version, run this command"
        echo "with DOCKER_IMAGE_ALLOW_OVERWRITE=1."
        echo ""
      } >&2

      exit 3
    fi
  fi
}

################################################################################
# Main Script Body
################################################################################
cd "${script_dirname}"

parse_args "$@"

container_name_and_tag="${container_name}:${container_tag}"
remote_container_url="${container_repository}/${container_name_and_tag}"

if [[ "${container_tag}" != "latest" ]]; then
  require_no_image_overwrite "${remote_container_url}"
fi

# shellcheck disable=SC2086
docker build -t "${container_name_and_tag}" . ${build_args:-}

docker tag "${container_name_and_tag}" "${remote_container_url}"
docker push "${remote_container_url}"
