#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="$1"
CLIENT_IP="$2"
CCA="$3"
DELAY="$4"
LOSS="$5"
RESULT_DIR="$6"

SSH_OPTS="-i keys/id_rsa -o StrictHostKeyChecking=no"
GREEN="\e[32m"
RESET="\e[0m"
DURATION=30

echo -e "${GREEN}[RUN_SCENARIO] Running scenario CCA=$CCA DELAY=${DELAY}ms LOSS=${LOSS}%${RESET}"

IFACE=$(ssh $SSH_OPTS ubuntu@"$CLIENT_IP" "ip route get 1.1.1.1 | grep -oP 'dev \\K\\S+'")
echo -e "${GREEN}[RUN_SCENARIO] Detected client interface: $IFACE${RESET}"

# Start iperf3 server
ssh $SSH_OPTS ubuntu@"$SERVER_IP" "pkill iperf3 || true"
ssh $SSH_OPTS ubuntu@"$SERVER_IP" "mkdir -p $RESULT_DIR"
ssh $SSH_OPTS ubuntu@"$SERVER_IP" "bash remote_runner.sh $CCA server $CLIENT_IP $DURATION $DELAY $LOSS $RESULT_DIR $IFACE" &

sleep 5

# Run client test
ssh $SSH_OPTS ubuntu@"$CLIENT_IP" "pkill iperf3 || true"
ssh $SSH_OPTS ubuntu@"$CLIENT_IP" "mkdir -p $RESULT_DIR"
ssh $SSH_OPTS ubuntu@"$CLIENT_IP" "bash remote_runner.sh $CCA client $SERVER_IP $DURATION $DELAY $LOSS $RESULT_DIR $IFACE"

echo -e "${GREEN}[RUN_SCENARIO] Scenario completed. Results in $RESULT_DIR on remote hosts${RESET}"
