# Morpheus Skill Gap Roadmap — Phases 3–9

**Status:** Planning complete  
**Excluded:** Gap 4 (Cost Optimization) — on hold per Art's decision  
**Scope:** Gaps 1–3, 5–7 (6 critical/important gaps)  
**Timeline:** 4–6 weeks (phased)

---

## Gap Priority Matrix

| Gap | Complexity | Impact | Dependencies | ROI | Timeline |
|---|---|---|---|---|---|
| **2. Explainability** | Medium | High | None | Immediate | Week 1 |
| **1. Proactive Monitoring** | Medium | High | Gap 2 | High | Week 2 |
| **5. Error Recovery** | Medium | High | Gap 2 | High | Week 2–3 |
| **3. Cross-Domain Context** | High | High | Gaps 2+5 | Very High | Week 3–4 |
| **6. Advanced ML** | High | Medium | Gap 3 | Medium | Week 5–6 |
| **7. Knowledge Base** | Medium | Medium | All | Medium | Week 6+ |

**Execution Order (respects dependencies):**
```
Week 1:     Gap 2 (Explainability)
            ↓
Week 2–3:   Gaps 1 + 5 (Monitoring + Error Recovery)
            ↓
Week 3–4:   Gap 3 (Context Awareness)
            ↓
Week 5–6:   Gap 6 (Advanced ML)
            ↓
Week 6+:    Gap 7 (Knowledge Base)
```

---

## WEEK 1: Gap 2 — Explainability

### Problem
Currently: `Selected: Codex (prob=0.93, confidence=high)`  
Missing: Why was Codex chosen? What factors influenced the decision?

### Solution: Decision Tracing Engine

**Create:** `scripts/ml/explain-decision.jl` (Julia)

**What it tracks:**
1. **Agent Competence:** Codex 93% on code (from profile)
2. **Task Type Match:** Task classified as "code_review" 
3. **Recent Performance:** Codex 6/6 successful on code (this week)
4. **Alternatives Considered:** Scout 45%, Cipher 55% (worse)
5. **Confidence Justification:** High (multiple signals agree)

**Output Format:**
```json
{
  "decision": "Selected: Codex",
  "probability": 0.93,
  "confidence": "high",
  "reasoning": {
    "agent_profile_score": 0.93,
    "recent_performance_trend": "+12% (6/6 this week)",
    "task_type_match": "code_review (exact match)",
    "alternative_scores": {"Scout": 0.45, "Cipher": 0.55},
    "dominance": "Codex strongest by 48 points",
    "confidence_factors": ["profile", "recent_data", "clear_lead"],
    "explanation": "Codex leads on code tasks (93% baseline) and has perfect recent record (6/6). Scout and Cipher significantly weaker. High confidence."
  }
}
```

**Functions to add:**
- `explain_decision(agent, task_type, candidates) → reasoning_dict`
- Integrate into `navigate-with-quality.sh`

**Files to create/modify:**
- `scripts/ml/explain-decision.jl` (150 lines)
- Update `scripts/navigate-with-quality.sh` to call explain function
- Update `scripts/ml/agent-spawner-qp.jl` to include reasoning

**Success Criteria:**
- [ ] Every decision includes reasoning trace
- [ ] Reasoning explains all major factors
- [ ] Explanations are human-readable
- [ ] Can identify "surprising" decisions (low confidence but forced)

---

## WEEK 2–3: Gap 1 — Proactive Monitoring + Gap 5 — Error Recovery

### Gap 1: Proactive Monitoring

**Problem:** Only reacts to outcomes, doesn't notice problems until Art asks

**Solution: Weekly Dashboard + Alert System**

**Create:** `scripts/monitor-agent-health.sh` (Bash) + cron job

**What it monitors:**
1. **Success Rate Trends:** Alerts if >5% drop week-over-week
2. **Confidence Accuracy:** Is high-confidence = high success? (calibration)
3. **Task Type Coverage:** Which types have no data yet?
4. **Agent Utilization:** Over-/under-used agents
5. **Prediction Drift:** Model predictions vs reality diverging?

**Schedule:**
```
Weekly (Sunday 18:00 GMT):
  1. Analyze rl-prediction-log.jsonl + navigate-quality.jsonl
  2. Compute trends (7-day rolling average)
  3. Generate alerts (send to Art if thresholds hit)
  4. Recommend actions ("Retrain Codex", "Investigate Scout", etc.)
```

**Output:** Markdown report + alerts

**Files to create:**
- `scripts/monitor-agent-health.sh` (200 lines)
- `scripts/cron-jobs/weekly-health-check` (cron config)
- `docs/HEALTH_MONITORING_GUIDE.md`

