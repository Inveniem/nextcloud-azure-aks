#!/usr/bin/env bash

./set_context.sh

kubectl exec -it $(kubectl get pods | grep -m1 nextcloud | awk '{ print $1 }') -- su -s /bin/sh www-data
