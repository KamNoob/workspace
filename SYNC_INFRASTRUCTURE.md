# SYNC_INFRASTRUCTURE.md - Sync Scripts & Cron Jobs

_Setup complete: 2026-03-21 11:29 GMT_

---

## Overview

Sync infrastructure enables automated data synchronization between systems:
- Memory to Knowledge Base (daily)
- Tasks to Cron Scheduler (daily)
- Agent Status to Notion (hourly)
- Phase 11 SLA & Compliance (daily/weekly)

---

## Directories

| Path | Purpose | Status |
|------|---------|--------|
| `~/sync-scripts/` | Bash scripts for data sync | ✅ Created |
| `~/sync-logs/` | Log files from sync runs | ✅ Created |

---

## Sync Scripts

### 1. sync-memory-to-kb.sh
**Purpose:** Sync MEMORY.md to Knowledge Base  
**Schedule:** Daily @ 00:05 UTC  
**Cron Job:** `f2a2f272-de61-41e5-86f9-05dacff13f67`  
**Log:** `~/sync-logs/memory-to-kb.log`

**What it does:**
- Reads MEMORY.md from workspace
- Extracts key sections (decisions, learnings, system improvements)
- Syncs to Knowledge Base (Notion or local JSON)
- Logs summary to sync-logs

**Next steps:** Integrate with Notion API when NOTION_KEY configured

---

### 2. sync-tasks-to-cron.sh
**Purpose:** Sync tasks from Notion to Cron Scheduler  
**Schedule:** Daily @ 01:00 UTC  
**Cron Job:** `32ba23a0-abe0-40df-b58c-1f1af8f972bb`  
**Log:** `~/sync-logs/tasks-to-cron.log`

**What it does:**
- Queries Notion Task Board (if NOTION_KEY configured)
- Parses task due dates
- Schedules tasks via `openclaw cron add`
- Logs scheduled jobs

**Next steps:** Integrate with Notion API for task sync

---

### 3. sync-agent-status.sh
**Purpose:** Sync agent status to Notion Team DB  
**Schedule:** Hourly @ :00 UTC (with 5-minute stagger)  
**Cron Job:** `a1c1f39c-2c30-473a-9894-03c7e06e64ee`  
**Log:** `~/sync-logs/agent-status.log`

**What it does:**
- Reads Q-learning scores (rl-agent-selection.json)
- Checks task execution logs (rl-task-execution-log.jsonl)
- Reviews Phase 11 audit logs (data/audit-logs/)
- Calculates agent health metrics
- Syncs to Notion Team DB (if configured)

**Next steps:** Integrate with Notion API for team status sync

---

## Phase 11 Cron Jobs

### Phase 11A: SLA Daily Calculator
**Job ID:** `e00a56cf-69b2-4daa-8b95-c296ef3c2fb5`  
**Schedule:** Daily @ 02:00 UTC  
**Payload:** System event (main session)  
**Next Run:** 2026-03-22 02:00 UTC

**What it does:**
- Analyzes Phase 11 audit logs
- Calculates SLA metrics: latency, success rate, cost, quality
- Writes results to `data/sla-metrics/YYYY-MM-DD.json`
- Alerts on SLA breaches

---

### Phase 11B: Compliance Weekly Reporter
**Job ID:** `6b9ed0c0-35fb-4cbd-bd0e-21c5012905ea`  
**Schedule:** Weekly @ 10:00 UTC (Mondays)  
**Payload:** System event (main session)  
**Next Run:** 2026-03-24 10:00 UTC

**What it does:**
- Generates auditable compliance report from audit logs
- Creates: `data/compliance-reports/YYYY-WW.json`
- Includes: task distribution, agent performance, SLA compliance, anomalies
- Ready for regulatory reviews

---

## Full Cron Job Schedule

