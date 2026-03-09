# HEARTBEAT.md - Periodic Checks & Monitoring

_Rotate through these checks, 2-4 times per day. Keep them light._

---

## System Health (Rotate Daily)

### Check 1: Gateway & Messaging
**Frequency:** 1x per day (morning)  
**Time:** ~5 min

```bash
openclaw status
```

**What to verify:**
- ✅ Gateway running on 18789
- ✅ RPC probe: ok
- ✅ WhatsApp: connected
- ✅ No config warnings (should be clean after lancedb removal)

**Action if issue:**
- Gateway down → `openclaw gateway restart`
- WhatsApp disconnected → Wait 30s, check again
- Config warnings → Note in memory, address next sprint

---

### Check 2: Memory & Learning Systems
**Frequency:** 2x per week (Wed, Sun)  
**Time:** ~10 min

```bash
# Check memory optimizer state
cat .memory-optimizer-state.json | jq '.stats, .metadata'

# Check memory search health
# (implicit — tests query performance)
```

**What to verify:**
- ✅ Total recalls > failed (aim for 98%+)
- ✅ Avg lookup time < 5ms
- ✅ Q-values converging (not all 0.5)
- ✅ Last consolidation recent (< 1 week)

**Action if issue:**
- Low recall rate → May need memory consolidation
- High lookup time → Memory index growing, consider cleanup
- Q-values stuck → Agent selection may need reset

---

### Check 3: Agent Performance (Q-Learning)
**Frequency:** 1x per week (Friday)  
**Time:** ~10 min

```bash
# Check agent Q-scores
cat data/rl/rl-agent-selection.json | jq '.task_types | to_entries[] | {task: .key, agents: .value.agents} | select(.agents != null)'
```

**What to verify:**
- ✅ Scout dominates research (Q > 0.75)
- ✅ Codex dominates code (Q > 0.65)
- ✅ Cipher dominates security (Q > 0.55)
- ✅ Sentinel dominates infrastructure (Q > 0.55)
- ✅ Learning log shows recent updates (< 1 week)

**Action if issue:**
- Agent underperforming → Consider retraining or task reassignment
- All Q-scores low → Learning may have reset
- No recent updates → Agent not being used for that task type

---

## Memory Maintenance (Weekly)

**Frequency:** 1x per week (Sunday)  
**Time:** ~15 min

**Process:**
1. Review daily logs: `memory/YYYY-MM-DD.md` (last 3-7 days)
2. Extract key learnings:
   - Important decisions made
   - Technical discoveries
   - Pattern learnings
   - System improvements
3. Update `MEMORY.md` with distilled insights
4. Remove outdated entries from MEMORY.md

**Action items:**
- [ ] Significant decision made → Document reasoning
- [ ] New agent outcome → Add to learning log
- [ ] System improvement → Note in infrastructure section
- [ ] Changed preference → Update USER.md or IDENTITY.md

---

## Projects & Tasks (Sprint-Based)

**Frequency:** Start of sprint + mid-sprint check  
**Time:** ~15 min

**At Sprint Start:**
1. Check Notion Task Board: https://www.notion.so/5680631b-eb20-434f-9388-b8db1ab4356c
2. Verify high-priority tasks are assigned
3. Check for blockers or dependencies
4. Note any task → cron mappings needed

**Mid-Sprint (optional):**
1. Review task completion % (from RL task log)
2. Check if any high-priority task slipped
3. Look for patterns in agent selection outcomes

**Action items:**
- [ ] Mark completed tasks in Notion
- [ ] If task failed → Log failure to sync-cron-to-tasks
- [ ] If new priority emerges → Discuss with Art

---

## Infrastructure & Syncs (Weekly)

**Frequency:** 1x per week (Monday)  
**Time:** ~10 min

**Check sync scripts:**
```bash
tail -10 ~/sync-logs/memory-to-kb.log
tail -10 ~/sync-logs/tasks-to-cron.log
tail -10 ~/sync-logs/agent-status.log
```

**What to verify:**
- ✅ memory-to-kb.sh last ran < 24h
- ✅ tasks-to-cron.sh last ran < 24h
- ✅ agent-status.sh last ran < 1h
- ✅ No ERROR lines in logs (WARN is ok)

