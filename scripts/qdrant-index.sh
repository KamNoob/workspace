#!/bin/bash
# Qdrant indexing wrapper script

set -e

WORKSPACE_ROOT="${1:-/home/art/.openclaw/workspace}"
LOG_FILE="${WORKSPACE_ROOT}/data/logs/qdrant-indexing.log"
INDEXER_SCRIPT="${WORKSPACE_ROOT}/scripts/indexing/qdrant_indexer.py"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    local level=$1
    shift
    local msg="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" | tee -a "$LOG_FILE"
}

# Check Qdrant health
check_qdrant() {
    log "INFO" "Checking Qdrant health..."
    if curl -s http://localhost:6333/collections > /dev/null 2>&1; then
        log "INFO" "✓ Qdrant is running"
        return 0
    else
        log "ERROR" "✗ Qdrant is not running. Start with: qdrant"
        return 1
    fi
}

# Run indexing
run_indexing() {
    local mode=$1
    local full_flag=""
    
    if [[ "$mode" == "full" ]]; then
        full_flag="--full"
        log "INFO" "Running FULL indexing (all files will be re-indexed)"
    else
        log "INFO" "Running incremental indexing (only changed files)"
    fi
    
    if [[ ! -f "$INDEXER_SCRIPT" ]]; then
        log "ERROR" "Indexer script not found: $INDEXER_SCRIPT"
        return 1
    fi
    
    log "INFO" "Starting Python indexer..."
    python3 "$INDEXER_SCRIPT" --workspace "$WORKSPACE_ROOT" $full_flag 2>&1 | tee -a "$LOG_FILE"
    
    local exit_code=${PIPESTATUS[0]}
    
    if [[ $exit_code -eq 0 ]]; then
        log "INFO" "✓ Indexing completed successfully"
    else
        log "ERROR" "✗ Indexing failed with exit code $exit_code"
    fi
    
    return $exit_code
}

# Main logic
case "${2:-incremental}" in
    full)
        check_qdrant && run_indexing "full"
        ;;
    incremental|*)
        check_qdrant && run_indexing "incremental"
        ;;
esac

log "INFO" "Done. See full log: $LOG_FILE"
