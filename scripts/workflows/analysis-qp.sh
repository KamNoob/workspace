#!/usr/bin/env bash
# =============================================================================
# analysis-qp.sh — Performance/Metrics Analysis Workflow
# Phase 2b Integration: Lens Agent (primary analyst)
# =============================================================================
# USAGE:
#   ./analysis-qp.sh "<system_or_metric>" [scope: quick|standard|deep]
#
# EXAMPLES:
#   ./analysis-qp.sh "API response time degradation"
#   ./analysis-qp.sh "database query performance" standard
#   ./analysis-qp.sh "memory usage patterns over past week" deep
#   ./analysis-qp.sh "cache hit rates by service" quick
# =============================================================================

set -euo pipefail

TOPIC="${1:-}"
SCOPE="${2:-standard}"
START_TIME=$(date +%s)
WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JULIA=/snap/julia/165/bin/julia
SPAWNER="$WORKSPACE_DIR/scripts/ml/agent-spawner-qp.jl"

# --- Input validation --------------------------------------------------------
if [[ -z "$TOPIC" ]]; then
  echo "Usage: $0 \"<system_or_metric>\" [scope: quick|standard|deep]"
  exit 1
fi

echo "🕶️  Morpheus Analysis Workflow"
echo "   Topic: $TOPIC"
echo "   Scope: $SCOPE"
echo ""

# --- Quality-aware agent selection -------------------------------------------
# Lens is primary analyst for all scopes.
# Scope determines additional agents:
# - quick: Lens only (fast metrics summary)
# - standard: Lens + Scout (research context) + Veritas (validation)
# - deep: Lens + Scout + Chronicle (documentation) + Veritas (comprehensive review)

spawn_analysis() {
  local scope="$1"
  
  if [[ "$scope" == "quick" ]]; then
    echo "⚙️  Quick scope → Lens (metrics analysis only)"
    $JULIA "$SPAWNER" --task analysis --candidates "Lens"
  elif [[ "$scope" == "deep" ]]; then
    echo "⚙️  Deep scope → Lens (primary) + Scout (context) + Chronicle (docs) + Veritas (validation)"
    $JULIA "$SPAWNER" --task analysis --candidates "Lens,Scout,Chronicle,Veritas"
  else
    echo "⚙️  Standard scope → Lens (primary) + Scout (context) + Veritas (validation)"
    $JULIA "$SPAWNER" --task analysis --candidates "Lens,Scout,Veritas"
  fi
}

spawn_analysis "$SCOPE"

# --- Outcome logging ---------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""
echo "✅ Analysis workflow dispatched."
echo "   Topic: $TOPIC"
echo "   Scope: $SCOPE"
echo "   Elapsed: ${ELAPSED}s"
echo ""
echo "📝 Log outcome when complete:"
echo "   $JULIA $SPAWNER --log-outcome \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" true|false"
