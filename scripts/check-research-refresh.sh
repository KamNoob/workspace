#!/bin/bash

# Research Refresh Monitor
# Checks research file ages and triggers Scout updates when stale
# Usage: ./check-research-refresh.sh [--auto-update]

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
INDEX_FILE="$WORKSPACE/RESEARCH_INDEX.md"
LOG_FILE="$WORKSPACE/logs/research-refresh.log"

# Ensure log directory exists
mkdir -p "$WORKSPACE/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log with timestamp
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to parse date (YYYY-MM-DD)
parse_date() {
  date -d "$1" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null
}

# Get current date in seconds since epoch
NOW=$(date +%s)

# Check if auto-update flag is set
AUTO_UPDATE=false
if [[ "${1:-}" == "--auto-update" ]]; then
  AUTO_UPDATE=true
fi

log "=== Research Refresh Check Started ==="

# Parse RESEARCH_INDEX.md for refresh dates
STALE_RESEARCH=()

while IFS= read -r line; do
  # Look for "Refresh: X days (next: YYYY-MM-DD)" pattern
  if [[ "$line" =~ Refresh:\ ([0-9]+)\ days\ \(next:\ ([0-9]{4}-[0-9]{2}-[0-9]{2})\) ]]; then
    REFRESH_DAYS="${BASH_REMATCH[1]}"
    NEXT_DATE="${BASH_REMATCH[2]}"
    
    # Get the research file path from previous lines
    # Look back for "**File:**" line
    FILE_PATH=""
    TITLE=""
    
    # Re-read to find title and file path (simplified - parse full entry)
    # For now, just check the date
    
    NEXT_TIMESTAMP=$(parse_date "$NEXT_DATE")
    DAYS_UNTIL_REFRESH=$(( (NEXT_TIMESTAMP - NOW) / 86400 ))
    
    if [ $DAYS_UNTIL_REFRESH -lt 0 ]; then
      # Research is overdue
      echo -e "${RED}⚠️  OVERDUE:${NC} Refresh needed (${DAYS_UNTIL_REFRESH#-} days overdue) - Next: $NEXT_DATE"
      STALE_RESEARCH+=("$NEXT_DATE")
    elif [ $DAYS_UNTIL_REFRESH -le 7 ]; then
      # Research due soon
      echo -e "${YELLOW}📅 DUE SOON:${NC} Refresh in $DAYS_UNTIL_REFRESH days - Next: $NEXT_DATE"
    else
      # Research fresh
      echo -e "${GREEN}✓ FRESH:${NC} $DAYS_UNTIL_REFRESH days until refresh - Next: $NEXT_DATE"
    fi
  fi
done < "$INDEX_FILE"

# Summary
echo ""
log "=== Summary ==="
STALE_COUNT=${#STALE_RESEARCH[@]}

if [ $STALE_COUNT -eq 0 ]; then
  log "✅ All research is current (no updates needed)"
  exit 0
else
  log "⚠️  $STALE_COUNT research file(s) need refresh"
  
  if [ "$AUTO_UPDATE" = true ]; then
    log "Auto-update enabled - triggering Scout to refresh stale research..."
    
    # Parse full entries to get titles and file paths
    # For now, manual intervention recommended
    log "⚠️  Auto-update requires manual implementation"
    log "   Next step: Parse RESEARCH_INDEX.md, extract file paths, trigger Scout"
    exit 1
  else
    log "Run with --auto-update to trigger automatic refresh (requires Scout)"
    log "Or manually update stale research files"
    
    # Output stale research list
    for date in "${STALE_RESEARCH[@]}"; do
      log "  - Next refresh was: $date"
    done
    
    exit 1
  fi
fi