**Check git status:**
```bash
git status
git log --oneline -5
```

**What to verify:**
- ✅ No uncommitted work sitting around
- ✅ Recent commits are meaningful
- ✅ No stale branches

**Action items:**
- [ ] Sync script failed → Check .env, debug, restart
- [ ] Uncommitted work → Commit or move to proto/
- [ ] Stale changes → Stage or trash them

---

## Research & Knowledge (Monthly)

**Frequency:** 1x per month (1st of month)  
**Time:** ~15 min

**Check knowledge bases:**
```bash
# RL knowledge base exists & is current
ls -lh skills/rl-knowledge/lib/rl-kb.js
ls -lh RL-BOOK-ENHANCED.json

# Can query it
cd skills/rl-knowledge
node bin/rl-cli.js list algorithms 2>/dev/null | head -5
```

**What to verify:**
- ✅ RL knowledge base files exist
- ✅ Query engine working (can list algorithms)
- ✅ Last modification date reasonable (< 6 months stale)

**Action items:**
- [ ] RL book needs updating → Check for latest version
- [ ] New papers discovered → Add to reference section
- [ ] Query engine broken → Rebuild from RL-BOOK-ENHANCED.json

---

## When to Alert (Escalate)

**Reach out immediately if:**
- Gateway down > 5 minutes
- WhatsApp disconnected > 10 minutes
- Memory recall success < 90% (data loss risk)
- Cron script error 3+ times in a row
- Git repo has uncommitted breaking changes
- Q-learning shows negative trends (scores dropping)

**Routine check failures (don't alert):**
- Occasional high lookup time (< 100ms is fine)
- Old memory consolidation (< 2 weeks is fine)
- Sync script WARN messages (not ERROR)
- Unreviewed daily logs (batch them on Sunday)

---

## Automated Weekly Test Cycles (Cron)

**Status:** ✅ ACTIVE  
**Job ID:** 49f85737-b6bf-4255-ba70-43bdefca282d  
**Schedule:** Every Friday 09:00 London time  
**Next run:** 2026-03-13 09:00 GMT

**What it does:**
- Runs 2 test workflows (code-review + research)
- Logs outcomes to rl-task-execution-log.jsonl
- Accumulates Phase 2b data (~8 outcomes/month)
- Keeps system warm between real work

**No action needed** — This runs automatically.

---

## Heartbeat State Tracking

Create `memory/heartbeat-state.json` to track what was last checked:

```json
{
  "lastChecks": {
    "gateway": "2026-03-09T14:00:00Z",
    "memory_optimizer": "2026-03-07T10:30:00Z",
    "agent_qscores": "2026-03-07T15:45:00Z",
    "memory_maintenance": "2026-03-03T16:00:00Z",
    "projects_tasks": "2026-03-09T09:00:00Z",
    "syncs_infrastructure": "2026-03-03T10:00:00Z",
    "research_knowledge": "2026-02-01T14:00:00Z"
  },
  "last_updated": "2026-03-09T15:05:00Z"
}
```

Update this file after each heartbeat check.

---

## Rotation Schedule

**Every session (if heartbeat triggered):**
- ✅ Read this file (HEARTBEAT.md)
- ✅ Review heartbeat-state.json
- ✅ Pick 1-2 checks that haven't run recently

**Suggested Rotation (2-4x daily):**
1. **Morning Check:** Gateway & Messaging (5 min)
2. **Midday Check:** Git status + sync logs (10 min)
3. **Evening Check:** Memory state + Q-scores (if weekly due, 10 min)
4. **End of week:** Full memory maintenance (15 min)

**Don't check:**
- ❌ Everything at once (token burn)
- ❌ Same check twice in 4 hours (unless recovering from failure)
- ❌ Late night checks unless urgent (respect sleep)

---

## Notes

- **Batch checks:** Similar items → one check
- **Skip if:** You're in a focused work session (don't interrupt)
- **Only alert if:** Issue actually needs Art's attention
- **Update this file:** As new systems get added or priorities change
- **Keep it lean:** If heartbeat grows > 50 lines, consolidate

---

_Heartbeat configuration created: 2026-03-09 15:05 GMT_  
_Based on: SYNC_SCRIPTS_MANIFEST.md, RL learning logs, memory optimizer, infrastructure patterns_
