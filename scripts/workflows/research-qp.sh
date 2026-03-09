#!/usr/bin/env bash
# =============================================================================
# research-qp.sh — Research Workflow with spawn-smart integration
# Phase 2b.0 Integration Template
# =============================================================================
# USAGE:
#   ./research-qp.sh "<topic>" [depth: quick|standard|deep] [validate: yes|no]
#
# EXAMPLES:
#   ./research-qp.sh "best practices for JWT refresh tokens"
#   ./research-qp.sh "compare Kafka vs RabbitMQ" deep yes
#   ./research-qp.sh "summarise OWASP Top 10" quick
# =============================================================================

set -euo pipefail

TOPIC="${1:-}"
DEPTH="${2:-standard}"
VALIDATE="${3:-no}"
START_TIME=$(date +%s)
WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JULIA=/snap/julia/165/bin/julia
SPAWNER="$WORKSPACE_DIR/scripts/ml/agent-spawner-qp.jl"

# --- Input validation --------------------------------------------------------
if [[ -z "$TOPIC" ]]; then
  echo "Usage: $0 \"<topic>\" [depth: quick|standard|deep] [validate: yes|no]"
  exit 1
fi

echo "🕶️  Morpheus Research Workflow"
echo "   Topic: $TOPIC"
echo "   Depth: $DEPTH"
echo "   Validate: $VALIDATE"
echo ""

# --- Quality-aware agent selection -------------------------------------------
# quick    → Scout only
# standard → Scout + optional Veritas validation
# deep     → Scout + Chronicle documentation + Veritas validation

spawn_research() {
  local depth="$1"
  local validate="$2"
  
  if [[ "$depth" == "quick" ]]; then
    echo "🔍 Quick research → Spawning Scout only..."
    $JULIA "$SPAWNER" --task research --candidates "Scout"
  elif [[ "$depth" == "deep" ]]; then
    echo "📚 Deep research → Spawning Scout (primary) + Chronicle (docs) + Veritas (validation)..."
    $JULIA "$SPAWNER" --task research --candidates "Scout,Chronicle,Veritas"
  else
    echo "🔍 Standard research → Spawning Scout + optional Veritas..."
    if [[ "$validate" == "yes" ]]; then
      $JULIA "$SPAWNER" --task research --candidates "Scout,Veritas"
    else
      $JULIA "$SPAWNER" --task research --candidates "Scout"
    fi
  fi
}

spawn_research "$DEPTH" "$VALIDATE"

# --- Outcome logging ---------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""
echo "✅ Research workflow dispatched."
echo "   Topic: $TOPIC"
echo "   Depth: $DEPTH"
echo "   Elapsed: ${ELAPSED}s"
echo ""
echo "📝 Log outcome when complete:"
echo "   $JULIA $SPAWNER --log-outcome \"<timestamp>\" true|false"
