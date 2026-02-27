# HEARTBEAT.md

## Sync Batch Check (hourly)

Monitor these sync scripts and batch their status:
- sync-agent-status.sh
- sync-office-status.sh
- sync-projects.sh
- sync-task-updates.sh

**Only alert if:**
- Any script fails (non-zero exit)
- Gateway disconnects without auto-reconnect within 5s
- Database sync errors

**Otherwise:** Silent (no batch summary).

---

## Session Health Monitoring (Active During Multi-Step Tasks)

**Threshold:** 90K+ tokens (80% of Haiku safe estimate)

**Behavior:**
- Check `session_status` during active work on complex tasks
- When approaching 90K tokens:
  1. Announce the reset (brief summary of state)
  2. Extract critical context (task progress, key facts, decisions)
  3. Spawn continuation session with summarized state
  4. Resume work seamlessly (no interruption)

**No user action required.** Automatic during active sessions.
