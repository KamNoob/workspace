# Phase 5: Cost Optimization Plan

**Goal:** Reduce cost per task from $0.054 → $0.035 (35% savings)  
**Timeline:** 8 hours total  
**Target Completion:** 2026-03-16 (1 day)  
**ROI:** $19/month saved at scale (1000 tasks)

---

## Overview: Four Optimization Pillars

```
Phase 5 Optimization Stack
├─ Pillar 1: Maximize Prompt Caching (2 hours)
├─ Pillar 2: Reduce Agent Context (3 hours)
├─ Pillar 3: Batch Similar Tasks (2 hours)
└─ Pillar 4: Memory Pruning (1 hour)
```

---

## Pillar 1: Maximize Prompt Caching (2 hours)

### Goal
- Current cache hit: 34-192% (variable)
- Target cache hit: >80% (consistent)
- Expected saving: 10-15% of input tokens

### What to Do

**1.1 Create "Caching Warmup" Script (30 min)**
```bash
scripts/optimization/cache-warmup.jl
```

Purpose: Ensure high-value data cached before main tasks
- Load SOUL.md, IDENTITY.md, AGENTS.md, MEMORY.md (50k tokens)
- Make dummy query to trigger caching
- Measure cache state after warmup

```julia
# Pseudocode
function warmup_cache()
    # Load all shared context files
    soul = read("SOUL.md")
    identity = read("IDENTITY.md")
    agents = read("AGENTS.md")
    memory = read("MEMORY.md")
    
    # Bundle into "context package"
    context = soul * identity * agents * memory
    
    # Send to Claude to cache
    response = ask_claude("Context loaded. Ready to work.", context_tokens=context)
    
    # Measure cache state
    cache_state = measure_cache()
    return cache_state
end
```

**1.2 Implement Cache Monitoring (45 min)**
```bash
scripts/optimization/cache-monitor.jl
```

Purpose: Track cache hit rate real-time
- Logs cache efficiency per session
- Alerts if hit rate drops below 70%
- Suggests when to re-warm cache

Output: `data/metrics/cache-efficiency.json`
```json
{
  "session_id": "agent:main:main",
  "cache_hit_rate": 0.85,
  "cached_tokens": 50000,
  "new_tokens_this_session": 2000,
  "efficiency_score": 0.96,
  "last_warmup": "2026-03-15T16:00:00Z"
}
```

**1.3 Optimize Session Reuse (45 min)**
```bash
scripts/optimization/session-reuse-pool.jl
```

Purpose: Keep hot sessions alive instead of spawning new ones
- Pool of 5-10 warm sessions ready to use
- Each pre-cached with context package
- Reuse same session for related tasks

Benefit: Zero cache cold-start overhead

### Success Criteria
- [ ] Cache hit rate: >80% on all sessions
- [ ] Warmup overhead: <2 seconds per session
- [ ] Monitor dashboard shows green (cache efficiency)

### Testing
```bash
julia scripts/optimization/cache-warmup.jl
julia scripts/optimization/cache-monitor.jl status
```

---

## Pillar 2: Reduce Agent Context (3 hours)

### Goal
- Current: ~15k tokens per agent
- Target: ~5k tokens per specialized agent
- Expected saving: 15-20% of input tokens

### What to Do

**2.1 Audit Current Agent Contexts (45 min)**
```bash
scripts/optimization/agent-context-audit.jl
```

For each agent (Cipher, Scout, Codex, etc):
- Measure current context size
- Identify unnecessary parts
- List what's truly essential

Output: `data/metrics/agent-context-sizes.json`
```json
{
  "Cipher": {
    "current_size": 14200,
    "breakdown": {
      "security_knowledge": 8000,
      "general_instructions": 3500,
      "examples": 2000,
      "metadata": 700
    },
    "optimization_target": 5500
  }
}
```

