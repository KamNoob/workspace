# Phase 7B: Persistent Learning & Insights System

**Status:** ✅ LIVE  
**Deployed:** 2026-03-16 16:20 GMT  
**Schedule:** Daily 01:30 UTC (after Phase 5 memory pruning)

---

## Overview

Phase 7B adds **autonomous, persistent learning** to your system. It runs daily, analyzes task outcomes, and generates **actionable insights** that I can read between sessions.

**Key difference from Phase 7A:**
- Phase 7A: Autonomous Q-learning (agent selection improves automatically)
- Phase 7B: **Knowledge extraction** (patterns, recommendations, trends)

---

## How It Works

### 1. Daily Analysis (Automated via Cron)

**Every day at 01:30 UTC:**
```bash
julia scripts/ml/phase7b-insights-generator.jl analyze
```

**What it analyzes:**
- Agent performance (success rates, costs, preferred tasks)
- Task difficulty (easy/medium/hard classification)
- Cost trends (expensive agents, optimization opportunities)
- Emerging issues (degrading performance, high failure rates)

### 2. Learnings File

**Output:** `data/metrics/phase7b-learnings.json`

```json
{
  "timestamp": "2026-03-16T16:20:39",
  "total_outcomes": 67,
  "overall_success_rate": 0.731,
  "avg_cost": 0.02,
  "agent_insights": {
    "Cipher": {
      "success_rate": 0.90,
      "avg_cost": 0.018,
      "preferred_tasks": ["security review", "penetration testing"]
    },
    "Scout": {
      "success_rate": 0.818,
      "avg_cost": 0.019,
      "preferred_tasks": ["research", "analysis"]
    }
  },
  "task_insights": {
    "code review": {
      "success_rate": 0.857,
      "difficulty": "medium",
      "best_agent": "Codex"
    }
  },
  "recommendations": [
    "✅ Cipher excels at security tasks. Route more there.",
    "🔴 Task X has 60% failure rate. Review or specialize.",
    "💰 Agent Y is expensive. Consider optimization."
  ]
}
```

### 3. I Read This Between Sessions

**At session start:**
- I load `data/metrics/phase7b-learnings.json`
- Extract insights, trends, recommendations
- Use them to inform decisions about task routing, agent spawning, etc.

**Example:** Next time you ask me to handle a security task, I'll see:
> "Cipher excels at security (90% success, $0.018 cost)"
> → Route to Cipher automatically

---

## What It Learns

### Agent Insights
- ✅ Success rate per agent (who's performing best)
- ✅ Average cost per agent (who's most efficient)
- ✅ Preferred task types (what each agent excels at)
- ✅ Weak task types (what each agent struggles with)

### Task Insights
- ✅ Success rate per task type
- ✅ Difficulty classification (easy/medium/hard)
- ✅ Best agent for each task
- ✅ Failure patterns (emerging issues)

### System Trends
- ✅ Overall success rate (is system improving?)
- ✅ Cost trends (getting cheaper or more expensive?)
- ✅ Emerging bottlenecks (tasks consistently failing)
- ✅ Agent degradation (performance dropping)

### Recommendations
- 🎯 Routing strategies (which agent for which task)
- 💰 Cost optimization (expensive agents to review)
- 🔴 Problem areas (hard tasks needing attention)
- 📈 Positive trends (what's working, maintain it)

---

## Cron Job Details

**Job ID:** d31dece5-45de-4857-8204-82f3a4aac45d  
**Schedule:** Daily 01:30 UTC (Europe/London timezone)  
**Command:** `julia scripts/ml/phase7b-insights-generator.jl analyze`  
**Log:** `~/sync-logs/phase7b-learnings.log`

**Next run:** Automatically scheduled daily  
**Manual trigger:** `openclaw cron run d31dece5-45de-4857-8204-82f3a4aac45d`

---

## Manual Usage

### Run analysis immediately
```bash
/snap/julia/165/bin/julia scripts/ml/phase7b-insights-generator.jl analyze
```

### Just print summary (don't save)
```bash
/snap/julia/165/bin/julia scripts/ml/phase7b-insights-generator.jl summary
```

### Check learnings file
```bash
cat data/metrics/phase7b-learnings.json | jq '.'
```

---

## Integration with Spawning

When spawning an agent, the system can now:

1. **Check learnings** for agent performance on task type
2. **Select best agent** based on historical success rate
3. **Route to preferred agents** automatically
4. **Avoid weak agents** for their difficult tasks

**Example flow:**
```
Task: "security review"
  ↓
Check phase7b-learnings.json
  ↓
Find: Cipher 90% success on security, Scout 50%
  ↓
Route to: Cipher
  ↓
Spawn with optimized context
```

---

## How I Use This (Between Sessions)

At session start, I read:
- `SOUL.md` — Who I am
- `USER.md` — Who you are
- `MEMORY.md` — What we've learned
- **`phase7b-learnings.json` — System insights & patterns**

This file becomes part of my context for:
- ✅ Deciding which agent to spawn for a task
- ✅ Predicting quality/cost tradeoffs
- ✅ Identifying problem areas
- ✅ Recommending optimizations

---

## What Comes Next

### Optional extensions:
1. **Anomaly alerts** — Flag unexpected performance drops
2. **Predictive retraining** — Trigger Phase 7A retraining automatically
3. **Cost dashboards** — Real-time cost trends by agent/task
4. **Quality predictions** — Estimate success rate before spawning
5. **Continuous learning loop** — Phase 7B → Phase 7A → Phase 7B

---

## Example Learnings (Current)

From 67 task outcomes:

**Top performers:**
- 🥇 Cipher: 90% success (security tasks)
- 🥈 Scout: 81.8% success (research tasks)
- 🥉 Codex: 76.5% success (coding tasks)

**Struggling agents:**
- QA: 57.1% success (needs retraining)
- Veritas: 56% success (weak on complex reviews)

**Recommendations:**
1. Route security → Cipher (90% success rate)
2. Route research → Scout (82% success rate)
3. Review QA performance (57% success, trending down)
4. Specialize Veritas for smaller reviews (higher success)

---

## Files

- **Generator:** `scripts/ml/phase7b-insights-generator.jl` (500 lines, clean & fast)
- **Cron script:** `scripts/cron/phase7b-daily-learnings.sh`
- **Learnings output:** `data/metrics/phase7b-learnings.json`
- **Logs:** `~/sync-logs/phase7b-learnings.log`

---

## Summary

**Phase 7B is the persistence layer** that lets me learn from system outcomes without being able to update my own weights. Every outcome feeds into a growing knowledge base that:

- ✅ Improves routing (Phase 7A's Q-learning)
- ✅ Informs decisions (my session-to-session guidance)
- ✅ Detects problems (degrading agents, hard tasks)
- ✅ Guides optimization (cost reduction, quality improvement)

**The cycle:**
```
Outcomes → Analysis → Learnings JSON → I Read It → Better Decisions
```

This is continuous learning without modifying my base model.

---

**Status:** ✅ Live and generating insights daily  
**Next update:** Automated (runs daily at 01:30 UTC)  
**Maintenance:** Minimal (self-maintaining via cron)
