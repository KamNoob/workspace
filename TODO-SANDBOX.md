# TODO: Container Sandboxing Implementation

**Priority:** CRITICAL (Phase 12A blocker)  
**Timeline:** This week (Mon-Fri before launch)  
**Effort:** 1-2 hours  
**Status:** ✅ COMPLETE — 2026-04-03 23:10 UTC

---

## Build Phase (Hour 1)

- [ ] Create `docker/Dockerfile.agent`
  - [ ] Base: julia:1.12-slim
  - [ ] Add appuser (unprivileged)
  - [ ] Install minimal deps
  
- [ ] Create `scripts/ml/spawner-sandboxed.jl`
  - [ ] SandboxConfig struct
  - [ ] spawn_sandboxed() function
  - [ ] Mount path handling
  - [ ] Resource limits
  - [ ] Container lifecycle management

- [ ] Create `configs/sandbox-default.toml`
  - [ ] Default mounts
  - [ ] Resource limits
  - [ ] Network settings
  - [ ] Timeout config

---

## Test Phase (Hour 2)

- [ ] Build Docker image
  ```bash
  docker build -f docker/Dockerfile.agent -t myclaw:agent-latest .
  ```

- [ ] Test Scout agent in container
  ```bash
  julia scripts/ml/spawner-sandboxed.jl --agent scout --task "research X" ...
  ```

- [ ] Security validation
  - [ ] Filesystem isolation ✓
  - [ ] Network isolation ✓
  - [ ] Resource limits ✓
  - [ ] Timeout works ✓
  - [ ] Mounts work ✓

- [ ] Performance check
  - [ ] Overhead < 300ms? ✓
  - [ ] Memory usage < 2GB? ✓

- [ ] Integration test
  - [ ] spawner-matrix.jl updated
  - [ ] All Phase 12A agents work sandboxed

---

## Rollout Phase

- [ ] Documentation
  - [ ] Update QUICK_START.md with sandbox info
  - [ ] Add to TOOLS.md (Docker requirements)

- [ ] Git commit
  - [ ] Commit Dockerfile
  - [ ] Commit spawner-sandboxed.jl
  - [ ] Commit config TOML
  - [ ] Clear commit message

- [ ] Validation checklist
  - [ ] All Phase 12A agents pass security tests
  - [ ] Performance acceptable
  - [ ] Rollback plan documented

---

## Phase 12A Launch Gate

Must complete BEFORE Monday 2026-03-31:

- [ ] Sandboxing implemented
- [ ] Scout tested + passing
- [ ] All Phase 12A agents tested
- [ ] Commits pushed to origin
- [ ] Phase 12A launch unblocked

---

## Files to Create

```
docker/
├── Dockerfile.agent                    ← NEW

scripts/ml/
├── spawner-sandboxed.jl                ← NEW

configs/
├── sandbox-default.toml                ← NEW
```

## Files to Modify

```
scripts/ml/
├── spawner-matrix.jl                   ← Update spawn logic
```

---

## Quick Reference Commands

```bash
# Build image
docker build -f docker/Dockerfile.agent -t myclaw:agent-latest .

# Test sandbox (once ready)
julia scripts/ml/spawner-sandboxed.jl \
  --agent scout \
  --task "research python" \
  --config configs/sandbox-default.toml

# Check containers running
docker ps

# View container logs
docker logs <container_id>

# Cleanup
docker system prune
```

---

_Created: 2026-03-29 23:22 GMT_  
_Blocks Phase 12A launch until complete_