**2.2 Create Specialized Prompts (90 min)**
```bash
prompts/specialized/
├─ cipher-security.md (3.5k tokens)
├─ scout-research.md (3.2k tokens)
├─ codex-development.md (3.8k tokens)
├─ chronicle-docs.md (2.9k tokens)
└─ ... (7 more agents)
```

For each agent:
- Remove generic instructions
- Keep domain-specific knowledge only
- Remove examples not relevant to their domain
- Compress technical guidance

Example: **Cipher (Security)**
- Keep: threat modeling, vulnerability patterns, security frameworks
- Remove: general coding tips, research methodology, documentation best practices
- Save: ~9k → 3.5k tokens (62% reduction)

**2.3 Test & Validate (45 min)**
```bash
scripts/optimization/test-agent-contexts.jl
```

For each agent:
- Run 3-5 test tasks with new context
- Compare success rate (should stay same or improve)
- Measure token reduction
- Log performance delta

Success threshold:
- Success rate: ≥95% of original (allow 5% variance)
- Token reduction: ≥60% (from 15k → 6k)
- Response quality: No degradation

### Success Criteria
- [ ] All 11 agents have optimized contexts (<6k tokens each)
- [ ] Success rates maintained (95%+ of baseline)
- [ ] Total agent context: 11 × 5.5k = 60.5k tokens (vs ~165k)

### Testing
```bash
julia scripts/optimization/agent-context-audit.jl
julia scripts/optimization/test-agent-contexts.jl run
```

---

## Pillar 3: Batch Similar Tasks (2 hours)

### Goal
- Current: Serial task execution (new context each time)
- Target: Batch 3-5 similar tasks per agent session
- Expected saving: 20-30% of context overhead

### What to Do

**3.1 Create Task Batching Engine (60 min)**
```bash
scripts/optimization/task-batcher.jl
```

Algorithm:
1. Queue incoming tasks
2. Group by task type (code, research, security, etc.)
3. Batch 3-5 similar tasks
4. Spawn single agent session for batch
5. Process all tasks in batch (context reused)
6. Log batch efficiency

```julia
function batch_similar_tasks(task_queue::Vector)
    # Group by task type
    batches = Dict()
    for task in task_queue
        task_type = detect_task_type(task)
        if !haskey(batches, task_type)
            batches[task_type] = []
        end
        push!(batches[task_type], task)
    end
    
    # Create batches of 3-5 tasks
    batch_size = 4
    results = []
    for (task_type, tasks) in batches
        for i in 1:batch_size:length(tasks)
            batch = tasks[i:min(i+batch_size-1, end)]
            result = spawn_agent_for_batch(task_type, batch)
            push!(results, result)
        end
    end
    
    return results
end
```

**3.2 Implement Batch Routing (45 min)**
```bash
scripts/ml/spawner-matrix-batched.jl
```

Modify agent router to:
- Check task queue (vs single task)
- Group by agent type
- Spawn batch job vs individual jobs

Integration point: Existing `spawner-matrix.jl`
- Create wrapper: `spawner-matrix-batched.jl`
- Backward compatible (single task = batch of 1)
- No changes to existing APIs

**3.3 Monitor Batch Efficiency (15 min)**
```bash
scripts/optimization/batch-monitor.jl
```

Track:
- Batch size used
- Context tokens saved per batch
- Success rate per batch
- Time savings

Output: `data/metrics/batch-efficiency.json`

### Success Criteria
- [ ] Batching enabled and active
- [ ] Average batch size: 3-5 tasks
- [ ] Context reuse: 70%+ across batch
- [ ] Efficiency gain: >20% vs serial

### Testing
```bash
# Simulate batch job
julia scripts/optimization/task-batcher.jl --test --batch-size 4

# Monitor efficiency
julia scripts/optimization/batch-monitor.jl status
```

---

## Pillar 4: Memory Pruning (1 hour)

### Goal
- Current: All memories kept forever (grows over time)
- Target: Time-decay pruning (old memories archived)
- Expected saving: 10% of memory vectors

