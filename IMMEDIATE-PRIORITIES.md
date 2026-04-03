# Immediate Priorities — What Needs to Be Done

**Last Updated:** 2026-04-03 23:40 UTC  
**Status:** Phase 12A Live | Phase 12B Pending | System Stable

---

## ✅ COMPLETED (This Session)

### Phase 12A Container Sandboxing
- [x] Docker image built (myclaw:agent-latest, 1.23 GB)
- [x] Sandbox configuration created (2GB mem, 2CPU, no network)
- [x] Spawner script implemented (spawner-sandboxed.jl)
- [x] All 4 validation tests passed
- [x] Documentation complete (SANDBOX-GUIDE, VALIDATION, OPTIMIZATIONS)
- [x] Git commits clean (4 commits, 26KB of code)
- [x] Deployed to production
- [x] 20 agents running (11 proven + 9 learning)

### Memory & Documentation
- [x] MEMORY.md condensed (84KB → 6.9KB)
- [x] Daily logs maintained (52 files)
- [x] Housekeeping audit complete
- [x] All docs aligned and current

---

## ⏳ IN PROGRESS / PENDING

### Phase 12B: RLVR (Verifiable Reward System)
**Status:** PLANNED but NOT STARTED  
**Originally scheduled:** Mon-Wed 2026-03-24 to 2026-03-26 (OVERDUE)  
**Current:** 8 days late (should have launched 2026-03-26)

**What needs to be done:**
1. **rlvr-calculator.jl** (2-3 hours)
   - Reward calculation with penalties/bonuses
   - SLA constraint checking
   - Unit tests (10+ cases)

2. **rlvr-verifier.jl** (1.5-2 hours)
   - Daily verification reports
   - Violation detection
   - Event logging

3. **spawner-matrix integration** (1-1.5 hours)
   - Add `verify_and_update_q()` wrapper
   - Block Q-updates on constraint violations
   - Integrate with audit logging

4. **rlvr-auditor.jl** (1-1.5 hours)
   - Compliance reporting
   - SLA dashboard
   - Audit trail

**Total effort:** 6-8 hours (can be done this week)

**Files to create:**
- scripts/ml/rlvr-calculator.jl
- scripts/ml/rlvr-verifier.jl
- scripts/ml/rlvr-auditor.jl
- test/test-rlvr.jl

**Why defer vs. do now?**
- ✅ Phase 12A just launched (needs stabilization)
- ✅ New agents just learning (RLVR constraints will kick in after warmup)
- ✅ System stable on current setup
- ❌ Could implement immediately if needed

**Recommendation:** Defer until Phase 12A shows 1-2 weeks of stable operation. New agents need time to learn before SLA constraints become meaningful.

---

### WhatsApp Re-authentication (Non-blocking)
**Status:** DISABLED (auth token invalid)  
**Impact:** Channel down, messaging unavailable  
**Priority:** Low (can wait)  
**Effort:** 30 min

**Steps:**
1. Delete old credentials: `rm -rf ~/.openclaw/credentials/whatsapp/default/*`
2. Re-authenticate: `whatsapp login`
3. Scan QR code
4. Test message: `message send "test" --channel whatsapp`
5. Re-enable in gateway config

**Recommendation:** Do this week when convenient (not urgent).

---

### Archive & Cleanup Tasks (Housekeeping)
**Status:** OPTIONAL  
**Impact:** Frees up space, reduces clutter  
**Effort:** 1-2 hours

**What to do:**
1. Archive legacy backup workspaces (3 items in ./backups/)
   ```bash
   tar -czf backups-2026-04-03.tar.gz ./backups/
   rm -rf ./backups/*
   ```

2. Clean old delivery queue failures (17 items)
   ```bash
   rm -rf ./delivery-queue/failed/*.json
   ```

3. Archive Qdrant old data (fully deprecated)
   ```bash
   rm -rf ./data/qdrant/
   ```

4. Compress docs-archive/ (historical reference)
   ```bash
   tar -czf docs-archive-2026-04-03.tar.gz ./workspace/archive/
   ```

**Recommendation:** Do in background, no urgency.

---

## 🚀 OPTIONAL IMPROVEMENTS (Post-Launch)

