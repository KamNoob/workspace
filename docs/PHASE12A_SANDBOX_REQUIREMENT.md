# Phase 12A: Container Sandboxing Requirement

**Status:** CRITICAL BLOCKER (Must complete before Monday launch)  
**Added:** 2026-03-29 23:20 GMT  
**Effort:** 1-2 hours  
**Assignee:** Implementation this week

---

## Why It's Critical

**Phase 12A expands agents: 11 → 20**

Current system runs agents directly in process with full filesystem access.

Risk increases 80% when scaling from 11 → 20 agents.

**We cannot launch Phase 12A without execution isolation.**

---

## What We're Building

Docker/Podman container wrapper that:
- Isolates agent filesystem (agents can't read/write host files)
- Limits resources (2GB RAM, 1 CPU max per agent)
- Blocks network (agents can't exfiltrate data)
- Kills runaway processes (300s timeout)
- Runs as unprivileged user (no privilege escalation)

---

## Implementation Plan

### Hour 1: Docker Image + Wrapper

**Files to create:**

1. `docker/Dockerfile.agent`
   - Based on julia:1.12-slim
   - Add appuser (unprivileged)
   - Install minimal dependencies
   - ~50 lines

2. `scripts/ml/spawner-sandboxed.jl`
   - SandboxConfig struct
   - spawn_sandboxed() function
   - Mount + resource management
   - ~100 lines

### Hour 2: Testing + Validation

**Test Scout agent:**

```bash
# Build image
docker build -f docker/Dockerfile.agent -t myclaw:agent-latest .

# Test spawn
julia scripts/ml/spawner-sandboxed.jl \
  --agent scout \
  --task "research python debugging" \
  --sandbox-config configs/sandbox-default.toml

# Verify:
# ✅ Can read /data (mounted)
# ✅ Can't read /etc/passwd (isolated)
# ✅ Killed after 5min timeout
# ✅ Memory limited to 2GB
```

---

## Configuration (TOML)

**New file:** `configs/sandbox-default.toml`

```toml
[sandbox]
image = "myclaw:agent-latest"
memory_limit = "2g"
timeout_seconds = 300
network = "none"           # Secure: no outbound access
user = "appuser"           # Unprivileged

[mounts]
"/home/art/.openclaw/workspace/data" = "/data:ro"    # Read-only
"/tmp/agent-scratch" = "/scratch:rw"                 # Writable

[resources]
cpus = "1.0"               # Max 1 CPU core
pids_limit = 50            # Max 50 processes per agent
```

---

## Phase 12A Launch Gate

Before Monday morning (2026-03-31):

- [ ] Docker image built
- [ ] spawner-sandboxed.jl written + tested
- [ ] Scout agent verified in container
- [ ] All Phase 12A agents (5) tested in containers
- [ ] Rollback procedure documented (fall back to direct spawn)
- [ ] Commit to git with clear message

**Blockers to resolve before Monday:**
- [ ] Docker/Podman available? (verify `docker --version`)
- [ ] Disk space? (~500MB per image)
- [ ] Performance acceptable? (~200ms overhead per spawn)

---

## Security Checklist

Before Phase 12A launch, verify:

- [ ] Agent cannot read `/etc/passwd` (filesystem isolation)
- [ ] Agent cannot reach external IPs (network isolation)
- [ ] Agent killed after 300s (timeout working)
- [ ] Memory usage capped at 2GB (resource limits)
- [ ] Agent can read `/data` (mount works)
- [ ] Agent can write to `/scratch` (writable mount works)

---

## Rollback Plan

If sandboxing causes unforeseen issues:

```julia
# In spawner-matrix.jl, add flag:
use_sandbox = true  # Set to false to revert

if use_sandbox
    result = spawn_sandboxed(agent, task, config)
else
    result = spawn_direct(agent, task)  # Old behavior
end
```

Zero impact on agents — transparent wrapper.

---

## Success Criteria

By end of this week:

✅ Docker image built  
✅ Scout passes container security tests  
✅ All Phase 12A agents (5 new + 11 existing) work sandboxed  
✅ Performance overhead acceptable (<300ms)  
✅ Git commit ready  
✅ Phase 12A launch unblocked  

---

## Next Steps

1. **Today/tomorrow:** Build image + wrapper
2. **Wednesday:** Test Scout agent
3. **Thursday:** Test all Phase 12A agents
4. **Friday:** Final validation
5. **Monday:** Launch Phase 12A with sandbox enabled

---

_Requirement added: 2026-03-29 23:20 GMT_  
_Blocks Phase 12A launch until complete_
