#!/bin/bash

# Default number of jobs is the number of CPU cores
num_jobs=20 #$(nproc)

# Check if at least two arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <input_file> <output_file> [num_jobs]"
    exit 1
fi

# Input and output files
input_file="$1"
output_file="$2"

# Optional: number of jobs
if [ "$#" -eq 3 ]; then
    num_jobs="$3"
fi

# Temporary directory for chunks
temp_dir=$(mktemp -d)

# Write the CSV header to the output file
echo "timestamp,rtt,rtt_var,cwnd,ssthresh,bytes_sent,pacing_rate,retrans,unacked,send,delivery_rate,minrtt" > "$output_file"

# Split the input file into chunks
split -l $((($(wc -l < "$input_file") + num_jobs - 1) / num_jobs)) "$input_file" "$temp_dir/chunk_"

process_chunk() {
    chunk_file="$1"
    temp_output="$2"
    while IFS= read -r line; do
        timestamp=$(echo "$line" | grep -oP '^\d+\.\d+')

        rtt_full=$(echo "$line" | grep -oP '\s+rtt:\K[0-9\.]+/[0-9\.]+' || echo "N/A")
        if [[ "$rtt_full" == "N/A" ]]; then
            rtt="N/A"
            rtt_var="N/A"
        else
            rtt=$(echo "$rtt_full" | cut -d'/' -f1 || echo "N/A")
            rtt_var=$(echo "$rtt_full" | cut -d'/' -f2 || echo "N/A")
        fi

        cwnd=$(echo "$line" | grep -oP '\s+cwnd:\K[0-9]+' || echo "N/A")
        ssthresh=$(echo "$line" | grep -oP '\s+ssthresh:\K[0-9]+' || echo "N/A")
        bytes_sent=$(echo "$line" | grep -oP '\s+bytes_sent:\K[0-9]+' || echo "N/A")
        pacing_rate=$(echo "$line" | grep -oP '\s+pacing_rate\s+\K[0-9]+(?=bps)' || echo "N/A")
        retrans=$(echo "$line" | grep -oP '\s+retrans:\K[0-9]+(?=/)' || echo "N/A")
        unacked=$(echo "$line" | grep -oP '\s+unacked:\K[0-9]+' || echo "N/A")
        send=$(echo "$line" | grep -oP '\s+send\s+\K[0-9]+(?=bps)' || echo "N/A")
        delivery_rate=$(echo "$line" | grep -oP '\s+delivery_rate\s+\K[0-9]+(?=bps)' || echo "N/A")
        minrtt=$(echo "$line" | grep -oP '\s+minrtt:\K[0-9\.]+' || echo "N/A")

        echo "$timestamp,$rtt,$rtt_var,$cwnd,$ssthresh,$bytes_sent,$pacing_rate,$retrans,$unacked,$send,$delivery_rate,$minrtt"
    done < "$chunk_file" > "$temp_output"
}

export -f process_chunk

# Process each chunk in parallel
find "$temp_dir" -type f -name "chunk_*" | parallel -j "$num_jobs" process_chunk {} {}.csv

# Concatenate the processed chunks back in order
for chunk_output in "$temp_dir"/chunk_*.csv; do
    cat "$chunk_output" >> "$output_file"
done

# Cleanup temporary files
rm -rf "$temp_dir"

echo "CSV file created at $output_file"
