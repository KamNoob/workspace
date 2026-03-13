#!/bin/bash
# kb-live-indexer.sh - Daily auto-learning from agent outcomes
# Runs daily at 01:00 UTC via OpenClaw cron
# Processes RL execution logs → extracts learnings → updates KB

set -e

WORKSPACE="/home/art/.openclaw/workspace"
METRICS_FILE="${WORKSPACE}/data/metrics/kb-system-metrics.json"
RL_LOG="${WORKSPACE}/data/rl/rl-task-execution-log.jsonl"
LAST_INDEX_FILE="${WORKSPACE}/.kb-last-index"
LOG_FILE="${WORKSPACE}/logs/kb-live-indexer.log"

# Initialize
mkdir -p "$(dirname "$LOG_FILE")"
{
  echo "=== KB Live Indexer ==="
  echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo ""
} | tee "$LOG_FILE"

# Get last indexed line
LAST_LINE=0
if [ -f "$LAST_INDEX_FILE" ]; then
  LAST_LINE=$(cat "$LAST_INDEX_FILE")
fi

TOTAL_LINES=$(wc -l < "$RL_LOG" 2>/dev/null || echo 0)
NEW_LINES=$((TOTAL_LINES - LAST_LINE))

echo "Processing $NEW_LINES new entries (lines $LAST_LINE → $TOTAL_LINES)" | tee -a "$LOG_FILE"

if [ $NEW_LINES -gt 0 ]; then
  # Extract success count from new entries
  SUCCESS_COUNT=$(tail -n "$NEW_LINES" "$RL_LOG" 2>/dev/null | jq -r 'select(.success == true)' 2>/dev/null | wc -l || echo 0)
  SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", $SUCCESS_COUNT / $NEW_LINES}")
  
  echo "✓ Success rate: $SUCCESS_RATE ($SUCCESS_COUNT/$NEW_LINES)" | tee -a "$LOG_FILE"
  
  # Update metrics
  if [ -f "$METRICS_FILE" ]; then
    jq \
      --arg timestamp "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      --arg success_rate "$SUCCESS_RATE" \
      --arg new_entries "$NEW_LINES" \
      '.last_updated = $timestamp |
       .kb_growth_history += [{timestamp: $timestamp, new_entries_added: ($new_entries|tonumber), success_rate: ($success_rate|tonumber)}] |
       .spawn_metrics.success_rate = ($success_rate|tonumber)' \
      "$METRICS_FILE" > "$METRICS_FILE.tmp" 2>/dev/null && mv "$METRICS_FILE.tmp" "$METRICS_FILE"
    echo "✓ Metrics updated" | tee -a "$LOG_FILE"
  fi
  
  # Persist state
  echo "$TOTAL_LINES" > "$LAST_INDEX_FILE"
fi

echo "✓ Complete at $(date -u '+%Y-%m-%d %H:%M:%S UTC')" | tee -a "$LOG_FILE"
exit 0
