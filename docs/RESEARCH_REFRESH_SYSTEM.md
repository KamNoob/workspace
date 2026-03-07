# Research Refresh System — Automated Knowledge Updates

**Status:** ✅ LIVE (2026-03-07)  
**Purpose:** Automatically monitor research freshness and trigger updates when stale  

---

## Overview

The Research Refresh System ensures OpenClaw's knowledge base stays current by:
1. Monitoring research file ages (via RESEARCH_INDEX.md)
2. Flagging stale research (overdue for refresh)
3. Alerting Morpheus to trigger Scout updates
4. (Future) Automatically updating research files

---

## Components

### 1. Research Index (`RESEARCH_INDEX.md`)

**Master catalog** of all research documents with refresh metadata:

```markdown
#### Dynamic Neural Architectures (2026)
- **File:** `docs/research/technology/dynamic-neural-architectures-2026.md`
- **Status:** Active
- **Created:** 2026-03-06
- **Refresh:** 30 days (next: 2026-04-05)
```

**Refresh Cycles:**
- **Technology topics:** 30 days (fast-moving)
- **General topics:** 90 days (stable)
- **Custom:** Adjust per topic

### 2. Checker Script (`scripts/check-research-refresh.py`)

**Python script** that parses RESEARCH_INDEX.md and checks staleness:

```bash
# Manual check (human-readable)
python3 scripts/check-research-refresh.py

# JSON output (for automation)
python3 scripts/check-research-refresh.py --json

# Show only stale research
python3 scripts/check-research-refresh.py --stale-only
```

**Output:**
- 🔴 OVERDUE: Past refresh date
- 🟡 DUE SOON: Within 7 days of refresh date
- 🟢 FRESH: >7 days until refresh

**Exit Codes:**
- `0` = All research fresh
- `1` = Stale research found

### 3. Cron Job (`scripts/research-refresh-cron.sh`)

**Daily automated check** (runs at 08:00 AM local time):

```bash
# Crontab entry
0 8 * * * /home/art/.openclaw/workspace/scripts/research-refresh-cron.sh

# Manual run
~/.openclaw/workspace/scripts/research-refresh-cron.sh
```

**Behavior:**
- Runs checker in JSON mode
- Counts overdue and due-soon entries
- If overdue: Creates alert file (`.research-refresh-alert`)
- If fresh: Removes alert file
- Logs to: `logs/research-refresh-cron.log`

### 4. Alert File (`.research-refresh-alert`)

**Morpheus alert** created when research is stale:

```markdown
# Research Refresh Alert

**Date:** 2026-03-07 08:00:15  
**Status:** 2 research file(s) need refresh

## Overdue Research

- Dynamic Neural Architectures (2026): 5 days overdue
- API Security (2026): 2 days overdue

## Action Required

1. Review overdue topics
2. Spawn Scout to update stale research
3. Update RESEARCH_INDEX.md with new refresh dates
```

**Trigger:**
- Morpheus checks for this file on heartbeat or session start
- If exists → Alert user + trigger research updates
- If resolved → Delete alert file

---

## Workflow

### Daily Automated Check (Passive)

```
[08:00 AM Daily]
   ↓
Cron runs research-refresh-cron.sh
   ↓
Checker parses RESEARCH_INDEX.md
   ↓
If overdue → Create .research-refresh-alert
   ↓
Morpheus sees alert on next heartbeat
   ↓
[User Action] Review + update research
```

### Manual Check (On-Demand)

```bash
# Quick status
python3 scripts/check-research-refresh.py

# Detailed JSON
python3 scripts/check-research-refresh.py --json | jq
```

### Update Workflow (When Research Stale)

1. **Identify stale research:**
   ```bash
   python3 scripts/check-research-refresh.py --stale-only
   ```

2. **Trigger Scout update:**
   ```bash
   # Example: Update "API Security 2026" research
   # Spawn Scout with original research query
   ```

3. **Update RESEARCH_INDEX.md:**
   - Change `Refresh: 30 days (next: 2026-04-05)` → new date (+30 days)
   - Update `**Last Updated:**` at top of index

4. **Verify:**
   ```bash
   python3 scripts/check-research-refresh.py
   # Should show "FRESH" for updated entry
   ```

