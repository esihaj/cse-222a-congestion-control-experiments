#!/usr/bin/env bash
set -euo pipefail

GREEN="\e[32m"
RESET="\e[0m"

echo -e "${GREEN}Updating packages and installing dependencies...${RESET}"
sudo apt-get update -y
sudo apt-get install -y iperf3 jq curl iproute2 moreutils

echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99_ubuntu
sudo chmod 440 /etc/sudoers.d/99_ubuntu

sudo modprobe tcp_bbr
# https://sysctl-explorer.net/net/ipv4/tcp_no_metrics_save/
sudo sysctl -w net.ipv4.tcp_no_metrics_save=1 

DEFAULT_CC=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
echo -e "${GREEN}Host setup complete. Default congestion control: $DEFAULT_CC${RESET}"
