#!/usr/bin/env bash

##
# This script launches a local socat process that's connected to a socat process
# inside a Nextcloud PHP container.
#
# Usage:
# launch_xdebug_proxy.sh <pod name> [xdebug client port] [local ssh port]
#
# Where:
#  - <pod name> is the name of the pod in Kubernetes that's running Nextcloud.
#  - <xdebug proxy port> is the port on the local machine that the IDE/XDebug
#    client has been configured to connect to.
#  - [local ssh port] is an optional override of what port to use locally when
#    forwarding SSH into the container.
#
# See:
# https://www.jetbrains.com/help/phpstorm/multiuser-debugging-via-xdebug-proxies.html
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -u
set -e

SSH_TUNNEL_CONTAINER="ssh-tunnel"
SSH_TUNNEL_IMAGE="hermsi/alpine-sshd:8.1_p1-r0"

LOCAL_SSH_PRIVATE_KEY_FILE="/tmp/ssh-tunnel.key"
LOCAL_SSH_PUBLIC_KEY_FILE="${LOCAL_SSH_PRIVATE_KEY_FILE}.pub"
LOCAL_KNOWN_HOSTS_FILE="/tmp/ssh-tunnel.known_hosts"

REMOTE_SSH_FOLDER="/home/tunnel/.ssh"
REMOTE_AUTHORIZED_KEYS_FILE="${REMOTE_SSH_FOLDER}/authorized_keys"
REMOTE_TUNNEL_SERVICE="xdebug-tunnel"

