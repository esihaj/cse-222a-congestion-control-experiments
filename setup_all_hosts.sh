#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
    echo "No .env file found. Please create one with SERVER_IP and CLIENT_IP."
    exit 1
fi

# Load environment variables
source .env

if [ -z "${SERVER_IP:-}" ] || [ -z "${CLIENT_IP:-}" ]; then
    echo "SERVER_IP or CLIENT_IP not set in .env."
    exit 1
fi

SSH_USER="${SSH_USER:-ubuntu}"
SSH_KEY_PATH="${SSH_KEY_PATH:-~/.ssh/id_rsa}"
SSH_OPTS="-i $SSH_KEY_PATH -o StrictHostKeyChecking=no"

echo "[SETUP_ALL_HOSTS] Running setup_host.sh on server..."
scp $SSH_OPTS scripts/setup_host.sh $SSH_USER@$SERVER_IP:setup_host.sh
ssh $SSH_OPTS $SSH_USER@$SERVER_IP "chmod +x setup_host.sh && ./setup_host.sh"

echo "[SETUP_ALL_HOSTS] Running setup_host.sh on client..."
scp $SSH_OPTS scripts/setup_host.sh $SSH_USER@$CLIENT_IP:setup_host.sh
ssh $SSH_OPTS $SSH_USER@$CLIENT_IP "chmod +x setup_host.sh && ./setup_host.sh"

echo "[SETUP_ALL_HOSTS] setup_host.sh completed on both hosts."

./check_bbr.sh