| Job | Time (UTC) | Frequency | Status |
|-----|-----------|-----------|--------|
| Phase 7B Insights Generator | Every hour | Hourly | ✅ Active |
| **Sync: Agent Status** | Every hour | Hourly | ✅ **NEW** |
| **Sync: Memory to KB** | 00:05 | Daily | ✅ **NEW** |
| **Sync: Tasks to Cron** | 01:00 | Daily | ✅ **NEW** |
| Phase 5 Memory Pruning | 02:00 | Daily | ✅ Active |
| **Phase 11 SLA Calculator** | 02:00 | Daily | ✅ **NEW** |
| Phase 11B SLA Calculation | 02:30 | Daily | ✅ Active |
| Phase 4 Dashboard | 10:00 | Monday | ✅ Active |
| **Phase 11 Compliance Reporter** | 10:00 | Monday | ✅ **NEW** |
| Phase 11C Compliance Report | 10:00 | Monday | ✅ Active |
| Weekly Agent Test Cycles | 09:00 | Friday | ✅ Active |
| Monthly Network Scan | 03:00 | 1st day | ✅ Active |

---

## Environment Setup

### Required Environment Variables

Add these to `~/.openclaw/.env` for full functionality:

```bash
# Notion integration (optional, for task/team syncing)
NOTION_KEY=ntn_...
NOTION_COMMAND_CENTER_ID=...
NOTION_PROJECTS_DB_ID=...
NOTION_TASKS_DB_ID=...
NOTION_TEAM_DB_ID=...

# Gateway token (for cron commands)
OPENCLAW_GATEWAY_TOKEN=...
```

### Testing Sync Scripts

Test individual scripts:
```bash
# Test memory sync
bash ~/sync-scripts/sync-memory-to-kb.sh
tail ~/sync-logs/memory-to-kb.log

# Test tasks sync
bash ~/sync-scripts/sync-tasks-to-cron.sh
tail ~/sync-logs/tasks-to-cron.log

# Test agent status sync
bash ~/sync-scripts/sync-agent-status.sh
tail ~/sync-logs/agent-status.log
```

---

## Monitoring

### Check sync logs
```bash
# Recent memory-to-kb activity
tail -20 ~/sync-logs/memory-to-kb.log

# Recent tasks-to-cron activity
tail -20 ~/sync-logs/tasks-to-cron.log

# Recent agent-status activity
tail -20 ~/sync-logs/agent-status.log
```

### Check cron job status
```bash
# List all cron jobs
openclaw cron list

# Check specific job
openclaw cron runs <job-id>

# View last run
openclaw cron runs <job-id> --limit 1
```

---

## Phase 11 Integration

Phase 11 (Audit + SLA + Compliance) is **LIVE**:

✅ **Phase 11A:** Audit Logger (immutable JSON-L logs, writing events)  
✅ **Phase 11B:** SLA Calculator (cron scheduled 02:00 UTC)  
✅ **Phase 11C:** Compliance Reporter (cron scheduled 10:00 UTC Mondays)

**Status:** All components operational, audit logs accumulating in `data/audit-logs/`

---

## Next Steps

1. ✅ Directories created
2. ✅ Scripts deployed
3. ✅ Cron jobs scheduled
4. 🟡 Integrate Notion API (when credentials available)
5. 🟡 Monitor sync logs for errors
6. 🟡 Review SLA/compliance reports on Monday

---

## Architecture Diagram

```
Workspace Data                  Sync Scripts                  Output
─────────────────────────────────────────────────────────────────────

MEMORY.md ───────→ sync-memory-to-kb.sh ────→ Knowledge Base (Notion/JSON)
                                             └─→ ~/sync-logs/memory-to-kb.log

Notion Tasks ────→ sync-tasks-to-cron.sh ───→ Cron Scheduler (openclaw cron)
                                             └─→ ~/sync-logs/tasks-to-cron.log

Q-scores ────────→ sync-agent-status.sh ────→ Notion Team DB
Audit Logs ─┐                              └─→ ~/sync-logs/agent-status.log
Exec Log ───┘

Phase 11 Audit ──→ Phase 11A: SLA Calculator ──→ data/sla-metrics/YYYY-MM-DD.json
(every 24h)

Phase 11 Audit ──→ Phase 11B: Compliance ─────→ data/compliance-reports/YYYY-WW.json
(every Monday)
```

---

_Setup completed: 2026-03-21 11:29 GMT_  
_All directories, scripts, and cron jobs operational._
