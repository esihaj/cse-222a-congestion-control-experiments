#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import os
import sys


def plot_graph(x, y, x_label, y_label, title, output_file, labels=None):
    """Generates and saves a graph."""
    plt.figure(figsize=(10, 6))
    
    if isinstance(y, list) and labels:
        for yi, label in zip(y, labels):
            plt.plot(x, yi, label=label)
    else:
        plt.plot(x, y, label=y_label)
    
    plt.title(title)
    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.grid(True)
    plt.legend()
    plt.savefig(output_file)
    plt.close()


def plot_cwnd_ssthresh(data, x, output_dir):
    """Plots cwnd and ssthresh together."""
    if 'cwnd' in data.columns and 'ssthresh' in data.columns:
        y = [data['cwnd'], data['ssthresh']]
        labels = ['cwnd', 'ssthresh']
        output_file = os.path.join(output_dir, "cwnd_ssthresh.png")
        plot_graph(
            x=x,
            y=y,
            x_label="Timestamp",
            y_label="Values",
            title="cwnd and ssthresh",
            output_file=output_file,
            labels=labels,
        )


def plot_individual_columns(data, x, output_dir, exclude_columns):
    """Plots individual graphs for each column, excluding specified columns."""
    for column in data.columns:
        if column in exclude_columns:
            continue
        y = data[column]
        output_file = os.path.join(output_dir, f"{column}.png")
        plot_graph(
            x=x,
            y=y,
            x_label="Timestamp",
            y_label=column,
            title=f"{column}",
            output_file=output_file,
        )


def generate_graphs(input_file, output_dir):
    """Main function to generate graphs from a CSV file."""
    data = pd.read_csv(input_file)
    os.makedirs(output_dir, exist_ok=True)

    x = data['timestamp']  # Set timestamp as x-axis

    # Plot special case for cwnd and ssthresh
    plot_cwnd_ssthresh(data, x, output_dir)

    # Plot individual columns, excluding timestamp, cwnd, and ssthresh
    exclude_columns = {'timestamp', 'cwnd', 'ssthresh'}
    plot_individual_columns(data, x, output_dir, exclude_columns)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: ./plot.py <input_file> <output_dir>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = sys.argv[2]

    generate_graphs(input_file, output_dir)
