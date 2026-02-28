#!/bin/bash
# Check for pending chat messages and log them (Morpheus monitors via heartbeat)

PENDING=$(curl -s http://localhost:4001/api/admin/pending)
COUNT=$(echo "$PENDING" | jq '.pending | length')

if [ "$COUNT" -gt 0 ]; then
  echo "[$(date)] PENDING CHAT MESSAGES: $COUNT unanswered message(s)"
  echo "$PENDING" | jq '.pending[] | "\(.conversationId): \(.message)"'
else
  true  # Silent if none pending
fi