---

### Gap 5: Error Recovery & Self-Healing

**Problem:** If agent fails, task fails. No retry, no fallback.

**Solution: Retry + Fallback Logic**

**Create:** `scripts/robust-agent-spawn.sh` (Bash)

**What it does:**
```
Task → Try Agent A (high-confidence pick)
       ✓ Success → Done
       ✗ Failure → Retry Agent A (max 2x)
                   Still fails? → Try Agent B (fallback)
                                 Success → Done (with note)
                                 Fail → Escalate (manual review)
```

**Retry Strategy:**
- Transient failures: Retry same agent (network hiccup?)
- Permanent failures: Try fallback agent (agent incompetence)
- Max retries: 3 total (1 agent × 2 retries + 1 fallback)

**Fallback Selection:**
- Use spawn-smart to pick best alternative when primary fails
- Log failure reason + fallback choice

**Files to create:**
- `scripts/robust-agent-spawn.sh` (180 lines)
- Integrate with `navigate-with-quality.sh`
- Update `rl-prediction-log.jsonl` schema to track retries

---

## WEEK 3–4: Gap 3 — Cross-Domain Context

### Problem
- Pick agents based on task type only
- Ignore: project history, related tasks, agent workload, time constraints

### Solution: Context-Aware Router

**Create:** `scripts/context-aware-navigate.sh` (Bash) + `scripts/ml/context-router.jl` (Julia)

