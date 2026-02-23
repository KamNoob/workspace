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
