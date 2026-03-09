#!/bin/bash
# Monitor chat notifications and send to Morpheus session
# Designed to run from cron and notify when pending messages arrive

LOG_FILE="/tmp/morpheus-chat-notifications.log"
STATE_FILE="/tmp/morpheus-chat-monitor.state"

# Initialize state
if [ ! -f "$STATE_FILE" ]; then
  echo "0" > "$STATE_FILE"
fi

LAST_LINE=$(cat "$STATE_FILE")

# Check if log exists
if [ ! -f "$LOG_FILE" ]; then
  exit 0
fi

# Get new lines since last check
CURRENT_LINES=$(wc -l < "$LOG_FILE")

if [ "$CURRENT_LINES" -gt "$LAST_LINE" ]; then
  # New notifications detected
  NEW_NOTIFICATIONS=$(tail -n +$((LAST_LINE + 1)) "$LOG_FILE")
  
  echo "[CHAT] New pending messages detected:"
  echo "$NEW_NOTIFICATIONS"
  
  # Update state
  echo "$CURRENT_LINES" > "$STATE_FILE"
fi
