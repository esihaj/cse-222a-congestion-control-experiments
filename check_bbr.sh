#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
    echo "No .env file found. Please create one with SERVER_IP and CLIENT_IP."
    exit 1
fi

# shellcheck source=/dev/null
source .env

if [ -z "${SERVER_IP:-}" ] || [ -z "${CLIENT_IP:-}" ]; then
    echo "SERVER_IP or CLIENT_IP not set in .env."
    exit 1
fi

SSH_USER="${SSH_USER:-ubuntu}"
SSH_KEY_PATH="${SSH_KEY_PATH:-~/.ssh/id_rsa}"
SSH_OPTS="-i $SSH_KEY_PATH -o StrictHostKeyChecking=no"

check_host() {
    HOST=$1
    echo "[CHECK_BBR] Checking BBR on $HOST..."
    AVAIL=$(ssh $SSH_OPTS $SSH_USER@$HOST "sysctl net.ipv4.tcp_available_congestion_control")
    echo "$AVAIL" | grep -q bbr || { echo "BBR not supported on $HOST"; exit 1; }
}

check_host $SERVER_IP
check_host $CLIENT_IP

echo "BBR is supported on both server and client."