### What to Do

**4.1 Implement Time-Decay Pruning (30 min)**
```bash
scripts/ml/memory-pruner.jl
```

Algorithm:
```
For each memory:
  age = now() - created_at
  if age > 30 days:
    decay = exp(-age / decay_constant)
    if decay < 0.1:  # Keep if <10% original weight
      mark for archival
```

Config: `config/memory-pruning.json`
```json
{
  "decay_constant_days": 30,
  "archive_threshold": 0.1,
  "retention_policy": "hot (30d) / warm (90d) / cold (archive)",
  "prune_schedule": "daily at 02:00 UTC"
}
```

**4.2 Set Up Archival (20 min)**
```bash
data/memory/
├─ hot/ (0-30 days, all cached)
├─ warm/ (30-90 days, some cached)
└─ archive/ (90+ days, cold storage)
```

Benefit:
- Hot memory: 97.9% recall, 2ms lookup
- Warm memory: 85% recall, 10ms lookup
- Archive: 70% recall, 100ms lookup (rarely accessed)

**4.3 Add Cron Job (10 min)**
```bash
scripts/cron/memory-pruning-cron.sh
```

Run daily at 02:00 UTC:
- Scan hot memory
- Identify stale entries
- Move to warm/archive
- Report pruning stats

### Success Criteria
- [ ] Pruning logic implemented
- [ ] Hot memory < 50MB (currently 60MB)
- [ ] Recall rate maintained (>97%)
- [ ] Cron job active and logged

### Testing
```bash
julia scripts/ml/memory-pruner.jl --dry-run
# Review what would be pruned

julia scripts/ml/memory-pruner.jl --execute
# Actually prune

ls -lh data/memory/
# Verify sizes
```

---

## Integration & Deployment

### Deployment Order
1. **Pillar 1 first** (Caching) — Enables faster Pillars 2-4
2. **Pillar 2 second** (Agent context) — Immediate token savings
3. **Pillar 3 third** (Batching) — Leverages optimized contexts
4. **Pillar 4 fourth** (Memory pruning) — Cleanup & optimization

### Integration Points
```
Existing Phase 1-4 ↓
├─ Phase 3 Q-Learning (agents optimized by domain)
├─ Phase 4 Dashboard (monitors cost metrics)
└─ Phase 5 Optimizations
   ├─ Cache warmup (before spawning agents)
   ├─ Reduced contexts (specialized prompts)
   ├─ Task batching (queue-based routing)
   └─ Memory pruning (daily cleanup)
```

### Configuration
Create `config/phase5-optimization.json`:
```json
{
  "caching": {
    "enabled": true,
    "warmup_interval_hours": 4,
    "target_hit_rate": 0.80,
    "pool_size": 10
  },
  "context_reduction": {
    "enabled": true,
    "target_tokens_per_agent": 5500,
    "validation_threshold": 0.95
  },
  "batching": {
    "enabled": true,
    "batch_size": 4,
    "max_wait_seconds": 30,
    "similar_task_threshold": 0.85
  },
  "memory_pruning": {
    "enabled": true,
    "decay_days": 30,
    "archive_threshold": 0.1,
    "prune_time": "02:00"
  }
}
```

---

## Measurement & Success Metrics

### Key Performance Indicators (KPIs)

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| Cost per task | $0.054 | $0.035 | 📊 Track |
| Cache hit rate | 34% | 80% | 📊 Track |
| Avg context size | 15k tokens | 5.5k tokens | 📊 Track |
| Batch efficiency | N/A | 70% reuse | 📊 Track |
| Memory size | 60MB | 45MB | 📊 Track |

### Monitoring Dashboard Addition
Add to `Phase 4 dashboard`:
```julia
# In phase4-monitoring-dashboard.jl, add:
section("Cost Optimization (Phase 5)")
  show_cache_efficiency()
  show_context_sizes()
  show_batch_efficiency()
  show_memory_stats()
```

