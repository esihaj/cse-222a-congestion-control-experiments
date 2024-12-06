# Network Congestion Control Experiment

This repository sets up an AWS-based testbed to compare different TCP congestion control algorithms (CUBIC and BBR) under various network conditions (delay, loss).

## Prerequisites

- Docker installed locally.
- AWS credentials (Access Key, Secret Key, and optionally Session Token) that can launch EC2 instances.

## Setup

1. Copy `.env.template` to `.env` and insert your AWS credentials:
   ```bash
   cp .env.template .env
   vi .env  # Insert AWS credentials, including AWS_SESSION_TOKEN if using temporary credentials
   ```

2. Run `./infra.sh setup` to:
   - Build the Docker image for Terraform
   - Initialize and apply Terraform configuration
   - Launch AWS infrastructure (server and client instances)
   - Check BBR support

3. Run the experiments:
   ```bash
   ./run_experiments.sh
   ```
   
   This will:
   - Install dependencies on the hosts
   - Run various scenarios with CUBIC and BBR
   - Introduce delay and packet loss
   - Automatically fetch results back into the local `results/` directory

4. Destroy the infrastructure when done:
   ```bash
   ./infra.sh teardown
   ```

## What is netem?

`netem` is a Linux kernel module that provides network emulation functions. It allows you to introduce artificial delay, packet loss, duplication, corruption, and reordering into the network. It's commonly used for testing applications under adverse network conditions.

## Files

- `main.tf` - Terraform configuration (all-in-one)
- `infra.sh` - Sets up/tears down infra and runs `check_bbr.sh`
- `check_bbr.sh` - Ensures BBR is supported on both server and client
- `run_experiments.sh` - Runs all the defined scenarios and fetches results
- `scripts/` - Contains scripts copied to remote hosts and orchestrate scenarios
- `.env.template` - Template for AWS credentials
- `results/` - Results directory for storing scenario outputs

## Results

Results are stored in `results/`. Each scenario has its own sub-directory with:
- `iperf3_output.json`
- `ss_cwnd_ssthresh.log`
- `rtt.log`

## Cleanup

After finishing all experiments:
- `./infra.sh teardown` to remove AWS instances and save costs.
- Remove `.env` and keys if no longer needed.
