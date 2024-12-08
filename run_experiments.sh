#!/usr/bin/env bash
set -euo pipefail

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


# Clear old results on remote hosts
echo "[RUN_EXPERIMENTS] Clearing out old results on server..."
ssh $SSH_OPTS $SSH_USER@$SERVER_IP "rm -rf results || true"

echo "[RUN_EXPERIMENTS] Clearing out old results on client..."
ssh $SSH_OPTS $SSH_USER@$CLIENT_IP "rm -rf results || true"

scp $SSH_OPTS scripts/remote_runner.sh $SSH_USER@$SERVER_IP:remote_runner.sh
ssh $SSH_OPTS $SSH_USER@$SERVER_IP "chmod +x remote_runner.sh"

scp $SSH_OPTS scripts/{remote_runner.sh,configure_network.sh,benchmark_nginx.sh} $SSH_USER@$CLIENT_IP:
ssh $SSH_OPTS $SSH_USER@$CLIENT_IP "chmod +x remote_runner.sh configure_network.sh benchmark_nginx.sh"

#remove results dir 
echo "[RUN_EXPERIMENTS] Clearing out old local results..."
rm -rf results

echo "[RUN_EXPERIMENTS] Running scenarios..."

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

DURATION=30

for scenario in "${SCENARIOS[@]}"; do
    ./run_scenario.sh "$SERVER_IP" "$CLIENT_IP" $scenario $DURATION
    echo "----------------------------------------------------------"
    echo "----------------------------------------------------------"
done



./run_nginx_scenarios.sh

echo "[RUN_EXPERIMENTS] All scenarios complete. Results are in results/."
