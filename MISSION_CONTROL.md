# Scheduled Tasks Calendar

## Database
- **URL:** https://www.notion.so/b9eaba8909cf4f64bc7c3dc260c95d76
- **Database ID:** `b9eaba89-09cf-4f64-bc7c-3dc260c95d76`

## What Gets Tracked
1. **Cron jobs** - Recurring automated tasks (daily, weekly, on specific schedules)
2. **One-time tasks** - Scheduled for a specific date/time
3. **Heartbeat checks** - Periodic monitoring (email, calendar, weather)
4. **Sub-agent spawns** - Scheduled background tasks

## Properties

| Field | Type | Purpose |
|-------|------|---------|
| **Task** | Title | Name of the scheduled task |
| **Type** | Select | `One-time`, `Recurring`, or `Heartbeat` |
| **Status** | Select | `Scheduled`, `Running`, `Completed`, `Failed`, `Paused` |
| **Schedule** | Text | Cron expression or plain description (e.g., "Daily at 2am") |
| **Next Run** | Date | When the task will next execute |
| **Description** | Text | What the task does |
| **Job ID** | Text | OpenClaw cron job ID (for reference) |
| **Notes** | Text | Updates, results, error info |

## How Tasks Get Added

### Automatically by Morpheus
When I schedule a new task, I will:
1. Create the cron job or schedule in OpenClaw
2. Add it to this calendar (using `add-to-calendar.sh`)
3. Set status to "Scheduled"
4. Update "Next Run" with the calculated date

### Example Cron Schedules

```
Daily at 2am UTC:          0 2 * * *
Every 6 hours:             0 */6 * * *
Monday at 9am:             0 9 * * 1
1st of month at 3am:       0 3 1 * *
Every 30 minutes:          */30 * * * *
```

## Usage Instructions

### Adding a Task (Manual)
```bash
cd ~/.openclaw/workspace
./add-to-calendar.sh \
  "Daily Email Check" \
  "recurring" \
  "0 8 * * * (8am daily)" \
  "2026-02-21" \
  "Check and summarize emails"
```

### Adding a Task (Parameters)
```bash
./add-to-calendar.sh \
  "Task Name" \
  "one-time|recurring|heartbeat" \
  "Schedule (cron or description)" \
  "Next Run (YYYY-MM-DD)" \
  "What does this task do?" \
  "optional-job-id"
```

### Updating Status
From Notion: Open any task, update the "Status" field, add notes if needed.

## Art's Oversight
✅ You can view the calendar anytime: https://www.notion.so/b9eaba8909cf4f64bc7c3dc260c95d76  
✅ You'll see what I'm scheduled to do and when  
✅ You can comment on tasks or update status if they complete early  
✅ You can pause tasks by changing status to "Paused"  
✅ All actual cron definitions stay in OpenClaw config for safety

---

**Last Updated:** 2026-02-20 10:00 GMT  
**Version:** 1.0
