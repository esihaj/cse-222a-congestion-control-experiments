#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

# Input and output files
input_file="$1"
output_file="$2"

# Write the CSV header
echo "timestamp,rtt,rtt_var,cwnd,ssthresh,bytes_sent,pacing_rate,retrans" > "$output_file"

# Process each line in the input file
while IFS= read -r line; do
    # Extract fields using regex with space before keywords
    timestamp=$(echo "$line" | grep -oP '^\d+\.\d+')
    rtt_full=$(echo "$line" | grep -oP '\s+rtt:\K[0-9\.]+/[0-9\.]+' || echo "N/A")
    rtt=$(echo "$rtt_full" | cut -d'/' -f1 || echo "N/A")
    rtt_var=$(echo "$rtt_full" | cut -d'/' -f2 || echo "N/A")
    cwnd=$(echo "$line" | grep -oP '\s+cwnd:\K[0-9]+' || echo "N/A")
    ssthresh=$(echo "$line" | grep -oP '\s+ssthresh:\K[0-9]+' || echo "N/A")
    bytes_sent=$(echo "$line" | grep -oP '\s+bytes_sent:\K[0-9]+' || echo "N/A")
    pacing_rate=$(echo "$line" | grep -oP '\s+pacing_rate\s+\K[0-9]+(?=bps)' || echo "N/A")
    retrans=$(echo "$line" | grep -oP '\s+retrans:\K[0-9]+(?=/)' || echo "N/A")

    # Combine all fields into a single CSV row
    echo "$timestamp,$rtt,$rtt_var,$cwnd,$ssthresh,$bytes_sent,$pacing_rate,$retrans" >> "$output_file"
done < "$input_file"

echo "CSV file created at $output_file"
