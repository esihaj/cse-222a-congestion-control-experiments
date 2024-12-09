#!/usr/bin/env bash
set -euo pipefail
echo -e "\e[32m[REMOTE_SETUP] Setting net sysctl parameters\e[0m"
sudo sysctl -w net.ipv4.tcp_no_metrics_save=1

# Set the TCP receive buffer sizes (min, default, max)
sudo sysctl -w net.ipv4.tcp_rmem='4096 33554432 67108864'

# Set the TCP send buffer sizes (min, default, max)
sudo sysctl -w net.ipv4.tcp_wmem='4096 33554432 67108864'

# Increase the system-wide max buffer sizes
sudo sysctl -w net.core.rmem_max=67108864
sudo sysctl -w net.core.wmem_max=67108864

# sudo sysctl -w net.ipv4.tcp_rmem='4096 2097152 8388608'
# sudo sysctl -w net.ipv4.tcp_wmem='4096 2097152 8388608'
# sudo sysctl -w net.core.rmem_max=8388608
# sudo sysctl -w net.core.wmem_max=8388608

# sudo sysctl -w net.ipv4.tcp_rmem='4096 1048576 6291456'
# sudo sysctl -w net.ipv4.tcp_wmem='4096 1048576 6291456'
# sudo sysctl -w net.core.rmem_max=6291456
# sudo sysctl -w net.core.wmem_max=6291456


exit 0
