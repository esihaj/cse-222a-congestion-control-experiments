#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
    echo "No .env file found. Please create one with SERVER_IP and CLIENT_IP."
    exit 1
fi

# shellcheck source=/dev/null
source .env

SSH_USER="${SSH_USER:-ubuntu}"
SSH_KEY_PATH="${SSH_KEY_PATH:-~/.ssh/id_rsa}"
SSH_OPTS="-i $SSH_KEY_PATH -o StrictHostKeyChecking=no"

TARGET=${1:-}
if [ -z "$TARGET" ]; then
    echo "Usage: $0 [c|client|s|server]"
    exit 1
fi

case "$TARGET" in
    c|client)
        if [ -z "${CLIENT_IP:-}" ]; then
            echo "CLIENT_IP not defined in .env"
            exit 1
        fi
        HOST="$CLIENT_IP"
        ;;
    s|server)
        if [ -z "${SERVER_IP:-}" ]; then
            echo "SERVER_IP not defined in .env"
            exit 1
        fi
        HOST="$SERVER_IP"
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Usage: $0 [c|client|s|server]"
        exit 1
        ;;
esac

echo "SSHing into $HOST..."
ssh $SSH_OPTS $SSH_USER@"$HOST"
