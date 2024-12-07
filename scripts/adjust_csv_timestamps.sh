#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_csv> <output_csv>"
    exit 1
fi

# Input and output files
input_csv="$1"
output_csv="$2"

# Read the first timestamp
first_timestamp=$(awk -F',' 'NR==2 {print $1}' "$input_csv")

# Check if the first timestamp was extracted correctly
if [ -z "$first_timestamp" ]; then
    echo "Error: Could not extract the first timestamp from $input_csv"
    exit 1
fi

# Write the header to the output CSV
head -n 1 "$input_csv" > "$output_csv"

# Adjust timestamps and write the result
awk -F',' -v first_ts="$first_timestamp" 'NR > 1 {
    $1 = $1 - first_ts;
    print $0
}' OFS=',' "$input_csv" >> "$output_csv"

echo "Adjusted timestamps written to $output_csv"
