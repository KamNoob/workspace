#!/bin/bash
# log-workflow.sh — Track process flow usage and outcomes

set -e

# Usage: log-workflow.sh <flow_name> <success> <time_minutes> <notes>
# Example: log-workflow.sh "Chain_A_Knowledge_Pipeline" true 5.2 "research task completed successfully"

FLOW_NAME="$1"
SUCCESS="$2"
TIME="$3"
NOTES="$4"

# Validation
if [ -z "$FLOW_NAME" ] || [ -z "$SUCCESS" ]; then
    echo "Usage: log-workflow.sh <flow_name> <success> <time_minutes> <notes>"
    echo "Example: log-workflow.sh Chain_A_Knowledge_Pipeline true 5.2 'completed successfully'"
    exit 1
fi

# Default values
TIME="${TIME:-0}"
NOTES="${NOTES:-}"

# Log file
LOG_FILE="$HOME/.openclaw/workspace/workflow-execution-log.jsonl"

# Create timestamp
TIMESTAMP=$(date -Iseconds)

# Create JSON entry
JSON=$(cat <<EOF
{"timestamp":"$TIMESTAMP","flow_name":"$FLOW_NAME","success":$SUCCESS,"time_minutes":$TIME,"notes":"$NOTES"}
EOF
)

# Append to log
echo "$JSON" >> "$LOG_FILE"

echo "✓ Logged workflow: $FLOW_NAME (success=$SUCCESS, time=${TIME}min)"

# Check if we should analyze workflows (every 10 entries)
ENTRY_COUNT=$(grep -c '^{' "$LOG_FILE" 2>/dev/null || echo "0")

if [ $((ENTRY_COUNT % 10)) -eq 0 ] && [ "$ENTRY_COUNT" -gt 0 ]; then
    echo "→ Analyzing workflows (${ENTRY_COUNT} entries logged)..."
    "$HOME/.openclaw/workspace/scripts/analyze-workflows.sh"
fi
