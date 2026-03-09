# Session Continuation Protocol (Auto-Reset at 75% Context)

## How It Works

**Trigger:** Context usage reaches 75% (150k/200k tokens)

**Automatic sequence:**
1. Cron job detects 75%+ usage
2. Creates concise session summary (1-2 paragraphs)
3. Logs summary to `/tmp/session-summary.txt`
4. Sends alert to main session (via sessions_send)
5. Main session receives alert → I spawn continuation session
6. Summary injected into new session as context
7. Work resumes seamlessly

**Goal:** Zero data loss, seamless continuation across context windows.

## Current Cron Job

**Name:** Token Usage Monitor + Auto-Summarize  
**ID:** 0827aaa9-37eb-4ad8-a406-b00548eaeac2  
**Schedule:** Every 15 minutes  
**Trigger:** 75%+ context usage

**Payload (updated for full auto-reset):**
```
Monitor session_status. 
If context >= 75%:
  1. Create summary: brief recap of current work (1-2 paragraphs)
  2. Log to /tmp/session-summary.txt with timestamp
  3. Send alert to main session: "CONTEXT_THRESHOLD_REACHED: [summary]"
Else:
  Report status only.
```

## Session Spawn Logic (Main Session)

When alert received from cron:

```
1. Extract summary from alert
2. Spawn continuation session:
   - runtime: "subagent"
   - agentId: "Morpheus" (or main agent)
   - mode: "session" (persistent, not one-shot)
   - task: "Resume work with context: [summary]. Previous session hit 75% threshold. Continue from summary checkpoint."
3. Inject summary as system context
4. Maintain session key for continuity
```

**Files involved:**
- `/tmp/session-summary.txt` — Current summary checkpoint
- USAGE_TRACKING.md — Updated with reset event
- Session logs — Document continuation

## Checkpoints Logged

| Checkpoint | Data | Purpose |
|---|---|---|
| Session summary | 1-2 para recap | Anchor for new session |
| Timestamp | When hit 75% | Track reset events |
| Session ID | Old → New | Trace continuity |
| Token count at reset | Context %, tokens used | Analytics |

## Example Reset Flow

**Time: 14:30 GMT**
- Context: 150k/200k (75%)
- Cron detects threshold
- Summary created: "Currently implementing feature X. Progress: 80% complete. Dependencies: module Y, config Z. Next steps: testing phase."
- Alert sent to main session
- Main session spawns continuation with summary
- Work resumes in new session at 75%→0% fresh context
- Zero data loss

## Coverage

**Main session:** ✅ Full auto-reset at 75%

**Sub-agents:** Hybrid approach
- One-shot agents (mode="run"): No monitoring (complete before overflow)
- Persistent agents (mode="session"): Continuation monitoring added on-demand
- Trigger: First time a persistent agent is spawned, add 75% check + summary + continuation logic
- Cost: Zero overhead until persistent agents are used

## Status

**Implementation:** Live (cron job active for main session)
**Trigger:** 75%+ context usage
**Auto-spawn:** Ready (code path prepared)
**Sub-agents:** Hybrid (implemented on-demand)
**Testing:** Next context overflow event, or first persistent agent spawn

## Files

| File | Purpose | Status |
|---|---|---|
| SESSION_CONTINUATION.md | This doc | ✅ Created |
| Cron job payload | Detection + alert | ⚠️ Need update |
| sessions_spawn integration | Continuation spawn | Ready to use |

---

**Created:** 2026-03-01 12:10 GMT  
**Status:** ✅ Protocol defined, implementation in progress
