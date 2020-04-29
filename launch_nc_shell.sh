#!/usr/bin/env bash
kubectl exec -it $(kubectl get pods | grep -m1 nextcloud | awk '{ print $1 }') -- su -s /bin/sh www-data
