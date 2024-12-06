#!/usr/bin/env bash
set -euo pipefail

GREEN="\e[32m"
RESET="\e[0m"

echo -e "${GREEN}Updating packages and installing dependencies...${RESET}"
sudo apt-get update -y
sudo apt-get install -y iperf3 jq curl iproute2

echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99_ubuntu
sudo chmod 440 /etc/sudoers.d/99_ubuntu

sudo sysctl -w net.core.default_qdisc=fq
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic

DEFAULT_CC=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
echo -e "${GREEN}Host setup complete. Default congestion control: $DEFAULT_CC${RESET}"
