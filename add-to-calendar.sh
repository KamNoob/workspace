#!/bin/bash
# add-to-calendar.sh
# Add a scheduled task to the Mission Control calendar
# Usage: ./add-to-calendar.sh "Task Name" "one-time|recurring" "Schedule" "Next Run Date" "Description" ["Job ID"]

NOTION_KEY="${NOTION_KEY}"
DB_ID="b9eaba89-09cf-4f64-bc7c-3dc260c95d76"

if [ -z "$1" ]; then
  echo "Usage: $0 \"Task Name\" \"one-time|recurring|heartbeat\" \"Schedule (cron or description)\" \"Next Run (YYYY-MM-DD)\" \"Description\" [Job ID]"
  exit 1
fi

TASK_NAME="$1"
TASK_TYPE="$2"
SCHEDULE="$3"
NEXT_RUN="$4"
DESCRIPTION="$5"
JOB_ID="${6:-}"

# Validate type
if [[ ! "$TASK_TYPE" =~ ^(one-time|recurring|heartbeat)$ ]]; then
  echo "Error: Type must be 'one-time', 'recurring', or 'heartbeat'"
  exit 1
fi

# Build properties JSON
PROPS="{
  \"Task\": {\"title\": [{\"text\": {\"content\": \"$TASK_NAME\"}}]},
  \"Type\": {\"select\": {\"name\": \"$TASK_TYPE\"}},
  \"Status\": {\"select\": {\"name\": \"Scheduled\"}},
  \"Schedule\": {\"rich_text\": [{\"text\": {\"content\": \"$SCHEDULE\"}}]},
  \"Description\": {\"rich_text\": [{\"text\": {\"content\": \"$DESCRIPTION\"}}]}
"

# Add optional fields
if [ -n "$NEXT_RUN" ]; then
  PROPS="$PROPS,\"Next Run\": {\"date\": {\"start\": \"$NEXT_RUN\"}}"
fi

if [ -n "$JOB_ID" ]; then
  PROPS="$PROPS,\"Job ID\": {\"rich_text\": [{\"text\": {\"content\": \"$JOB_ID\"}}]}"
fi

PROPS="$PROPS}"

# Create page
curl -s -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d "{\"parent\": {\"database_id\": \"$DB_ID\"}, \"properties\": $PROPS}" | jq '.id' | head -c 8
  
echo " (added to calendar)"
