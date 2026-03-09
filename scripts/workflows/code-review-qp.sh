#!/usr/bin/env bash
# =============================================================================
# code-review-qp.sh — Code Review Workflow with spawn-smart integration
# Phase 2b.0 Integration Template
# =============================================================================
# USAGE:
#   ./code-review-qp.sh <pr_url_or_path> [complexity: low|medium|high]
#
# EXAMPLES:
#   ./code-review-qp.sh https://github.com/org/repo/pull/42
#   ./code-review-qp.sh ./src/feature.ts high
#   ./code-review-qp.sh "review auth module changes" medium
# =============================================================================

set -euo pipefail

TASK="${1:-}"
COMPLEXITY="${2:-medium}"
WORKFLOW="code-review"
AGENT="Codex"
START_TIME=$(date +%s)
WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JULIA=/snap/julia/165/bin/julia
SPAWNER="$WORKSPACE_DIR/scripts/ml/agent-spawner-qp.jl"

# --- Input validation --------------------------------------------------------
if [[ -z "$TASK" ]]; then
  echo "Usage: $0 <pr_url_or_path> [complexity: low|medium|high]"
  exit 1
fi

echo "🕶️  Morpheus Code Review Workflow"
echo "   Task: $TASK"
echo "   Complexity: $COMPLEXITY"
echo ""

# --- Quality-aware agent selection -------------------------------------------
# Use spawn-smart to decide: Codex vs Codex+QA+Veritas

spawn_code_review() {
  local complexity="$1"
  
  if [[ "$complexity" == "low" ]]; then
    echo "⚙️  Low complexity → Spawning Codex only..."
    $JULIA "$SPAWNER" --task code --candidates "Codex"
  elif [[ "$complexity" == "high" ]]; then
    echo "⚙️  High complexity → Spawning Codex (primary) + QA (review) + Veritas (validation)..."
    $JULIA "$SPAWNER" --task review --candidates "Codex,QA,Veritas"
  else
    echo "⚙️  Medium complexity → Spawning Codex + QA..."
    $JULIA "$SPAWNER" --task code --candidates "Codex,QA"
  fi
}

spawn_code_review "$COMPLEXITY"

# --- Outcome logging ---------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""
echo "✅ Code Review workflow dispatched."
echo "   Task: $TASK"
echo "   Elapsed: ${ELAPSED}s"
echo ""
echo "📝 Log outcome when complete:"
echo "   $JULIA $SPAWNER --log-outcome \"<timestamp>\" true|false"
