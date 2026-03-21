# PHASE 12B-i: RLVR (Reinforcement Learning with Verifiable Rewards) Specification

**Status:** PLANNING (2026-03-21 19:18 GMT)  
**Target:** Production deployment 2026-03-26 (Wednesday)  
**Confidence:** HIGH (88%)  
**Effort:** ~6-8 hours Julia

---

## Executive Summary

Formalize the system's current Q-learning metrics (Phase 7A/7B) into a **Verifiable Rewards** framework that:
1. **Tracks** measurable outcomes (success rate, latency, cost, quality)
2. **Verifies** that agents meet SLA constraints (not just optimizing Q)
3. **Audits** all reward decisions with immutable logs (for compliance/safety)
4. **Scales** safely to 20+ agents by detecting reward drift early

**Why Now:** Phase 12A adds 9 new agents (11→20). RLVR prevents scaling disasters by catching failing agents before SLA breach.

---

## Problem Statement

### Current State (Phase 7A-7B)
✅ Q-learning optimizes for success  
✅ SLA calculator tracks metrics  
✅ Audit logs immutable  
❌ **No formal verification** — Can't prove agent meets SLA constraints  
❌ **Reward drift undetected** — Agent can degrade without triggering guardrails  
❌ **Scaling risk** — 20 agents with opaque reward signals = unpredictable failures  

### Concrete Risk Scenario
1. Scout (research) Q=0.803, success=100%
2. Scale to 20 agents, Scout gets 3x task volume
3. Success drops to 72% (overloaded, context limits)
4. Q-learning slowly adjusts Q from 0.803 → 0.65 over days
5. **Problem detected on Day 4.** SLA already breached Day 1.

**RLVR Solves This:**
- Define success rate ≥ 80% as **hard constraint** (not just optimization target)
- Daily verification: Is Scout meeting 80% threshold?
- **YES** → Reward signal is trustworthy, Q-learning updates safe
- **NO** → Alert immediately, freeze Q-updates, investigate

---

## Core Concepts

### 1. Verifiable Reward (VR)

A reward is "verifiable" if it's **measured, audited, and constraint-checked**.

**Structure (per task outcome):**
```json
{
  "event_type": "task_outcome",
  "agent": "Scout",
  "task": "research",
  "success": true,
  "duration_ms": 1850,
  "cost_usd": 0.019,
  "quality_score": 0.92,
  "timestamp": "2026-03-21T09:51:28Z",
  
  "verifiable_reward": {
    "base_reward": 0.85,           // Raw success (0 or 1)
    "latency_penalty": 0,           // -0.15 if duration_ms > 2000
    "cost_penalty": 0,              // -0.10 if cost_usd > 0.025
    "quality_bonus": 0.07,          // +0.07 if quality_score > 0.90
    "final_reward": 0.92,           // base + penalties + bonuses
    
    "constraint_check": {
      "latency_p50_meets_sla": true,  // 1850ms < 2000ms target
      "success_rate_meets_sla": true, // Running success ≥ 80%
      "cost_meets_sla": true,         // cost_usd ≤ 0.025
      "quality_meets_sla": true,      // quality_score ≥ 0.85
      "overall_sla_compliant": true,  // All constraints met
      "audit_id": "ar-2026-03-21-scout-001"
    },
    
    "verification_timestamp": "2026-03-21T09:51:28.500Z",
    "verifier_version": "phase12b-rlvr-v1"
  }
}
```

### 2. SLA Constraints (Hard Requirements)

**Global SLA (applies to all agents):**
| Metric | Target | Threshold | Alert |
|--------|--------|-----------|-------|
| Success Rate | ≥ 80% | < 75% | CRITICAL |
| Latency P50 | ≤ 2000ms | > 2500ms | WARNING |
| Latency P95 | ≤ 3000ms | > 3500ms | WARNING |
| Cost per Task | ≤ $0.025 | > $0.030 | WARNING |
| Quality Score | ≥ 0.85 | < 0.80 | WARNING |

**Agent-Specific Overrides (if needed later):**
```julia
const SLA_OVERRIDES = Dict(
    "Cipher" => Dict("success_rate" => 0.75),  # Security is harder
    "Scout" => Dict("latency_p95_ms" => 3500), # Research needs time
    # ... more as needed
)
```

### 3. Verification Loop (Daily)

