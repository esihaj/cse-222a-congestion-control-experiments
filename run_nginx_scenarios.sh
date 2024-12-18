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


SCENARIOS=(
    # "cubic 0 0.0 results/cubic/standard"
    "cubic 20 0.0 results/cubic/delay_20ms"
    "cubic 20 0.005 results/cubic/delay_20ms_loss_0.005"
    "cubic 20 0.01 results/cubic/delay_20ms_loss_0.01"
    # "bbr 0 0.0 results/bbr/standard"
    "bbr 20 0.0 results/bbr/delay_20ms"
    "bbr 20 0.005 results/bbr/delay_20ms_loss_0.005"
    "bbr 20 0.01 results/bbr/delay_20ms_loss_0.01"
)


NGINX_BASE_RESULTS_DIR="results/nginx"

echo -e "\033[32m[RUN_EXPERIMENTS] Running nginx scenarios...\033[0m"

# Prepare directories for nginx results
mkdir -p "$NGINX_BASE_RESULTS_DIR"

echo -e "\033[31m[EXPERIMENTS] Check CPU utilization on client and server during the benchmark execution to make sure it is not the bottleneck.\033[0m"
echo "[RUN_EXPERIMENTS] Running benchmark_nginx.sh on client for each scenario..."

# Run nginx benchmark for each CCA scenario
for scenario in "${SCENARIOS[@]}"; do
    read -r CCA DELAY LOSS SCENARIO_DIR <<< "$scenario"

    # Create specific nginx results directory for the scenario
    NGINX_SCENARIO_DIR="$NGINX_BASE_RESULTS_DIR/$CCA/$(basename "$SCENARIO_DIR")"
    mkdir -p "$NGINX_SCENARIO_DIR"

    NGINX_SCENARIOS=(
        "-t 30 -c 900 -d 6s -r 30000 -o $NGINX_SCENARIO_DIR/conns_900_rps_30k.txt"
        "-t 30 -c 900 -d 6s -r 45000 -o $NGINX_SCENARIO_DIR/conns_900_rps_45k.txt"
        "-t 30 -c 900 -d 6s -r 50000 -o $NGINX_SCENARIO_DIR/conns_900_rps_50k.txt"
        # "-t 20 -c 40 -d 10s -r 4000 -o $NGINX_SCENARIO_DIR/conns_40_rps_4000.txt"
        # "-t 20 -c 40 -d 10s -r 6000 -o $NGINX_SCENARIO_DIR/conns_40_rps_6000.txt"
        # "-t 20 -c 40 -d 10s -r 8000 -o $NGINX_SCENARIO_DIR/conns_40_rps_8000.txt"
        # "-t 20 -c 40 -d 10s -r 10000 -o $NGINX_SCENARIO_DIR/conns_40_rps_10000.txt"
    )

    for nginx_scenario in "${NGINX_SCENARIOS[@]}"; do
        ssh $SSH_OPTS $SSH_USER@$CLIENT_IP "./benchmark_nginx.sh -u http://$SERVER_IP --cca $CCA --delay $DELAY --loss $LOSS $nginx_scenario"
    done
done

echo "[RUN_EXPERIMENTS] Fetching results..."
scp -r $SSH_OPTS $SSH_USER@$CLIENT_IP:"$NGINX_BASE_RESULTS_DIR" results/