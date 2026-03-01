# Q-Learning Integration Strategy for OpenClaw

**Date:** 2026-02-28  
**Status:** Design (ready for implementation)  
**Purpose:** Optimize Morpheus decision-making via reinforcement learning

---

## Current State

**memory-optimizer** uses Q-Learning locally:
- Algorithm: Q-Learning + TD(λ), α=0.01, γ=0.99, λ=0.9
- Learns: Which memories are valuable
- Updates: Q-scores per memory based on usage
- Storage: `.memory-optimizer-state.json`

**Gap:** RL is only applied to memory prioritization. Not optimizing agent selection, task routing, or workflow decisions.

---

## Extended RL Integration

### 1. Agent Selection Optimization

**Problem:** Which agent to spawn for which task?

**Q-Learning approach:**
- **State:** Task type (research, code, security, data, testing, etc.)
- **Action:** Agent choice (Scout, Codex, Cipher, QA, etc.)
- **Reward:** Task success (0 = failed, 1 = passed verification, 0.5 = partial)
- **Learning:** Over time, agent Q-scores improve for each task type

**Example Q-table:**
```
State: "Research on API security"
Actions:
  Scout: Q=0.92 (good at research, high success)
  Codex: Q=0.15 (bad at research)
  Cipher: Q=0.45 (medium, can contribute)
  
→ Select Scout (highest Q)
```

**Implementation:**
- Track: Agent → Task type → Success/Failure
- Update: Q-value per (agent, task) pair
- Decision: Always pick agent with highest Q-score for that task
- Exploration: 10% random choice (to explore alternatives)

**File:** `rl-agent-selection.json` (persist Q-table)

---

### 2. Task Prioritization

**Problem:** Which task should Morpheus focus on if multiple are pending?

**Q-Learning approach:**
- **State:** Task characteristics (complexity, urgency, dependencies)
- **Action:** Do task, defer task, or escalate to user
- **Reward:** Completion time + user satisfaction + dependency resolution
- **Learning:** Optimize task ordering

**Example Q-table:**
```
State: "Research task (low complexity, not urgent)"
Actions:
  Do now: Q=0.6 (reasonable, gets it done)
  Defer 1h: Q=0.75 (batch with other research)
  Escalate: Q=0.2 (unnecessary)
  
→ Select Defer 1h (batch efficiency)
```

**Implementation:**
- Track: Task type → Action → Outcome (time, quality, user feedback)
- Update: Q-values for task handling
- Decision: Pick action with highest Q-score
- Reward: (1 / time_minutes) × quality_score

**File:** `rl-task-prioritization.json`

---

### 3. Research Refresh Optimization

**Problem:** Which research topics to refresh first (limited time)?

**Q-Learning approach:**
- **State:** Research topic (technology, business, security, etc.)
- **Action:** Refresh now, refresh in 7 days, archive
- **Reward:** Query frequency + relevance + staleness
- **Learning:** Prioritize refreshing high-value research

**Example Q-table:**
```
State: "api-security-2026.md (30 days old)"
Actions:
  Refresh now: Q=0.85 (queried 12 times this month!)
  Refresh in 7d: Q=0.5 (can wait slightly)
  Archive: Q=0.1 (still useful)
  
→ Select Refresh now (high usage, stale)
```

**Implementation:**
- Track: Research topic → Query count → Refresh action → User satisfaction
- Update: Q-values per research entry
- Decision: When refresh cycle due, prioritize by Q-score
- Reward: (query_count / month) × relevance_score

**File:** `rl-research-refresh.json`

---

### 4. Workflow Optimization

**Problem:** Which PROCESS_FLOWS work best for your actual patterns?

**Q-Learning approach:**
- **State:** Incoming task description
- **Action:** Use PROCESS_FLOW #1, #2, #3, ... #11
- **Reward:** Task completion quality + efficiency
- **Learning:** Route tasks to best flows over time

**Example Q-table:**
```
State: "Build new feature with testing"
Actions:
  Flow 2 (Code Dev): Q=0.88 (proper QA loop, 92% success)
  Flow 11 (Simple): Q=0.45 (skips testing, 60% quality)
  
→ Select Flow 2 (higher success)
```

**Implementation:**
- Track: Task → Selected flow → Quality score → Time
- Update: Q-values per (task_pattern, flow) pair
- Decision: For new task, recommend highest Q-score flow
- Reward: (quality_score × speed_bonus) - time_penalty

**File:** `rl-workflow-selection.json`

---

### 5. Success Metrics Learning

**Problem:** What actually indicates "good work"?

