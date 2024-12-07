#!/bin/bash

# Setup script to clone and install iperf3_plotter
setup_iperf3_plotter() {
    local repo_url="https://github.com/ekfoury/iperf3_plotter.git"
    local clone_dir="iperf3_plotter"

    printf "Cloning iperf3_plotter...\n"
    if [[ -d $clone_dir ]]; then
        printf "Directory '%s' already exists. Skipping clone.\n" "$clone_dir"
    else
        if ! git clone "$repo_url"; then
            printf "Error: Failed to clone repository.\n" >&2
            return 1
        fi
    fi

    printf "Building iperf3_plotter...\n"
    if ! (cd "$clone_dir" && sudo make); then
        printf "Error: Failed to build iperf3_plotter.\n" >&2
        return 1
    fi

    printf "iperf3_plotter installed successfully.\n"
}

# Script to plot all iperf3 results
plot_all_results() {
    local base_dir
    base_dir=$(realpath "$(dirname "$0")")
    local results_dir="$base_dir/results"
    local plotter_script="$base_dir/iperf3_plotter/plot_iperf.sh"

    if [[ ! -d $results_dir ]]; then
        printf "Error: Results directory '%s' does not exist.\n" "$results_dir" >&2
        return 1
    fi

    if [[ ! -f $plotter_script ]]; then
        printf "Error: Plotter script '%s' not found. Please run the setup script first.\n" "$plotter_script" >&2
        return 1
    fi

    find "$results_dir" -mindepth 2 -maxdepth 2 -type d | while IFS= read -r scenario_dir; do
        local json_file
        json_file=$(find "$scenario_dir" -maxdepth 1 -type f -name 'iperf3_output.json')
        
        if [[ -z $json_file ]]; then
            printf "Warning: No iperf3_output.json found in '%s'. Skipping.\n" "$scenario_dir" >&2
            continue
        fi

        local plot_dir="$scenario_dir/plot"
        mkdir -p "$plot_dir"

        printf "Plotting results for '%s'...\n" "$scenario_dir"
        if ! (cd "$plot_dir" && bash "$plotter_script" "$json_file"); then
            printf "Error: Failed to plot results for '%s'.\n" "$scenario_dir" >&2
            continue
        fi

        # Move all files from the nested "results" directory into "plot"
        if [[ -d "$plot_dir/results" ]]; then
            printf "Flattening nested 'results' directory in '%s'...\n" "$plot_dir"
            mv "$plot_dir/results/"* "$plot_dir/"
            rmdir "$plot_dir/results"
        fi

        printf "Plot saved in '%s'.\n" "$plot_dir"
    done
}

main() {
    local cmd="$1"

    case "$cmd" in
        setup)
            setup_iperf3_plotter
            ;;
        plot)
            plot_all_results
            ;;
        *)
            printf "Usage: %s {setup|plot}\n" "$0" >&2
            return 1
            ;;
    esac
}

main "$@"
