#!/usr/bin/env bash
# =============================================================================
# security-audit-qp.sh — Security Audit Workflow with spawn-smart integration
# Phase 2b.0 Integration Template
# =============================================================================
# USAGE:
#   ./security-audit-qp.sh "<target>" [scope: quick|standard|full]
#
# EXAMPLES:
#   ./security-audit-qp.sh "auth service" standard
#   ./security-audit-qp.sh "payment API endpoints" full
#   ./security-audit-qp.sh "npm dependencies" quick
# =============================================================================

set -euo pipefail

TARGET="${1:-}"
SCOPE="${2:-standard}"
START_TIME=$(date +%s)
WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JULIA=/snap/julia/165/bin/julia
SPAWNER="$WORKSPACE_DIR/scripts/ml/agent-spawner-qp.jl"

# --- Input validation --------------------------------------------------------
if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 \"<target>\" [scope: quick|standard|full]"
  exit 1
fi

echo "🕶️  Morpheus Security Audit Workflow"
echo "   Target: $TARGET"
echo "   Scope: $SCOPE"
echo ""

# --- Quality-aware agent selection -------------------------------------------
# quick    → Cipher vulnerability scan
# standard → Cipher + Veritas validation
# full     → Cipher + Sentinel (infra) + Veritas (validation)

spawn_security_audit() {
  local scope="$1"
  
  if [[ "$scope" == "quick" ]]; then
    echo "🔒 Quick scan → Spawning Cipher only..."
    $JULIA "$SPAWNER" --task security --candidates "Cipher"
  elif [[ "$scope" == "full" ]]; then
    echo "🛡️  Full audit → Spawning Cipher (primary) + Sentinel (infra) + Veritas (validation)..."
    $JULIA "$SPAWNER" --task security --candidates "Cipher,Sentinel,Veritas"
  else
    echo "🔒 Standard audit → Spawning Cipher + Veritas..."
    $JULIA "$SPAWNER" --task security --candidates "Cipher,Veritas"
  fi
}

spawn_security_audit "$SCOPE"

# --- Outcome logging ---------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""
echo "✅ Security audit workflow dispatched."
echo "   Target: $TARGET"
echo "   Scope: $SCOPE"
echo "   Elapsed: ${ELAPSED}s"
echo ""
echo "📝 Log outcome when complete:"
echo "   $JULIA $SPAWNER --log-outcome \"<timestamp>\" true|false"
