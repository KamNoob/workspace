# Q-Learning Agent Selection Implementation Guide

**Date:** 2026-02-28  
**Status:** ✅ ACTIVE  
**File:** `rl-agent-selection.json`

---

## How It Works

### 1. Task Arrives

Art: "Research API security best practices"

### 2. Morpheus Identifies Task Type

Matches to: `task_types.research` in Q-table

### 3. Morpheus Checks Q-Scores

```json
{
  "research": {
    "Scout": {"q_score": 0.50, "success_rate": 0.0},
    "Veritas": {"q_score": 0.50, "success_rate": 0.0},
    "Chronicle": {"q_score": 0.50, "success_rate": 0.0},
    "Codex": {"q_score": 0.50, "success_rate": 0.0},
    "Lens": {"q_score": 0.50, "success_rate": 0.0}
  }
}
```

### 4. Morpheus Decides (With Exploration)

**Default behavior:**
- 90% of time: Pick agent with highest Q-score (exploit)
- 10% of time: Pick random agent (explore)

**Rationale:**
- **Exploit:** Use what works best (Scout currently)
- **Explore:** Try alternatives occasionally (discover if Lens is good at research)

**Today's decision:**
```
All Q-scores are 0.50 (equal)
→ Pick randomly (or use AGENTS_CONFIG recommendation as tiebreaker)
→ Spawn Scout
```

### 5. Scout Researches

Scout completes research on API security.

### 6. Morpheus Logs Outcome

**Successful?** Check:
- Did Veritas validate it? ✓ Yes, "research is accurate"
- Quality score: 0.95 (on 0.0-1.0 scale)
- Task type: "research"
- Agent: Scout
- Time: 8 minutes

**Log entry:**
```json
{
  "timestamp": "2026-02-28T19:40:00Z",
  "task_type": "research",
  "agent": "Scout",
  "quality_score": 0.95,
  "success": true,
  "time_minutes": 8
}
```

### 7. Q-Learning Update

**Formula:**
```
Q_new = Q_old + α × (reward - Q_old)

Where:
  α = 0.01 (learning rate)
  reward = quality_score = 0.95
  Q_old = 0.50
```

**Calculation:**
```
Q_new = 0.50 + 0.01 × (0.95 - 0.50)
      = 0.50 + 0.01 × 0.45
      = 0.50 + 0.0045
      = 0.5045
```

**Scout's Q-score increases:** 0.50 → 0.5045

### 8. Next Research Task

Art: "Research OAuth 2.0 implementation"

**Q-scores now:**
```json
{
  "research": {
    "Scout": {"q_score": 0.5045, "success_rate": 100.0},
    "Veritas": {"q_score": 0.50, "success_rate": 0.0},
    "Chronicle": {"q_score": 0.50, "success_rate": 0.0},
    "Codex": {"q_score": 0.50, "success_rate": 0.0},
    "Lens": {"q_score": 0.50, "success_rate": 0.0}
  }
}
```

**Decision:** Pick Scout (highest Q-score: 0.5045)

**Confidence grows:** After 20 successful Scout research tasks, Q-score reaches 0.70+
→ Morpheus becomes very confident Scout is best for research

---

## Q-Table Structure

### File: `rl-agent-selection.json`

**Metadata:**
```json
{
  "metadata": {
    "created": "2026-02-28T19:35:00Z",
    "algorithm": "Q-Learning + TD(λ)",
    "alpha": 0.01,           // Learning rate
    "gamma": 0.99,           // Discount factor
    "lambda": 0.9,           // Eligibility trace decay
    "epsilon": 0.1           // Exploration rate (10%)
  }
}
```

**Task Types (6):**
1. `research` — Scout, Veritas, Chronicle, Codex, Lens
2. `code` — Codex, QA, Prism, Veritas
3. `security` — Cipher, Veritas, Sentinel
4. `infrastructure` — Sentinel, Cipher, Veritas
5. `analysis` — Lens, Veritas, Chronicle
6. `documentation` — Chronicle, Veritas

**Per Agent (per task type):**
```json
{
  "q_score": 0.50,              // Current Q-value
  "success_count": 0,           // Tasks completed successfully
  "failure_count": 0,           // Tasks that failed
  "total_uses": 0,              // Total times spawned
  "success_rate": 0.0,          // success_count / total_uses
  "last_updated": "2026-02-28T19:35:00Z"
}
```

---

## Integration Points

### 1. When to Check Q-Table (Before Spawning Agent)

