#!/bin/bash
# Run every 30 seconds via cron
PENDING=$(curl -s http://localhost:4001/api/admin/pending 2>/dev/null)
COUNT=$(echo "$PENDING" | jq -r '.pending | length' 2>/dev/null || echo 0)
if [ "$COUNT" -gt 0 ]; then
  # Alert by writing to a log Morpheus watches
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] CHAT ALERT: $COUNT unanswered message(s)" >> /tmp/morpheus-chat-alerts.log
  # Also output so cron email would catch it (if enabled)
  echo "$PENDING" | jq -r '.pending[] | "  - [\(.conversationId)] \(.message)"' 2>/dev/null
fi
