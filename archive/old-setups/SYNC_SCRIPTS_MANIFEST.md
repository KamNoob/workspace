# OpenClaw ↔ Notion Sync Scripts Manifest

**Location:** `/home/art/.openclaw/sync-scripts/`  
**Created:** 2026-02-20 10:44 UTC  
**Status:** ✅ All 4 scripts live and executable

---

## Script Overview

| Script | Purpose | Trigger | Frequency |
|--------|---------|---------|-----------|
| `sync-memory-to-kb.sh` | Memory → Knowledge Base | Cron (scheduled) | Daily 00:05 UTC |
| `sync-tasks-to-cron.sh` | Tasks → Cron Queue | Cron (scheduled) | Daily 01:00 UTC |
| `sync-agent-status.sh` | Agent Status → Team DB | Cron (scheduled) | Hourly :00 |
| `sync-cron-to-tasks.sh` | Cron Completion → Tasks | Event hook (real-time) | On job completion |

---

## Script Details

### 1. sync-memory-to-kb.sh
**Purpose:** Sync your memory entries (MEMORY.md + daily logs) to Notion Knowledge Base

**Environment Variables Required:**
- `NOTION_KEY` — Notion API token
- `NOTION_KB_DB_ID` — Knowledge Base database ID

**Execution:**
```bash
/home/art/.openclaw/sync-scripts/sync-memory-to-kb.sh
```

**What It Does:**
1. Reads `/home/art/.openclaw/workspace/MEMORY.md`
2. Reads daily memory logs: `/home/art/.openclaw/workspace/memory/YYYY-MM-DD.md`
3. Computes SHA256 hashes to detect changes
4. Posts new/updated entries to Notion Knowledge Base
5. Tracks sync state in `notion_sync_state.json`

**Log Output:**
- `~/sync-logs/memory-to-kb.log`

---

### 2. sync-tasks-to-cron.sh
**Purpose:** Query Notion for high-priority tasks and create OpenClaw cron jobs

**Environment Variables Required:**
- `NOTION_KEY` — Notion API token
- `NOTION_TASKS_DB_ID` — Tasks database ID

**Execution:**
```bash
/home/art/.openclaw/sync-scripts/sync-tasks-to-cron.sh
```

**What It Does:**
1. Queries Notion Tasks database
2. Filters for: `Priority = High` AND `Status = Todo`
3. For each task, checks if a cron job already exists
4. Creates/updates cron jobs in OpenClaw if needed
5. Links task due dates to cron job schedules

**Log Output:**
- `~/sync-logs/tasks-to-cron.log`

---

### 3. sync-agent-status.sh
**Purpose:** Hourly sync of agent availability to Notion Team/Agents DB

**Environment Variables Required:**
- `NOTION_KEY` — Notion API token
- `NOTION_TEAM_DB_ID` — Team/Agents database ID

**Execution:**
```bash
/home/art/.openclaw/sync-scripts/sync-agent-status.sh
```

**What It Does:**
1. Queries OpenClaw for current agent status (active/idle/offline)
2. Gets list of active sessions per agent
3. Updates or creates entries in Notion Team/Agents DB
4. Tracks last-seen timestamps

**Log Output:**
- `~/sync-logs/agent-status.log`

---

### 4. sync-cron-to-tasks.sh
**Purpose:** Log cron job completions to Notion Tasks DB (real-time)

**Environment Variables Required:**
- `NOTION_KEY` — Notion API token
- `NOTION_TASKS_DB_ID` — Tasks database ID

**Execution (with parameters):**
```bash
/home/art/.openclaw/sync-scripts/sync-cron-to-tasks.sh "Job Name" "status" "duration_ms" "exit_code"

# Example:
/home/art/.openclaw/sync-scripts/sync-cron-to-tasks.sh "backup-memory" "Completed" "5000" "0"
```

**Parameters:**
- `Job Name` — Name of the cron job (e.g., "backup-memory")
- `Status` — Job outcome (e.g., "Completed", "Failed")
- `Duration MS` — How long it took in milliseconds
- `Exit Code` — Unix exit code (0 = success)

**What It Does:**
1. Formats job completion data
2. Determines Notion Status based on exit code
3. POSTs completion record to Tasks database
4. Tags with "automation, cron"

**Log Output:**
- `~/sync-logs/cron-to-tasks.log`

---

## Environment Setup

All scripts read from the `.env` file automatically:

```bash
# In ~/.openclaw/.env:
NOTION_KEY=ntn_...
NOTION_COMMAND_CENTER_ID=52dab2f6-...
NOTION_PROJECTS_DB_ID=...
NOTION_TASKS_DB_ID=...
NOTION_TEAM_DB_ID=...
NOTION_KB_DB_ID=...
```

**Already configured:** ✅ Config Manager saved all IDs

---

## Manual Testing

Test a single script:

```bash
# Test memory sync
bash /home/art/.openclaw/sync-scripts/sync-memory-to-kb.sh

# Check logs
tail -f ~/sync-logs/memory-to-kb.log
```

---

## Cron Job Integration

The 3 scheduled syncs are already in your OpenClaw cron system:

```bash
# View scheduled jobs
openclaw cron list

# Expected output:
# - Memory → Knowledge Base Sync (00:05 UTC)
# - Tasks → Cron Queue Sync (01:00 UTC)
# - Agent Status Sync (every hour at :00)
```

---

## Logging & Monitoring

All scripts log to `~/sync-logs/`:
- `memory-to-kb.log` — Memory sync activity
- `tasks-to-cron.log` — Task import activity
- `agent-status.log` — Agent status updates
- `cron-to-tasks.log` — Cron completion records

Monitor in real-time:
```bash
tail -f ~/sync-logs/*.log
```

---

## Error Handling

Each script includes:
- ✅ Environment variable validation
- ✅ curl error checking
- ✅ jq JSON parsing with fallbacks
- ✅ Comprehensive logging
- ✅ Exit code propagation

If a script fails:
1. Check the `.log` file for details
2. Verify env variables are set: `env | grep NOTION`
3. Test Notion connectivity: `curl -H "Authorization: Bearer $NOTION_KEY" https://api.notion.com/v1/users/me`

---

## Future Enhancements

Potential improvements:
- Bidirectional conflict detection (both sides modified)
- Automatic retry on rate-limit (429 errors)
- Slack notifications on sync failure
- Incremental sync (don't re-sync unchanged entries)
- Custom mapping rules (project → cron schedule)

---

## Support

If issues arise:
1. Check logs: `cat ~/sync-logs/[script-name].log`
2. Verify .env: `grep NOTION ~/.openclaw/.env`
3. Test API: `curl -H "Authorization: Bearer $NOTION_KEY" https://api.notion.com/v1/search`

---

**Last Updated:** 2026-02-20 10:44 UTC
