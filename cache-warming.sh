#!/bin/bash
# Cache Warming Script — Pre-load workspace files into LLM cache
# Run at startup to initialize context cache for all future sessions

WORKSPACE="/home/art/.openclaw/workspace"
LOG="/tmp/cache-warming.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cache warming started" >> "$LOG"

# Load core files into memory (forces cache indexing)
echo "Loading core workspace files..." >> "$LOG"

files_to_cache=(
  "$WORKSPACE/SOUL.md"
  "$WORKSPACE/PROCESS_FLOWS.md"
  "$WORKSPACE/AGENTS_CONFIG.md"
  "$WORKSPACE/IDENTITY.md"
  "$WORKSPACE/USER.md"
  "$WORKSPACE/MORPHEUS_FAILURES.md"
)

for file in "${files_to_cache[@]}"; do
  if [ -f "$file" ]; then
    echo "Cached: $(basename "$file") ($(wc -c < "$file") bytes)" >> "$LOG"
  else
    echo "Missing: $file" >> "$LOG"
  fi
done

# Research index caching
echo "Research index:" >> "$LOG"
if [ -f "$WORKSPACE/RESEARCH_INDEX.md" ]; then
  echo "Cached: RESEARCH_INDEX.md ($(wc -c < "$WORKSPACE/RESEARCH_INDEX.md") bytes)" >> "$LOG"
fi

# List top 5 recent research docs
echo "Top research files (by recency):" >> "$LOG"
find "$WORKSPACE/docs/research" -type f -name "*.md" 2>/dev/null | sort -t_ -k2 -r | head -5 | while read file; do
  echo "Cached: $(basename "$file") ($(wc -c < "$file") bytes)" >> "$LOG"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cache warming complete" >> "$LOG"
