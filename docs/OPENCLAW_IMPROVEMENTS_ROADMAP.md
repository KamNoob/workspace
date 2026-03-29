# OpenClaw Improvements Roadmap — Julia / Rust / R

**Current State:** Phase 1+3B complete (fast RL, analytics ready)  
**Next Frontier:** Predictive routing, cost visibility, session optimization

---

## Impact Matrix

| Improvement | Julia | Rust | R | Impact | Effort | Time |
|------------|-------|------|---|--------|--------|------|
| **Container Sandboxing (Phase 12A Blocker)** | ✓ | | | **CRITICAL** | **Low** | **1-2h** |
| **Task Prediction** | ✓ | | | High | Medium | 3-4h |
| **Outcome Prediction** | ✓ | | | High | Low | 2-3h |
| **Cost Analysis** | | | ✓ | Medium | Low | 2-3h |
| **Session Optimization** | ✓ | ✓ | | High | Medium | 3-4h |
| **Interactive Dashboard** | | | ✓ | Medium | Medium | 5-8h |
| **Embedding Speedup** | ✓ | ✓ | | Low | Hard | 5-6h |
| **Workflow Recommendation** | ✓ | | | Medium | Low | 2-3h |

---

## Top Priority: Container Sandboxing (Phase 12A Blocker)

### Container Sandbox Execution — 1-2 hours (CRITICAL)

**What it does:**
Wraps agent spawning in Docker/Podman containers with mount security, resource limits, and network isolation. Agents execute in isolated environments, preventing filesystem access, privilege escalation, and resource starvation.

**Problem it solves:**
- **Current risk:** Agents run directly in process with full filesystem access (can trash system)
- **Phase 12A blocker:** Before scaling to 20 agents, need execution isolation
- **Security gap:** No protection against buggy or compromised agents
- **Resource risk:** Runaway agent can consume all CPU/RAM

**Why critical for Phase 12A:**
- Scales from 11 → 20 agents (more agents = higher risk)
- Enables safe agent expansion without sandbox = no go-live
- Prerequisite for Phase 13+ (autonomous routing requires agent isolation)

**Implementation (1-2 hours):**

```julia
# NEW: scripts/ml/spawner-sandboxed.jl

struct SandboxConfig
    image::String              # "julia:1.12-slim"
    mounts::Dict              # {host_path => container_path}
    memory_limit::String      # "2g", "4g"
    timeout_seconds::Int      # Kill after this long
    network::String           # "none" (secure) or "host"
end

function spawn_sandboxed(agent::String, task::String, config::SandboxConfig)
    # Docker run with:
    # - Mount security (read-only data, writable scratch)
    # - Resource limits (memory, CPU)
    # - Network isolation (network=none)
    # - Unprivileged user (no root)
    # - Kill timeout (no hung agents)
    # Returns: {status, output, container_id, runtime_ms}
end
```

**Deployment timeline:**
1. **Hour 1:** Build Docker image + write spawner-sandboxed.jl
2. **Hour 2:** Wrap 1 agent (Scout) as test + verify isolation works
3. **Gate Phase 12A:** All agents spawn sandboxed before Monday launch

**New files:**
- `docker/Dockerfile.agent` — Agent container image
- `scripts/ml/spawner-sandboxed.jl` — Sandbox wrapper
- `docker-compose.yml` — Optional: manage multiple containers

**Configuration example:**
```julia
sandbox_config = SandboxConfig(
    image="julia:1.12-slim",
    mounts=Dict(
        "/home/art/.openclaw/workspace/data" => "/data:ro",      # Read-only
        "/tmp/agent-scratch" => "/scratch:rw"                    # Writable
    ),
    memory_limit="2g",
    timeout_seconds=300,
    network="none"  # No outbound access
)
```

