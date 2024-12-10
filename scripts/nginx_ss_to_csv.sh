#!/bin/bash

# Check if the correct number of arguments is provided
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <results_directory> [--skip-processing]"
    exit 1
fi

# Base directory containing results (from the command-line argument)
base_dir="$1"
skip_processing=false

# Check for the optional --skip-processing flag
if [[ $# -eq 2 && "$2" == "--skip-processing" ]]; then
    skip_processing=true
fi

# Path to scripts
ss_to_csv_script="scripts/ss_to_csv.sh"
plot_ss_script="scripts/plot_ss.py"

# Ensure the base directory exists
if [[ ! -d "$base_dir" ]]; then
    echo "Error: Directory $base_dir does not exist."
    exit 1
fi

# Ensure the required scripts exist and are executable
if [[ ! -x "$ss_to_csv_script" ]]; then
    echo "Error: ss_to_csv.sh not found or not executable at $ss_to_csv_script"
    exit 1
fi
if [[ ! -f "$plot_ss_script" ]]; then
    echo "Error: plot_ss.py not found at $plot_ss_script"
    exit 1
fi

# Iterate through all ss_metrics*.log files in the directory structure
find "$base_dir" -type f -name "ss_metrics*.log" | while read -r log_file; do
    # Extract the 10th ip:port in the file
    ip_port=$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' "$log_file" | sed -n '10p')
    
    # Skip if the 10th ip:port is not found
    if [[ -z "$ip_port" ]]; then
        echo "Less than 10 ip:port entries in $log_file, skipping..."
        continue
    fi

    # Extract the RPS from the file name
    rps=$(basename "$log_file" | grep -Eo 'rps_[0-9]+k' | sed 's/rps_//')

    # Create the output file names
    output_file_dir=$(dirname "$log_file")
    output_file="$output_file_dir/ss_${rps}_${ip_port//:/_}.txt"
    csv_output="$output_file_dir/ss_${rps}_${ip_port//:/_}.csv"
    plot_dir="$output_file_dir/plots"

    # Create the plot directory if it doesn't exist
    mkdir -p "$plot_dir"

    # If not skipping processing, generate the .txt and .csv files
    if [[ "$skip_processing" == false ]]; then
        grep -A1 "$ip_port" "$log_file" | grep -v "$ip_port" | grep -v "^--$" > "$output_file"

        echo "Processed $log_file, output written to $output_file"

        # Call ss_to_csv.sh on the resulting file
        "$ss_to_csv_script" "$output_file" "$csv_output"

        echo "Converted $output_file to CSV format at $csv_output"
    fi

    # Call plot_ss.py on the CSV file only if it's 45k rps
    if [[ "$rps" == "45k" && -f "$csv_output" ]]; then
        python3 "$plot_ss_script" "$csv_output" "$plot_dir"
        echo "Generated plots for $csv_output in $plot_dir"
    elif [[ "$rps" == "45k" ]]; then
        echo "CSV file $csv_output not found, skipping plot generation..."
    fi
done
