#!/bin/bash
# import-memories.sh
# Imports memories from workspace files into Notion Memories database

NOTION_KEY="${NOTION_KEY}"
DB_ID="0b6460d8-3160-4e7e-b666-07070c7f4040"
WORKSPACE="${HOME}/.openclaw/workspace"
MEMORY_DIR="${WORKSPACE}/memory"

if [ -z "$NOTION_KEY" ]; then
  echo "Error: NOTION_KEY environment variable not set"
  exit 1
fi

echo "🧠 Importing memories into Notion..."

add_memory() {
  local title="$1"
  local category="$2"
  local content="$3"
  local source="$4"
  local date="${5:-}"
  local importance="${6:-Medium}"
  
  # Truncate content to 2000 chars
  content="${content:0:2000}"
  
  # Escape JSON
  title=$(echo "$title" | sed 's/"/\\"/g')
  content=$(echo "$content" | sed 's/"/\\"/g' | sed 's/$/\\n/g' | tr -d '\n')
  source=$(echo "$source" | sed 's/"/\\"/g')
  
  # Build properties JSON
  props="{\"Memory\": {\"title\": [{\"text\": {\"content\": \"$title\"}}]}, \"Category\": {\"select\": {\"name\": \"$category\"}}, \"Content\": {\"rich_text\": [{\"text\": {\"content\": \"$content\"}}]}, \"Source\": {\"rich_text\": [{\"text\": {\"content\": \"$source\"}}]}, \"Importance\": {\"select\": {\"name\": \"$importance\"}}}"
  
  if [ -n "$date" ]; then
    props=$(echo "$props" | sed "s/}$/,\"Date\": {\"date\": {\"start\": \"$date\"}}}/")
  fi
  
  # Add tags
  props=$(echo "$props" | sed 's/}$/,"Tags": {"multi_select": [{"name": "Daily Note"}]}}/')
  
  curl -s -X POST "https://api.notion.com/v1/pages" \
    -H "Authorization: Bearer $NOTION_KEY" \
    -H "Notion-Version: 2025-09-03" \
    -H "Content-Type: application/json" \
    -d "{\"parent\": {\"database_id\": \"$DB_ID\"}, \"properties\": $props}" > /dev/null 2>&1
    
  echo "✓ $title"
}

# Import main memory sections
if [ -f "${WORKSPACE}/MEMORY.md" ]; then
  echo ""
  echo "📚 Importing MEMORY.md..."
  
  # Extract sections and key insights
  grep "^## " "${WORKSPACE}/MEMORY.md" | head -10 | while read -r line; do
    section=$(echo "$line" | sed 's/^## //')
    add_memory "$section" "Long-term Knowledge" "Key section from MEMORY.md" "MEMORY.md" "" "High"
  done
fi

# Import recent daily notes
if [ -d "$MEMORY_DIR" ]; then
  echo ""
  echo "📅 Importing recent daily notes..."
  
  ls -1 "$MEMORY_DIR"/*.md 2>/dev/null | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" | sort -r | head -5 | while read -r file; do
    filename=$(basename "$file")
    date=$(echo "$filename" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
    
    echo "  → $filename"
    
    # Extract first 500 chars as preview
    content=$(head -c 500 "$file")
    add_memory "Daily Note: $date" "Daily Note" "$content" "$filename" "$date" "Medium"
  done
fi

echo ""
echo "✅ Import queued! (Notion may take a moment to sync)"