**Q-Learning approach:**
- **State:** Task type (research, code, security, etc.)
- **Action:** Accept as done, ask for refinement, escalate
- **Reward:** User satisfaction + agent verification + quality metrics
- **Learning:** Learn thresholds for what's "good enough"

**Example Q-table:**
```
State: "Research completed, score 0.75"
Actions:
  Accept: Q=0.6 (risky, might disappoint user)
  Refine: Q=0.85 (better quality, better received)
  Escalate: Q=0.3 (unnecessary)
  
→ Select Refine (higher satisfaction)
```

**Implementation:**
- Track: Task output → User feedback → Adjustment needed
- Update: Q-values for acceptance thresholds
- Decision: If score < Q-threshold, request refinement
- Reward: User feedback + verification score

**File:** `rl-success-metrics.json`

---

## Implementation Architecture

### Files & Structure

```
OpenClaw System
├── Core Operations
│   ├── PROCESS_FLOWS.md (currently: manual selection)
│   ├── AGENTS_CONFIG.md (currently: manual specification)
│   └── MORPHEUS_FAILURES.md (log failures for learning)
│
├── Q-Learning Tables (NEW)
│   ├── rl-agent-selection.json (which agent per task)
│   ├── rl-task-prioritization.json (what to do when)
│   ├── rl-research-refresh.json (which research to refresh)
│   ├── rl-workflow-selection.json (which flow per task)
│   └── rl-success-metrics.json (what's "good enough")
│
├── Learning Loop (NEW)
│   ├── Observe: Task, action, outcome
│   ├── Reward: Calculate success/failure
│   ├── Update: Q-values in corresponding table
│   └── Decide: Next action based on Q-scores
│
└── Memory System (EXISTING)
    ├── memory-optimizer (learning memory value)
    └── .memory-optimizer-state.json (Q-scores)
```

### Decision Flow (With RL)

**Old flow (manual):**
```
Task arrives → Morpheus decides → Execute → Done
```

**New flow (RL-optimized):**
```
Task arrives
    ↓
Query rl-agent-selection → Get best agent Q-score
Query rl-task-prioritization → Get best action Q-score
Query rl-workflow-selection → Get best flow Q-score
    ↓
Execute (with chosen agent, flow, priority)
    ↓
Observe: Success/Failure + Quality Score
    ↓
Calculate reward
    ↓
Update Q-tables (all 5 systems learn simultaneously)
    ↓
Done (system is smarter for next time)
```

---

## Implementation Steps

### Phase 1: Infrastructure (Week 1)
1. Create 5 Q-table JSON files (empty, ready for learning)
2. Write Q-Learning update functions
3. Wire into MORPHEUS_FAILURES.md reading
4. Create cron job to persist Q-tables daily

### Phase 2: Agent Selection (Week 2)
1. Track which agent was chosen for each task
2. Track success/failure per agent
3. Calculate Q-scores for (agent, task_type) pairs
4. Recommend best agent before spawning

### Phase 3: Task Prioritization (Week 3)
1. Track task type, action chosen, time to complete
2. Track user satisfaction (from context)
3. Calculate Q-scores for task handling
4. Recommend action (do now, defer, escalate)

### Phase 4: Research Refresh (Week 4)
1. Track query count per research file
2. Track staleness (days since refresh)
3. Calculate Q-scores for refresh timing
4. Auto-prioritize research refresh queue

### Phase 5: Workflow & Success Metrics (Week 5)
1. Track which flow was used, quality outcome
2. Calculate Q-scores per flow
3. Set quality thresholds based on learning
4. Auto-recommend flow and acceptance criteria

---

## Concrete Example: Agent Selection

### Scenario: "Research OAuth 2.0 best practices"

**Step 1: Query rl-agent-selection.json**
```json
{
  "task_type": "research",
  "agents": {
    "Scout": {"q_score": 0.92, "success_rate": 94},
    "Codex": {"q_score": 0.15, "success_rate": 20},
    "Chronicle": {"q_score": 0.70, "success_rate": 85},
    "Veritas": {"q_score": 0.45, "success_rate": 50}
  }
}
```

**Step 2: Morpheus decision**
```
Best Q-score: Scout (0.92)
→ Spawn Scout to research OAuth 2.0
```

**Step 3: Scout completes, verification happens**
```
Veritas: "Research is accurate, well-sourced" → Success ✓
Quality score: 0.98
```

**Step 4: Update Q-table**
```
Old Scout Q-score for "research": 0.92
New Q-score: 0.92 + α × (reward - 0.92)
           = 0.92 + 0.01 × (0.98 - 0.92)
           = 0.920 + 0.00006
           = 0.920006 (reinforced: Scout is even better)
```

