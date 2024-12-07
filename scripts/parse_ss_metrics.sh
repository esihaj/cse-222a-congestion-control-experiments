#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_dir>"
    exit 1
fi

# Input file and output directory
input_file="$1"
output_dir="$2"

# Ensure the output directory exists
mkdir -p "$output_dir"

# Create a plot directory inside the output directory
plot_dir="${output_dir}/plot"
mkdir -p "$plot_dir"

# Temporary file to store unique src_ip:port values
temp_src_ports=$(mktemp)

# Extract unique src_ip:port values (the first part of two ip:port pairs)
grep -oP '\d+\.\d+\.\d+\.\d+:\d+\s+\d+\.\d+\.\d+\.\d+:\d+' "$input_file" | awk '{print $1}' | sort | uniq > "$temp_src_ports"

# Variables to store file paths and bytes_sent values
txt_files=()
bytes_sent_values=()

# Define helper scripts
ss_to_csv=$(dirname "${BASH_SOURCE[0]}")/ss_to_csv.sh
adjust_timestamp=$(dirname "${BASH_SOURCE[0]}")/adjust_csv_timestamps.sh
plot_ss=$(dirname "${BASH_SOURCE[0]}")/plot_ss.py

# Process each src_ip:port value
while IFS= read -r src_port; do
    # Create a file named after the src_ip:port value in the output directory
    output_file="${output_dir}/${src_port//:/_}.txt"
    txt_files+=("$output_file")

    # Extract only the detail lines following the src_ip:port line
    awk -v src="$src_port" '
        $0 ~ src {getline; print}
    ' "$input_file" > "$output_file"

    echo "Extracted detail data for $src_port into $output_file"

    # Convert the TXT file to CSV and adjust timestamps inline
    temp_csv=$(mktemp)
    "$ss_to_csv" "$output_file" "$temp_csv"
    adjusted_csv="${output_file%.txt}.csv"
    "$adjust_timestamp" "$temp_csv" "$adjusted_csv"
    rm "$temp_csv"

    # Extract the bytes_sent value from the adjusted CSV
    bytes_sent=$(awk -F',' 'NR > 1 {print $5}' "$adjusted_csv" | awk '{sum += $1} END {print sum}')
    bytes_sent_values+=("$bytes_sent")
done < "$temp_src_ports"

echo "================="

# Compare bytes_sent values and rename files
if (( bytes_sent_values[0] < bytes_sent_values[1] )); then
    mv "${txt_files[0]}" "${output_dir}/control-plane.txt"
    mv "${txt_files[1]}" "${output_dir}/data-plane.txt"
    mv "${txt_files[0]%.txt}.csv" "${output_dir}/control-plane.csv"
    mv "${txt_files[1]%.txt}.csv" "${output_dir}/data-plane.csv"

    echo "${txt_files[0]} -> control-plane"
    echo "${txt_files[1]} -> data-plane"
else
    mv "${txt_files[1]}" "${output_dir}/control-plane.txt"
    mv "${txt_files[0]}" "${output_dir}/data-plane.txt"
    mv "${txt_files[1]%.txt}.csv" "${output_dir}/control-plane.csv"
    mv "${txt_files[0]%.txt}.csv" "${output_dir}/data-plane.csv"

    echo "${txt_files[1]} -> control-plane"
    echo "${txt_files[0]} -> data-plane"
fi

# Run ./plot_ss.py on the data-plane.csv file
data_plane_csv="${output_dir}/data-plane.csv"
if [[ -f "$data_plane_csv" ]]; then
    "$plot_ss" "$data_plane_csv" "$plot_dir"
    echo "Plots generated in $plot_dir"
else
    echo "Error: data-plane.csv not found!"
fi

# Clean up temporary file
rm "$temp_src_ports"