**Security properties:**
- ✅ Filesystem isolation (agents can't access host files)
- ✅ Network isolation (can't exfiltrate data)
- ✅ Resource limits (can't starve system)
- ✅ Unprivileged execution (can't escalate privileges)
- ✅ Kill timeout (can't hang indefinitely)

**Performance overhead:**
- ~200ms per spawn (container startup)
- ~500MB disk per image (acceptable)
- Requires Docker/Podman running

**Reversibility:**
- If sandbox causes issues, can fall back to direct spawn
- Config flag: `use_sandbox=true/false`
- Zero impact on agent code (transparent wrapper)

**Success criteria:**
- ✅ Scout agent runs in container
- ✅ Agent can read `/data` (mount works)
- ✅ Agent can't read `/etc/passwd` (isolation works)
- ✅ Agent killed after 5min timeout (safety works)
- ✅ All Phase 12A agents ready by Monday

**Go-live gate:** Phase 12A launch blocked until sandbox passes security tests.

---

## Top 3 Recommendations (Quick Wins)

### 1. Task Prediction (Julia ML) — 3-4 hours

**What it does:**
Predicts the next task type from context, allowing smarter initial agent selection.

**Problem it solves:**
- First agent choice is currently random (equal Q-scores at startup)
- Current system needs 3-5 attempts to learn task → agent mapping
- With prediction: First agent choice is 70-80% optimal

**Implementation:**

```julia
# TaskPredictor.jl
using StatsBase, Distributions

"""
    MarkovTaskModel
    
Learns task sequence transitions from outcome logs.
Returns probability distribution over next task type.
"""
mutable struct MarkovTaskModel
    transitions::Dict{String, Dict{String, Float64}}  # task → {next_task → prob}
    counts::Dict{String, Dict{String, Int}}
end

function predict_next_task(model::MarkovTaskModel, current_task::String)
    # Return P(next_task | current_task)
    return get(model.transitions, current_task, Dict())
end
```

**Usage:**
```bash
julia scripts/ml/task-predictor.jl train
# Learns from rl-task-execution-log.jsonl

julia scripts/ml/task-predictor.jl predict "code"
# Output: {research: 0.4, review: 0.3, security: 0.2, ...}
```

**Expected Gain:**
- Cold-start optimization: 20-30% better first agent choice
- Convergence speed: ~10% faster (smarter exploration)

---

### 2. Outcome Prediction (Julia ML) — 2-3 hours

**What it does:**
Predicts success probability BEFORE spawning an agent, enabling escalation of risky decisions.

**Problem it solves:**
- No warning before bad decisions
- Can't pre-filter high-risk assignments
- Low-confidence spawns could fail silently

**Implementation:**

```julia
# OutcomePredictor.jl
"""
    LogisticOutcomeModel
    
P(success | task, agent, context_metadata)
Trained on outcome logs.
"""
struct LogisticOutcomeModel
    weights::Dict{String, Float64}
    intercept::Float64
end

function predict_success(model, task, agent, context_features)
    # Logistic regression: 1 / (1 + exp(-z))
    z = model.intercept
    z += model.weights["task_$task"] 
    z += model.weights["agent_$agent"]
    z += dot(model.weights["context_"], context_features)
    
    return 1 / (1 + exp(-z))
end
```

**Usage:**
```bash
# Before spawning agent
prob_success = predict_success(model, "code", "Codex", features)

if prob_success < 0.6
    # Escalate instead of spawn
    return Dict("decision" => "escalate", "reason" => "Low confidence ($(prob_success))")
end
```

**Expected Gain:**
- Pre-filter 5-10% of low-confidence decisions
- Reduce failure rate by 50% (from 0% to near-0%)
- Better cost control

---

### 3. Cost/Benefit Analysis (R) — 2-3 hours

**What it does:**
Attribute token costs to agents, calculate ROI, identify expensive patterns.

**Problem it solves:**
- No visibility into which agents are expensive
- Can't optimize budget allocation
- No data-driven cost optimization

**Implementation:**

```r
# cost-analysis.R
library(tidyverse)
library(ggplot2)

# Load outcomes + token counts
outcomes <- read.csv("data/rl/rl-outcomes.csv")
tokens <- read.csv("data/rl/rl-tokens.csv")  # Add to pipeline

# Agent cost summary
agent_cost <- outcomes %>%
  left_join(tokens, by = "outcome_id") %>%
  group_by(agent) %>%
  summarise(
    total_tokens = sum(tokens),
    avg_tokens = mean(tokens),
    success_count = sum(success),
    token_per_success = total_tokens / sum(success),
    roi = sum(success) / (total_tokens / 1000)  # Success per 1K tokens
  ) %>%
  arrange(desc(roi))

# Plot: Token efficiency
ggplot(agent_cost, aes(x = reorder(agent, roi), y = roi)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = round(roi, 2))) +
  coord_flip() +
  labs(title = "Agent ROI (Success per 1K tokens)")
```

**Usage:**
```bash
# Add token tracking to spawner
# Then:
Rscript scripts/analytics/cost-analysis.R
```

**Expected Gain:**
- Identify expensive agents (maybe replace with cheaper alternative)
- Calculate payoff of each agent specialization
- Budget forecasting

---

## Medium-Priority Improvements

### 4. Session Context Optimization (Julia) — 3-4 hours

**Compress/deduplicate context across calls**
- Current: 58K context, growing
- Target: 30-40K (30-50% compression)
- Method: Vector clustering + delta encoding

### 5. Interactive Dashboard (R Shiny) — 5-8 hours

**Real-time web UI for monitoring**
- Agent health cards (success rate, avg response time)
- Convergence plots (live updating)
- Cost gauge
- Alert panel

### 6. Workflow Recommendation (Julia) — 2-3 hours

**Auto-route tasks to optimal workflow template**
- 6+ workflow templates (code-review, research, security-audit, etc.)
- Learn: task type → best workflow
- Reduce manual routing decisions

---

## Lower Priority (Phase 4+)

| Name | Impact | Difficulty | Time |
|------|--------|-----------|------|
| **Unsloth Fine-Tuning Integration** | 2x faster agent adaptation | Medium | 6-8h |
| **Embedding Optimization (Rust/Julia SIMD)** | 2-5x speedup | Hard | 5-6h |
| **Bayesian Agent Selection (Julia)** | Better exploration | Medium | 4-5h |
| **Performance Profiling (Julia)** | Find bottlenecks | Medium | 3-4h |
| **Rust Cron Scheduler** | Ultra-fast cron | Hard | 10+ h |

---

## My Recommendation

### Do This Week: Task + Outcome Prediction + Cost Analysis (6-7 hours total)

**Why:**
- Highest ROI (improve decision quality + visibility)
- All can use existing data (36+ outcomes)
- Build on Phase 1+3B foundation
- Modest time investment

**Sequence:**
```
Hour 1-3:  Task Prediction (Julia Markov model)
Hour 4-6:  Outcome Prediction (Julia logistic regression)
Hour 7-9:  Cost Analysis (R aggregation + plots)
```

**Payoff:**
- Smarter first agent choice (20-30% better)
- Early warning for bad decisions (<0.6 confidence)
- Visibility into cost per agent

### Then Consider: Interactive Dashboard (5-8 hours)

**Why:**
- Builds on Phase 3B analytics
- Replaces manual checking with real-time UI
- Good ROI for ongoing monitoring

**When:**
- After Task/Outcome/Cost analysis stabilize
- If real-time visibility becomes important

---

## Architecture: Where to Add Code

### Julia (scripts/ml/)
- `task-predictor.jl` — Task sequence model
- `outcome-predictor.jl` — Success probability model
- `workflow-recommender.jl` — Task → workflow routing

### R (scripts/analytics/)
- `cost-analysis.R` — Token spend + ROI
- `dashboard-shiny.R` — Real-time web UI (optional)

### Data Pipeline
- Add `token_count` to spawner logs
- Export to `rl-tokens.csv`
- Feed into cost analysis

---

## Phase 12A Pre-Launch: Security Requirements

**Before Phase 12A launch (Monday 2026-03-31):**

- [x] Agent specialization complete (11 → 20 agents designed)
- [x] Q-learning routing ready (agent-task pairs converged)
- [ ] **Container sandboxing implemented** (security gate) ← ADD THIS
- [ ] SLA monitoring active (Phase 11B live)
- [ ] Audit logging enabled (Phase 11A live)

**Container sandboxing is a launch blocker** for Phase 12A. Cannot scale to 20 agents without execution isolation.

---

## Backlog Details

### Unsloth Fine-Tuning Integration (Phase 14-15) — 6-8 hours

**What it does:**
Integrate unsloth (2x faster, 70% less VRAM fine-tuning) for adaptive agent specialization.

**When to use:**
- Phase 12A/12B scaling reveals systematic task-type patterns that pure Q-routing can't solve
- GPU becomes available (currently CPU-only environment)
- Specific agents consistently underperform on certain tasks
- Cost efficiency plateaus and model-level optimization needed

**Implementation strategy:**
```julia
# Future: Agent fine-tuning for task-specific adaptation
# scripts/ml/agent-fine-tuner.jl
# 
# 1. Detect underperforming agent-task pairs (Q < 0.4)
# 2. Collect successful outcomes for that task type
# 3. Fine-tune agent model weights on those patterns
# 4. A/B test: standard routing vs fine-tuned routing
# 5. Commit improvements to production if +10% quality
```

**Why Phase 14-15:**
- Phase 13: Autonomous routing (agents self-negotiate)
- Phase 14: Multi-tenant scaling (separate team instances)
- Phase 15: Knowledge emergence (agents design new agents)
- Unsloth fits Phase 15 (system optimizes its own model weights)

**Prerequisite:** GPU or TPU access (not available in current environment)

**Decision:** Revisit when Phase 12A validates horizontal scaling works without fine-tuning.

---

## Decision: What Do You Want?

**Option A:** Quick wins (6-7h)
- Task Prediction
- Outcome Prediction  
- Cost Analysis
→ Better decisions + visibility

**Option B:** Full feature set (13-15h)
- All of Option A
- Interactive Dashboard
- Workflow Recommendation
→ Production-grade system

**Option C:** Deep optimization (20+ h)
- All of Option B
- Embedding Speedup
- Performance profiling
→ Ultra-high performance

What interests you most?

---

_Roadmap created: 2026-03-13 18:57 GMT_  
_Updated: 2026-03-29 23:07 GMT (added Unsloth backlog)_  
_Based on: Current system state, outcome data (36 samples), agent specialization patterns_
