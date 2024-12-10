#!/usr/bin/env python3

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import argparse

def calculate_fairness(data_dir):
    csv_files = [f for f in os.listdir(data_dir) if f.endswith('.csv') and 'control-plane' not in f and f not in ['fairness.csv', 'aggregate_flows.csv']]
    if not csv_files:
        print(f"No CSV files to process in {data_dir}.")
        return None

    results = []
    send_rates = []
    total_bytes_sent = 0
    all_data = pd.DataFrame()

    for i, csv_file in enumerate(csv_files, start=1):
        csv_path = os.path.join(data_dir, csv_file)
        data = pd.read_csv(csv_path)

        required_columns = {'timestamp', 'send', 'delivery_rate', 'rtt', 'bytes_sent'}
        missing_columns = required_columns - set(data.columns)
        if missing_columns:
            print(f"Error in file {csv_file}: Missing required columns.")
            print(f"Expected columns: {required_columns}")
            print(f"Found columns: {set(data.columns)}")
            continue

        all_data = pd.concat([all_data, data])

        # Calculate per-flow metrics
        max_bytes_sent = data['bytes_sent'].iloc[-1]
        total_bytes_sent += max_bytes_sent
        avg_send_rate = data['send'].mean()
        avg_delivery_rate = data['delivery_rate'].mean()
        avg_rtt = data['rtt'].mean()
        p99_rtt = np.percentile(data['rtt'].dropna(), 99)

        send_rates.append(avg_send_rate)
        results.append({
            "Flow Number": f"Flow {i}",
            "Max Bytes Sent": max_bytes_sent,
            "Avg Send Rate (bps)": avg_send_rate,
            "Avg Delivery Rate (bps)": avg_delivery_rate,
            "Avg RTT (ms)": avg_rtt,
            "P99 RTT (ms)": p99_rtt,
        })

    # Calculate Jain Fairness Index
    if send_rates:
        numerator = sum(send_rates) ** 2
        denominator = len(send_rates) * sum([rate ** 2 for rate in send_rates])
        jain_fairness_index = numerator / denominator if denominator != 0 else 0
    else:
        jain_fairness_index = None

    for result in results:
        result["Jain Fairness Index"] = jain_fairness_index

    # Save fairness details
    fairness_file = os.path.join(data_dir, "fairness.csv")
    fairness_df = pd.DataFrame(results)
    fairness_df.to_csv(fairness_file, index=False)
    print(f"Saved fairness details to {fairness_file}")

    # Calculate aggregate metrics
    if not all_data.empty:
        scenario_name = os.path.basename(data_dir)
        total_bytes_sent_gb = total_bytes_sent / (1024 ** 3)  # Convert bytes to GB
        avg_send_rate_mbps = all_data['send'].mean() / (10 ** 6)  # Convert bps to Mbps
        avg_delivery_rate_mbps = all_data['delivery_rate'].mean() / (10 ** 6)  # Convert bps to Mbps
        avg_rtt = all_data['rtt'].mean()
        p99_rtt = np.percentile(all_data['rtt'].dropna(), 99)

        aggregate_data = {
            "Scenario Name": scenario_name,
            "Total Bytes Sent (GB)": total_bytes_sent_gb,
            "Avg Send Rate (Mbps)": avg_send_rate_mbps,
            "Avg Delivery Rate (Mbps)": avg_delivery_rate_mbps,
            "Avg RTT (ms)": avg_rtt,
            "P99 RTT (ms)": p99_rtt,
        }

        aggregate_file = os.path.join(data_dir, "aggregate_flows.csv")
        pd.DataFrame([aggregate_data]).to_csv(aggregate_file, index=False)
        print(f"Saved aggregate metrics to {aggregate_file}")

def plot_column(data_dir, column_name, output_dir):
    csv_files = [f for f in os.listdir(data_dir) if f.endswith('.csv') and 'control-plane' not in f and f not in ['fairness.csv', 'aggregate_flows.csv']]
    if not csv_files:
        print(f"No CSV files to process in {data_dir}.")
        return

    plt.figure(figsize=(10, 6), dpi=300)

    for i, csv_file in enumerate(csv_files, start=1):
        csv_path = os.path.join(data_dir, csv_file)
        data = pd.read_csv(csv_path)

        required_columns = {'timestamp', column_name}
        missing_columns = required_columns - set(data.columns)
        if missing_columns:
            print(f"Error in file {csv_file}: Missing required columns.")
            print(f"Expected columns: {required_columns}")
            print(f"Found columns: {set(data.columns)}")
            continue

        plt.plot(data['timestamp'], data[column_name], label=f"Flow {i}")

    plt.xlabel('Time (s)')
    plt.ylabel(column_name.replace('_', ' ').capitalize())
    plt.title(f"{column_name.replace('_', ' ').capitalize()} Over Time")
    plt.legend()
    plt.grid(True)

    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, f"{column_name}.png")
    plt.savefig(output_file)
    plt.close()
    print(f"Saved plot to {output_file}")

def process_directory(results_dir):
    for root, dirs, files in os.walk(results_dir):
        if any(f.endswith('.csv') for f in files):
            rel_path = os.path.relpath(root, results_dir)
            output_dir = os.path.join(root, 'plot')

            print(f"Processing directory: {rel_path}")
            calculate_fairness(root)
            plot_column(root, 'send', output_dir)
            plot_column(root, 'delivery_rate', output_dir)

def main():
    parser = argparse.ArgumentParser(description="Plot send and delivery_rate from CSV files and calculate fairness and aggregate metrics.")
    parser.add_argument('results_dir', type=str, help="Path to the results directory.")
    args = parser.parse_args()

    results_dir = args.results_dir

    if not os.path.exists(results_dir):
        print(f"Error: Directory {results_dir} does not exist.")
        return

    process_directory(results_dir)

if __name__ == "__main__":
    main()
