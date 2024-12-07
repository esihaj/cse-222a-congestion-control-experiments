#!/usr/bin/env bash
set -euo pipefail

GREEN="\e[32m"
RESET="\e[0m"

echo -e "${GREEN}Updating packages and checking dependencies...${RESET}"

# Define required packages
REQUIRED_PACKAGES=("iperf3" "jq" "curl" "iproute2" "moreutils")

# Check for missing packages using dpkg-query
MISSING_PACKAGES=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "^install ok installed$"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

# Install missing packages if any
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "The following packages are missing and will be installed: ${MISSING_PACKAGES[*]}"
    sudo apt-get update -y
    sudo apt-get install -y "${MISSING_PACKAGES[@]}"
else
    echo "All required packages are already installed."
fi

# Ensure sudoers entry for "ubuntu" exists
SUDOERS_FILE="/etc/sudoers.d/99_ubuntu"
if [ -f "$SUDOERS_FILE" ]; then
    echo "Sudoers entry for 'ubuntu' already exists. Skipping."
else
    echo "Adding sudoers entry for 'ubuntu'..."
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 440 "$SUDOERS_FILE"
fi

# Load tcp_bbr module only if not already loaded
if lsmod | grep -qw "tcp_bbr"; then
    echo "tcp_bbr module is already loaded."
else
    echo "Loading tcp_bbr module..."
    sudo modprobe tcp_bbr
fi

# Set sysctl parameter idempotently
# https://sysctl-explorer.net/net/ipv4/tcp_no_metrics_save/
sudo sysctl -w net.ipv4.tcp_no_metrics_save=1 
echo "Setting sysctl parameter net.ipv4.tcp_no_metrics_save=1"

# Get the default congestion control algorithm
DEFAULT_CC=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
echo -e "${GREEN}Host setup complete. Default congestion control: $DEFAULT_CC${RESET}"
