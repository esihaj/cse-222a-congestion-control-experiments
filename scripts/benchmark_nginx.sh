#!/usr/bin/env bash
set -euo pipefail

GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Function to display usage information
usage() {
    echo -e "${GREEN}Usage:${RESET}"
    echo -e "  $0 -u <url> -t <threads> -c <connections> -d <duration> -r <rate> -o <output_file> [--cca <cca>] [--delay <delay>] [--loss <loss>]"
    echo -e "\n${GREEN}Options:${RESET}"
    echo -e "  -u    URL of the website to benchmark (required)"
    echo -e "  -t    Number of threads (default: 2)"
    echo -e "  -c    Number of connections (default: 100)"
    echo -e "  -d    Duration of the benchmark (default: 30s)"
    echo -e "  -r    Request rate in requests per second (default: 1000)"
    echo -e "  -o    Output file to write the results (default: benchmark_results.txt)"
    echo -e "  --cca Congestion control algorithm (default: cubic)"
    echo -e "  --delay Network delay in ms (default: 0)"
    echo -e "  --loss Network packet loss percentage (default: 0)"
    exit 1
}

# Default parameters
THREADS=2
CONNECTIONS=100
DURATION="30s"
RATE=1000
URL=""
OUTPUT_FILE="benchmark_results.txt"
CCA="cubic"
DELAY=0
LOSS=0

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u) URL="$2"; shift ;;
        -t) THREADS="$2"; shift ;;
        -c) CONNECTIONS="$2"; shift ;;
        -d) DURATION="$2"; shift ;;
        -r) RATE="$2"; shift ;;
        -o) OUTPUT_FILE="$2"; shift ;;
        --cca) CCA="$2"; shift ;;
        --delay) DELAY="$2"; shift ;;
        --loss) LOSS="$2"; shift ;;
        *) usage ;;
    esac
    shift
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

# Determine network interface
IFACE=$(ip route get 1.1.1.1 | grep -oP 'dev \K\S+')
if [ -z "$IFACE" ]; then
    echo -e "${RED}Error: Could not determine network interface.${RESET}"
    exit 1
fi

# Configure network settings
echo -e "${GREEN}Configuring network with the following parameters:${RESET}"
echo -e "  Congestion Control Algorithm: $CCA"
echo -e "  Network Delay: ${DELAY}ms"
echo -e "  Network Packet Loss: ${LOSS}%"
./configure_network.sh "$IFACE" "$CCA" "$DELAY" "$LOSS"

# Create output directory if it doesn't exist
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
OUTPUT_BASENAME=$(basename "$OUTPUT_FILE" .txt)
SS_LOG="$OUTPUT_DIR/ss_metrics_${OUTPUT_BASENAME}.log"

mkdir -p "$OUTPUT_DIR"
SERVER_IP=${URL#http://}

# Run the benchmark and write results to file
echo -e "${GREEN}Starting benchmark with the following parameters:${RESET}"
echo -e "  URL: $URL"
echo -e "  Server IP: $SERVER_IP"
echo -e "  Threads: $THREADS"
echo -e "  Connections: $CONNECTIONS"
echo -e "  Duration: $DURATION"
echo -e "  Request Rate: $RATE requests/second"
echo -e "  Output File: $OUTPUT_FILE"

# Start collecting `ss` metrics in the background
echo -e "${GREEN}Starting socket statistics (ss) collection in the background...${RESET}"
EXTRA_TIME=2  # Collect a bit after wrk finishes
END_TIME=$((SECONDS + ${DURATION%s} + EXTRA_TIME))

(
  while [ $SECONDS -lt $END_TIME ]; do
    ss --no-header -in dst "$SERVER_IP" | ts '%.s' >> "$SS_LOG" 2>&1
    sleep 0.2
  done
) &
SS_PID=$!

wrk -t"$THREADS" -c"$CONNECTIONS" -d"$DURATION" -R"$RATE" "$URL" | tee "$OUTPUT_FILE"

# Stop collecting `ss` metrics
echo -e "${GREEN}Benchmark completed. Stopping ss collection...${RESET}"
kill $SS_PID || true
wait $SS_PID 2>/dev/null || true

echo -e "${GREEN}Benchmark completed. Results written to: $OUTPUT_FILE${RESET}"