**Current (Phase 8A):** Hourly drift detection → alerts if Q < 0.55  
**RLVR addition:** Constraint verification → alerts if SLA breached

```
Task Outcome
    ↓
Calculate VR (reward + constraint check)
    ↓
Log to audit trail (immutable)
    ↓
Update Q-learning (IF constraints met)
    ↓
Detect drift (Phase 8A continues)
    ↓
Alert if SLA breached (NEW)
```

### 4. Audit Trail (Immutable Record)

**New audit event type: `reward_verification`**
```json
{
  "event_type": "reward_verification",
  "timestamp": "2026-03-21T09:51:28.500Z",
  "verification_id": "arv-2026-03-21-001",
  "agent": "Scout",
  "task": "research",
  "verifiable_reward": { ... },
  "constraint_violations": [],  // Empty if all OK
  "action_taken": "q_update_allowed",  // or "q_update_blocked"
  "reason": "All SLA constraints met"
}
```

---

## Implementation Plan

### Phase 12B-i: Core RLVR (6-8 hours)

**Script 1: rlvr-calculator.jl** (2 hours)
- Input: Task outcome JSON
- Output: Verifiable reward + constraint check
- Implements SLA thresholds
- Creates audit record
- ~300 lines Julia

**Script 2: rlvr-verifier.jl** (1.5 hours)
- Reads audit logs
- Generates daily verification report
- Detects constraint violations
- Recommends actions (freeze Q? investigate?)
- ~200 lines Julia

**Script 3: spawner-matrix-rlvr.jl** (1.5 hours)
- Integrate RLVR into spawner-matrix.jl
- Before Q-update: Verify constraints
- If violation detected: Alert + freeze Q
- Otherwise: Normal Q-learning
- ~150 lines Julia additions

**Script 4: rlvr-auditor.jl** (1 hour)
- Generate immutable audit reports
- Proof of SLA compliance (for regulatory)
- Monthly/weekly summaries
- ~180 lines Julia

**Testing** (1 hour)
- Unit tests (constraint checking)
- Integration tests (spawner + RLVR)
- Simulation: 20-agent scaling test
- Verify no Q-learning regression

**Documentation** (30 min)
- Update PHASE12B_RLVR_SPEC.md (this file)
- Add RLVR_OPERATIONS.md (how to monitor/debug)
- Update spawner-matrix.jl comments

---

## Technical Details

### Reward Calculation

```julia
function calculate_verifiable_reward(outcome::Dict)
    base_reward = outcome["success"] ? 1.0 : 0.0
    
    # Latency penalty (0 to -0.15)
    latency_penalty = if outcome["duration_ms"] > 2000
        -0.15 * min(1.0, (outcome["duration_ms"] - 2000) / 1000)
    else
        0
    end
    
    # Cost penalty (0 to -0.10)
    cost_penalty = if outcome["cost_usd"] > 0.025
        -0.10 * min(1.0, (outcome["cost_usd"] - 0.025) / 0.010)
    else
        0
    end
    
    # Quality bonus (0 to +0.15)
    quality_bonus = if outcome["quality_score"] > 0.90
        0.15 * (outcome["quality_score"] - 0.90) / 0.10
    else
        0
    end
    
    final_reward = clamp(
        base_reward + latency_penalty + cost_penalty + quality_bonus,
        0.0, 1.0
    )
    
    return final_reward
end
```

### Constraint Checking

```julia
function check_sla_constraints(agent::String, task::String, metrics::Dict)
    constraints = Dict(
        "latency_p50_meets_sla" => metrics["latency_p50_ms"] <= 2000,
        "success_rate_meets_sla" => metrics["success_rate"] >= 0.80,
        "cost_meets_sla" => metrics["cost_per_task"] <= 0.025,
        "quality_meets_sla" => metrics["quality_score_avg"] >= 0.85
    )
    
    constraints["overall_sla_compliant"] = all(values(constraints))
    
    return constraints
end
```

### Q-Learning Update Gate

```julia
function update_q_with_verification(agent::String, task::String, reward::Float64, constraints::Dict)
    if !constraints["overall_sla_compliant"]
        # SLA breached: freeze Q-learning for this agent
        log_alert("SLA_BREACH", agent, constraints)
        return false  # Don't update Q
    end
    
    # Normal Q-learning update
    update_q_learning(agent, task, reward)
    return true  # Updated
end
```

---

## Integration Points