```
// Pseudocode
function selectAgent(taskType) {
  // Get Q-scores for this task type
  agents = loadQTable(taskType);
  
  // Random number 0-1
  random = Math.random();
  
  if (random < 0.1) {
    // 10% of time: explore (pick random agent)
    agent = pickRandom(agents);
  } else {
    // 90% of time: exploit (pick highest Q-score)
    agent = pickByHighestQ(agents);
  }
  
  return agent;
}
```

### 2. When to Update Q-Table (After Task Completes)

```
// Pseudocode
function updateQScore(taskType, agent, qualityScore) {
  // Load current Q-score
  qOld = loadQ(taskType, agent);
  
  // Q-Learning update
  alpha = 0.01;
  reward = qualityScore;  // 0.0 to 1.0
  qNew = qOld + alpha * (reward - qOld);
  
  // Save updated Q-score
  saveQ(taskType, agent, qNew);
  
  // Update success/failure counts
  if (qualityScore > 0.7) {
    incrementSuccess(taskType, agent);
  } else {
    incrementFailure(taskType, agent);
  }
  
  // Recalculate success rate
  updateSuccessRate(taskType, agent);
}
```

### 3. Task Logging (Record Outcome)

After agent completes:
```json
{
  "timestamp": "2026-02-28T19:40:00Z",
  "task": {
    "type": "research",
    "description": "API security best practices"
  },
  "agent": {
    "name": "Scout",
    "selected_by_q_score": 0.50,
    "reason": "equal_with_others_random_choice"
  },
  "outcome": {
    "success": true,
    "quality_score": 0.95,
    "verifier": "Veritas",
    "verification": "Research accurate, well-sourced",
    "time_minutes": 8.5
  },
  "rl_update": {
    "q_old": 0.50,
    "q_new": 0.5045,
    "alpha": 0.01,
    "reward": 0.95
  }
}
```

---

## Learning Over Time

### Example: First 50 Research Tasks

**Task 1:**
- Q-scores: All 0.50 (equal)
- Pick: Scout (random)
- Outcome: Success (0.95)
- Scout Q: 0.50 → 0.5045

**Task 2:**
- Q-scores: Scout=0.5045, others=0.50
- Pick: Scout (highest Q)
- Outcome: Success (0.93)
- Scout Q: 0.5045 → 0.5089

**Task 3:**
- Pick: Scout (highest Q)
- Outcome: Success (0.97)
- Scout Q: 0.5089 → 0.5159

**... (repeat 47 more times) ...**

**Task 50:**
- Q-scores: Scout=0.68, others=0.50
- Pick: Scout (very confident now, Q=0.68)
- Outcome: Success (0.96)
- Scout Q: 0.68 → 0.6804

**Result:** Scout's Q-score: 0.50 → 0.68 (36% increase in confidence)
→ Morpheus is 100% confident Scout is best for research

---

## Failure Scenarios

### What if Scout Fails?

**Task 45:**
- Scout is assigned (Q=0.65)
- Outcome: Failed (quality_score=0.20)
- Update: Q = 0.65 + 0.01 × (0.20 - 0.65) = 0.65 - 0.0045 = 0.6455

**Effect:**
- Scout Q drops slightly (0.65 → 0.6455)
- Still highest, but confidence reduced
- If failures continue, other agents' Q-scores eventually higher

**After 5 failures + 5 successes for Scout:**
- Scout Q: ~0.60
- Veritas Q: ~0.55
- Still use Scout, but less confident

**After 10 consecutive Scout failures:**
- Scout Q: ~0.45
- Veritas Q: ~0.55
- Switch to Veritas (higher Q now)

**Learning:** System self-corrects when agents consistently fail

---

## Parameters & Tuning

### Current Settings

```json
{
  "alpha": 0.01,      // Learning rate
  "gamma": 0.99,      // Discount factor
  "lambda": 0.9,      // Trace decay
  "epsilon": 0.1      // Exploration rate
}
```

### What Each Does

**Alpha (0.01):**
- Higher (0.1): Learn faster, but more volatile
- Lower (0.001): Learn slower, but more stable
- **0.01 is conservative:** Good for starting

**Gamma (0.99):**
- Higher (0.99): Value long-term rewards
- Lower (0.5): Focus on immediate rewards
- **0.99 is typical:** Slightly forward-looking

**Lambda (0.9):**
- Higher (0.9): Credit recent decisions more
- Lower (0.5): Distribute credit evenly
- **0.9 is standard:** Recent decisions matter

**Epsilon (0.1):**
- Higher (0.5): Explore more, learn slower
- Lower (0.01): Exploit more, miss alternatives
- **0.1 is balanced:** Explore 10%, exploit 90%

### When to Adjust

