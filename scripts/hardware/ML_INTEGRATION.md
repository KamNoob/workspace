# Morpheus ML Integration Guide

## Overview

**Two Modes of Operation:**

### 1. Rules-Based (Current)
- **File:** morpheus-server.jl
- **Logic:** if/else decision rules
- **Speed:** <5ms per decision
- **Flexibility:** Fixed rules
- **Status:** ✅ Production
- **Use Case:** Simple sensor rules (temperature thresholds, etc.)

### 2. ML-Enhanced (New)
- **File:** morpheus-ml-server.jl
- **Logic:** MatrixRL agent selection + KB context
- **Speed:** ~50-100ms per decision (includes agent spawning)
- **Flexibility:** Learns from outcomes
- **Status:** ⏳ Ready to test
- **Use Case:** Complex decisions requiring multiple agents

## Architecture Comparison

### Rules-Based Flow
```
Sensor Input
    ↓
if value > 30 then relay_on
    ↓
Log Decision
    ↓
Execute (GPIO)
```

### ML-Enhanced Flow
```
Sensor Input
    ↓
Classify to Task (temperature → infrastructure)
    ↓
Query RL Matrix (Q-learning scores)
    ↓
Select Best Agent (Codex, Cipher, Scout, Sentinel)
    ↓
Retrieve KB Context (relevant knowledge base entries)
    ↓
Make Decision (with agent reasoning)
    ↓
Log + Execute
```

## Quick Start

### Switch to ML Mode (Testing)

**Stop current server:**
```bash
pkill -f morpheus-server.jl
```

**Start ML server:**
```bash
/snap/julia/165/bin/julia \
  /home/art/.openclaw/workspace/scripts/hardware/morpheus-ml-server.jl &
```

**Verify:**
```bash
curl http://localhost:8000/api/health
# Should show: "mode": "ml_enhanced"
```

**Test decision:**
```bash
curl -X POST http://localhost:8000/api/decide \
  -H "Content-Type: application/json" \
  -d '{"sensor":"temperature","value":35,"unit":"C","device_id":"ML_TEST"}'

# Response includes "agent": "Codex" (or another agent)
```

### Monitor Agent Spawning
```bash
# Watch decisions + agents
tail -f /home/art/.openclaw/workspace/logs/morpheus-decisions.jsonl | \
  jq -r '[.device_id, .sensor, .decision, .agent] | @csv'
```

## Integration Points

### 1. MatrixRL (Agent Selection)
**Location:** `/scripts/ml/spawner-matrix.jl`

**How it works:**
- Loads Q-learning matrix from `data/rl/rl-state.jld2`
- Scores agents (Codex, Cipher, Scout, Sentinel, Chronicle)
- Returns best agent for task + confidence score

**Called by:** ML server when decision needs agent expertise

```julia
result = spawn_agent_ml(task, sensor_data)
# Returns: Dict("agent" => "Codex", "q_score" => 0.82, "kb_used" => true)
```

### 2. Knowledge Base (Context Injection)
**Location:** `/scripts/ml/kb-rag-injector.jl`

**What it does:**
- Searches KB for relevant entries
- Scores by semantic similarity
- Injects top-3 blocks into agent prompt

**Called by:** Agent spawner before decision making

### 3. Task Classification
**Mapping:**
```
temperature     → infrastructure (Sentinel)
security        → security (Cipher)
light           → monitoring (Scout)
motion          → automation (Codex)
humidity        → infrastructure (Sentinel)
co2             → environmental (Scout)
power           → infrastructure (Sentinel)
```

**Edit in:** `sensor_to_task()` function in morpheus-ml-server.jl

## Testing Phases

### Phase 1: Basic ML (NOW)
```bash
# Start ML server
/snap/julia/165/bin/julia morpheus-ml-server.jl &

# Test with various sensors
curl -X POST http://localhost:8000/api/decide \
  -H "Content-Type: application/json" \
  -d '{"sensor":"security","value":1,"device_id":"TEST_SEC"}'
  
# Should spawn Cipher agent
```

### Phase 2: Outcome Logging
```bash
# After decision, log outcome
julia /scripts/ml/spawner-matrix.jl log infrastructure Sentinel true

# This updates Q-values for future decisions
```

### Phase 3: Dashboard
```bash
# Visualize agent selection over time
Rscript /scripts/analytics/rl-plots.R
```

## Performance Comparison

| Metric | Rules | ML |
|--------|-------|-----|
| Decision Time | <5ms | 50-100ms |
| Memory | 350 MB | 400 MB |
| CPU Idle | 2% | 3% |
| Decisions/sec | 1000+ | 100-200 |
| Flexibility | Fixed | Learning |
| Agent Context | No | Yes (KB) |
| Cost | Free (rules) | ~$0.01/decision (API) |

