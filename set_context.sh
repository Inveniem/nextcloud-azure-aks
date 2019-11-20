#!/usr/bin/env bash

##
# Sets the local Kubernetes context to match the one in the configuration.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "${SCRIPT_DIR}/config.env"

kubectl config use-context "${KUBE_CONTEXT}"
