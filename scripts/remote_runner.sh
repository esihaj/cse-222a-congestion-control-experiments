#!/usr/bin/env bash
set -euo pipefail

CCA="$1"
ROLE="$2"
PEER_IP="$3"
DURATION="$4"
DELAY="$5"
LOSS="$6"
RESULT_DIR="$7"
IFACE="$8"

GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

echo -e "${GREEN}[REMOTE_RUNNER] Starting with CCA=$CCA ROLE=$ROLE PEER=$PEER_IP DELAY=${DELAY}ms LOSS=${LOSS}% IFACE=$IFACE ${RESET}"

sudo sysctl -w net.ipv4.tcp_congestion_control=$CCA

# Clear existing qdisc
sudo tc qdisc del dev "$IFACE" root || true

# Add netem if needed
if [ "$DELAY" != "0" ] || [ "$LOSS" != "0" ]; then
    NETEM_CMD="sudo tc qdisc add dev $IFACE root netem"
    if [ "$DELAY" != "0" ]; then
        NETEM_CMD="$NETEM_CMD delay ${DELAY}ms"
    fi
    if [ "$LOSS" != "0" ]; then
        NETEM_CMD="$NETEM_CMD loss ${LOSS}%"
    fi
    eval "$NETEM_CMD"
fi

mkdir -p "$RESULT_DIR"

if [ "$ROLE" = "server" ]; then
    echo -e "${GREEN}[REMOTE_RUNNER] Starting iperf3 server...${RESET}"
    pkill iperf3 || true
    nohup iperf3 -s > "$RESULT_DIR/iperf3_server.log" 2>&1 &
    exit 0
else
    echo -e "${GREEN}[REMOTE_RUNNER] Running iperf3 client test...${RESET}"
    pkill iperf3 || true
    iperf3 -c "$PEER_IP" -t "$DURATION" -J > "$RESULT_DIR/iperf3_output.json"

    for i in $(seq 1 "$DURATION"); do
        ss -i dst "$PEER_IP" >> "$RESULT_DIR/ss_cwnd_ssthresh.log" 2>&1 || true
        ping -c1 "$PEER_IP" | grep 'time=' >> "$RESULT_DIR/rtt.log" 2>&1 || true
        sleep 1
    done
fi