### P0: Validation Gateway (30 min)
**Impact:** Prevents wasted container spawns  
**When:** This week

```julia
function validate_spawn_request(agent, task)
    # Check agent exists, task valid, resources available
    # Return (true, "") or (false, "reason")
end
```

### P1: Container Pool Reuse (2 hours)
**Impact:** 10x faster task execution (500ms → 50ms)  
**When:** Next week, after 12A stabilizes

```julia
const CONTAINER_POOL = []
function spawn_from_pool(agent, task)
    # Reuse warm containers from pool
end
```

### P2: Sandbox Profiles (1.5 hours)
**Impact:** 50% memory reduction  
**When:** Week 2, if memory becomes constraint

```toml
[profiles.light]      # Docs, review: 512M, 0.5 CPU
[profiles.standard]   # Research, code: 2G, 2 CPU  
[profiles.heavy]      # Optimization: 4G, 4 CPU
```

### P3: Parallel Spawning (1.5 hours)
**Impact:** 4x batch throughput  
**When:** Week 3, when batch tasks arrive

```julia
function spawn_parallel(tasks)
    asyncmap(tasks, ntasks=4) do (task, agent)
        spawn_sandboxed(agent, task)
    end
end
```

---

## PRIORITY MATRIX

| Task | Priority | Impact | Effort | Timeline | Status |
|------|----------|--------|--------|----------|--------|
| Phase 12B RLVR | High | Quality gates | 6-8h | Next week | ⏳ Deferred |
| WhatsApp auth | Low | Messaging | 30m | This week | ⏳ Pending |
| Archive cleanup | Low | Space | 1-2h | Optional | ⏳ Pending |
| P0 Validation | Medium | Stability | 30m | This week | 📋 Planned |
| P1 Pool reuse | Medium | Perf | 2h | Week 2 | 📋 Planned |
| P2 Profiles | Low | Memory | 1.5h | Week 2-3 | 📋 Planned |
| P3 Parallel | Medium | Throughput | 1.5h | Week 3 | 📋 Planned |

---

## DECISION: What to Do This Week?

### Recommend: Focused Path
1. **Monitor Phase 12A** (passive) — Watch agents learning, gateway stable
2. **Implement P0** (active) — Validation gateway (30 min, high value)
3. **Optional: WhatsApp** (passive) — Re-auth if needed for comms
4. **Optional: Cleanup** (passive) — Archive old files in background

### Do NOT do this week:
- ❌ Phase 12B yet (let Phase 12A stabilize first)
- ❌ P1-P3 optimizations (can wait until Phase 12A is proven)

### Why?
- Phase 12A just launched with 9 new agents at Q=0.5
- New agents need 1-2 weeks to learn and converge
- System is stable and operational
- No blocking issues preventing normal work

---

## RECOMMENDED SCHEDULE

### This week (Week of 2026-04-03)
- [x] Phase 12A monitoring (passive)
- [ ] P0 validation gateway (30 min active work)
- [ ] WhatsApp auth (if time)
- [ ] Archive cleanup (background)

### Next week (Week of 2026-04-10)
- [ ] Phase 12A review (check convergence)
- [ ] P1 container pool (2h active)
- [ ] Phase 12B planning (prep, not impl yet)

### Week of 2026-04-17
- [ ] Phase 12B RLVR implementation (6-8h)
- [ ] P2 sandbox profiles (if needed)

### Week of 2026-04-24
- [ ] Phase 12B testing & validation
- [ ] P3 parallel spawning
- [ ] Phase 13 planning

---

## Summary

**What's Done:**
- ✅ Phase 12A container sandboxing (complete, live, tested)
- ✅ 20 agents in production
- ✅ System stable and monitored

**What's Next:**
- ⏳ Phase 12B RLVR (defer 1-2 weeks for stabilization)
- ⏳ P0-P3 optimizations (prioritized, 6-8h total)
- ⏳ WhatsApp auth (low priority)

**Immediate Action:**
- **This week:** Monitor Phase 12A + implement P0 validation (30 min)
- **No blockers** — system operates well as-is

---

_Updated: 2026-04-03 23:40 UTC_  
_Next review: 2026-04-10 (weekly status)_
