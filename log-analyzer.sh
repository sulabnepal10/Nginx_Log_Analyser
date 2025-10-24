#!/bin/bash

# log-analyzer.sh - Professional NGINX Access Log Analyzer
# Author: Sulab Nepal
# Description: Parses NGINX logs to extract top IPs, paths, status codes, and user agents.

# --------------------------
# Configuration
# --------------------------
LOG_FILE="${1:-access.log}"  # Allow custom log file input
OUTPUT_FILE="log_analysis_$(date +%Y%m%d_%H%M%S).txt"  # Output filename with timestamp
TEMP_DIR="/tmp/log_analyzer"  # Temp directory for intermediate files

# --------------------------
# Functions
# --------------------------

# Initialize the analyzer (check dependencies + clean old temp files)
init_analyzer() {
    # Check if log file exists
   if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found!"
    echo "Try:"
    echo "1. ./log-analyzer.sh /path/to/your/logfile"
    echo "2. Or create test logs with:"
    echo "   curl http://localhost >/dev/null 2>&1"
    exit 1
fi 

    # Check required commands (awk, sort, uniq, etc.)
    for cmd in awk sort uniq head; do
        if ! command -v "$cmd" &> /dev/null; then
            echo " Error: '$cmd' command not found. Please install it." >&2
            exit 1
        fi
    done

    # Create temp directory
    mkdir -p "$TEMP_DIR"
    rm -f "$TEMP_DIR"/*
}

# Extract top N IPs (default: 5)
analyze_ips() {
    local limit="${1:-5}"
    echo " Top $limit IP Addresses:"
    awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n "$limit" | awk '{printf "%-15s - %d requests\n", $2, $1}'
    echo ""
}

# Extract top N paths (default: 5)
analyze_paths() {
    local limit="${1:-5}"
    echo " Top $limit Requested Paths:"
    awk -F'"' '{print $2}' "$LOG_FILE" | awk '{print $2}' | sort | uniq -c | sort -nr | head -n "$limit" | awk '{printf "%-30s - %d requests\n", $2, $1}'
    echo ""
}

# Extract top N status codes (default: 5)
analyze_status_codes() {
    local limit="${1:-5}"
    echo " Top $limit HTTP Status Codes:"
    awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n "$limit" | awk '{printf "%-3s - %d requests\n", $2, $1}'
    echo ""
}

# Extract top N user agents (default: 5)
analyze_user_agents() {
    local limit="${1:-5}"
    echo " Top $limit User Agents:"
    awk -F'"' '{print $6}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n "$limit" | awk '{printf "%-50s - %d requests\n", $2, $1}'
    echo ""
}

# Generate a full report
generate_report() {
    echo " Generating report..."
    {
        echo " Report generated on: $(date)"
        echo " Log file analyzed: $LOG_FILE"
        echo "========================================"
        analyze_ips "$@"
        analyze_paths "$@"
        analyze_status_codes "$@"
        analyze_user_agents "$@"
    } > "$OUTPUT_FILE"
    echo " Report saved to: $OUTPUT_FILE"
}

# --------------------------
# Main Execution
# --------------------------
init_analyzer

# Check if a custom limit is provided (e.g., `./log-analyzer.sh access.log 10`)
LIMIT="${2:-5}"
generate_report "$LIMIT"

# Optional: Print report to terminal
cat "$OUTPUT_FILE"
