#!/usr/bin/env bash

##
# Generates an SFTP password.
#
# Based on documentation from:
# https://hub.docker.com/r/atmoz/sftp#encrypted-password
#
read -s -p 'Password: ' password && echo "" &&
  (echo -n "${password}" | \
    docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-)
