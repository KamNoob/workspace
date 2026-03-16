# EXPLORATION_THREADS.md - Open Exploration Paths

_Active threads to explore. Pick one, build momentum, iterate._

---

## Priority Tier 1: Immediate Value

### 🔧 Arduino/ESP32 Hardware Integration
**Status:** ✅ Phase 1 Complete (2026-03-14 12:26)  
**Effort:** 2-3 days  
**Impact:** High (tangible hardware + AI bridge)

**What you have:**
- 3 ESP32 modules
- 3 Arduino UNOs
- ✅ Arduino CLI v1.4.1 installed

**What's done:**
- ✅ Arduino CLI installed (~/.local/bin/arduino-cli)
- ✅ Board definitions: Arduino AVR 1.8.7, ESP32 2.0.18
- ✅ Starter sketches: blink_uno, wifi_esp32
- ✅ Wrapper script: arduino-cli-wrapper.sh (compile, upload, monitor)
- ✅ Morpheus integration roadmap (Phase 1-3 design doc)

**What's next:**
- [ ] Phase 2: Morpheus API server (Julia HTTP server)
- [ ] Phase 3: ESP32 client connecting to Morpheus
- [ ] Real hardware testing (WiFi sketch on actual board)
- [ ] Multi-device coordination

**Why:** Tangible, fun, teaches full stack (hardware → AI)

---

### 🧠 Predictive Agent Router (Neural Network)
**Status:** ✅ Phase 1-2 Complete (2026-03-14 12:37)  
**Effort:** 3 days to first model  
**Impact:** High (20-30% improvement in agent selection)

**Architecture:**
```
Python: Train classifier
    ↓ ONNX export
Rust: Inference API
    ↓ calls
Julia: Replace spawner-matrix logic
    ↓ metrics
R: Performance dashboard
```

**What's done (Phase 1-2):**
1. ✅ Data prep (Julia): Load RL logs, featurize, encode agents
   - Script: agent-router-data.jl
   - Output: 7 train / 6 test samples, 6-dim features, 6 agents
   
2. ✅ Neural network trainer (Julia): 3-layer MLP + training loop
   - Script: train-agent-router.jl
   - Model: 6 → 16 → 16 → 6 (trained)
   - Output: agent-router-model.json (5.5KB)

**What's next (Phase 3):**
3. [ ] Rust: Build inference server (HTTP API on localhost:8000)
4. [ ] Julia: Integrate into spawner-matrix.jl (query before spawn)
5. [ ] R: Visualize predictions vs outcomes

**Why:** Strategic improvement, measurable ROI, teaches full stack

---

## Priority Tier 2: Knowledge & Infrastructure

### 📚 Knowledge Base Expansion
**Status:** Tesla KB live (1 of N)  
**Effort:** 1-2 days per domain  
**Impact:** Medium (enables better context injection)

**Domains to add:**
- [ ] AI/ML concepts (from research papers)
- [ ] Arduino/ESP32 hardware specs & libraries
- [ ] Your project patterns (lessons learned)
- [ ] System architecture docs (your infra)

**What to do:**
1. Pick a domain (e.g., Arduino reference)
2. Scrape/organize docs
3. Create JSON KB file (like tesla-kb.json)
4. Integrate with kb-rag-injector.jl
5. Test context injection

**Why:** Better spawn context = smarter agent decisions

---

### 📊 Dashboards & Monitoring
**Status:** None exist (metrics exist, no viz)  
**Effort:** 3-5 days  
**Impact:** Medium (visibility, debugging)

**What to build:**
1. **Agent Performance Dashboard** (R Shiny)
   - Real-time Q-scores by task
   - Success rate trends
   - Agent latency heatmap

2. **Memory Analytics**
   - Search accuracy over time
   - Cache hit rates
   - Query patterns

3. **Cost Tracking Dashboard**
   - Token usage by agent/task
   - ROI analysis
   - Budget alerts

**Why:** See what's working, debug failures faster

---

## Priority Tier 3: Advanced Features

### 🧠 Advanced Memory System Upgrade
**Status:** Current system is good, can be better  
**Effort:** 1 week  
**Impact:** Medium (UX, discovery)

**Enhancements:**
- [ ] Persistent consolidation (merge similar memories daily)
- [ ] Temporal search ("what happened last Tuesday?")
- [ ] Cross-reference discovery (auto-link related ideas)
- [ ] Spaced repetition (surface forgotten memories)
- [ ] Semantic deduplication (find duplicate memories)

**What to do:**
1. Add consolidation routine (daily cron)
2. Implement temporal indexing
3. Add cross-reference detection
4. Build spaced repetition scheduler

**Why:** Better memory = smarter decisions, less noise

---

### 🎯 Skill Development (OpenClaw)
**Status:** Not started  
**Effort:** 2-3 days per skill  
**Impact:** Medium (reusable, shareable)

**Skills to create:**
- [ ] `arduino-cli-wrapper` — Board management + sketch upload
- [ ] `email-threat-analyzer` — Extend Cipher integration
- [ ] `code-review-enhancer` — Improve Veritas workflow
- [ ] `task-workflow-automation` — Your personal task patterns

**What to do:**
1. Pick a skill (e.g., arduino-cli-wrapper)
2. Create SKILL.md + implementation
3. Test with your workflows
4. Publish to clawhub (optional)

**Why:** Reusable, teachable, share with others

---

## Parking Lot (Lower Priority)

- [ ] PostgreSQL migration (only if scaling beyond 75k entries)
- [ ] Distributed training (Distributed.jl) — overkill for now
- [ ] Actor-Critic RL upgrade — wait for NN router success
- [ ] Interactive debugging REPL — nice-to-have

---

## Recommended Starting Path

**Week 1:**
1. Arduino CLI setup + first sketch
2. Start Predictive Agent Router (Python training)

**Week 2:**
1. Rust inference server (agent router)
2. Arduino integation with Morpheus

**Week 3:**
1. Julia spawner integration (agent router live)
2. R dashboard (monitor improvements)

---

## Tracking

| Thread | Owner | Status | Started | ETA | Notes |
|--------|-------|--------|---------|-----|-------|
| Arduino | — | Phase 1 ✅ | 2026-03-14 | 2d (Phase 2-3) | CLI done, sketches ready, integration plan in place |
| Agent Router | — | Phase 1-2 ✅ | 2026-03-14 | 1d (Phase 3) | Data + training done, Rust API next |
| KB Expansion | — | Not started | — | 1d/domain | Tesla done; Arduino next? |
| Dashboards | — | Not started | — | 3-5d | Low-hanging fruit |
| Memory System | — | Not started | — | 1w | Nice-to-have, lower priority |
| Skills | — | Not started | — | 2-3d/each | Arduino skill first? |

---

## How to Use This File

1. **Pick a thread** that excites you
2. **Create a branch** for focused work
3. **Update this file** as you progress
4. **Commit frequently** with clear messages
5. **Review learnings** in MEMORY.md weekly

---

_Created: 2026-03-14 12:24 GMT_  
_Source: Exploration discussion + brainstorm session_  
_Next: Pick one thread and start_