---

## Configuration

### Refresh Thresholds

**Default cycles (in RESEARCH_INDEX.md):**
- Technology/AI: 30 days
- Business/Strategy: 90 days
- Security: 60 days (medium)
- Infrastructure: 90 days
- Custom: Adjust per topic

**Alert thresholds:**
- **Overdue:** Past next refresh date (red alert)
- **Due Soon:** ≤7 days until refresh (yellow warning)
- **Fresh:** >7 days until refresh (green)

### Cron Schedule

**Current:** Daily at 08:00 AM local time

**Change schedule:**
```bash
crontab -e
# Modify line:
0 8 * * * /home/art/.openclaw/workspace/scripts/research-refresh-cron.sh

# Examples:
# Twice daily: 0 8,20 * * *
# Weekly (Mon): 0 8 * * 1
```

---

## Future Enhancements

### Phase 1 (Current) ✅
- [x] Monitor research staleness
- [x] Flag overdue research
- [x] Alert Morpheus via file

### Phase 2 (Next)
- [ ] Auto-trigger Scout for research updates
- [ ] Parse original research query from index
- [ ] Spawn Scout with "update" context
- [ ] Auto-update RESEARCH_INDEX.md dates

### Phase 3 (Advanced)
- [ ] Diff research updates (what changed?)
- [ ] Version history for research files
- [ ] Smart refresh (only update if source changed)
- [ ] Multi-source validation (cross-check facts)

---

## Files & Structure

```
~/.openclaw/workspace/
├── RESEARCH_INDEX.md                    # Master catalog (refresh dates)
├── scripts/
│   ├── check-research-refresh.py       # Checker script (Python)
│   └── research-refresh-cron.sh        # Cron wrapper (Bash)
├── logs/
│   └── research-refresh-cron.log       # Cron execution log
├── .research-refresh-alert             # Alert file (created if stale)
└── docs/
    ├── research/                       # Research files
    └── RESEARCH_REFRESH_SYSTEM.md      # This file

Crontab:
  0 8 * * * /home/art/.openclaw/workspace/scripts/research-refresh-cron.sh
```

---

## Troubleshooting

### Cron job not running

**Check crontab:**
```bash
crontab -l | grep research
```

**Check cron logs:**
```bash
tail -20 ~/.openclaw/workspace/logs/research-refresh-cron.log
```

**Manual test:**
```bash
~/.openclaw/workspace/scripts/research-refresh-cron.sh
```

### Alert file not appearing

**Possible causes:**
1. All research is fresh (no overdue entries)
2. Cron job failed (check logs)
3. Checker script error (run manually)

**Verify:**
```bash
# Run checker manually
python3 scripts/check-research-refresh.py

# If overdue shown, alert should be created
ls -lh .research-refresh-alert
```

### Wrong refresh dates

**Fix RESEARCH_INDEX.md:**
- Each entry must have: `**Refresh:** X days (next: YYYY-MM-DD)`
- Date format: YYYY-MM-DD
- Days: integer (30, 60, 90, etc.)

**Re-run checker after fixing:**
```bash
python3 scripts/check-research-refresh.py
```

---

## Metrics

| Metric | Value | Target |
|--------|-------|--------|
| Active Research | 2 entries | Growing |
| Overdue Research | 0 | 0 |
| Avg Refresh Cycle | 30 days | 30-90 days |
| Auto-Update Coverage | 0% | 80% (Phase 2) |

---

## Summary

**What Works:**
- ✅ Daily automated staleness checks (08:00 AM)
- ✅ Alert file creation for overdue research
- ✅ Human-readable and JSON output
- ✅ Cron job logging

**What's Manual:**
- ⚠️ Triggering Scout for updates (Morpheus decides)
- ⚠️ Updating RESEARCH_INDEX.md dates (manual edit)
- ⚠️ Resolving alert file (manual delete)

**Next Steps:**
- Implement Phase 2 (auto-trigger Scout)
- Parse original research queries from index
- Auto-update RESEARCH_INDEX.md after refresh

**Status:** ✅ Phase 1 Complete — Daily monitoring active, manual refresh workflow documented
