#!/usr/bin/env python3

import os
import pandas as pd
import matplotlib.pyplot as plt
import sys


def traverse_results_dir(results_dir):
    """Traverse the results directory and collect paths to all `data-plane.csv` files."""
    experiment_data = []
    for root, dirs, files in os.walk(results_dir):
        if "data-plane.csv" in files:
            # Extract subdir names for labeling
            subdirs = os.path.relpath(root, results_dir).split(os.sep)
            label = "_".join(subdirs)  # e.g., "bbr_delay_20ms"
            file_path = os.path.join(root, "data-plane.csv")
            experiment_data.append((label, file_path))
    return experiment_data


def plot_aggregate_metrics(results_dir, aggregate_dir):
    """Generate aggregate plots for all metrics across experiments."""
    os.makedirs(aggregate_dir, exist_ok=True)

    # Collect all experiment data
    experiment_data = traverse_results_dir(results_dir)

    # Read the first data-plane.csv to get the metric names
    if not experiment_data:
        print("No data-plane.csv files found in the results directory.")
        return

    sample_data = pd.read_csv(experiment_data[0][1])
    metrics = [col for col in sample_data.columns if col != "timestamp"]

    # Prepare a plot for each metric
    for metric in metrics:
        plt.figure(figsize=(10, 6))
        for label, file_path in experiment_data:
            data = pd.read_csv(file_path)
            if metric in data.columns:
                plt.plot(data["timestamp"], data[metric], label=label)

        # Configure and save the plot
        plt.title(f"Aggregate {metric}")
        plt.xlabel("Timestamp")
        plt.ylabel(metric)
        plt.legend()
        plt.grid(True)
        output_file = os.path.join(aggregate_dir, f"{metric}.png")
        plt.savefig(output_file)
        plt.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: ./aggregate_metrics.py <results_dir>")
        sys.exit(1)

    results_dir = sys.argv[1]
    aggregate_dir = os.path.join(results_dir, "aggregate_plots")
    plot_aggregate_metrics(results_dir, aggregate_dir)
