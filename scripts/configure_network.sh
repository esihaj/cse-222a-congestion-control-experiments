#!/usr/bin/env bash
set -euo pipefail

IFACE="$1"
CCA="$2"
DELAY="$3"
LOSS="$4"

# Set the congestion control algorithm
echo -e "\e[32m[CONFIGURE_NETWORK] Setting CCA to $CCA\e[0m"
sudo sysctl -w net.ipv4.tcp_congestion_control="$CCA"

# Clear existing qdisc (ignore error if no qdisc)
echo -e "\e[32m[CONFIGURE_NETWORK] Clearing existing qdisc on $IFACE\e[0m"
sudo tc qdisc del dev "$IFACE" root 2>/dev/null || true

# Apply netem settings for delay and loss if needed
if [ "$DELAY" != "0" ] || [ "$LOSS" != "0" ]; then
    NETEM_CMD="sudo tc qdisc add dev $IFACE root netem"
    if [ "$DELAY" != "0" ]; then
        NETEM_CMD="$NETEM_CMD delay ${DELAY}ms"
    fi
    if [ "$LOSS" != "0" ]; then
        NETEM_CMD="$NETEM_CMD loss ${LOSS}%"
    fi
    echo -e "\e[32m[CONFIGURE_NETWORK] Applying netem: $NETEM_CMD\e[0m"
    eval "$NETEM_CMD"
fi
