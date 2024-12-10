# Network Congestion Control Experiment

This repository sets up an AWS-based testbed to compare different TCP congestion control algorithms (CUBIC and BBR) under various network conditions (delay, loss).

## Prerequisites

- Docker installed locally.
- AWS credentials (Access Key, Secret Key, and optionally Session Token) that can launch EC2 instances.

## Setup

0. setup 2 hosts (on AWS).

1. Copy `.env.template` to `.env` and insert your host ip, ssh user, and ssh key path:
   ```bash
   cp .env.template .env
   vi .env  # Insert AWS credentials, including AWS_SESSION_TOKEN if using temporary credentials
   ```
2. Run `pip install -r requirements.txt` to install the dependencies to generate the graphs locally.
3. Run `./setup_all_hosts.sh` to install dependencies on the remote hosts and configure them.
4. Run `./check_bbr.sh` to make sure bbr is supported on the hosts.

5. Run the experiments:
   ```bash
   ./run_experiments.sh
   ```
   
   This will:
   - Run various scenarios with CUBIC and BBR
   - Introduce delay and packet loss
   - Automatically fetch results back into the local `results/` directory
   - parse ss metrics into csv files
   - plot csv files

6. Remember to teardown the infra after the experiments.

## What is netem?

`netem` is a Linux kernel module that provides network emulation functions. It allows you to introduce artificial delay, packet loss, duplication, corruption, and reordering into the network. It's commonly used for testing applications under adverse network conditions.

## Project Files Overview

### Configuration and Dependencies
- `.env.template` - Template for AWS credentials and configuration. Copy and fill in `.env`.
- `requirements.txt` - Python dependencies for local graph generation.

### High-Level Scripts
- `check_bbr.sh` - Checks if BBR congestion control is available on both server and client.
- `setup_all_hosts.sh` - Installs dependencies and configures the remote hosts once they are ready.
- `run_experiments.sh` - Runs all defined scenarios and retrieves results.
- `run_nginx_scenarios.sh` - Runs Nginx-based scenarios for testing web server performance.
- `run_scenario.sh` - Executes a single scenario (one configuration of delay, loss, and CCA).
- `iperf3_plotter.sh` - Installs and runs the `iperf3_plotter` tool to visualize iperf3 results.
- `ssh.sh` - Provides convenient SSH access to the server or client machines.

### Scripts Directory
- `scripts/adjust_csv_timestamps.sh` - Aligns timestamps in CSV files for consistent comparisons.
- `scripts/benchmark_nginx.sh` - Benchmarks Nginx performance under different conditions.
- `scripts/clean_generated_results.sh` - Cleans up generated results files.
- `scripts/configure_network.sh` - Configures network parameters (e.g., delay, loss) on remote hosts.
- `scripts/nginx_ss_to_csv.sh` - Converts `ss` output from Nginx scenarios into CSV format.
- `scripts/parse_ss_metrics.sh` - Parses `ss` metrics log files into a more structured format.
- `scripts/plot_aggregate_metrics.py` - Generates aggregate performance metrics graphs.
- `scripts/plot_fairness.py` - Plots fairness metrics between flows.
- `scripts/plot_nginx.py` - Plots performance metrics related to the Nginx scenarios.
- `scripts/plot_ss.py` - Creates graphs from `ss` metric CSV files.
- `scripts/remote_runner.sh` - Handles initialization and run phases on remote hosts (server/client).
- `scripts/remote_setup.sh` - Additional setup tasks run on remote hosts before experiments.
- `scripts/setup_host.sh` - Installs required packages and configures a single remote host.
- `scripts/setup_nginx.sh` - Installs and configures Nginx on the remote host.
- `scripts/setup_wrk2_deathstarbench.sh` - Installs wrk2 and DeathStarBench tools for load testing.
- `scripts/setup_wrk2.sh` - Installs wrk2 load generator.
- `scripts/slow_ss_to_csv.sh` - Converts slower paced `ss` measurements to CSV format.
- `scripts/ss_to_csv.sh` - Converts `ss` outputs to CSV for analysis.


## Results

Results are stored in the `results/` directory. Each scenario has its own sub-directory with the following files:

- `ss_metrics.log` - Log file containing congestion window and slow start threshold metrics.
- `data-plane.txt` - Log file containing data plane metrics.
- `data-plane.csv` - CSV file containing data plane metrics in a structured format.
- `plot/` - Directory containing generated plots from the experiment data.

- `iperf3_output.json` - JSON output from iperf3, containing detailed performance metrics.

- `control-plane.txt` - Log file containing control plane metrics.
- `control-plane.csv` - SV file containing control plane metrics in a structured format.
- `iface.txt` - ignore - Text file containing the network interface used during the experiment.

