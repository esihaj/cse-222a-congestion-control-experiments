#!/usr/bin/env bash
set -euo pipefail

ROLE="$1"    # server or client
PHASE="$2"   # init or run

GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

if [ "$PHASE" = "init" ]; then
    # Args: ROLE init RESULT_DIR
    RESULT_DIR="$3"
    echo -e "${GREEN}[REMOTE_RUNNER-$ROLE] INIT phase for $ROLE${RESET}"

    pkill iperf3 || true
    mkdir -p "$RESULT_DIR"
    ./remote_setup.sh
    
    if [ "$ROLE" = "client" ]; then
        # Determine IFACE and store it
        IFACE=$(ip route get 1.1.1.1 | grep -oP 'dev \K\S+')
        echo "$IFACE" > "$RESULT_DIR/iface.txt"
        echo -e "${GREEN}[REMOTE_RUNNER-$ROLE] IFACE detected: $IFACE${RESET}"
    fi

elif [ "$PHASE" = "run" ]; then
    # Args for run: ROLE run CCA RemoteIP Duration Delay Loss RESULT_DIR
    CCA="$3"
    REMOTE_IP="$4"
    DURATION="$5"
    DELAY="$6"
    LOSS="$7"
    RESULT_DIR="$8"

    if [ "$ROLE" = "server" ]; then
        echo -e "${GREEN}[REMOTE_RUNNER-$ROLE] Running as server...${RESET}"
        # Start iperf3 server
        echo -e "${GREEN}[REMOTE_RUNNER-$ROLE] Starting iperf3 server...${RESET}"
        nohup iperf3 -i 1 -s > "$RESULT_DIR/iperf3_server.log" 2>&1 &
        exit 0
    else
        echo -e "${GREEN}[REMOTE_RUNNER-$ROLE] Running as client...${RESET}"
        # Client side
        IFACE=$(cat "$RESULT_DIR/iface.txt")
        ./configure_network.sh "$IFACE" "$CCA" "$DELAY" "$LOSS"

        # Start collecting ss metrics in background
        echo -e "${GREEN}[REMOTE_RUNNER-$ROLE] Starting metric collection (ss -i) in background...${RESET}"
        EXTRA_TIME=2  # Collect a bit after iperf finishes
        END_TIME=$((SECONDS + DURATION + EXTRA_TIME))

        (
          while [ $SECONDS -lt $END_TIME ]; do
            ss --no-header -in dst "$REMOTE_IP" | ts '%.s' >> "$RESULT_DIR/ss_metrics.log" 2>&1
            # echo "###" >> "$RESULT_DIR/ss_metrics.log"
            # sleep 0.2
          done
        ) &
        METRIC_PID=$!

        # Wait a bit before starting iperf for baseline metrics
        sleep 1

        echo -e "${GREEN}[REMOTE_RUNNER-$ROLE] Running iperf3 client test...${RESET}"
        iperf3 -c "$REMOTE_IP" -t "$DURATION" -i 0.2 -J > "$RESULT_DIR/iperf3_output.json"

        echo -e "${GREEN}[REMOTE_RUNNER-$ROLE] iperf3 test complete, stopping metric collection...${RESET}"
        kill $METRIC_PID || true
        wait $METRIC_PID 2>/dev/null || true

        # If you want to collect a bit post-iperf, you could let the sleep run out instead of killing immediately.
    fi

else
    echo -e "${YELLOW}[REMOTE_RUNNER] Invalid phase: $PHASE${RESET}"
    exit 1
fi
