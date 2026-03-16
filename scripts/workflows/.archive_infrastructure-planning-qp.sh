#!/usr/bin/env bash
# =============================================================================
# infrastructure-planning-qp.sh — LLM Infrastructure Planning with llmfit
# Phase 2b.0 Integration Template
# =============================================================================
# USAGE:
#   ./infrastructure-planning-qp.sh <ram_gb> <vram_gb> <cpu_cores> [complexity: low|medium|full]
#
# EXAMPLES:
#   ./infrastructure-planning-qp.sh 32 8 8
#   ./infrastructure-planning-qp.sh 16 0 4 low
#   ./infrastructure-planning-qp.sh 64 24 16 full
#
# OUTPUTS:
#   - Model recommendations for your hardware
#   - Fit analysis (perfect/good/marginal/tootight)
#   - Speed estimates (tokens/sec)
#   - Hardware upgrade recommendations
# =============================================================================

set -euo pipefail

RAM_GB="${1:-}"
VRAM_GB="${2:-}"
CPU_CORES="${3:-}"
COMPLEXITY="${4:-medium}"
WORKFLOW="infrastructure-planning"
AGENT="Sentinel"
START_TIME=$(date +%s)
WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
JULIA=/snap/julia/165/bin/julia
SPAWNER="$WORKSPACE_DIR/scripts/ml/agent-spawner-qp.jl"
LLMFIT_CLI="node $WORKSPACE_DIR/skills/llmfit-infrastructure/bin/sentinel-llmfit.js"

# --- Input validation --------------------------------------------------------
if [[ -z "$RAM_GB" || -z "$VRAM_GB" || -z "$CPU_CORES" ]]; then
  echo "Usage: $0 <ram_gb> <vram_gb> <cpu_cores> [complexity: low|medium|full]"
  echo ""
  echo "Examples:"
  echo "  ./infrastructure-planning-qp.sh 32 8 8"
  echo "  ./infrastructure-planning-qp.sh 16 0 4 low"
  echo "  ./infrastructure-planning-qp.sh 64 24 16 full"
  exit 1
fi

echo "🕶️  Morpheus Infrastructure Planning Workflow"
echo "   Hardware: ${RAM_GB}GB RAM, ${VRAM_GB}GB VRAM, ${CPU_CORES} CPU cores"
echo "   Complexity: $COMPLEXITY"
echo ""

# --- Run llmfit analysis -----------------------------------------------------
analyze_infrastructure() {
  local ram="$1"
  local vram="$2"
  local cores="$3"
  local complexity="$4"
  
  echo "⚙️  Analyzing with llmfit-infrastructure..."
  echo ""
  
  # Run llmfit analysis
  $LLMFIT_CLI analyze "$ram" "$vram" "$cores" > /tmp/llmfit-analysis.json 2>&1
  
  if [[ "$complexity" == "low" ]]; then
    echo "📊 Top 5 model recommendations:"
    node -e "
      const data = require('/tmp/llmfit-analysis.json');
      data.slice(0, 5).forEach(m => {
        console.log('  [' + m.fit.toUpperCase() + '] ' + m.name + ' (' + m.params + ')');
        console.log('    Mode: ' + m.run_mode + ' | TPS: ' + m.estimated_tps);
      });
    "
  elif [[ "$complexity" == "full" ]]; then
    echo "📊 Detailed analysis (full output):"
    cat /tmp/llmfit-analysis.json | jq '.' | head -100
  else
    echo "📊 Model recommendations:"
    node -e "
      const data = require('/tmp/llmfit-analysis.json');
      data.slice(0, 10).forEach(m => {
        const util = m.utilization;
        console.log('  [' + m.fit.toUpperCase() + '] ' + m.name);
        console.log('    Params: ' + m.params + ' | Mode: ' + m.run_mode + ' | TPS: ' + m.estimated_tps);
        console.log('    RAM: ' + util.ram_percent + '% | VRAM: ' + util.vram_percent + '%');
      });
    "
  fi
  
  echo ""
}

# --- Quality-aware agent selection -------------------------------------------
spawn_infrastructure_analysis() {
  local complexity="$1"
  
  if [[ "$complexity" == "low" ]]; then
    echo "⚙️  Low complexity → Spawning Sentinel only..."
    $JULIA "$SPAWNER" --task infrastructure --candidates "Sentinel"
  elif [[ "$complexity" == "full" ]]; then
    echo "⚙️  Full analysis → Spawning Sentinel + Lens + Navigator..."
    $JULIA "$SPAWNER" --task infrastructure --candidates "Sentinel,Lens,Navigator"
  else
    echo "⚙️  Medium complexity → Spawning Sentinel + Lens..."
    $JULIA "$SPAWNER" --task infrastructure --candidates "Sentinel,Lens"
  fi
}

analyze_infrastructure "$RAM_GB" "$VRAM_GB" "$CPU_CORES" "$COMPLEXITY"
spawn_infrastructure_analysis "$COMPLEXITY"

# --- Outcome logging ---------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo ""
echo "✅ Infrastructure Planning workflow dispatched."
echo "   Hardware: ${RAM_GB}GB RAM, ${VRAM_GB}GB VRAM, ${CPU_CORES} cores"
echo "   Elapsed: ${ELAPSED}s"
echo ""
echo "📝 Log outcome when complete:"
echo "   $JULIA $SPAWNER --log-outcome \"<timestamp>\" true|false"
