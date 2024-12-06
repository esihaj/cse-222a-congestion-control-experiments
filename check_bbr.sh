#!/usr/bin/env bash
set -euo pipefail

SSH_OPTS="-i keys/id_rsa -o StrictHostKeyChecking=no"

SERVER_IP=$(docker run --rm \
    -v "$(pwd)":/app \
    -w /app \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_DEFAULT_REGION \
    local-terraform:latest \
    terraform output -raw server_public_ip)

CLIENT_IP=$(docker run --rm \
    -v "$(pwd)":/app \
    -w /app \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_DEFAULT_REGION \
    local-terraform:latest \
    terraform output -raw client_public_ip)

GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

check_host() {
    HOST=$1
    echo -e "${GREEN}[CHECK_BBR] Checking BBR on $HOST...${RESET}"
    AVAIL=$(ssh $SSH_OPTS ubuntu@$HOST "sysctl net.ipv4.tcp_available_congestion_control")
    echo "$AVAIL" | grep -q bbr || { echo -e "${RED}BBR not supported on $HOST${RESET}"; exit 1; }
}

check_host $SERVER_IP
check_host $CLIENT_IP

echo -e "${GREEN}BBR is supported on both server and client.${RESET}"
