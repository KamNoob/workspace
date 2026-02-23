#!/bin/bash
set -e

# Configuration
SUBNET="192.168.0.0/24"
LOG_DIR="$HOME/.openclaw/workspace/scans"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE="$LOG_DIR/scan_$TIMESTAMP.txt"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Run the scan
# -T4: Faster execution
# -F: Fast mode (scans fewer ports than the default scan)
# --open: Only show open ports
echo "Starting network scan for $SUBNET at $TIMESTAMP..." > "$REPORT_FILE"
nmap -T4 -F --open "$SUBNET" >> "$REPORT_FILE"

# Summarize findings
HOST_COUNT=$(grep "Nmap scan report for" "$REPORT_FILE" | wc -l)
OPEN_PORTS=$(grep "open" "$REPORT_FILE" | wc -l)

echo "Scan complete." >> "$REPORT_FILE"
echo "Hosts found: $HOST_COUNT" >> "$REPORT_FILE"
echo "Open ports found: $OPEN_PORTS" >> "$REPORT_FILE"

# Output summary for the agent to read if run interactively
echo "Scan saved to: $REPORT_FILE"
echo "Hosts: $HOST_COUNT"
echo "Open Ports: $OPEN_PORTS"
