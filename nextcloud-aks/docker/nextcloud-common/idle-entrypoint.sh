#!/bin/sh

##
# This entrypoint can be used in the Dockerfile for debugging purposes. It
# basically spins up a container that does nothing useful, but keeps the
# container alive so that it's possible to SSH-in and try out a few things.
#
# Without this, it is nearly impossible to debug issues that cause the container
# to crash.
#
# Source:
# https://github.com/docker/compose/issues/1926#issuecomment-422351028
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#
trap : TERM INT
tail -f /dev/null & wait
