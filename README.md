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

## Files

### configs and dependencies
- `.env.template` - Template for AWS credentials and configuration. Copy this to `.env` and fill in your details.
- `requirements.txt` - Lists Python dependencies for generating graphs locally.
- `iperf3_plotter/` - Directory for the `iperf3_plotter` repository, used for plotting results.

### High level scripts
- `check_bbr.sh` - Ensures BBR is supported on both server and client.
- `setup_all_hosts.sh` - Installs dependencies and configures the remote hosts.
- `run_experiments.sh` - Runs all the defined scenarios and fetches results.
- `ssh.sh` - provides easy ssh access to the client and server
- `iperf3_plotter.sh` - Clones and installs the `iperf3_plotter` repository and plots all iperf3 results.

### Internal scripts
- `run_scenario.sh` - Runs a single experiment scenario.
- `scripts/` - Contains various scripts used in the experiments:
  - `setup_host.sh` - Sets up a single host with necessary dependencies.
  - `remote_runner.sh` - Manages the initialization and execution phases on remote hosts.
  - `parse_ss_metrics.sh` - Parses `ss` metrics and generates CSV files.
  - `ss_to_csv.sh` - Converts `ss` output to CSV format.
  - `plot_ss.py` - Generates graphs from CSV files.

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

