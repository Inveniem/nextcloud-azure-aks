#!/usr/bin/env bash

##
# This script attempts to publish all of the Docker images inside this repo
# to an Azure Container Registry instance.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

cd "./docker"
./publish_all.sh
