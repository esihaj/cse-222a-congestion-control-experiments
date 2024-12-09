#!/bin/bash

# Base directory
base_dir="./results"

# Collect files and directories to delete
files_to_delete=$(find $base_dir/{cubic,bbr}/* -type f -name "control-plane.*" -o -name "data-plane.*")
dirs_to_delete=$(find $base_dir/{cubic,bbr}/* -type d -name "plot")

echo -e "\e[32mCleaning up iperf3 generated (not raw) results...\e[0m"

# Echo the paths that will be deleted
echo "The following files will be deleted:"
echo "$files_to_delete"
echo
echo "The following directories will be deleted:"
echo "$dirs_to_delete"
echo

# Ask for confirmation
echo -e "\e[31mDo you want to proceed with the deletion? [y/N]: \e[0m\c"
read confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Delete the files
    echo "Deleting files..."
    echo "$files_to_delete" | xargs -d '\n' rm -f
    echo "Deleting directories..."
    echo "$dirs_to_delete" | xargs -d '\n' rm -rf
    echo "Cleanup completed."
else
    echo "Cleanup canceled."
fi