**Step 5: Next research task**
```
Morpheus checks rl-agent-selection again
Scout Q-score: 0.920006 (slightly higher)
→ Even more confident to use Scout
```

---

## Benefits of This Integration

### For Morpheus
- Learns which agents are best (doesn't guess)
- Learns task patterns (optimizes workflow)
- Learns what's "good enough" (sets realistic standards)
- Improves over time (every task makes it smarter)

### For Art
- Better task outcomes (AI gets better over time)
- Faster decisions (RL recommends best path)
- Fewer failures (learns from mistakes automatically)
- Personalized workflows (learns YOUR patterns)

### For System Efficiency
- Less token waste (faster decisions, better routing)
- Better resource allocation (prioritizes high-value work)
- Continuous optimization (no manual tuning needed)
- Adaptive behavior (changes as your needs change)

---

## Data Requirements

### What Gets Logged

For each task execution:
1. **Input:** Task type, description, time
2. **Decision:** Agent chosen, flow chosen, priority
3. **Execution:** Time taken, resources used
4. **Output:** Success/failure, quality score
5. **Feedback:** User satisfaction (explicit or inferred)

### Example Log Entry
```json
{
  "timestamp": "2026-02-28T19:35:00Z",
  "task": {
    "type": "research",
    "description": "API security 2026 best practices"
  },
  "decisions": {
    "agent": "Scout",
    "flow": "Section 1 - Research",
    "priority": "normal"
  },
  "outcome": {
    "success": true,
    "quality_score": 0.98,
    "time_minutes": 8.5,
    "verification": "Veritas approved"
  },
  "reward": 0.98
}
```

---

## Starting Simple

### Minimal MVP (Start Here)

Don't implement all 5 immediately. Start with #1:

**Agent Selection Only:**
1. Create `rl-agent-selection.json`
2. Track agent choices and outcomes
3. After 20 tasks per agent type, start using Q-scores
4. Let the system learn for a week

**Then expand** to other 4 based on results.

---

## Configuration

### Q-Learning Parameters (Tunable)

```json
{
  "alpha": 0.01,      // Learning rate (how fast to update Q-scores)
  "gamma": 0.99,      // Discount factor (value of future rewards)
  "lambda": 0.9,      // Trace decay (for TD(λ))
  "epsilon": 0.1,     // Exploration rate (10% random choices)
  "update_interval": 86400  // Update Q-tables daily
}
```

**Tuning:**
- **Lower alpha:** Learn more conservatively (fewer updates)
- **Higher gamma:** Value long-term outcomes more
- **Higher epsilon:** Explore more alternatives
- **Update more often:** Adapt faster to changes

---

## Monitoring & Control

### Dashboard (Future)

```
Q-Learning System Status

Agent Selection (Research):
  Scout: Q=0.92 (94% success, 120 uses)
  Chronicle: Q=0.70 (85% success, 45 uses)
  
Task Prioritization:
  Defer 1h: Q=0.75 (high batch efficiency)
  Do now: Q=0.60 (acceptable)
  
Research Refresh:
  api-security-2026: Queried 12x → Refresh now (Q=0.85)
  
System Learning Rate: 2% improvement per week
```

### Override Capability

Morpheus can always override Q-recommended decisions:
- "Use Codex instead of Scout" → Works, learns from outcome
- "Run this flow manually" → Works, updates Q-table
- No hard constraints, just recommendations

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| RL learns bad patterns | Ensure reward signal is correct; audit Q-tables |
| Exploration wastes time | Set epsilon low (0.05-0.1); explore sparingly |
| Q-tables stale | Update tables daily, reset outlier Q-scores monthly |
| Over-optimizes for speed | Include quality in reward function; don't rush |

---

## Timeline

**If implementing:**
- **Week 1:** Agent selection (core, highest impact)
- **Week 2:** Task prioritization
- **Week 3:** Research refresh optimization
- **Week 4:** Workflow selection
- **Week 5:** Success metrics learning

**Expected improvement:** 10-20% better decisions within a month

---

## Next Steps

**To activate this:**
1. Confirm you want agent selection RL first (Phase 2)
2. Decide on reward signal (success/failure? quality score?)
3. Create `rl-agent-selection.json` template
4. Wire logging into task execution
5. Let it learn for 50+ tasks per agent type
6. Monitor Q-scores, adjust alpha/gamma if needed

**Decision:** Ready to implement, or want to review design first?
