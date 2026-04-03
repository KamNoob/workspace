# Phase 12A Optimizations Guide

**Status:** ✅ Documented (Ready to implement post-launch)  
**Timeline:** Week 1-4 after Phase 12A launch  
**Target:** 30-40% efficiency gain

---

## Quick Reference

```
P0: Validation Gateway          30 min  High    Prevent failed spawns
P1: Container Pool Reuse        2 h     Medium  Save 400ms/task
P2: Sandbox Profiles            1.5 h   Medium  Right-size resources
P3: Parallel Spawning           1.5 h   High    3-4x batch throughput
P4: Lazy Config Loading         15 min  Low     5ms savings
```

---

## P0: Validation Gateway (30 min, Implement First Week)

**Problem:** No pre-spawn validation → wasted container creates on bad inputs

**Code:**
```julia
# Add to spawner-matrix.jl

function validate_spawn_request(agent::String, task::String, config::Dict)::Tuple{Bool, String}
    """Validate spawn request before creating container."""
    
    # Check agent exists in config
    if !haskey(config, "agents") || !haskey(config["agents"], agent)
        return (false, "Agent not found: $agent")
    end
    
    # Check task type valid
    valid_tasks = get(config, "valid_tasks", String[])
    if !isempty(valid_tasks) && task ∉ valid_tasks
        return (false, "Unknown task type: $task")
    end
    
    # Check system resources available
    available_memory = Sys.total_memory() / 1024^3  # GB
    required_memory = 2.5  # Buffer above 2GB limit
    if available_memory < required_memory
        return (false, "Insufficient memory: need $(required_memory)GB, have $(available_memory)GB")
    end
    
    # Check sandbox config accessible
    config_path = "configs/sandbox-default.toml"
    if !isfile(config_path)
        return (false, "Sandbox config not found: $config_path")
    end
    
    return (true, "")
end

# Usage in spawn()
if PHASE12A_SANDBOX_ENABLED
    is_valid, reason = validate_spawn_request(agent, task, ROUTING_CONFIG)
    if !is_valid
        return Dict("error" => reason, "status" => "rejected")
    end
end
```

**Impact:** 1-2ms validation, prevents resource waste  
**Effort:** Low (validation logic straightforward)  
**Blocker:** No (nice-to-have)

---

## P1: Container Pool Reuse (2 hours, Week 1-2)

**Problem:** Each task = new container (cold start ~500ms)  
**Solution:** Pre-warm pool of 3-5 idle containers

**Code:**
```julia
# New module: ContainerPool.jl

module ContainerPool
    using JSON
    
    mutable struct Container
        id::String
        created_at::DateTime
        last_used::DateTime
        status::String  # idle, running, terminated
    end
    
    const POOL_SIZE = 5
    const pool = Container[]
    const pool_lock = Threads.SpinLock()
    
    function initialize_pool()
        """Create warm pool of idle containers."""
        for i = 1:POOL_SIZE
            cid = "pool-worker-$(i)-$(string(now(), format="yyyymmddHHmmss"))"
            container = Container(cid, now(), now(), "idle")
            push!(pool, container)
        end
        return pool
    end
    
    function request_container()::Union{Container, Nothing}
        """Get next idle container from pool."""
        lock(pool_lock) do
            for (idx, c) in enumerate(pool)
                if c.status == "idle"
                    c.status = "running"
                    c.last_used = now()
                    return c
                end
            end
        end
        return nothing  # Pool exhausted
    end
    
    function return_container(container::Container)
        """Return container to pool after task."""
        lock(pool_lock) do
            for c in pool
                if c.id == container.id
                    c.status = "idle"
                    c.last_used = now()
                    break
                end
            end
        end
    end
    
    function spawn_with_pool(agent, task, config)
        container = request_container()
        
        if container !== nothing
            # Reuse existing container
            result = reuse_container(container, agent, task, config)
            return_container(container)
            return result
        else
            # Pool exhausted, spawn new
            return spawn_new_container(agent, task, config)
        end
    end
end

# Usage in spawner-sandboxed.jl
if should_use_pool(agent, task)
    result = ContainerPool.spawn_with_pool(agent, task, config)
else
    result = spawn_sandboxed(agent, task, config)
end
```

**Impact:**
- Cold start: 500ms → 50ms (10x faster)
- Per-task gain: ~400ms
- System throughput: +2x for research tasks
- Memory tradeoff: +5×512MB = 2.5GB idle

**When:** High-frequency tasks (research, code, review)  
**Skip:** One-off tasks (optimization, training)

---

## P2: Sandbox Profiles (1.5 hours, Week 2-3)

**Problem:** 2GB/2CPU fits all tasks poorly (overkill for docs, insufficient for optimization)

**Config Structure:**
```toml
# configs/sandbox-profiles.toml

[profiles.light]
description = "Documentation, review, triage"
memory_limit = "512M"
cpus = 0.5
timeout = 300
mounts = ["work", "memory"]  # Minimal mounts

[profiles.standard]
description = "Research, code, analysis"
memory_limit = "2G"
cpus = 2.0
timeout = 1800
mounts = ["work", "memory", "data", "scripts"]

[profiles.heavy]
description = "Optimization, compliance, training"
memory_limit = "4G"
cpus = 4.0
timeout = 3600
mounts = ["work", "memory", "data", "scripts", "skills"]

# Agent-to-profile mapping
[agent_profiles]
Scout = "standard"
Codex = "standard"
Cipher = "light"
Chronicle = "light"
Navigator-Ops = "heavy"
Analyst-Perf = "heavy"
Mentor = "heavy"
```

