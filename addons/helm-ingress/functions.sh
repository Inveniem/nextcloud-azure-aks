#!/usr/bin/env bash

##
# Reusable functions for the scripts in this folder.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#
confirmation_prompt() {
    question="${1}"

    echo "" >&2
    read -p "${question} (y/n)? " choice >&2
    case "$choice" in
      y|Y ) confirmed=1;;
      n|N ) confirmed=0;;
      * ) confirmed=0;;
    esac

    echo "" >&2
}
