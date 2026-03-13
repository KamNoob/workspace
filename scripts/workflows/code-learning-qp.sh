#!/usr/bin/env bash
# =============================================================================
# code-learning-qp.sh — Learn by Building with build-your-own-x tutorials
# Phase 2b.0 Integration Template
# =============================================================================
# USAGE:
#   ./code-learning-qp.sh <topic> [depth: light|standard|deep]
#
# EXAMPLES:
#   ./code-learning-qp.sh "database architecture"
#   ./code-learning-qp.sh "web server" standard
#   ./code-learning-qp.sh "neural network" deep
#   ./code-learning-qp.sh "git version control" light
#
# OUTPUTS:
#   - Relevant tutorials for the topic
#   - Implementation patterns and examples
#   - Architecture guidance
#   - Language-specific options
# =============================================================================

set -euo pipefail

TOPIC="${1:-}"
DEPTH="${2:-standard}"
WORKFLOW="code-learning"
AGENT="Codex"
START_TIME=$(date +%s)
WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JULIA=/snap/julia/165/bin/julia
SPAWNER="$WORKSPACE_DIR/scripts/ml/agent-spawner-qp.jl"
BYOX_CLI="node $WORKSPACE_DIR/skills/build-your-own-x/bin/byox-cli.js"

# --- Input validation --------------------------------------------------------
if [[ -z "$TOPIC" ]]; then
  echo "Usage: $0 <topic> [depth: light|standard|deep]"
  echo ""
  echo "Examples:"
  echo "  ./code-learning-qp.sh \"database architecture\""
  echo "  ./code-learning-qp.sh \"web server\" standard"
  echo "  ./code-learning-qp.sh \"neural network\" deep"
  echo "  ./code-learning-qp.sh \"git\" light"
  exit 1
fi

echo "🕶️  Morpheus Code Learning Workflow"
echo "   Topic: $TOPIC"
echo "   Depth: $DEPTH"
echo ""

# --- Search build-your-own-x tutorials ---------------------------------------
search_tutorials() {
  local topic="$1"
  local depth="$2"
  
  echo "⚙️  Searching tutorials for: $topic"
  echo ""
  
  # Search tutorials
  local results=$($BYOX_CLI search "$topic" 2>&1 || echo "No results found")
  
  if [[ "$depth" == "light" ]]; then
    echo "📚 Quick tutorials (top 3):"
    echo "$results" | head -20
  elif [[ "$depth" == "deep" ]]; then
    echo "📚 Comprehensive tutorials (all matches):"
    echo "$results"
  else
    echo "📚 Recommended tutorials:"
    echo "$results" | head -40
  fi
  
  echo ""
}

# --- Quality-aware agent selection -------------------------------------------
spawn_learning_session() {
  local depth="$1"
  
  if [[ "$depth" == "light" ]]; then
    echo "⚙️  Light learning → Codex (implementation only)"
    $JULIA "$SPAWNER" --task learning --candidates "Codex"
  elif [[ "$depth" == "deep" ]]; then
    echo "⚙️  Deep learning → Codex (impl) + Echo (ideation) + Lens (perf analysis) + Chronicle (docs)"
    $JULIA "$SPAWNER" --task learning --candidates "Codex,Echo,Lens,Chronicle"
  else
    echo "⚙️  Standard learning → Codex (impl) + Echo (ideation) + Lens (analysis)"
    $JULIA "$SPAWNER" --task learning --candidates "Codex,Echo,Lens"
  fi
}

search_tutorials "$TOPIC" "$DEPTH"
spawn_learning_session "$DEPTH"

# --- Outcome logging ---------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""
echo "✅ Code Learning workflow dispatched."
echo "   Topic: $TOPIC"
echo "   Depth: $DEPTH"
echo "   Elapsed: ${ELAPSED}s"
echo ""
echo "📝 Log outcome when complete:"
echo "   $JULIA $SPAWNER --log-outcome \"<timestamp>\" true|false"
