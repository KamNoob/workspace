#!/bin/bash
# add-memory.sh
# Quickly add a new memory to the Notion Memories database
# Usage: ./add-memory.sh "Memory Title" "category" "Content text" ["Tags: tag1,tag2"]

NOTION_KEY="${NOTION_KEY}"
DB_ID="0b6460d8-3160-4e7e-b666-07070c7f4040"

if [ -z "$1" ]; then
  echo "Usage: $0 \"Memory Title\" \"category\" \"Content text\" [\"tags: tag1,tag2\"]"
  echo ""
  echo "Categories: Long-term Knowledge, Daily Note, Learning, Decision, Entity, System"
  echo "Default importance: Medium"
  echo ""
  echo "Example:"
  echo "  $0 \"Cache optimization technique\" \"Learning\" \"Implement LRU cache for faster lookups\" \"tags: Performance,Architecture\""
  exit 1
fi

TITLE="$1"
CATEGORY="${2:-Daily Note}"
CONTENT="$3"
TAGS_STR="${4:-}"

# Extract tags if provided
TAGS_JSON=""
if [[ "$TAGS_STR" =~ ^tags:\ (.*)$ ]]; then
  TAGS="${BASH_REMATCH[1]}"
  IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
  TAGS_JSON='"Tags": {"multi_select": ['
  for i in "${!TAG_ARRAY[@]}"; do
    TAG=$(echo "${TAG_ARRAY[$i]}" | xargs)
    TAGS_JSON="${TAGS_JSON}{\"name\": \"$TAG\"}"
    [ $i -lt $((${#TAG_ARRAY[@]} - 1)) ] && TAGS_JSON="${TAGS_JSON},"
  done
  TAGS_JSON="${TAGS_JSON}]},"
fi

# Truncate content to 2000 chars
CONTENT_TRUNC="${CONTENT:0:2000}"

# Escape special chars for JSON
TITLE_JSON=$(echo "$TITLE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
CONTENT_JSON=$(echo "$CONTENT_TRUNC" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
CATEGORY_JSON=$(echo "$CATEGORY" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

# Get today's date
DATE=$(date +%Y-%m-%d)

# Build the payload
PAYLOAD="{
  \"parent\": {\"database_id\": \"$DB_ID\"},
  \"properties\": {
    \"Memory\": {\"title\": [{\"text\": {\"content\": \"$TITLE_JSON\"}}]},
    \"Category\": {\"select\": {\"name\": \"$CATEGORY_JSON\"}},
    \"Importance\": {\"select\": {\"name\": \"Medium\"}},
    \"Date\": {\"date\": {\"start\": \"$DATE\"}},
    \"Content\": {\"rich_text\": [{\"text\": {\"content\": \"$CONTENT_JSON\"}}]},
    $TAGS_JSON
    \"Source\": {\"rich_text\": [{\"text\": {\"content\": \"Manual entry\"}}]}
  }
}"

curl -s -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" | jq -r '.id' | head -c 8

echo " (saved)"