## Hybrid Approach (Recommended)

**Use both:** Rules for simple decisions, ML for complex ones.

```julia
if value > 40
    # Critical: use ML
    agent_info = spawn_agent_ml(task, sensor_data)
    decision = "alert_with_agent:" * agent_info["agent"]
else
    # Normal: fast rules
    decision = "idle"
end
```

## Configuration

### Add New Agent
Edit `spawn_agent_ml()`:
```julia
cmd = `... spawn $task Codex,Cipher,Scout,Sentinel,Echo`
#                                              ↑ Add Echo
```

### Add New Task Type
Edit `sensor_to_task()`:
```julia
mapping = Dict(
    ...
    "custom_sensor" => "custom_domain"  # Add this
)
```

### Change RL Threshold
Edit spawner settings:
```julia
const SPAWN_THRESHOLD = 0.70  # Only spawn if Q > 0.7
```

### Disable KB Context
Edit ML server:
```julia
if use_kb && KB_ENABLED && false  # Change to false
    kb_context = ...
end
```

## Monitoring

### Check Agent Selection Quality
```bash
tail -100 /home/art/.openclaw/workspace/logs/morpheus-decisions.jsonl | \
  jq -r '.agent' | sort | uniq -c
```

### View Q-Scores
```bash
julia /scripts/ml/spawner-matrix.jl status
```

### Track Agent Performance
```bash
jq -r '[.agent, .confidence] | @csv' \
  /home/art/.openclaw/workspace/logs/morpheus-decisions.jsonl | \
  awk -F, '{sum[$1]+=$2; cnt[$1]++} END {for(a in sum) print a, sum[a]/cnt[a]}'
```

## Deployment Steps

### 1. Backup Current Logs
```bash
cp logs/morpheus-decisions.jsonl logs/morpheus-decisions.backup.jsonl
```

### 2. Verify RL State
```bash
ls -la data/rl/rl-state.jld2
# Should exist and be < 1MB
```

### 3. Test ML Server (Localhost)
```bash
/snap/julia/165/bin/julia morpheus-ml-server.jl &
sleep 3
curl http://localhost:8000/api/health | jq .mode
# Should output: "ml_enhanced"
```

### 4. Monitor Decisions
```bash
tail -f logs/morpheus-decisions.jsonl | jq '.agent' &
# Should see agent names (Codex, Cipher, Scout, etc.)
```

### 5. Validate Performance
```bash
# After 10 decisions, check latency
curl http://localhost:8000/api/stats | jq .decisions
```

### 6. Switch to Production (Optional)
```bash
# Kill rules server
pkill -f "morpheus-server.jl" | grep -v ml

# Install ML server as systemd service
cp morpheus-ml-server.jl /tmp/morpheus-ml.jl
# Edit morpheus.service to use morpheus-ml.jl
# systemctl --user restart morpheus
```

## Rollback (if needed)

```bash
# Stop ML server
pkill -f morpheus-ml-server.jl

# Restore rules server
/snap/julia/165/bin/julia morpheus-server.jl &

# Data is preserved - decisions log unchanged
tail -f logs/morpheus-decisions.jsonl
```

## Next Steps

1. **Test ML Mode** with various sensors (temperature, security, light)
2. **Log Outcomes** to train RL model
3. **Monitor Agent Selection** (view decisions log)
4. **Build Dashboard** (R Shiny) to visualize learning
5. **Deploy to Production** when confident

## Architecture Files

```
/scripts/hardware/
├─ morpheus-server.jl              (Rules-based, current)
├─ morpheus-ml-server.jl           (ML-enhanced, new)
└─ ML_INTEGRATION.md               (This guide)

/scripts/ml/
├─ spawner-matrix.jl               (Agent selection via RL)
├─ kb-rag-injector.jl              (Knowledge base context)
├─ MatrixRL.jl                     (Q-learning engine)
└─ data-collection-sprint.jl       (Outcome logging)

/data/rl/
├─ rl-state.jld2                   (Q-matrix state)
└─ rl-task-execution-log.jsonl     (Training data)
```

## Support

- **Q-Learning Questions:** See MatrixRL.jl docs
- **KB Questions:** See kb-rag-injector.jl
- **Agent Spawning:** See spawner-matrix.jl
- **Issues:** Check logs/morpheus-decisions.jsonl for patterns

---

**Status:** ML Integration Ready to Test ✅  
**Recommended:** Start with ML mode on localhost, switch to prod after validation
