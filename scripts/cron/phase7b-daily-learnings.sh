#!/bin/bash
# Phase 7B: Daily Learning & Insights Generation
# Runs daily at 01:30 UTC (after Phase 5 memory pruning at 02:00)
# Generates learnings from task outcomes for persistent knowledge

set -e

WORKSPACE_DIR="/home/art/.openclaw/workspace"
JULIA="/snap/julia/165/bin/julia"
LOG_FILE="$HOME/sync-logs/phase7b-learnings.log"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Create log directory
mkdir -p "$HOME/sync-logs"

# Log header
{
    echo "[$TIMESTAMP] Starting Phase 7B Insights Generation"
    echo "=================================================="
} >> "$LOG_FILE"

cd "$WORKSPACE_DIR" || exit 1

# Run insights generator
if [ -f "$JULIA" ]; then
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] Running Phase 7B insights analyzer..." >> "$LOG_FILE"
    
    if $JULIA scripts/ml/phase7b-insights-generator.jl analyze >> "$LOG_FILE" 2>&1; then
        echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ✅ Insights generated successfully" >> "$LOG_FILE"
    else
        echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ⚠️  Error generating insights (see log above)" >> "$LOG_FILE"
    fi
else
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ERROR: Julia not found at $JULIA" >> "$LOG_FILE"
    exit 1
fi

# Check if learnings file was updated
LEARNINGS_FILE="$WORKSPACE_DIR/data/metrics/phase7b-learnings.json"
if [ -f "$LEARNINGS_FILE" ]; then
    MOD_TIME=$(stat -c %Y "$LEARNINGS_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - MOD_TIME))
    
    if [ "$TIME_DIFF" -lt 60 ]; then
        echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ✅ Learnings file updated (size: $(du -h "$LEARNINGS_FILE" | cut -f1))" >> "$LOG_FILE"
        
        # Check for critical recommendations
        CRITICAL_COUNT=$(grep -c "degrading\|failure rate" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
        if [ "$CRITICAL_COUNT" -gt 0 ]; then
            echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ⚠️  ALERT: $CRITICAL_COUNT critical issues detected in learnings" >> "$LOG_FILE"
        fi
    else
        echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ⚠️  Learnings file not recently updated" >> "$LOG_FILE"
    fi
else
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ⚠️  Learnings file not created" >> "$LOG_FILE"
fi

# Log footer
{
    echo "=================================================="
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] Phase 7B job complete"
    echo ""
} >> "$LOG_FILE"

exit 0
