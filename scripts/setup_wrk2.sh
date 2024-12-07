#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables
WRK2_REPO="https://github.com/giltene/wrk2.git"
WRK2_DIR="$HOME/wrk2"
REQUIRED_PACKAGES=("build-essential" "libssl-dev" "git" "zlib1g-dev")

# Function to check if a package is installed
is_package_installed() {
    dpkg -l | grep -qw "$1"
}

# Check for missing packages
MISSING_PACKAGES=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! is_package_installed "$pkg"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

# Install missing packages if any
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "The following packages are missing and will be installed: ${MISSING_PACKAGES[*]}"
    sudo apt update
    sudo apt install -y "${MISSING_PACKAGES[@]}"
else
    echo "All required packages are already installed."
fi

# Clone the wrk2 repository if it doesn't already exist
echo "Checking for the wrk2 repository..."
if [ -d "$WRK2_DIR" ]; then
    echo "wrk2 repository already cloned at $WRK2_DIR. Skipping cloning."
else
    echo "Cloning the wrk2 repository..."
    git clone "$WRK2_REPO" "$WRK2_DIR"
fi

# Build wrk2
echo "Building wrk2..."
cd "$WRK2_DIR"
make -j

# Add wrk2 to the system PATH
echo "Adding wrk2 to PATH..."
if ! command -v wrk &> /dev/null; then
    sudo ln -sf "$WRK2_DIR/wrk" /usr/local/bin/wrk
else
    echo "wrk2 is already in the PATH."
fi

# Output success message
echo "wrk2 has been successfully installed and added to your PATH."
echo "You can run wrk2 using the 'wrk' command."