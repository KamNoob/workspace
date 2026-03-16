# ML Integration Roadmap

## Current Status

✅ **Hardware System:** Production-ready (Morpheus + ESP32)  
✅ **Rules Engine:** Live and tested  
⏳ **ML Integration:** Frameworks built, testing in progress

---

## Three Integration Levels

### Level 1: Rules-Based (CURRENT ✅)
**File:** `scripts/hardware/morpheus-server.jl`

**How it works:**
```julia
if temperature > 30
    decision = "relay_on"
else
    decision = "idle"
end
```

**Characteristics:**
- Speed: <5ms per decision
- Memory: 350 MB
- Rules: Fixed, hardcoded
- Learning: None
- Agent context: None

**Status:** ✅ Production, 9+ decisions logged

---

### Level 2: ML-Lite Agent Assignment (READY ⏳)
**File:** `scripts/hardware/morpheus-ml-lite.jl`

**How it works:**
```julia
agent = get_agent(sensor_type)  # temperature → Sentinel
decision = make_decision(value, agent)
# Logs: {decision, agent, confidence, reasoning}
```

**Agent Mapping:**
- Temperature → Sentinel (infrastructure)
- Security → Cipher (security)
- Light → Scout (monitoring)
- Motion → Codex (automation)

**Characteristics:**
- Speed: ~50ms per decision
- Memory: 400 MB
- Rules: Fixed agent assignment
- Learning: Ready for outcome logging
- Agent context: Names in reasoning

**Status:** ⏳ Framework built, needs testing

**To deploy:**
```bash
pkill -f morpheus-server.jl
/snap/julia/165/bin/julia morpheus-ml-lite.jl &
curl -X POST http://localhost:8000/api/decide ...
```

---

### Level 3: Full ML with RL + KB (ADVANCED)
**File:** `scripts/hardware/morpheus-ml-server.jl`

**How it works:**
```julia
task = sensor_to_task(sensor_type)
agents = MatrixRL.spawn(task, candidates)        # Q-learning
kb_context = KB.retrieve(task)                    # Knowledge base
decision = make_decision_with_context(...)
```

**Characteristics:**
- Speed: 100-200ms per decision
- Memory: 400+ MB
- Rules: Learned via Q-learning
- Learning: Active (Q-values update)
- Agent context: KB entries injected

**Status:** ⏳ Framework ready, needs:
1. Verify RL state file (`data/rl/rl-state.jld2`)
2. Load KB context system
3. Test agent spawning
4. Validate outcomes logging

**To deploy:**
```bash
# First, ensure RL state exists
ls -la data/rl/rl-state.jld2

# Then start server
/snap/julia/165/bin/julia morpheus-ml-server.jl &
```

---

## Recommended Deployment Path

### Phase 1: Stabilize Rules-Based (This Week)
```bash
# Current: working well
/snap/julia/165/bin/julia morpheus-server.jl &

# Collect 50+ decisions with various sensors
# Monitor: tail -f logs/morpheus-decisions.jsonl | jq .
```

**Deliverable:** 50 decisions logged, patterns identified

---

### Phase 2: Test ML-Lite (Next Session)
```bash
# Debug and deploy ML-lite
#  1. Fix any remaining issues in morpheus-ml-lite.jl
# 2. Run with ESP32 for 1-2 hours
# 3. Collect outcomes with agents

/snap/julia/165/bin/julia morpheus-ml-lite.jl &

# After decisions, log outcomes
julia /scripts/ml/spawner-matrix.jl log infrastructure Sentinel true
julia /scripts/ml/spawner-matrix.jl log infrastructure Sentinel false
```

**Deliverable:** 100+ decisions with agent assignments

---

### Phase 3: Full ML Deployment (1-2 Weeks)
```bash
# Prerequisites:
# 1. Verify/rebuild RL state
julia /scripts/ml/init-matrix-rl.jl

# 2. Train KB system
julia /scripts/ml/kb-live-indexer.jl

# 3. Deploy full ML server
/snap/julia/165/bin/julia morpheus-ml-server.jl &

# 4. Monitor learning
julia /scripts/ml/spawner-matrix.jl status
```

**Deliverable:** Live ML system with learning

---

### Phase 4: Monitoring Dashboard (2-3 Weeks)
```bash
# Build R Shiny dashboard
Rscript /scripts/analytics/rl-plots.R

# Real-time:
# - Decision timeline
# - Agent performance
# - Q-value convergence
# - KB context usage
```