- **Learning too slow?** Increase alpha to 0.02-0.05
- **Too volatile?** Decrease alpha to 0.005
- **Want more exploration?** Increase epsilon to 0.15-0.2
- **Want exploitation?** Decrease epsilon to 0.05

---

## Monitoring & Debugging

### Check Q-Scores Anytime

```bash
# View current Q-table (pretty-printed)
jq . /home/art/.openclaw/workspace/rl-agent-selection.json

# View just research Q-scores
jq '.task_types.research' /home/art/.openclaw/workspace/rl-agent-selection.json

# View learning log
jq '.learning_log' /home/art/.openclaw/workspace/rl-agent-selection.json
```

### Example Output

```json
{
  "research": {
    "Scout": {
      "q_score": 0.68,
      "success_count": 42,
      "failure_count": 8,
      "total_uses": 50,
      "success_rate": 84.0
    },
    "Veritas": {
      "q_score": 0.55,
      "success_count": 15,
      "failure_count": 10,
      "total_uses": 25,
      "success_rate": 60.0
    }
  }
}
```

**Reading:**
- Scout: 50 uses, 84% success rate, Q-score 0.68 (highest)
- Veritas: 25 uses, 60% success rate, Q-score 0.55
- **Recommendation:** Use Scout for research (higher Q)

### When Q-Scores Look Wrong

| Symptom | Cause | Fix |
|---------|-------|-----|
| All agents Q=0.50 | No tasks completed yet | Run more tasks |
| Agent Q too high (0.95+) | Very few tasks | Keep learning, Q will stabilize |
| Agent Q too low (0.0) | Lots of failures | Review why failures happen |
| All Q-scores dropping | Quality scores declining | Check if task difficulty changed |
| No learning progress | Alpha too low | Increase alpha (try 0.02) |

---

## Migration Strategy (How To Adopt)

### Phase 1: Passive Monitoring (Week 1)
- Q-table running, collecting data
- Morpheus still follows AGENTS_CONFIG recommendations
- Log outcomes, don't change decisions yet
- Goal: Build baseline data (50+ tasks)

### Phase 2: Soft Integration (Week 2)
- When Q-scores confident (Q > 0.6), use them
- When Q-scores uncertain (0.4 < Q < 0.6), use AGENTS_CONFIG
- Goal: Gradually shift to RL-guided decisions

### Phase 3: Full Integration (Week 3+)
- Use Q-scores for all decisions
- AGENTS_CONFIG is secondary reference
- Keep monitoring, adjust alpha if needed
- Goal: RL-driven optimal agent selection

---

## Expected Outcomes

### After 1 Week (50-100 tasks)
- Q-scores start differentiating (0.50 → 0.55-0.65 range)
- Patterns emerge (Scout good at research)
- Success rates visible per agent

### After 2 Weeks (100-200 tasks)
- Clear winners per task type (Q > 0.7)
- Morpheus confidently picks best agents
- Some task types fully optimized

### After 4 Weeks (200+ tasks)
- All task types optimized
- 10-20% reduction in wrong agent picks
- System is self-improving

---

## Safety & Overrides

### Morpheus Can Always Override

```
User: "Use Codex for this research, not Scout"
→ Morpheus uses Codex (task completes)
→ Quality score is low (0.4)
→ Codex Q drops for research
→ System learns "Codex not good at research"
→ Next research: Back to Scout
```

**No hard constraints:** RL is advice, not law. Override anytime.

---

## Persistence & Backup

### Daily Backup

```bash
# Cron job (daily at midnight)
cp rl-agent-selection.json rl-agent-selection.json.$(date +%Y%m%d).bak
```

### Restore from Backup

```bash
# If corrupted
cp rl-agent-selection.json.20260228.bak rl-agent-selection.json
```

### Reset (If Needed)

```bash
# Reset all Q-scores to 0.50 (start learning over)
jq '.task_types[] |= map_values(.q_score = 0.50 | .success_count = 0 | .failure_count = 0)' \
  rl-agent-selection.json > rl-agent-selection.json.reset
mv rl-agent-selection.json.reset rl-agent-selection.json
```

---

## Summary

✅ **Q-table created** (rl-agent-selection.json)  
✅ **6 task types defined** (research, code, security, infrastructure, analysis, documentation)  
✅ **All agents included** (per their specialization)  
✅ **Learning ready** (alpha=0.01, epsilon=0.1, gamma=0.99)  
✅ **Logging structure** (task outcomes → Q-score updates)  

**Status:** System is ready. Integrate logging and start collecting task outcomes.

Next step: Modify task execution to log outcomes and update Q-table automatically.
