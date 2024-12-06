#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

ACTION=${1:-}

if [ -z "$ACTION" ]; then
    echo -e "${YELLOW}Usage: $0 [setup|teardown]${RESET}"
    exit 1
fi

cd "$(dirname "$0")"

# Load env
if [ ! -f .env ]; then
    echo -e "${YELLOW}.env file not found. Copying from .env.template. Please fill your AWS creds.${RESET}"
    cp .env.template .env
    echo -e "${RED}Please edit .env with your AWS credentials and re-run.${RESET}"
    exit 1
fi

# shellcheck source=/dev/null
source .env

# Check AWS creds
if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ] || [ -z "${AWS_DEFAULT_REGION:-}" ]; then
    echo -e "${RED}AWS credentials not set in .env. Please set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION.${RESET}"
    exit 1
fi

# Ensure SSH key exists
if [ ! -f keys/id_rsa ]; then
    echo -e "${GREEN}Generating SSH key...${RESET}"
    mkdir -p keys
    ssh-keygen -t rsa -b 2048 -f ./keys/id_rsa -N "" > /dev/null
fi

# Common docker run environment arguments
ENV_ARGS=(-e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION")
if [ -n "${AWS_SESSION_TOKEN:-}" ]; then
    ENV_ARGS+=(-e AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN")
fi

confirm_action() {
    local prompt="$1"
    while true; do
        read -rp "$prompt (y/n): " response
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "${YELLOW}Please answer y or n.${RESET}" ;;
        esac
    done
}

if [ "$ACTION" = "setup" ]; then
    echo -e "${GREEN}Building Docker image for Terraform...${RESET}"
    docker build -t local-terraform:latest -f docker/Dockerfile.terraform .

    echo -e "${GREEN}Initializing Terraform...${RESET}"
    docker run --rm -it \
        -v "$(pwd)":/app \
        -w /app \
        "${ENV_ARGS[@]}" \
        local-terraform:latest \
        init

    echo -e "${GREEN}Validating Terraform configuration...${RESET}"
    docker run --rm -it \
        -v "$(pwd)":/app \
        -w /app \
        "${ENV_ARGS[@]}" \
        local-terraform:latest \
        validate

    echo -e "${GREEN}Generating Terraform plan...${RESET}"
    docker run --rm -it \
        -v "$(pwd)":/app \
        -w /app \
        "${ENV_ARGS[@]}" \
        local-terraform:latest \
        plan

    if confirm_action "${YELLOW}Do you want to proceed with applying the Terraform plan?${RESET}"; then
        echo -e "${GREEN}Applying Terraform...${RESET}"
        docker run --rm -it \
            -v "$(pwd)":/app \
            -w /app \
            "${ENV_ARGS[@]}" \
            local-terraform:latest \
            apply -auto-approve

        echo -e "${GREEN}Checking BBR support...${RESET}"
        ./check_bbr.sh
    else
        echo -e "${RED}Apply cancelled by user.${RESET}"
    fi

elif [ "$ACTION" = "teardown" ]; then
    if confirm_action "${YELLOW}Are you sure you want to destroy the infrastructure?${RESET}"; then
        echo -e "${GREEN}Destroying infrastructure...${RESET}"
        docker run --rm -it \
            -v "$(pwd)":/app \
            -w /app \
            "${ENV_ARGS[@]}" \
            local-terraform:latest \
            destroy -auto-approve
    else
        echo -e "${RED}Destroy cancelled by user.${RESET}"
    fi
else
    echo -e "${RED}Invalid action: $ACTION${RESET}"
    exit 1
fi
