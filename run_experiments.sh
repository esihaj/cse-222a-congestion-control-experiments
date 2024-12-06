#!/usr/bin/env bash
set -euo pipefail

SSH_OPTS="-i keys/id_rsa -o StrictHostKeyChecking=no"

cd "$(dirname "$0")"

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
RESET="\e[0m"

echo -e "${GREEN}[RUN_EXPERIMENTS] Copying scripts to remote hosts...${RESET}"
scp $SSH_OPTS scripts/setup_host.sh ubuntu@$SERVER_IP:setup_host.sh
scp $SSH_OPTS scripts/setup_host.sh ubuntu@$CLIENT_IP:setup_host.sh
ssh $SSH_OPTS ubuntu@$SERVER_IP "chmod +x setup_host.sh && ./setup_host.sh"
ssh $SSH_OPTS ubuntu@$CLIENT_IP "chmod +x setup_host.sh && ./setup_host.sh"

scp $SSH_OPTS scripts/remote_setup.sh ubuntu@$SERVER_IP:remote_setup.sh
scp $SSH_OPTS scripts/remote_setup.sh ubuntu@$CLIENT_IP:remote_setup.sh
ssh $SSH_OPTS ubuntu@$SERVER_IP "chmod +x remote_setup.sh && ./remote_setup.sh"
ssh $SSH_OPTS ubuntu@$CLIENT_IP "chmod +x remote_setup.sh && ./remote_setup.sh"

scp $SSH_OPTS scripts/remote_runner.sh ubuntu@$SERVER_IP:remote_runner.sh
scp $SSH_OPTS ubuntu@$CLIENT_IP:remote_runner.sh
ssh $SSH_OPTS ubuntu@$SERVER_IP "chmod +x remote_runner.sh"
ssh $SSH_OPTS ubuntu@$CLIENT_IP "chmod +x remote_runner.sh"

scp $SSH_OPTS scripts/run_scenario.sh ubuntu@$CLIENT_IP:run_scenario.sh
ssh $SSH_OPTS ubuntu@$CLIENT_IP "chmod +x run_scenario.sh"

echo -e "${GREEN}[RUN_EXPERIMENTS] Running scenarios...${RESET}"

SCENARIOS=(
    "cubic 0 0.0 results/cubic/standard"
    "cubic 20 0.0 results/cubic/delay_20ms"
    "cubic 20 0.005 results/cubic/delay_20ms_loss_0.005"
    "cubic 20 0.01 results/cubic/delay_20ms_loss_0.01"
    "bbr 0 0.0 results/bbr/standard"
    "bbr 20 0.0 results/bbr/delay_20ms"
    "bbr 20 0.005 results/bbr/delay_20ms_loss_0.005"
    "bbr 20 0.01 results/bbr/delay_20ms_loss_0.01"
)

for scenario in "${SCENARIOS[@]}"; do
    # run_scenario.sh: CCA DELAY LOSS RESULT_DIR
    # We pass SERVER_IP, CLIENT_IP first
    ssh $SSH_OPTS ubuntu@$CLIENT_IP "./run_scenario.sh $SERVER_IP $CLIENT_IP $scenario"
done

echo -e "${GREEN}[RUN_EXPERIMENTS] All scenarios completed. Fetching results...${RESET}"

# Fetch all results from both server and client
LOCAL_RESULTS_DIR="results"
mkdir -p "$LOCAL_RESULTS_DIR"

# We know the directories from SCENARIOS, so fetch them
for scenario in "${SCENARIOS[@]}"; do
    PARTS=($scenario)
    CCA=${PARTS[0]}
    DELAY=${PARTS[1]}
    LOSS=${PARTS[2]}
    REMOTE_DIR=${PARTS[3]}

    # Fetch from client
    mkdir -p "$LOCAL_RESULTS_DIR/$CCA"
    scp -r $SSH_OPTS ubuntu@$CLIENT_IP:"$REMOTE_DIR" "$LOCAL_RESULTS_DIR/$CCA/"
    # Fetch from server
    scp -r $SSH_OPTS ubuntu@$SERVER_IP:"$REMOTE_DIR" "$LOCAL_RESULTS_DIR/$CCA/"
done

echo -e "${GREEN}[RUN_EXPERIMENTS] Results are now in the local results/ directory.${RESET}"
