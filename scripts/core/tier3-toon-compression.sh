#!/bin/bash
# Tier 3: TOON Compression for Agent-to-Agent & Cron Payloads
# Reduces context payload size 30-50%, speeds up transmission
# Use in workflows that spawn agents or queue cron jobs

set -euo pipefail

WORKSPACE="/home/art/.openclaw/workspace"
TOON_BIN="${WORKSPACE}/skills/toon-encoding/bin/toon-encode"

# Example 1: Compress MEMORY.md before sending to agent
compress_memory() {
  local output="${1:-.}"
  
  if [[ ! -x "$TOON_BIN" ]]; then
    echo "Error: toon-encode not found. Install: npm install toon-encoding" >&2
    return 1
  fi
  
  echo "Compressing MEMORY.md..."
  
  # Read MEMORY.md, encode to TOON, output base64
  local original_size=$(wc -c < "$WORKSPACE/MEMORY.md")
  local compressed=$("$TOON_BIN" < "$WORKSPACE/MEMORY.md" | base64 -w 0)
  local compressed_size=$(echo "$compressed" | wc -c)
  
  echo "Original: $original_size bytes"
  echo "Compressed: $compressed_size bytes"
  echo "Compression ratio: $(echo "scale=2; ($original_size - $compressed_size) * 100 / $original_size" | bc)%"
  
  # Save for agent transmission
  echo "$compressed" > "$output/memory.toon.b64"
  echo "✓ Saved to: $output/memory.toon.b64"
}

# Example 2: Compress RL data before storing in cron
compress_rl_data() {
  local output="${1:-.}"
  
  if [[ ! -x "$TOON_BIN" ]]; then
    echo "Error: toon-encode not found" >&2
    return 1
  fi
  
  echo "Compressing RL training data..."
  
  local original_size=$(wc -c < "$WORKSPACE/data/rl/rl-agent-selection.json")
  local compressed=$("$TOON_BIN" < "$WORKSPACE/data/rl/rl-agent-selection.json" | base64 -w 0)
  local compressed_size=$(echo "$compressed" | wc -c)
  
  echo "Original: $original_size bytes"
  echo "Compressed: $compressed_size bytes"
  echo "Compression ratio: $(echo "scale=2; ($original_size - $compressed_size) * 100 / $original_size" | bc)%"
  
  echo "$compressed" > "$output/rl-selection.toon.b64"
  echo "✓ Saved to: $output/rl-selection.toon.b64"
}

# Example 3: Compress workflow payload
compress_workflow_context() {
  local task_description="$1"
  local output="${2:-.}"
  
  if [[ ! -x "$TOON_BIN" ]]; then
    echo "Error: toon-encode not found" >&2
    return 1
  fi
  
  echo "Compressing workflow context for: $task_description"
  
  # Create a temporary JSON with task + system context
  local temp_payload=$(mktemp)
  cat > "$temp_payload" << EOF
{
  "task": "$task_description",
  "workspace": "$WORKSPACE",
  "timestamp": "$(date -Iseconds)",
  "context": {
    "system": "$(cat "$WORKSPACE/SOUL.md" | head -20)",
    "user": "$(cat "$WORKSPACE/USER.md" | head -20)",
    "team": "$(cat "$WORKSPACE/IDENTITY.md" | head -20)"
  }
}
EOF
  
  local original_size=$(wc -c < "$temp_payload")
  local compressed=$("$TOON_BIN" < "$temp_payload" | base64 -w 0)
  local compressed_size=$(echo "$compressed" | wc -c)
  
  echo "Original: $original_size bytes"
  echo "Compressed: $compressed_size bytes"
  echo "Compression ratio: $(echo "scale=2; ($original_size - $compressed_size) * 100 / $original_size" | bc)%"
  
  echo "$compressed" > "$output/workflow-context.toon.b64"
  echo "✓ Saved to: $output/workflow-context.toon.b64"
  
  rm "$temp_payload"
}

# Main: Show compression examples
main() {
  local output_dir="${1:-.}"
  mkdir -p "$output_dir"
  
  echo "=== Tier 3: TOON Compression Examples ==="
  echo ""
  
  echo "1. Compress MEMORY.md (for agent transmission)"
  compress_memory "$output_dir"
  echo ""
  
  echo "2. Compress RL data (for cron storage)"
  compress_rl_data "$output_dir"
  echo ""
  
  echo "3. Compress workflow context (task + system state)"
  compress_workflow_context "example task" "$output_dir"
  echo ""
  
  echo "✓ All examples complete"
  echo "Output files in: $output_dir/"
  ls -lh "$output_dir"/*.toon.b64
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${1:-.}"
fi