**Code:**
```julia
function get_agent_profile(agent::String, task::String)::String
    """Determine optimal profile for agent-task pair."""
    
    # Check explicit mapping first
    agent_map = get(PROFILES_CONFIG, "agent_profiles", Dict())
    if haskey(agent_map, agent)
        return agent_map[agent]
    end
    
    # Fallback: infer from agent characteristics
    if agent ∈ ["Scout", "Veritas", "Codex"]
        return "standard"
    elseif agent ∈ ["Navigator-Ops", "Analyst-Perf", "Mentor"]
        return "heavy"
    else
        return "light"
    end
end

function spawn_with_profile(agent::String, task::String)
    profile_name = get_agent_profile(agent, task)
    profile = PROFILES_CONFIG["profiles"][profile_name]
    
    config = build_sandbox_config(profile)
    result = spawn_sandboxed(agent, task, config)
    
    return result
end
```

**Impact:**
- Memory: 60MB × 20 agents (12GB) → 30MB avg (6GB) = -50%
- Performance: Right-sized for each task
- Latency: Slight improvement (less resource contention)
- Maintainability: +profile config management

---

## P3: Parallel Spawning (1.5 hours, Week 3-4)

**Problem:** Batch research tasks wait sequentially (10 tasks = 20+ seconds)

**Code:**
```julia
using Base.Threads

function spawn_parallel(tasks::Vector{Tuple{String, String}})::Vector{Dict}
    """Spawn multiple agents in parallel."""
    
    # Check if parallelization worth it
    if length(tasks) < 3
        # Sequential for small batches
        return map(tasks) do (task, agent)
            spawn_sandboxed(agent, task)
        end
    end
    
    # Parallel for larger batches
    results = asyncmap(tasks, ntasks=min(4, length(tasks))) do (task, agent)
        try
            spawn_sandboxed(agent, task)
        catch e
            Dict("error" => string(e), "task" => task, "agent" => agent)
        end
    end
    
    return results
end

# Usage in spawner-matrix.jl
if is_batch_task(task) && length(candidates) > 2
    # Batch research: parallel spawn
    batch = [(task, agent) for agent in candidates]
    results = spawn_parallel(batch)
    return Dict("batch_results" => results)
else
    # Single task: sequential
    result = spawn_sandboxed(agent, task)
    return result
end
```

**Impact:**
- Throughput: 1 task/2sec → 4 tasks/2sec (4x)
- Latency: Negligible (async overhead ~10ms)
- Resource use: +CPU contention (intended)
- Best for: Research batches, analysis, testing

**Safety:** Limit to 4 parallel (2GB × 4 = 8GB memory usage)

---

## P4: Lazy Config Loading (15 min, Week 4+)

**Problem:** Load + parse config for every spawn (tiny overhead)

**Code:**
```julia
# Global cached config (load once)
const SANDBOX_CONFIG = load_config("configs/sandbox-default.toml")

function spawn_sandboxed(agent::String, task::String)
    # Use cached config instead of reloading
    cmd = build_docker_command(SANDBOX_CONFIG, agent, task, container_id)
    result = run(cmd, wait=true)
    return result
end
```

**Impact:** -5ms per task (negligible, not worth optimizing now)

---

## Implementation Timeline

### Week 1 (Post-Launch)
- [ ] P0: Add validation gateway (30 min)
- [ ] Monitor Phase 12A baseline metrics (container overhead, agent learning rates)
- [ ] Collect performance data

### Week 2
- [ ] P1: Implement container pool (2h)
- [ ] Test with Scout (research tasks) — should see 10x speedup
- [ ] Benchmark memory usage

### Week 3
- [ ] P2: Create sandbox profiles (1.5h)
- [ ] Reassign agents to profiles
- [ ] Optimize memory footprint

### Week 4
- [ ] P3: Implement parallel spawning (1.5h)
- [ ] Test with batch research queries
- [ ] Validate 4x throughput claim

### Post-Launch
- [ ] P4: Lazy config loading (15 min, optional)
- [ ] Review + iterate based on operational experience

---

## Rollout Checklist

Before each optimization:

- [ ] Code reviewed
- [ ] Tests pass (unit + integration)
- [ ] Performance measured before/after
- [ ] No regression in reliability
- [ ] Rollback plan documented
- [ ] Git committed with clear message
- [ ] MEMORY.md updated with decision

---

## Success Metrics

After all optimizations (target: Week 4):

| Metric | Before | Target | Status |
|--------|--------|--------|--------|
| Task latency | 500ms | 100ms | -80% |
| Container memory | 12GB (20×600MB) | 6GB (20×300MB) | -50% |
| Batch throughput | 1 task/2s | 4 tasks/2s | +400% |
| Spawn validation | None | 100% | ✅ |
| System reliability | TBD | >99% | TBD |

---

## Notes

- **Don't over-optimize prematurely.** Run Phase 12A first, measure, then optimize.
- **Container pool is the big win.** Do P1 first after validation.
- **Profiles are nice but optional.** Implement if memory becomes constraint.
- **Parallel spawning valuable for research.** Batch queries common pattern.
- **Lazy loading negligible.** Only if profiling shows overhead.

---

_Guide: 2026-04-03 23:20 UTC_  
_Status: Ready for post-launch implementation_  
_Effort total: ~6 hours over 4 weeks_  
_Expected ROI: 30-40% efficiency gain_
