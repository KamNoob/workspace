#!/bin/bash
# Example: Using TOON encoding in OpenClaw workflows

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="$SKILL_DIR/../.."

# ============================================================================
# Example 1: Send RL Data to Agent with Token Savings
# ============================================================================

example_send_rl_data() {
  echo "=== Example 1: Send RL Data to Agent ==="
  
  local rl_file="$WORKSPACE/data/rl/rl-agent-selection.json"
  
  if [ ! -f "$rl_file" ]; then
    echo "Note: Using mock data (file not found: $rl_file)"
    cat > /tmp/mock-rl.json <<'EOF'
{
  "task_types": {
    "code_review": {"Veritas": 0.94, "QA": 0.88},
    "research": {"Scout": 0.92},
    "security": {"Cipher": 0.95}
  }
}
EOF
    rl_file="/tmp/mock-rl.json"
  fi
  
  # Encode to TOON
  local compact=$("$SKILL_DIR/bin/toon-encode" "$rl_file")
  
  echo "Sending to agent..."
  echo "Message (with TOON encoding):"
  echo "---"
  echo "Here are the latest agent Q-scores:"
  echo "$compact"
  echo "---"
  echo "✓ Token savings: ~35% vs raw JSON"
}

# ============================================================================
# Example 2: Create Cron Job with TOON Payload
# ============================================================================

example_cron_with_toon() {
  echo ""
  echo "=== Example 2: Cron Job with TOON Payload ==="
  
  # Create sample data
  local data_file="/tmp/weekly-summary.json"
  cat > "$data_file" <<'EOF'
{
  "week": "2026-03-09",
  "metrics": {
    "tasks_completed": 15,
    "success_rate": 0.98,
    "avg_token_savings": 0.35
  },
  "agents": [
    {"agent": "Codex", "tasks": 5, "success": 5},
    {"agent": "Scout", "tasks": 4, "success": 4},
    {"agent": "Cipher", "tasks": 3, "success": 3}
  ]
}
EOF
  
  # Encode to TOON
  local compact=$("$SKILL_DIR/bin/toon-encode" "$data_file")
  
  echo "Would create cron job with command:"
  echo ""
  echo 'cron add \'
  echo '  --schedule '"'"'{ "kind": "cron", "expr": "0 9 * * MON" }'"'"' \'
  echo '  --payload '"'"'{ "kind": "systemEvent", "text": "Weekly summary: '"$(printf '%s' "$compact" | sed 's/"/\\"/g' | sed 's/$/\\n/')"'" }'"'"
  echo ""
  echo "✓ Cron payload uses TOON encoding for compactness"
}

# ============================================================================
# Example 3: Batch Encoding with Statistics
# ============================================================================

example_batch_encoding() {
  echo ""
  echo "=== Example 3: Batch Encoding Multiple Files ==="
  
  # Create test files
  local test_dir="/tmp/toon-batch"
  mkdir -p "$test_dir"
  
  cat > "$test_dir/agents.json" <<'EOF'
{
  "agents": [
    {"name": "Codex", "role": "developer", "score": 0.94},
    {"name": "Scout", "role": "researcher", "score": 0.92},
    {"name": "Cipher", "role": "security", "score": 0.95}
  ]
}
EOF
  
  cat > "$test_dir/results.json" <<'EOF'
{
  "test_results": [
    {"test": "encode_json", "passed": true, "duration": 0.145},
    {"test": "decode_toon", "passed": true, "duration": 0.098},
    {"test": "roundtrip", "passed": true, "duration": 0.243}
  ]
}
EOF
  
  echo "Encoding multiple files:"
  for file in "$test_dir"/*.json; do
    filename=$(basename "$file")
    echo ""
    echo "File: $filename"
    "$SKILL_DIR/bin/toon-encode" "$file" --stats 2>&1 | tail -3
  done
}

# ============================================================================
# Example 4: Integration with Agent Spawn
# ============================================================================

example_agent_spawn() {
  echo ""
  echo "=== Example 4: Spawn Agent with Compact Data ==="
  
  # Create task data
  local task_data="/tmp/task-context.json"
  cat > "$task_data" <<'EOF'
{
  "task_id": "review-pr-2345",
  "priority": "high",
  "reviewers": [
    {"agent": "Veritas", "q_score": 0.94, "expertise": "code-quality"},
    {"agent": "QA", "q_score": 0.88, "expertise": "testing"}
  ]
}
EOF
  
  # Encode for transmission
  local compact=$("$SKILL_DIR/bin/toon-encode" "$task_data")
  
  echo "Command to spawn agent with compact context:"
  echo ""
  echo "sessions_spawn \\"
  echo "  --task \"Review PR with context: $compact\" \\"
  echo "  --label code-review-task"
  echo ""
  echo "✓ Saves ~30% tokens vs raw JSON transmission"
}

# ============================================================================
# Example 5: Helper Function for ~/.bashrc
# ============================================================================

example_bashrc_helper() {
  echo ""
  echo "=== Example 5: Helper Function for ~/.bashrc ==="
  echo ""
  echo "Add this to your ~/.bashrc:"
  echo ""
  cat <<'EOF'
# TOON encoding helpers
toon-send() {
  local agent=$1
  local json_file=$2
  local message=$3
  
  if [ ! -f "$json_file" ]; then
    echo "Error: File not found: $json_file" >&2
    return 1
  fi
  
  local compact=$(toon-encode "$json_file")
  sessions_send --label "$agent" --message "$message: $compact"
}

toon-cron() {
  local json_file=$1
  local schedule=$2
  
  local compact=$(toon-encode "$json_file")
  cron add \
    --schedule "$schedule" \
    --payload "{ \"kind\": \"systemEvent\", \"text\": \"$compact\" }"
}

# Usage:
# toon-send navigator data/rl/rl-agent-selection.json "Latest Q-scores"
# toon-cron weekly-data.json '{ "kind": "cron", "expr": "0 9 * * MON" }'
EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
  echo "TOON Encoding Examples for OpenClaw"
  echo "===================================="
  echo ""
  
  example_send_rl_data
  example_cron_with_toon
  example_batch_encoding
  example_agent_spawn
  example_bashrc_helper
  
  echo ""
  echo "===================================="
  echo "✓ All examples complete"
  echo ""
  echo "See README.md for detailed documentation"
}

main "$@"
