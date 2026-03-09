# Q-Learning Agent Selection — Quick Start

**Status:** ✅ LIVE & ACTIVE (2026-02-28 19:35 GMT)

---

## What Just Happened

Q-Learning is now automatically optimizing agent selection. Every task Morpheus completes teaches the system which agent is best for that task type.

---

## How It Works (30-Second Version)

1. **Task arrives** → Morpheus checks Q-table → Picks agent with highest Q-score
2. **Task completes** → Quality score recorded
3. **Q-score updates** → `Q_new = Q_old + 0.01 × (quality - Q_old)`
4. **Next similar task** → Morpheus is slightly more confident in that agent
5. **Repeat 50+ times** → System becomes very confident

---

## Files You Need to Know

| File | Purpose |
|------|---------|
| **rl-agent-selection.json** | Q-table (agent scores per task type) |
| **RL_AGENT_SELECTION_GUIDE.md** | How it works, detailed examples |
| **rl-task-execution-log.jsonl** | Logs every task outcome (for learning) |
| **RL_INTEGRATION_STRATEGY.md** | Future: task priority, research refresh, etc. |

---

## Example: First Research Task

```
Task: "Research API security"

Step 1: Check Q-scores for "research" task
  Scout: Q=0.50
  Veritas: Q=0.50
  Chronicle: Q=0.50
  Codex: Q=0.50
  Lens: Q=0.50
  → All equal, pick randomly → Pick Scout

Step 2: Scout researches API security

Step 3: Veritas validates → "Research is excellent" (quality: 0.95)

Step 4: Update Scout's Q-score
  Q_new = 0.50 + 0.01 × (0.95 - 0.50)
        = 0.50 + 0.0045
        = 0.5045

Step 5: Log entry added to rl-task-execution-log.jsonl
```

---

## What to Expect

### Week 1
- Q-scores start changing (0.50 → 0.51-0.52 range)
- System still learning, patterns not clear yet
- Continue normal work

### Week 2
- Q-scores more differentiated (0.55-0.65 range)
- Clear winners emerging (Scout at 0.65 for research)
- Morpheus more confident

### Week 3+
- System fully confident (Q-scores 0.7+)
- Morpheus automatically picks best agents
- 10-20% fewer wrong agent selections

---

## How to Monitor

### View Current Q-Scores

```bash
# Pretty print Q-table
jq . rl-agent-selection.json

# View just research scores
jq '.task_types.research' rl-agent-selection.json

# View agent statistics
jq '.task_types.research | to_entries[] | {agent: .key, q_score: .value.q_score, success_rate: .value.success_rate}' rl-agent-selection.json
```

### Example Output

```json
[
  {
    "agent": "Scout",
    "q_score": 0.65,
    "success_rate": 84.0
  },
  {
    "agent": "Veritas",
    "q_score": 0.55,
    "success_rate": 60.0
  }
]
```

**Reading:** Scout is more successful (84% vs 60%), so its Q-score is higher (0.65 vs 0.55).

---

## Can I Override It?

**Yes, anytime.** Morpheus can always use a different agent:

```
You: "Use Codex for this research, not Scout"
→ Morpheus uses Codex
→ If it fails, Codex's Q-score drops
→ Next research, back to Scout
```

No hard constraints, just recommendations.

---

## What Gets Learned

### 6 Task Types

1. **research** — Scout, Veritas, Chronicle, Codex, Lens
2. **code** — Codex, QA, Prism, Veritas
3. **security** — Cipher, Veritas, Sentinel
4. **infrastructure** — Sentinel, Cipher, Veritas
5. **analysis** — Lens, Veritas, Chronicle
6. **documentation** — Chronicle, Veritas

### Quality Score (0.0 to 1.0)

- **1.0** = Perfect (met all criteria, verified by secondary agent)
- **0.8-0.9** = Good (meets requirements, minor gaps)
- **0.5-0.7** = Acceptable (works, but not ideal)
- **0.1-0.4** = Poor (issues, needs refinement)
- **0.0** = Failed (doesn't work)

---

## Parameters (Tuning)

Current settings are conservative (safe for learning):

```json
{
  "alpha": 0.01,      // Learning rate (1% per update)
  "epsilon": 0.1,     // Exploration (10% random)
  "gamma": 0.99,      // Future discounting
  "lambda": 0.9       // Eligibility traces
}
```

**If learning too slow:** Increase alpha to 0.02  
**If learning too fast:** Decrease alpha to 0.005  
**If want more exploration:** Increase epsilon to 0.15  

Edit rl-agent-selection.json → metadata section to change.

---

## How to Get Help

### Questions

1. **"How do I check Q-scores?"** → See "Monitor" section above
2. **"Can I reset it?"** → Yes, set all Q-scores back to 0.50 (fresh start)
3. **"Why is agent X low?"** → Check success_rate (failures drop Q-score)
4. **"Is it working?"** → Check MEMORY.md and rl-agent-selection.json

### Files for Deep Dives

- **RL_AGENT_SELECTION_GUIDE.md** — All details, examples, troubleshooting
- **RL_INTEGRATION_STRATEGY.md** — Future extensions (task priority, research refresh)
- **RL_INTEGRATION_STRATEGY.md** (section 5) — How Q-Learning math works

---

## Key Dates

- **2026-02-28 19:35 GMT** — Q-Learning Agent Selection activated
- **2026-03-06** — Expect first confident Q-scores (after ~50 tasks)
- **2026-03-14** — System becomes very confident
- **2026-03-28** — Measurable improvement (10-20% better selections)

---

## Summary

✅ Q-Learning is learning which agent excels at what  
✅ Automatic: no manual tuning needed  
✅ Safe: can override anytime  
✅ Measurable: Q-scores show confidence  
✅ Future: Will expand to task priority, research refresh, workflows  

**Just do normal work. System learns in the background.**