### 1. **spawner-matrix.jl** (Modify)
- After task outcome received
- Before Q-learning update
- Call RLVR verification
- Gate Q-update on constraint check

### 2. **audit-logs/YYYY-MM-DD.jsonl** (Append to)
- New event type: `reward_verification`
- Immutable record of all constraint checks
- Enables regulatory audit trail

### 3. **Phase 7B Insights** (Enhance)
- Daily insights now include constraint compliance
- Flag agents with marginal SLA status
- Recommend retraining if violations detected

### 4. **Phase 8A Drift Detector** (Complement, not replace)
- Phase 8A: Detects Q < 0.55 (performance issue)
- RLVR: Detects SLA breach (safety issue)
- Both run independently, both alert on problems

---

## Success Criteria

✅ **Verification Accuracy:** 100% of task outcomes have VR + constraint check  
✅ **Audit Trail:** All verification events immutably logged  
✅ **SLA Detection:** Constraint violations detected within 1 outcome (same-day alert)  
✅ **Q-Learning Safety:** Q doesn't update if SLA violated (prevents bad learning)  
✅ **Zero Regression:** Phase 7A/7B/8A continue functioning (RLVR is additive)  
✅ **Scaling Readiness:** System detects degradation when scaling to 20 agents  
✅ **Compliance Ready:** Audit trail suitable for regulatory review  

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| SLA thresholds too strict | MEDIUM | Q-learning frozen, agents unused | Start with warning-only, escalate to freeze after validation |
| Audit log size explodes | LOW | Disk usage grows | Rotate logs daily, compress weekly |
| Constraint violations cascade | LOW | Multiple agents fail together | Isolate per-agent constraints, don't freeze global Q |
| Q-learning stagnates | MEDIUM | No improvement if SLA marginal | Adjust SLA thresholds per agent if needed |
| Verifier becomes bottleneck | LOW | Verification latency > task latency | Run async, verify after outcome logged |

**Overall Risk:** LOW (88% confidence) → MEDIUM (75%) with scaling to 20 agents → LOW again after RLVR active

---

## Timeline

| Milestone | Date | Duration | Owner |
|-----------|------|----------|-------|
| Spec approval + design review | 2026-03-21 | -- | Morpheus + Art |
| Core scripts (RLVR calculator + verifier) | 2026-03-23 to 2026-03-24 | 3-4h | Codex |
| Spawner integration + testing | 2026-03-24 to 2026-03-25 | 2-3h | Codex + QA |
| Audit trail validation | 2026-03-25 | 1h | Veritas |
| Documentation + runbooks | 2026-03-25 | 1h | Chronicle |
| **Prod deployment** | **2026-03-26 (Wed)** | **-- (go-live)** | **Sentinel** |
| Phase 12A stability + RLVR monitoring | 2026-03-26 to 2026-03-28 | 3 days | Morpheus |

---

## Appendix: Current State (Reference)

**What's Already Live:**
- ✅ Phase 11A: Audit logs (all task spawns + outcomes logged)
- ✅ Phase 11B: SLA calculator (metrics: latency, success, cost, quality)
- ✅ Phase 7A-7B: Q-learning (adaptive agent selection)
- ✅ Phase 8A: Drift detector (hourly checks, Q < 0.55 alert)

**What RLVR Adds:**
- 🔄 **Constraint verification** (formal SLA contract)
- 🔄 **Verifiable rewards** (trustworthy reward signal)
- 🔄 **Q-learning gates** (don't learn from bad data)
- 🔄 **Audit proof** (regulatory-grade compliance trail)

**What Stays Unchanged:**
- Phase 4, 5, 6, 7A-7B, 8A, 9A, 11A-11C continue as-is
- RLVR is **additive**, not replacing

---

## Verification & Sign-Off

**Spec Review:**
- [ ] Technical feasibility (Codex)?
- [ ] Risk assessment OK (Cipher)?
- [ ] Audit trail compliance (Veritas)?
- [ ] Operational runbook viable (Sentinel)?
- [ ] Documentation complete (Chronicle)?

**Art Sign-Off:**
- [ ] Spec aligns with 2026 research trends?
- [ ] Worth 6-8 hours effort before Phase 12A stabilizes?
- [ ] Acceptable risk profile for scaling to 20 agents?

---

**Document Status:** DRAFT → REVIEW → APPROVED → IMPLEMENTED

_Created: 2026-03-21 19:18 GMT_