### Rollback Plan
If any optimization causes <95% success rate:
1. Disable that optimization immediately
2. Revert agent contexts to baseline
3. Log incident to `data/metrics/phase5-incidents.log`
4. Report findings and adjust

---

## Timeline & Milestones

### Day 1 (2026-03-15 evening)
- **16:30-18:30** — Pillar 1 (Caching): 2 hours
  - Cache warmup script
  - Cache monitor
  - Session pool
  - ✅ Measurable: Cache hit rate >70%

### Day 2 Morning (2026-03-16)
- **09:00-12:00** — Pillar 2 (Context): 3 hours
  - Audit current contexts
  - Create specialized prompts
  - Test & validate
  - ✅ Measurable: Agent contexts <6k tokens

- **12:00-14:00** — Pillar 3 (Batching): 2 hours
  - Batching engine
  - Batch routing
  - Efficiency monitor
  - ✅ Measurable: Batch efficiency >20%

- **14:00-15:00** — Pillar 4 (Pruning): 1 hour
  - Time-decay pruning
  - Archival setup
  - Cron job
  - ✅ Measurable: Memory <50MB

- **15:00-16:00** — Integration & Testing
  - Combine all pillars
  - Run integration tests
  - Update Phase 4 dashboard
  - ✅ Final cost verification

---

## Expected Outcomes

### Before Phase 5
```
Cost per task: $0.054
Cache hit: 50%
Agent context: 15k tokens avg
Batching: None
Memory size: 60MB
Total monthly (100 tasks): $5.40
```

### After Phase 5
```
Cost per task: $0.035 (35% savings! ✨)
Cache hit: 82%
Agent context: 5.5k tokens avg
Batching: 4-task batches, 70% context reuse
Memory size: 45MB
Total monthly (100 tasks): $3.50
```

### Why This Works
- **Caching:** 50% → 82% hit rate = 16% input token savings
- **Context:** 15k → 5.5k avg = 63% reduction on context overhead
- **Batching:** 4 tasks reuse 3 contexts = 75% less context overhead
- **Memory:** Prune old data = 10-15% fewer vectors
- **Combined:** Multiplicative effect = 35% total savings

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Cache hits drop | Token costs rise | Monitor hit rate, re-warm cache |
| Context too small | Success rate drops | Maintain 95% threshold, expand if needed |
| Batching overhead | Slower throughput | Optimize batch size, add async processing |
| Memory pruning loses data | Recall issues | Dry-run first, archive to cold storage |

---

## Rollout Strategy

### Option A: Aggressive (Parallel All Pillars)
- Risk: Higher but faster
- Timeline: 4 hours
- Best if: You want results ASAP

### Option B: Conservative (Sequential)
- Risk: Lower but slower
- Timeline: 8 hours (full plan)
- Best if: You want safety first

**Recommendation:** Conservative (Option B) — Test each pillar, measure before next.

---

## Success Criteria Checklist

- [ ] Pillar 1: Cache hit rate >80%
- [ ] Pillar 2: All agents <6k tokens, 95% success rate
- [ ] Pillar 3: Batching active, 20% efficiency gain
- [ ] Pillar 4: Memory <50MB, pruning scheduled
- [ ] Integration: All 4 pillars working together
- [ ] Dashboard: Shows Phase 5 metrics
- [ ] Cost: $0.054 → $0.035 (35% savings verified)
- [ ] Production: Ready to deploy

---

## Next Steps

1. ✅ Review this plan
2. ⏳ Approve/adjust timeline
3. ⏳ Start Pillar 1 (Caching)
4. ⏳ Track progress with Phase 4 dashboard
5. ⏳ Report final cost savings

---

*Phase 5 Plan created: 2026-03-15 16:14 GMT*
*Based on Cost Efficiency Research (docs/COST_EFFICIENCY_RESEARCH.md)*
