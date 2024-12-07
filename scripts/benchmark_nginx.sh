#!/usr/bin/env bash
set -euo pipefail

GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Function to display usage information
usage() {
    echo -e "${GREEN}Usage:${RESET}"
    echo -e "  $0 -u <url> -t <threads> -c <connections> -d <duration> -r <rate> -o <output_file>"
    echo -e "\n${GREEN}Options:${RESET}"
    echo -e "  -u    URL of the website to benchmark (required)"
    echo -e "  -t    Number of threads (default: 2)"
    echo -e "  -c    Number of connections (default: 100)"
    echo -e "  -d    Duration of the benchmark (default: 30s)"
    echo -e "  -r    Request rate in requests per second (default: 1000)"
    echo -e "  -o    Output file to write the results (default: benchmark_results.txt)"
    exit 1
}

# Default parameters
THREADS=2
CONNECTIONS=100
DURATION="30s"
RATE=1000
URL=""
OUTPUT_FILE="benchmark_results.txt"

# Parse command-line arguments
while getopts "u:t:c:d:r:o:" opt; do
    case $opt in
        u) URL="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        c) CONNECTIONS="$OPTARG" ;;
        d) DURATION="$OPTARG" ;;
        r) RATE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if the URL is provided
if [ -z "$URL" ]; then
    echo -e "${RED}Error: URL is required.${RESET}"
    usage
fi

# Verify that wrk2 is installed
if ! command -v wrk &> /dev/null; then
    echo -e "${RED}Error: wrk2 is not installed. Please install it first.${RESET}"
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

# Run the benchmark and write results to file
echo -e "${GREEN}Starting benchmark with the following parameters:${RESET}"
echo -e "  URL: $URL"
echo -e "  Threads: $THREADS"
echo -e "  Connections: $CONNECTIONS"
echo -e "  Duration: $DURATION"
echo -e "  Request Rate: $RATE requests/second"
echo -e "  Output File: $OUTPUT_FILE"

wrk -t"$THREADS" -c"$CONNECTIONS" -d"$DURATION" -R"$RATE" "$URL" | tee "$OUTPUT_FILE"

echo -e "${GREEN}Benchmark completed. Results written to: $OUTPUT_FILE${RESET}"
