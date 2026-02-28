# HEARTBEAT.md

## Chat Monitoring (Real-Time)

Check for pending chat messages via webhook listener:
- Webhook listener running on port 4002
- Chat server POSTs to `http://localhost:4002/webhook/message` on new user messages
- Notifications logged to `/tmp/morpheus-chat-notifications.log`

**Alert when:**
- New pending messages detected in log
- Show message content and conversation ID

**Response protocol:**
- Fetch pending via: `curl -s http://localhost:4001/api/admin/pending`
- Generate response to user
- POST response via: `curl -X POST http://localhost:4001/api/admin/respond -d '{conversationId, response}'`

---

## Sync Batch Check (hourly)

Monitor these sync scripts and batch their status:
- sync-agent-status.sh
- sync-office-status.sh
- sync-projects.sh
- sync-task-updates.sh

**Alert only if:**
- Any script fails (non-zero exit)
- Gateway disconnects without auto-reconnect within 5s
- Database sync errors

**Otherwise:** Completely silent (no responses, no HEARTBEAT_OK).

---

## Session Health Monitoring (Active During Multi-Step Tasks)

**Per-Model Thresholds:**
| Model | Reset Threshold |
|-------|---|
| Haiku 4.5 (primary) | 90K tokens |
| Sonnet 4.5/4.6 | 100K tokens |
| Opus 4.5 | 100K tokens |

**Behavior (Main Session):**
- Check `session_status` during active work on complex tasks
- When approaching model's threshold:
  1. Announce the reset (brief summary of state)
  2. Extract critical context (task progress, key facts, decisions)
  3. Spawn continuation session with summarized state
  4. Resume work seamlessly (no interruption)

**No user action required.** Automatic during active sessions.

---

## Agent Session Health (Spawned Sub-Agents)

**Monitoring:**
- Track token usage for long-running agents (Codex, Scout, Chronicle, Sentinel, etc.)
- Same per-model thresholds apply
- For multi-step agent tasks:
  1. Check agent session health via `sessions_list` 
  2. If approaching threshold, spawn continuation agent with summarized context
  3. Chain results back to main session

**Note:** One-shot agent runs (mode=run) typically complete before hitting limits. Monitor only for extended investigations or multi-part tasks.
