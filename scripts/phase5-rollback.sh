#!/bin/bash
# Phase 5 Rollback Script
# Disables all Phase 5 optimizations if needed

set -e

echo ""
echo "======================================================================"
echo "PHASE 5 ROLLBACK — EMERGENCY PROCEDURE"
echo "======================================================================"
echo ""

echo "⚠️  This will disable all Phase 5 optimizations:"
echo "  - Cache warmup"
echo "  - Specialized prompts"
echo "  - Task batching"
echo "  - Memory pruning"
echo ""

read -p "Continue with rollback? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Rollback cancelled."
    exit 0
fi

echo ""
echo "Rolling back Phase 5..."
echo ""

# Disable in config
if [ -f "config/phase5-production.json" ]; then
    echo "✓ Backing up production config"
    cp config/phase5-production.json config/phase5-production.json.backup.$(date +%s)
    echo "✓ Disabling Phase 5 in config (manual: edit config/phase5-production.json)"
fi

# Remove cache state
if [ -f "data/metrics/cache-warmup-state.json" ]; then
    echo "✓ Clearing cache state"
    rm data/metrics/cache-warmup-state.json
fi

# Remove batch metrics
if [ -f "data/metrics/batch-efficiency.json" ]; then
    echo "✓ Clearing batch metrics"
    rm data/metrics/batch-efficiency.json
fi

# Remove memory pruning state
if [ -f "data/metrics/memory-pruning.json" ]; then
    echo "✓ Clearing pruning state"
    rm data/metrics/memory-pruning.json
fi

echo ""
echo "✅ ROLLBACK COMPLETE"
echo ""
echo "To re-enable Phase 5:"
echo "  1. Edit config/phase5-production.json"
echo "  2. Set 'status': 'production' for each pillar"
echo "  3. Restart gateway"
echo ""
