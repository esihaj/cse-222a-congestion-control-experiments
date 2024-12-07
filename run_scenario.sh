#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="$1"
CLIENT_IP="$2"
CCA="$3"
DELAY="$4"
LOSS="$5"
RESULT_DIR="$6"
DURATION=$7

echo "duration: $DURATION"

GREEN="\e[32m"
RESET="\e[0m"


if [ ! -f .env ]; then
    echo "No .env file found. Please create one with SERVER_IP and CLIENT_IP."
    exit 1
fi

source .env

if [ -z "${SERVER_IP:-}" ] || [ -z "${CLIENT_IP:-}" ]; then
    echo "SERVER_IP or CLIENT_IP not set in .env."
    exit 1
fi

SSH_USER="${SSH_USER:-ubuntu}"
SSH_KEY_PATH="${SSH_KEY_PATH:-~/.ssh/id_rsa}"
SSH_OPTS="-i $SSH_KEY_PATH -o StrictHostKeyChecking=no"

echo -e "${GREEN}[RUN_SCENARIO] Starting scenario: CCA=$CCA, DELAY=${DELAY}ms, LOSS=${LOSS}%${RESET}"

# Init phase on both server and client
ssh $SSH_OPTS $SSH_USER@"$SERVER_IP" "./remote_runner.sh server init $RESULT_DIR"
ssh $SSH_OPTS $SSH_USER@"$CLIENT_IP" "./remote_runner.sh client init $RESULT_DIR"

# Run server (start iperf3 server)
ssh $SSH_OPTS $SSH_USER@"$SERVER_IP" "./remote_runner.sh server run $CCA $CLIENT_IP $DURATION $DELAY $LOSS $RESULT_DIR"

# Run client (configure netem, run iperf3 client, gather metrics)
ssh $SSH_OPTS $SSH_USER@"$CLIENT_IP" "./remote_runner.sh client run $CCA $SERVER_IP $DURATION $DELAY $LOSS $RESULT_DIR"

echo -e "${GREEN}[RUN_SCENARIO] Scenario complete. Fetching results...${RESET}"
mkdir -p "$(dirname "$RESULT_DIR")"
scp -r $SSH_OPTS $SSH_USER@$CLIENT_IP:"$RESULT_DIR" $(dirname "$RESULT_DIR")/
scp -r $SSH_OPTS $SSH_USER@$SERVER_IP:"$RESULT_DIR" $(dirname "$RESULT_DIR")/

echo -e "${GREEN}[RUN_SCENARIO] Results fetched into $RESULT_DIR locally${RESET}"

./scripts/parse_ss_metrics.sh $RESULT_DIR/ss_metrics.log $RESULT_DIR
