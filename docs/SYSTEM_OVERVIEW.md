# System Overview — Complete Architecture

_Last updated: 2026-03-28 21:13 UTC_

---

## Tiers

Your AI team operates across **three tiers**:

### Tier 1: Core Infrastructure (Always Running)
- **OpenClaw Gateway** (port 18789) — Message routing, authentication, session management
- **Memory Systems** — Persistent memory (MEMORY.md), daily logs (memory/*.md)
- **Q-Learning Engine** — Tracks agent-task performance, optimizes routing
- **Cron Scheduler** — Automated jobs (syncs, learning, monitoring)

### Tier 2: Agent Team (On-Demand)
- **Morpheus** (Lead) — Orchestration, decision-making, strategy
- **11 Specialist Agents** — Codex, Cipher, Scout, Chronicle, Sentinel, Lens, Veritas, QA, Prism, Echo, Navigator-Ops
- **Routing:** Via Q-learning (task type → best agent)
- **Learning:** From outcomes (success rate, quality feedback)

### Tier 3: Learning Systems (Automatic, Daily)
- **P0: Feedback Validation** — User feedback → Q-learning updates
- **P1: Collaboration Detection** — Agent pairs → performance patterns
- **P2: Knowledge Extraction** — Task outcomes → reusable patterns
- **Automation:** Cron jobs run daily (03:00 UTC) + 6-hourly (P0)

---

## Core Systems

### 1. Task Routing (Agent Selection)

**How it works:**
```
New Task Arrives
    ↓
Extract: task_type, complexity, context
    ↓
Check: Knowledge Base for similar tasks
    ↓
Lookup: Q-matrix for best agent(s)
    ↓
Check: Collaboration graph for high-performing pairs
    ↓
Decision: Single agent OR agent pair
    ↓
Spawn: Via spawner-matrix.jl
    ↓
Execute: Agent(s) complete task
    ↓
Capture: Outcome (success, quality, cost, time)
```

**Data sources:**
- `data/rl/rl-agent-selection.json` — Q-scores for all agent-task pairs
- `data/collaboration-graph.json` — High-performing agent pairs
- `data/knowledge-base/extracted-patterns.json` — Task-to-solution mapping

### 2. Learning Pipeline (P0+P1+P2)

```
Task Execution
    ├─→ [P0] User Feedback → Q-Learning Updates
    │        (every 6 hours, cron)
    │
    ├─→ [P1] Collaboration Patterns
    │        (daily, cron)
    │
    └─→ [P2] Knowledge Extraction
             (daily, cron)
             ↓
         Improved Q-scores → Better routing
         Identified pairs → Smarter delegation
         Extracted patterns → Warm-start learning
```

**Files:**
- `scripts/ml/unified-learning-system.jl` — Orchestrator
- `scripts/ml/feedback-validator.jl` — P0 implementation
- `scripts/ml/collaboration-graph.jl` — P1 implementation
- `scripts/ml/knowledge-extractor.jl` — P2 implementation

### 3. Memory System

**Three-layer memory:**

1. **Persistent Long-Term** — `MEMORY.md`
   - Curated insights, decisions, lessons
   - Only loaded in main session (privacy)
   - Updated weekly during memory maintenance

2. **Daily Working Memory** — `memory/YYYY-MM-DD.md`
   - Raw session logs, observations, learnings
   - Accessible any time
   - Consolidated into MEMORY.md weekly

3. **Knowledge Bases** — `data/`
   - Q-learning matrices (agent-task performance)
   - Audit logs (immutable task history)
   - Collaboration graphs (agent partnership data)
   - Extracted patterns (solution database)

### 4. Audit Trail & Compliance

**Immutable logging:**
- `data/audit-logs/YYYY-MM-DD.jsonl` — Every task spawn and outcome
- `data/feedback-logs/feedback-validation.jsonl` — User validation signals
- Phase 11A (live): All events logged with timestamps, no deletions

**SLA Monitoring:**
- `scripts/ml/sla-calculator.jl` — Tracks latency, success rate, cost, quality
- Phase 11B (live): Daily calculation, thresholds enforced
- Compliance reports: Weekly (Phase 11C)

---

## Operational Commands

### Learning System Health
```bash
# Check learning system status
julia scripts/ml/unified-learning-system.jl --report

# Run full learning cycle (P0+P1+P2)
julia scripts/ml/unified-learning-system.jl --full-cycle

# Just feedback processing
julia scripts/ml/unified-learning-system.jl --feedback-only

# Just collaboration analysis
julia scripts/ml/unified-learning-system.jl --collaboration

# Just knowledge extraction
julia scripts/ml/unified-learning-system.jl --knowledge
```

### Recording Feedback
```bash
# After a task completes, record user feedback
julia scripts/ml/feedback-validator.jl \
  --task-id "task-uuid-here" \
  --approved true \
  --quality 4 \
  --notes "Optional feedback notes"
```

### Analyzing Patterns
```bash
# Query knowledge base for a task type
julia scripts/ml/knowledge-extractor.jl --query-pattern "code_optimization"

# Find similar tasks
julia scripts/ml/knowledge-extractor.jl --find-similar "optimization performance"

# Suggest agent pairs for a task type
julia scripts/ml/collaboration-graph.jl --suggest-pairs "code"
```

### Gateway Health
```bash
# Check OpenClaw status
openclaw status

# View recent cron jobs
openclaw cron list

# Check learning crons specifically
openclaw cron list | grep -E "Learning|Feedback|Collaboration"
```

---

## Key Files & Directories

### Workspace Root
```
/home/art/.openclaw/workspace/
├── AGENTS.md                 ← How the workspace works
├── SOUL.md                   ← Morpheus identity & philosophy
├── USER.md                   ← Art's profile & preferences
├── IDENTITY.md              ← Morpheus detailed identity
├── MEMORY.md                ← Long-term memory (main session only)
├── TOOLS.md                 ← Development environment status
├── HEARTBEAT.md             ← Periodic check routines
│
├── docs/
│   ├── LEARNING-SYSTEM.md          ← P0+P1+P2 complete reference
│   ├── SYSTEM_OVERVIEW.md          ← This file
│   ├── INFRASTRUCTURE.md           ← Phase 11 architecture
│   ├── CONFIGURATION.md            ← All config files documented
│   └── [research, guides, reference]
│
├── scripts/ml/
│   ├── unified-learning-system.jl  ← P0+P1+P2 orchestrator
│   ├── feedback-validator.jl       ← P0: Feedback processing
│   ├── collaboration-graph.jl      ← P1: Agent pairs
│   ├── knowledge-extractor.jl      ← P2: Pattern extraction
│   ├── spawner-matrix.jl           ← Core task routing
│   └── [other ML scripts]
│
├── data/
│   ├── audit-logs/                 ← Immutable task history
│   ├── feedback-logs/              ← User validation signals
│   ├── rl/                         ← Q-learning matrices
│   ├── collaboration-graph.json    ← Agent pair performance
│   └── knowledge-base/             ← Extracted patterns
│
├── memory/
│   ├── YYYY-MM-DD.md              ← Daily logs (rotating)
│   └── heartbeat-state.json       ← Last check timestamps
│
└── .git/                           ← Version control
```

---

## Performance Baselines

### Current (2026-03-28)

| Metric | Value | Status |
|--------|-------|--------|
| Agent Selection Accuracy | 85%+ | ✅ Via Q-learning |
| Cost Savings | 60-65% | ✅ Phase 5-7 live |
| Quality Improvement | +8-15% | ✅ Phase 9A live |
| Memory Recall | 98% | ✅ Hybrid search |
| Average Task Latency | ~1.2s | ✅ Sub-2s target |
| Collaboration Pairs Identified | 15+ | ✅ P1 active |
| Patterns Extracted | 8+ | ✅ P2 active |

### Expected Post-Learning (Full P0+P1+P2 cycle)

| Metric | Improvement | Timeline |
|--------|-------------|----------|
| Q-Learning Convergence | +10-15% faster | Immediate (P0) |
| Overall Quality | +5-8% | Daily learning (P1) |
| Similar Task Speed | +20-30% | Weekly learning (P2) |
| Agent Utilization | 15-20% better | Monthly baseline |

---

## Cron Jobs (Active)

All times in Europe/London timezone:

| Job | Schedule | Purpose | Status |
|-----|----------|---------|--------|
| P0: Feedback Processing | Every 6h | Process feedback → Q-learning | ✅ Live |
| Unified Learning Cycle | Daily 03:00 UTC | P0+P1+P2 full cycle | ✅ Live |
| SLA Monitoring | Daily 02:30 UTC | Calculate SLA metrics | ✅ Live (Phase 11B) |
| Compliance Reports | Weekly Mon 10:00 | Generate audit reports | ✅ Live (Phase 11C) |
| Memory Consolidation | Weekly Sun 16:00 | Merge daily → MEMORY.md | ✅ Live |

**View all crons:**
```bash
openclaw cron list
```

---

## Integration Points

### With Spawner (Task Routing)
- `feedback-hook.jl` — Captures outcomes post-execution
- Q-matrix lookup — Selects best agent(s)
- Collaboration graph — Routes complex tasks to pairs
- Knowledge base — Warm-start similar tasks

### With User (Feedback)
- `feedback-validator.jl` — Records approval + quality rating
- Updates audit logs with validation
- Feeds reward signals into Q-learning

### With Memory System
- Daily logs → Long-term consolidation
- Audit logs → Historical record
- Q-scores → Agent performance trends

### With Gateway
- Cron jobs spawn isolated agents for learning
- Results announced to main session
- Status updates available via `openclaw status`

---

## Next Phases

### Phase 13: Autonomous Task Routing (Q2 2026)
- Agents self-negotiate assignments
- Central spawner becomes advisory (not mandatory)
- Real-time Q-learning negotiation

### Phase 14: Multi-Tenant Scaling (Q3 2026)
- Spawn temporary team instances for projects
- Isolated learning + global insight merge
- 10-50x workload capacity

### Phase 15: Knowledge Emergence (Q4 2026)
- System generates new agent archetypes
- Agents design agents (meta-learning)
- Compound learning over time

---

## Monitoring & Maintenance

### Daily
- Check: `openclaw status` (gateway health)
- Check: Learning system report (`unified-learning-system.jl --report`)
- Action if needed: Run full cycle manually

### Weekly
- Review: Memory maintenance (consolidate daily logs)
- Review: Q-scores (agent performance trends)
- Review: Collaboration graph (new partnerships)

### Monthly
- Archive: Old audit logs (compress/backup)
- Review: Knowledge base quality (patterns still valid?)
- Cleanup: Stale cron jobs, unused configs

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│            NEW TASK ARRIVES                              │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────▼───────────┐
         │ Task Routing Engine   │
         │ (spawner-matrix.jl)   │
         └───────────┬───────────┘
                     │
       ┌─────────────┼─────────────┐
       │             │             │
    ┌──▼──┐      ┌───▼────┐   ┌──▼──┐
    │Q-   │      │Collab. │   │Know-│
    │Scores│      │Graph   │   │ledge│
    └──┬──┘      └───┬────┘   └──┬──┘
       │             │           │
       └─────────────┼───────────┘
                     │
         ┌───────────▼───────────┐
         │ Agent Selection       │
         │ (single or pair)      │
         └───────────┬───────────┘
                     │
       ┌─────────────▼─────────────┐
       │ AGENT EXECUTION           │
       │ (Codex, Scout, Cipher...) │
       └─────────────┬─────────────┘
                     │
         ┌───────────▼───────────┐
         │ Outcome Capture       │
         │ (success, quality,    │
         │  cost, time)          │
         └───────────┬───────────┘
                     │
       ┌─────────────┴──────────────────┐
       │ LEARNING PIPELINE (Daily)      │
       │                                │
       ├→ P0: Feedback → Q-Learning     │
       ├→ P1: Collaboration Patterns    │
       └→ P2: Knowledge Extraction      │
                     │
       ┌─────────────▼──────────────────┐
       │ IMPROVED ROUTING (Next Cycle)  │
       │ Better Q-scores                │
       │ Identified partnerships        │
       │ Extracted patterns             │
       └────────────────────────────────┘
```

---

## References

- **Full Documentation:** See `docs/` directory
- **Learning System:** `docs/LEARNING-SYSTEM.md`
- **Infrastructure:** `docs/INFRASTRUCTURE.md`
- **Configuration:** `docs/CONFIGURATION.md`
- **Git History:** `git log --oneline` (recent commits)

---

_System ready for production. Feed it tasks, let it learn._