**Deliverable:** Production dashboard

---

## Integration Checklist

### Pre-Deployment
- [ ] Backup current rules-based logs
- [ ] Verify new code compiles
- [ ] Test locally (no ESP32)
- [ ] Prepare rollback plan

### Testing
- [ ] Deploy on localhost
- [ ] Send 10 test decisions (curl)
- [ ] Verify agent assignment
- [ ] Check log format
- [ ] Monitor latency

### Production
- [ ] Switch server version
- [ ] Monitor first 50 decisions
- [ ] Verify ESP32 still works
- [ ] Watch error rate
- [ ] Log outcomes

### Validation
- [ ] Agent consistency
- [ ] Decision quality
- [ ] No performance regression
- [ ] Safe rollback confirmed

---

## Files to Know

### Core System
```
scripts/hardware/
├─ morpheus-server.jl          (Rules-based, current)
├─ morpheus-ml-lite.jl         (Agent assignment, ready)
├─ morpheus-ml-server.jl       (Full ML, pending)
├─ ML_INTEGRATION.md           (Detailed guide)
└─ upload.sh                   (ESP32 deployment)
```

### ML Components
```
scripts/ml/
├─ spawner-matrix.jl           (Agent selection via RL)
├─ MatrixRL.jl                 (Q-learning engine)
├─ kb-rag-injector.jl          (KB context)
└─ kb-confidence-scorer.jl     (KB quality scoring)
```

### Data
```
data/rl/
├─ rl-state.jld2               (Q-matrix, RL state)
├─ rl-agent-selection.json     (Agent configs)
└─ rl-task-execution-log.jsonl (Training data)

logs/
└─ morpheus-decisions.jsonl    (Decision history)
```

---

## Success Metrics

### Level 1 (Rules)
✅ Latency < 10ms  
✅ Decisions logged correctly  
✅ GPIO execution works  
✅ Error rate < 1%  

### Level 2 (ML-Lite)
- [ ] Agents assigned consistently
- [ ] Latency 50-100ms acceptable
- [ ] Outcome logging works
- [ ] Learning-ready

### Level 3 (Full ML)
- [ ] Q-values converging
- [ ] Agent scores improving
- [ ] KB context injected
- [ ] Decision quality improving

---

## Rollback Plan

**If issues arise:**

```bash
# Stop current
pkill -f morpheus-server

# Restore previous version
/snap/julia/165/bin/julia morpheus-server.jl &

# Logs are preserved
tail -100 logs/morpheus-decisions.jsonl
```

**No data loss** - decisions are always logged to JSONL

---

## Questions & Debugging

### "Server not responding"
```bash
# Check if running
ps aux | grep julia | grep -v grep

# Check port in use
lsof -i :8000

# Check logs
curl http://localhost:8000/api/health

# Restart
pkill -f morpheus-server.jl
/snap/julia/165/bin/julia morpheus-server.jl &
```

### "Agent not assigned"
```bash
# Verify agent mapping
grep AGENT_MAP morpheus-ml-lite.jl

# Check sensor type in logs
jq '.sensor' logs/morpheus-decisions.jsonl | sort | uniq -c
```

### "Decisions not logging"
```bash
# Verify log directory
ls -la logs/

# Check file permissions
touch logs/morpheus-decisions.jsonl
chmod 666 logs/morpheus-decisions.jsonl

# Test write
echo '{"test":true}' >> logs/morpheus-decisions.jsonl
```

### "RL state not found"
```bash
# Initialize RL state
julia /scripts/ml/init-matrix-rl.jl

# Verify it exists
ls -la data/rl/rl-state.jld2
```

---

## Next Actions

**Immediate (This Session):**
1. ✅ Rules-based system running
2. ⏳ Test ML-Lite on localhost
3. [ ] Fix any remaining issues

**Before Next Session:**
1. Collect 50+ decisions with current system
2. Document any patterns
3. Identify sensor types for ML assignment

**Next Session:**
1. Deploy ML-Lite with ESP32
2. Monitor agent assignments
3. Log outcomes for RL training

---

## Contact

- **Current Server:** localhost:8000
- **Logs:** logs/morpheus-decisions.jsonl
- **Config:** ML_INTEGRATION.md
- **Status:** Docs + frameworks ready, testing in progress

---

**Last Updated:** 2026-03-14 15:05 GMT  
**Status:** Ready for Phase 2 (ML-Lite testing)
