#!/bin/bash
# log-task-outcome.sh — Log task outcomes for Q-Learning

set -e

# Usage: log-task-outcome.sh <task_type> <agent> <success> <quality_score> <time_minutes>
# Example: log-task-outcome.sh research Scout true 0.9 8.5

TASK_TYPE="$1"
AGENT="$2"
SUCCESS="$3"
QUALITY="$4"
TIME="$5"

# Validation
if [ -z "$TASK_TYPE" ] || [ -z "$AGENT" ] || [ -z "$SUCCESS" ]; then
    echo "Usage: log-task-outcome.sh <task_type> <agent> <success> <quality_score> <time_minutes>"
    echo "Example: log-task-outcome.sh research Scout true 0.9 8.5"
    exit 1
fi

# Default values
QUALITY="${QUALITY:-0.5}"
TIME="${TIME:-0}"

# Log file
LOG_FILE="$HOME/.openclaw/workspace/rl-task-execution-log.jsonl"

# Create timestamp
TIMESTAMP=$(date -Iseconds)

# Create JSON entry
JSON=$(cat <<EOF
{"timestamp":"$TIMESTAMP","task_type":"$TASK_TYPE","agent":"$AGENT","success":$SUCCESS,"quality_score":$QUALITY,"time_minutes":$TIME}
EOF
)

# Append to log
echo "$JSON" >> "$LOG_FILE"

echo "✓ Logged: $TASK_TYPE → $AGENT (success=$SUCCESS, quality=$QUALITY, time=${TIME}min)"

# Check if we should update Q-scores (every 5 entries)
ENTRY_COUNT=$(grep -c '^{' "$LOG_FILE" 2>/dev/null || echo "0")

if [ $((ENTRY_COUNT % 5)) -eq 0 ] && [ "$ENTRY_COUNT" -gt 0 ]; then
    echo "→ Triggering Q-score update (${ENTRY_COUNT} entries logged)..."
    "$HOME/.openclaw/workspace/scripts/update-q-scores.sh"
fi
