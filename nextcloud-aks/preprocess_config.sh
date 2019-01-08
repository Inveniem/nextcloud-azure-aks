#!/usr/bin/env bash

##
# A utility script that pre-processes a template for a Kubernetes config file,
# expanding inline references to variables defined in `config.env` to make it
# a full config file Kubernetes can process.
#
# This utility depends on `envsubst` which is part of GNU gettext.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -e
set -u

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ${0} <YAML config template filename>" >&2
    echo "" >&2
    echo "Expands all inline references to variables that are defined in" >&2
    echo "'config.env' within the provided Kubernetes configuration file," >&2
    echo "then prints the result to standard output." >&2

    exit 1
fi

set -a

source './config.env'
cat $1 | envsubst
