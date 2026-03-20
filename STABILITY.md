# STABILITY.md - System Stability & Self-Improvement

Last updated: 2026-03-20 22:25 GMT
Status: **GUARDRAILS ADDED** — Agent drift detection + task validation live

---

## System Stability Strategy

### Three-Layer Defense

1. **Guardrails (Detect Drift)**
   - Script: `scripts/agent-drift-detector.py`
   - Monitors: Q-scores, success rates, task type performance
   - Alerts: If any agent success < 50% or Q-score < 0.55
   - Frequency: Hourly (via cron)

2. **Task Validation (Prevent Mismatches)**
   - Script: `scripts/task-validator.py`
   - Verifies: Task definitions match agent specialization
   - Identifies: Routing misalignments before they impact performance
   - Frequency: Daily (via cron)

3. **Feedback Loop (Learn from Outcomes)**
   - Phase 7B: Daily insights analysis (01:30 UTC)
   - Phase 4: Weekly monitoring dashboard (Monday 10:00 UTC)
   - Action: Session startup reads learnings, informs routing decisions

---

## Current System Health

### Agent Performance (as of 2026-03-20 22:25 UTC)

**High Performers:**
- ✅ Scout: Q=0.803, Success=100% (research specialist)
- ✅ Cipher: Q=0.90, Success=90% (security specialist)
- ✅ Codex: Q=0.75, Success=76% (coding specialist)

**Monitor:**
- 🟡 Chronicle: Q=0.616, Success=67% (documentation)
  - Issue: Being assigned research tasks (RL papers)
  - Fix: Route research → Scout, documentation → Chronicle

- 🟡 Sentinel: Q=0.532, Success=57% (infrastructure)
  - Issue: Being assigned testing/security tasks
  - Fix: Clarify task type boundaries, reduce allocation

**Newly Fixed:**
- 🟢 QA: Q=0.70, Success=baseline (testing)
  - Fix applied 2026-03-20 22:16: Removed from code routing, created "testing" type
  - Status: Learning from real testing tasks now

---

## Critical Metrics to Watch

### Stability Thresholds

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Agent Q-score | > 0.70 | 0.55-0.70 | < 0.55 |
| Success rate | > 75% | 50-75% | < 50% |
| Cost reduction | 60-65% | 55-60% | < 55% |
| Task mismatches | < 10% | 10-20% | > 20% |

### Current Status

- **Cost Reduction:** ✅ 60-65% (GOOD)
- **Agent Alignment:** 🟡 7 agents show misalignment (MONITOR)
- **Learning Speed:** ⏰ Phase 7B daily at 01:30 UTC (acceptable, can optimize)
- **Feedback Lag:** ⏳ 24h between outcome and routing insight (may add drift)

---

## Stability Roadmap

### Phase 8A: Immediate Safeguards (2026-03-20 22:25)
**Status:** IN PROGRESS

- [x] Agent drift detector script
- [x] Task validator script
- [ ] **NEXT:** Schedule cron jobs (hourly + daily)
- [ ] Document known misalignments (Chronicle, Sentinel)
- [ ] Create rollback procedure if issues detected

### Phase 8B: Feedback Acceleration (2026-03-21)
**Planned:** Reduce Phase 7B cycle from daily to hourly
- Benefit: Faster learning, quicker issue detection
- Cost: ~1% more compute
- Trade-off: Accept for stability

### Phase 8C: Task Refinement (2026-03-22+)
**Planned:** Address identified misalignments
- Chronicle: Clarify documentation vs. research boundaries
- Sentinel: Define infrastructure scope (not security/testing)
- Codex: Reduce exposure to security/database work

---

## Known Issues

### 1. Task-Agent Misalignment
**Status:** DETECTED (Phase 8A)
- Chronicle assigned research (should be Scout)
- Sentinel assigned security (should be Cipher)
- Codex assigned security review (should be Cipher/Veritas)
- QA assigned coding (FIXED 2026-03-20)

**Resolution:**
- Review task definitions in spawner-matrix.jl
- Use Phase 7B learnings to guide routing
- Retest after adjustments

### 2. Low Learning Speed (24h cycle)
**Status:** ACCEPTABLE for now
- Phase 7B runs daily at 01:30 UTC
- Outcomes recorded immediately
- Routing updated at next session start
- Lag: Up to 24 hours for new insights to affect routing

**Option:** Accelerate to hourly in Phase 8B

### 3. Cold Start (New Task Types)
**Status:** MANAGED
- QA testing: Started at 0.70 baseline
- Recommendation: Feed 5 easy tasks first, then hard tasks
- Monitor: Watch success rate during first 20 outcomes

---

## How to Maintain Stability

### Daily (Automated)
- ✅ Phase 7B: Insights analysis at 01:30 UTC
- ✅ Read learnings at session start
- ✅ Log decisions in daily memory file

### Weekly (Manual Review)
- Check: Phase 4 monitoring dashboard (Monday 10:00 UTC)
- Review: Any agent below 60% success
- Action: Investigate root cause (task mismatch vs. capability)

### Monthly (Deep Dive)
- Run: scripts/agent-drift-detector.py (validate no new drift)
- Run: scripts/task-validator.py (check alignment)
- Analyze: Trends in cost, quality, success rate
- Adjust: Task definitions or agent allocation if needed

---

## Rollback Safety

### If System Degrades

1. **Detect:** Agent drift detector alerts (Q-score drops >0.10)
2. **Confirm:** Task validator shows misalignment
3. **Isolate:** Reduce allocation to affected agent
4. **Revert:** Roll back task routing to previous config

**Rollback Procedure:**
```bash
# Find backup
ls -lh data/rl/rl-agent-selection.json.backup*

# Restore previous version
cp data/rl/rl-agent-selection.json.backup-TIMESTAMP data/rl/rl-agent-selection.json

# Commit rollback
git commit -m "rollback: revert QA/Sentinel/Chronicle routing due to drift"

# Notify: Document reason in memory file
```

---

## Self-Improvement Loop

**Current State (2026-03-20):**
1. Outcomes recorded in rl-task-execution-log.jsonl
2. Phase 7B analyzes daily, generates insights
3. Session reads insights, makes routing decisions
4. New outcomes feed back into analysis

**Positive Feedback:**
- More outcomes → Better learnings → Better routing → More success → Faster learning

**Safeguard:**
- Drift detector prevents runaway degradation
- Task validator prevents persistent mismatches
- Q-learning naturally degrades poor agents

---

## Success Metrics

We'll know the system is stable when:
1. ✅ All agents Q-score > 0.65 (or specialized high)
2. ✅ Task-agent misalignment < 5% (good alignment)
3. ✅ Cost reduction maintained at 60%+
4. ✅ No agent success rate drops >0.10 in 24h
5. ✅ Daily learnings show improvement trend

---

**Next Action:** Schedule cron jobs (Phase 8A step 2)
