#!/usr/bin/env bash
# =============================================================================
# brainstorm-qp.sh — Creative Ideation & Brainstorming Workflow
# Phase 2b Integration: Echo Agent (primary creative lead)
# =============================================================================
# USAGE:
#   ./brainstorm-qp.sh "<challenge_or_topic>" [depth: quick|standard|deep]
#
# EXAMPLES:
#   ./brainstorm-qp.sh "how to improve API latency" quick
#   ./brainstorm-qp.sh "redesign onboarding flow" standard
#   ./brainstorm-qp.sh "novel approaches to caching strategies" deep
#   ./brainstorm-qp.sh "naming conventions for microservices"
# =============================================================================

set -euo pipefail

TOPIC="${1:-}"
DEPTH="${2:-standard}"
START_TIME=$(date +%s)
WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JULIA=/snap/julia/165/bin/julia
SPAWNER="$WORKSPACE_DIR/scripts/ml/agent-spawner-qp.jl"

# --- Input validation --------------------------------------------------------
if [[ -z "$TOPIC" ]]; then
  echo "Usage: $0 \"<challenge_or_topic>\" [depth: quick|standard|deep]"
  exit 1
fi

echo "🕶️  Morpheus Brainstorm Workflow"
echo "   Challenge: $TOPIC"
echo "   Depth: $DEPTH"
echo ""

# --- Creative ideation agent selection ----------------------------------------
# Echo is primary creative lead for all depths.
# Depth determines supporting agents:
# - quick: Echo only (rapid-fire ideas)
# - standard: Echo + Scout (research context) + Codex (technical feasibility)
# - deep: Echo + Scout + Codex + Chronicle (structured documentation of ideas)

spawn_brainstorm() {
  local depth="$1"
  
  if [[ "$depth" == "quick" ]]; then
    echo "⚙️  Quick depth → Echo (rapid ideation)"
    $JULIA "$SPAWNER" --task brainstorming --candidates "Echo"
  elif [[ "$depth" == "deep" ]]; then
    echo "⚙️  Deep depth → Echo (creative) + Scout (research) + Codex (technical) + Chronicle (structured docs)"
    $JULIA "$SPAWNER" --task brainstorming --candidates "Echo,Scout,Codex,Chronicle"
  else
    echo "⚙️  Standard depth → Echo (creative) + Scout (research) + Codex (technical feasibility)"
    $JULIA "$SPAWNER" --task brainstorming --candidates "Echo,Scout,Codex"
  fi
}

spawn_brainstorm "$DEPTH"

# --- Outcome logging ---------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""
echo "✅ Brainstorm workflow dispatched."
echo "   Challenge: $TOPIC"
echo "   Depth: $DEPTH"
echo "   Elapsed: ${ELAPSED}s"
echo ""
echo "📝 Log outcome when complete:"
echo "   $JULIA $SPAWNER --log-outcome \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" true|false"