parse_args() {
    if [[ $# -lt 1 || $# -gt 3 ]]; then
        print_usage_and_exit
    else
        POD_NAME="${1}"
        LOCAL_XDEBUG_PORT="${2:-9000}"
        LOCAL_SSH_PORT="${3:-1022}"
    fi
}

print_usage_and_exit() {
    {
        echo "Usage: ${0} <pod name> [xdebug client port] [local ssh port]"
        echo ""
        echo "Where:"
        echo "  - <pod name> is the name of the pod in Kubernetes that's"
        echo "    running Nextcloud."
        echo "  - [xdebug proxy port] optionally specifies the port on the"
        echo "    local machine that the IDE/XDebug client has been configured"
        echo "    to connect to. The default is 9000."
        echo "  - [local ssh port] optionally specifies the port to use locally"
        echo "    when forwarding SSH into the container. The default is 1022."
        echo ""
    } >&2

    exit 1
}

# Credit:
# https://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
declare -a on_exit_items

##
# Queue-up a command to run when this script exits normally or abnormally.
#
# @param string $*
#   The command and arguments to queue-up.
#
add_on_exit() {
    set +u

    local n=${#on_exit_items[*]}

    on_exit_items[$n]="$*"

    # Setup trap on the first item added to the list
    if [[ $n -eq 0 ]]; then
        trap dispatch_on_exit_items INT TERM HUP EXIT
    fi
}

##
# Execute commands that were queued-up for when this script exits.
#
dispatch_on_exit_items() {
    set +u

    for i in "${on_exit_items[@]}"; do
        eval $i
    done
}

##
# Queues-up a background process to be killed when this script exits.
#
# @param int $1
#   The ID of the process that should be killed on script exit.
#
kill_process_on_exit() {
    local process_id="${1}"

    add_on_exit "pkill -HUP -P ${process_id} || true"
}

##
# Delays this script, polling until the specified pod is running.
#
# @param string $1
#   The name of the pod to wait for.
#
wait_for_pod_ready() {
    local container_name="${1}"

    while [[ $(get_pod_status "${container_name}") != 'Running' ]]; do
        sleep 1
    done
}

##
# Gets the status of the specified pod.
#
# @param string $1
#   The name of the pod to get a status for.
#
get_pod_status() {
    local container_name="${1}"

    kubectl get po "${container_name}" -o=jsonpath='{$.status.phase}' \
        2>/dev/null
}

##
# Delays this script, waiting until the specified local port is listening for
# connections.
#
# @param int $1
#   The port on which to wait for an open socket.
#
wait_for_listening_port() {
    local port="${1}"

    while ! nc -z localhost "${port}" </dev/null; do
        sleep 1
    done
}

##
# Executes the specified command in the SSH tunnel container.
#
# The command is run through Bash to enable built-in commands to be used.
#
# @param string $1
#   The command to execute in the remote container.
#
tunnel_container_exec() {
    local command="${1}"

    kubectl exec -i "${SSH_TUNNEL_CONTAINER}" -- bash -c "${command}"
}

parse_args "$@"

echo "Launching SSH container for port forwarding..."
kubectl run "${SSH_TUNNEL_CONTAINER}" \
  --generator=run-pod/v1 \
  "--image=${SSH_TUNNEL_IMAGE}" \
  --env SSH_USERS="tunnel:1000:1000" \
  --port=9001
add_on_exit "kubectl delete po ${SSH_TUNNEL_CONTAINER}"

wait_for_pod_ready "${SSH_TUNNEL_CONTAINER}"

rm -f "${LOCAL_SSH_PRIVATE_KEY_FILE}" "${LOCAL_SSH_PUBLIC_KEY_FILE}"
rm -f "${LOCAL_KNOWN_HOSTS_FILE}"

echo ""
echo "Generating ephemeral SSH key..."

ssh-keygen -t rsa -b 2048 -N '' -f "${LOCAL_SSH_PRIVATE_KEY_FILE}"

echo ""
echo "Configuring SSH and 'tunnel' account..."

cat "${LOCAL_SSH_PUBLIC_KEY_FILE}" | \
    tunnel_container_exec "cat > ${REMOTE_AUTHORIZED_KEYS_FILE}"

kubectl exec -i "${SSH_TUNNEL_CONTAINER}" -- chown tunnel:tunnel -R "${REMOTE_SSH_FOLDER}"
kubectl exec -i "${SSH_TUNNEL_CONTAINER}" -- chmod 0700 "${REMOTE_SSH_FOLDER}"
kubectl exec -i "${SSH_TUNNEL_CONTAINER}" -- chmod 0600 "${REMOTE_AUTHORIZED_KEYS_FILE}"

tunnel_container_exec "sed -i 's/AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config"
tunnel_container_exec "sed -i 's/GatewayPorts no/GatewayPorts yes/' /etc/ssh/sshd_config"
tunnel_container_exec 'killall -HUP sshd'

echo ""
echo "Setting up local port '${LOCAL_SSH_PORT}' to forward to SSH container port '22'"

kubectl port-forward "${SSH_TUNNEL_CONTAINER}" "${LOCAL_SSH_PORT}:22" &
PORT_FORWARDER_ID=$!
kill_process_on_exit "${PORT_FORWARDER_ID}"

wait_for_listening_port "${LOCAL_SSH_PORT}"

echo "Exposing port remote port '9001' to the cluster..."
kubectl expose pod "${SSH_TUNNEL_CONTAINER}" --port=9001 "--name=${REMOTE_TUNNEL_SERVICE}"
add_on_exit "kubectl delete service ${REMOTE_TUNNEL_SERVICE}"

echo ""
echo "Setting up remote XDebug forward from remote port '9001' to local port '${LOCAL_XDEBUG_PORT}'"

ssh -NT \
  -o "StrictHostKeyChecking no" \
  -o UserKnownHostsFile="${LOCAL_KNOWN_HOSTS_FILE}" \
  -i "${LOCAL_SSH_PRIVATE_KEY_FILE}" \
  -4 tunnel@localhost -p "${LOCAL_SSH_PORT}" \
  -R "9001:localhost:${LOCAL_XDEBUG_PORT}" &
SSH_CLIENT_ID=$!
kill_process_on_exit "${SSH_CLIENT_ID}"

sleep 1

echo ""
echo 'XDebug proxy ready! Press ENTER or CTRL+C to end.'
read
