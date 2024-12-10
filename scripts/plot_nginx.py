#!/usr/bin/env python3

import os
import re
import argparse
import matplotlib.pyplot as plt

def parse_latency(value):
    """Parses and converts latency values to seconds."""
    if value.endswith('ms'):
        return float(value.replace('ms', '')) / 1000  # Convert milliseconds to seconds
    elif value.endswith('s'):
        return float(value.replace('s', ''))  # Seconds, no conversion needed
    elif value.endswith('m'):
        return float(value.replace('m', '')) * 60  # Convert minutes to seconds
    else:
        raise ValueError(f"Unknown latency unit in value: {value}")

def extract_metrics(file_path):
    """Extracts Requests/sec and Latency from a given file."""
    requests_sec = None
    latency = None

    with open(file_path, 'r') as file:
        for line in file:
            if "Requests/sec:" in line:
                requests_sec = float(line.split()[1])
            elif "Latency" in line and "Thread Stats" not in line:
                latency_value = line.split()[1]
                try:
                    latency = parse_latency(latency_value)
                except ValueError as e:
                    print(f"Warning: {e} in file {file_path}")

    return requests_sec, latency

def gather_metrics(results_dir):
    """Gathers metrics from the directory structure."""
    data = {}

    for root, _, files in os.walk(results_dir):
        for file in files:
            if file.startswith("conns_") and file.endswith(".txt"):
                file_path = os.path.join(root, file)

                # Extract the subdirectory structure as the label (e.g., bbr_delay_20ms)
                relative_path = os.path.relpath(root, results_dir)
                subdir_label = relative_path.replace(os.sep, '_')

                # Extract RPS from filename (e.g., conns_40_rps_10000.txt -> 10000)
                match = re.search(r"rps_(\d+)", file)
                if not match:
                    continue

                rps = int(match.group(1))

                # Extract metrics
                requests_sec, latency = extract_metrics(file_path)

                if requests_sec is not None and latency is not None:
                    if subdir_label not in data:
                        data[subdir_label] = []
                    data[subdir_label].append((rps, requests_sec, latency))

    # Sort each subdir's data by RPS for consistent plotting
    for subdir_label in data:
        data[subdir_label].sort(key=lambda x: x[0])

    return data

def plot_metrics(data, output_file="output_graphs.png"):
    """Plots the gathered metrics and saves to a file."""
    plt.figure(figsize=(12, 6))

    # Plot Requests/sec
    plt.subplot(2, 1, 1)
    for subdir_label, metrics in data.items():
        if metrics:  # Check if there are valid data points
            rps_values = [item[0] for item in metrics]
            requests_sec_values = [item[1] for item in metrics]
            plt.plot(rps_values, requests_sec_values, marker='o', label=subdir_label)

    plt.title("Requests/sec vs RPS")
    plt.xlabel("RPS")
    plt.ylabel("Requests/sec")
    plt.legend(loc="best")
    plt.grid()

    # Plot Latency
    plt.subplot(2, 1, 2)
    for subdir_label, metrics in data.items():
        if metrics:  # Check if there are valid data points
            rps_values = [item[0] for item in metrics]
            latency_values = [item[2] for item in metrics]
            plt.plot(rps_values, latency_values, marker='o', label=subdir_label)

    plt.title("Latency vs RPS")
    plt.xlabel("RPS")
    plt.ylabel("Latency (s)")
    plt.legend(loc="best")
    plt.grid()

    plt.tight_layout()

    # Save the figure to a file
    plt.savefig(output_file)
    print(f"Graphs saved to {output_file}")
    plt.close()

def main():
    parser = argparse.ArgumentParser(description="Gather metrics and plot graphs.")
    parser.add_argument("results_dir", type=str, help="Path to the results directory.")
    parser.add_argument(
        "--output", type=str, default="output_graphs.png",
        help="Path to save the output graphs (default: output_graphs.png)."
    )
    args = parser.parse_args()

    data = gather_metrics(args.results_dir)
    plot_metrics(data, args.output)

if __name__ == "__main__":
    main()
