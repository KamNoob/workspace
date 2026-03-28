# Quick Start — Learning System Operations

_Fast reference for day-to-day operations_

---

## Daily Routine (2 minutes)

```bash
# Morning check
julia scripts/ml/unified-learning-system.jl --report

# Automatically reports:
# ✅ Feedback entries pending
# ✅ Agent pairs identified  
# ✅ Patterns extracted
# ✅ Next steps
```

**What to look for:**
- Green checkmarks = all systems nominal
- Warnings = review docs/LEARNING-SYSTEM.md
- No pending feedback = system is waiting for outcomes

---

## Recording Task Feedback (1 minute)

After a task completes:

```bash
# Get task UUID (from spawner output or audit log)
TASK_ID="a1b2c3d4-e5f6-7890"

# Record: Did this task succeed? (true/false)
#         Quality score: 1-5 (1=poor, 5=excellent)

julia scripts/ml/feedback-validator.jl \
  --task-id "$TASK_ID" \
  --approved true \
  --quality 4 \
  --notes "Quick feedback (optional)"
```

**Examples:**

```bash
# Excellent outcome
--approved true --quality 5 --notes "Perfect solution"

# Acceptable outcome
--approved true --quality 3 --notes "Got the job done"

# Rejected outcome
--approved false --quality 1 --notes "Didn't meet requirements"
```

---

## Analyzing Patterns (2 minutes)

### Find best agent for a task type:
```bash
julia scripts/ml/knowledge-extractor.jl --query-pattern "code"
# Shows: best agent, success rate, cost, efficiency
```

### Find similar tasks:
```bash
julia scripts/ml/knowledge-extractor.jl --find-similar "optimization"
# Shows: related task types that succeeded before
```

### Check agent pairs:
```bash
julia scripts/ml/collaboration-graph.jl --analyze
# Shows: top 20 partnerships, quality scores
```

---

## Cron Jobs (Automatic)

Everything runs automatically. No action needed.

| Timing | What | Status |
|--------|------|--------|
| Every 6h | Process pending feedback → Q-learning | ✅ Auto |
| Daily 03:00 | Full learning cycle (P0+P1+P2) | ✅ Auto |
| Daily 02:30 | SLA monitoring & alerts | ✅ Auto |
| Weekly Mon | Compliance reports | ✅ Auto |

**Check cron status:**
```bash
openclaw cron list | grep -E "Feedback|Learning|Collaboration"
```

---

## Troubleshooting

### "No feedback log found"
- **Meaning:** No feedback recorded yet
- **Action:** Run a task, then record feedback (see above)
- **Normal:** System starts fresh, accumulates data over time

### "0 agent pairs analyzed"
- **Meaning:** Not enough task history for pattern detection
- **Action:** Run more tasks, wait for P1 cycle to complete
- **Normal:** Patterns emerge after 10-20 tasks

### "0 patterns extracted"
- **Meaning:** No knowledge base built yet
- **Action:** Complete tasks, let P2 extraction run
- **Normal:** Patterns accumulate from task history

### Learning reports show no activity
- **Meaning:** Cron jobs haven't run yet
- **Action:** Check time (jobs run at specific hours)
- **Normal:** Run `--full-cycle` manually to test

---

## Manual Trigger (Force Run)

If you want learning to run immediately (don't wait for cron):

```bash
# Full cycle (P0+P1+P2)
julia scripts/ml/unified-learning-system.jl --full-cycle

# Just feedback processing
julia scripts/ml/unified-learning-system.jl --feedback-only

# Just collaboration analysis
julia scripts/ml/unified-learning-system.jl --collaboration

# Just knowledge extraction
julia scripts/ml/unified-learning-system.jl --knowledge
```

Each takes 30-90 seconds.

---

## Reading Results

### Feedback Report
```
✅ Feedback System: ACTIVE (23 feedback entries)
```
→ 23 user validation signals recorded since startup

### Collaboration Graph
```
✅ Collaboration Graph: 15 agent pairs analyzed
```
→ Identified 15 high-performing partnerships

### Knowledge Base
```
✅ Knowledge Base: 8 patterns extracted
```
→ 8 task types have solution patterns (for warm-start)

---

## Key Files to Know

```
data/
├── feedback-logs/feedback-validation.jsonl    ← Your feedback history
├── collaboration-graph.json                   ← Agent partnerships
├── knowledge-base/extracted-patterns.json     ← Solution patterns
├── rl/rl-agent-selection.json                 ← Q-scores (agent routing)
└── audit-logs/YYYY-MM-DD.jsonl               ← Task history (immutable)

scripts/ml/
├── unified-learning-system.jl                 ← Main interface
├── feedback-validator.jl                      ← Record feedback
├── collaboration-graph.jl                     ← Analyze partnerships
└── knowledge-extractor.jl                     ← Extract patterns
```

---

## One-Minute System Check

```bash
# Run this if you think something's wrong
time julia scripts/ml/unified-learning-system.jl --report

# Should show:
# - Feedback system status
# - Collaboration pairs count
# - Knowledge patterns count
# - Next steps
# - Time taken <5 seconds
```

If it takes >30 seconds or shows errors, check:
1. Disk space: `df -h`
2. Gateway health: `openclaw status`
3. Recent git changes: `git log --oneline -5`

---

## Weekly Checklist

- [ ] Run learning report (see if patterns growing)
- [ ] Record feedback for recent tasks
- [ ] Check Q-scores trending up (git log on rl-agent-selection.json)
- [ ] No audit log errors (check data/audit-logs/*.jsonl)

---

## Common Questions

**Q: Do I need to run learning manually?**  
A: No, cron jobs handle it. Manual runs only for testing/debugging.

**Q: How long until I see improvements?**  
A: 
- Immediate: First feedback → Q-learning updated (6h)
- Short-term: Patterns after 10-20 tasks (1-2 days)
- Long-term: Agent specialization visible after 100+ tasks (1-2 weeks)

**Q: What if feedback doesn't match my expectations?**  
A: That's data! The system learns from truth. Use `--quality` honestly.

**Q: Can I delete old feedback?**  
A: Not recommended (audit trail). Just mark future feedback accurately.

**Q: How do I export learning results?**  
A: All data is JSON. Parse with any tool:
```bash
# Query patterns
jq '.patterns | keys' data/knowledge-base/extracted-patterns.json

# Check Q-scores
jq '.task_types | to_entries[0]' data/rl/rl-agent-selection.json

# View feedback history
tail -10 data/feedback-logs/feedback-validation.jsonl
```

---

## Learning System Is Ready

You have:
- ✅ Feedback validation (P0)
- ✅ Collaboration detection (P1)  
- ✅ Knowledge extraction (P2)
- ✅ Automated learning pipeline
- ✅ Daily cron jobs running

**Next step:** Run tasks, record feedback, watch the system improve.

---

_For complete reference: see `docs/LEARNING-SYSTEM.md`_  
_For architecture: see `docs/SYSTEM_OVERVIEW.md`_  
_For configuration: see `docs/CONFIGURATION.md`_