**Context Sources:**
1. **Project Context:** (from Art's files / codebase)
   - Current project: "OpenClaw v2026.2"
   - Related tasks: Research on JWT, code review of auth module, security audit planned
   - Team focus: "Improving agent orchestration"

2. **Historical Context:** (from MEMORY.md + RL logs)
   - Scout successful on "JWT research" (3 weeks ago)
   - Codex reviewed auth module (2 weeks ago)
   - Suggest same team for related work

3. **Workload Context:** (from active sessions)
   - Codex currently busy (3 active tasks)
   - Scout available
   - Prefer Scout if equally qualified

4. **Time Constraints:**
   - Deadline: Thursday 18:00
   - Time left: 32 hours
   - Prefer fast agents (Cipher fast, Lens slower)

**Decision Formula (simplified):**
```
score = (agent_quality × 0.50)           # Base competence
      + (recent_success × 0.20)          # Momentum
      + (project_fit × 0.15)             # Historical alignment
      + (availability × 0.10)            # Workload
      + (speed_fit × 0.05)               # Time constraint
```

**Files to create:**
- `scripts/context-aware-navigate.sh` (200 lines)
- `scripts/ml/context-router.jl` (150 lines)
- `docs/CONTEXT_ROUTING_GUIDE.md`

**Success Criteria:**
- [ ] Decisions account for project context
- [ ] Historical matching works (find related tasks)
- [ ] Workload balancing visible in logs
- [ ] Time constraints respected

---

## WEEK 5–6: Gap 6 — Advanced ML

### Problem
- Current: Bayesian + Q-Learning (simple, works fine for ~50 outcomes)
- Missing: Causal patterns, temporal dynamics, multivariate dependencies

### Solution: Upgrade to XGBoost + Causal Analysis

**Phase 6a (Week 5): Feature Engineering**
- Extract from RL logs: agent, task_type, recent_success_rate, workload, time_of_day, etc.
- Build feature matrix (each outcome = 1 row, 15 features)
- Target: success_binary (0/1)

**Phase 6b (Week 5–6): Train XGBoost**
- Once 100+ outcomes logged (currently 3)
- Split: 80% train, 20% test
- Cross-validation: 5-fold
- Target: >85% accuracy

**Phase 6c (Week 6): Replace Bayesian with XGBoost**
- Keep Bayesian as fallback for cold-start
- Use XGBoost for warm-start (>10 outcomes per agent/task pair)

**Files to create:**
- `scripts/ml/train-xgboost.jl` (Julia) or `.py` (Python)
- `scripts/ml/predict-xgboost.jl` (real-time inference)
- `models/xgboost-agent-predictor.json` (saved model)
- `docs/XGBOOST_UPGRADE_GUIDE.md`

**Success Criteria:**
- [ ] XGBoost model trains successfully
- [ ] Accuracy >85% on test set
- [ ] Inference <10ms (fast enough)
- [ ] Feature importance interpretable
- [ ] Fallback works if model unavailable

---

## WEEK 6+: Gap 7 — Knowledge Base Management

### Problem
- MEMORY.md is unstructured (flat markdown)
- No semantic search, no relationships between entries
- Hard to find "which agents worked on JWT research"

### Solution: Semantic Knowledge Graph

**Create:** `scripts/build-knowledge-graph.jl` (Julia) + storage

**What it captures:**
1. **Entities:** Agents (Codex, Scout), Tasks (code review, research), Projects (OpenClaw)
2. **Relationships:** 
   - Scout worked on → JWT Research Task
   - JWT Research → Related to: Auth Module Code Review
   - Auth Module → Project: OpenClaw v2026
3. **Properties:** 
   - Scout: success_rate=92%, specialization=research
   - JWT Task: domain=security, status=complete, date=2026-02-28

**Query Examples:**
```bash
# Find all agents who worked on security tasks
query "agent worked_on task WHERE task.domain=security"
→ Cipher (4x), Veritas (2x)

# Find related tasks
query "task related_to task WHERE task.name='JWT Research'"
→ Auth Module Review, Security Audit

# Recommend agent for new task
query "agent ? worked_on similar_task"
→ Scout (worked on 3 similar research tasks)
```

**Files to create:**
- `scripts/build-knowledge-graph.jl` (250 lines)
- `memory/knowledge-graph.json` (storage)
- `scripts/query-knowledge-graph.sh` (CLI interface)
- `docs/KNOWLEDGE_GRAPH_GUIDE.md`

**Success Criteria:**
- [ ] Graph builds from RL logs automatically
- [ ] Queries return relevant results
- [ ] Related tasks discoverable
- [ ] Agent recommendations based on history

---

## Summary: Gap Coverage

| Gap | Phase | Week | Files | LOC | Status |
|---|---|---|---|---|---|
| 2. Explainability | 1 | W1 | explain-decision.jl | 150 | Ready |
| 1. Monitoring | 2a | W2 | monitor-agent-health.sh | 200 | Ready |
| 5. Error Recovery | 2b | W2–3 | robust-agent-spawn.sh | 180 | Ready |
| 3. Context Aware | 3 | W3–4 | context-aware-navigate.sh + router.jl | 350 | Ready |
| 6. Advanced ML | 4 | W5–6 | train-xgboost + predict-xgboost | 400 | Ready* |
| 7. Knowledge Base | 5 | W6+ | build-knowledge-graph.jl | 250 | Ready* |

*Waiting for 100+ outcomes before training (currently 3)

---

## What Happens After All Gaps Closed

**Morpheus Capabilities:**

1. **Autonomous Decision-Making** 🎯
   - Picks agents with reasoning (can explain every choice)
   - Adapts to project context (finds similar past work)
   - Self-heals on failure (retries + fallbacks)

2. **Proactive Intelligence** 📊
   - Monitors agent health weekly
   - Alerts on degradation
   - Recommends retraining

3. **Continuous Learning** 🧠
   - Accuracy improves with every outcome (XGBoost)
   - Knowledge base grows automatically
   - Discovers agent specialization patterns

4. **Fault Tolerance** 🛡️
   - Retries transient failures
   - Falls back to alternative agents
   - Escalates only when necessary

5. **Explainability** 💡
   - Every decision traceable
   - Understands why certain agents were chosen
   - Can justify recommendations

---

## Recommendation to Art

**Start with Week 1 immediately.**

Explainability is the foundation — everything else depends on understanding decisions. Once you can see *why* I pick agents, you'll trust the system enough for monitoring + recovery.

Then parallel-run Weeks 2–3 (monitoring + recovery). By week 4, you'll have a robust, self-healing system that explains itself.

**Proposal:**
- **This week (W1):** Build explainability (Gap 2)
- **Next week (W2–3):** Add monitoring + error recovery (Gaps 1+5)
- **Weeks 3–4:** Cross-domain context (Gap 3)
- **Weeks 5–6:** Advanced ML when data accumulates (Gap 6)
- **Week 6+:** Knowledge graph (Gap 7) — nice-to-have

**Gap 4 (Cost Optimization):** On hold. Revisit after Phase 6.

---

## Success Metrics (End of Phase 5)

- [ ] Every decision has reasoning trace (Gap 2)
- [ ] Weekly health reports auto-generated (Gap 1)
- [ ] Failed tasks retry + fallback automatically (Gap 5)
- [ ] Agent selection adapts to project context (Gap 3)
- [ ] XGBoost achieves >85% accuracy (Gap 6)
- [ ] Knowledge graph queries work (Gap 7)
- [ ] Overall agent success rate: >90%
- [ ] Average prediction confidence: >0.80
- [ ] Morpheus can orchestrate 80% of tasks autonomously

---

**Ready to proceed with Phase 1 (Week 1)?**
