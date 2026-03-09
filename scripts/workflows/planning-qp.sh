#!/usr/bin/env bash
# =============================================================================
# planning-qp.sh — Project Planning & Management Workflow
# Phase 2a Integration Template with Navigator routing
# =============================================================================
# USAGE:
#   ./planning-qp.sh "<scope>" [complexity: quick|standard|comprehensive]
#
# EXAMPLES:
#   ./planning-qp.sh "sprint planning for march data pipeline" standard
#   ./planning-qp.sh "quarterly roadmap and milestone planning" comprehensive
#   ./planning-qp.sh "project kickoff and timeline estimation" quick
# =============================================================================

set -euo pipefail

TASK="${1:-}"
COMPLEXITY="${2:-standard}"
WORKFLOW="planning"
AGENT="Navigator"
START_TIME=$(date +%s)
WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JULIA=/snap/julia/165/bin/julia
SPAWNER="$WORKSPACE_DIR/scripts/ml/agent-spawner-qp.jl"

# --- Input validation --------------------------------------------------------
if [[ -z "$TASK" ]]; then
  echo "Usage: $0 \"<scope>\" [complexity: quick|standard|comprehensive]"
  exit 1
fi

# --- Map complexity to workflow config ----------------------------------------
case "$COMPLEXITY" in
  quick) DEPTH="quick" ;;
  standard) DEPTH="standard" ;;
  comprehensive) DEPTH="comprehensive" ;;
  *) echo "Invalid complexity: $COMPLEXITY"; exit 1 ;;
esac

# --- Header --------------------------------------------------------
echo ""
echo "🕶️  Morpheus Project Planning Workflow"
echo "   Scope: $TASK"
echo "   Complexity: $COMPLEXITY"
echo ""

# --- Call spawn-smart with Navigator ----------------------------------------
echo "⚙️  $COMPLEXITY planning → Spawning Navigator (deputy commander) + optional Veritas..."
echo ""

RESULT=$($JULIA $SPAWNER --task planning --candidates "Navigator,Veritas,Codex")
DECISION=$(echo "$RESULT" | grep "Decision:" | awk '{print $NF}')
AGENT=$(echo "$RESULT" | grep "Selected:" | awk '{print $2}')
TIMESTAMP=$(echo "$RESULT" | grep "Timestamp:" | awk '{print $NF}')

# --- Print prediction result -----------------------------------------------
echo "$RESULT"
echo ""

# --- Execute based on decision -----------------------------------------------
if [[ "$DECISION" == "spawn" ]]; then
  ELAPSED=$(($(date +%s) - START_TIME))
  echo "✅ Planning workflow dispatched."
  echo "   Scope: $TASK"
  echo "   Complexity: $COMPLEXITY"
  echo "   Elapsed: ${ELAPSED}s"
  echo ""
  echo "📝 Log outcome when complete:"
  echo "   $JULIA $SPAWNER --log-outcome \"$TIMESTAMP\" true|false"
  echo ""
else
  echo "⚠️  Quality prediction recommends manual review"
  exit 1
fi
