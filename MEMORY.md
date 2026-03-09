# MEMORY.md - Long-Term Memory

Last updated: 2026-03-09 14:44 GMT

## System State

- **OpenClaw Version:** 2026.3.2
- **Gateway:** Running on port 18789 (loopback), RPC healthy
- **WhatsApp:** Connected and operational
- **Memory Search:** Enabled (local embeddings, EmbeddingGemma 300M)
- **Workspace Root:** `/home/art/.openclaw/workspace`
- **Julia:** 1.12.5 ✅ (snap, /snap/julia/165/bin/julia) — Phase 2a/2b READY

## Operational Rules

### 1. Development Workflow
- **ALL prototyping & experiments** → `prototype/` directory first
- Structure: `prototype/features/`, `prototype/experiments/`, `prototype/temp/`
- Rule: Create in prototype/ → Test → Review → Move to main when stable
- Workspace main dirs are **production only**

### 2. Memory Management
- Raw session logs auto-generated to `memory/YYYY-MM-DD-*.md`
- MEMORY.md is the curated layer (this file)
- Update MEMORY.md periodically with lessons & decisions from daily logs
- Keep MEMORY.md focused on what matters long-term

### 3. Config Management
- Config file: `~/.openclaw/openclaw.json`
- Use `gateway config.patch` for partial updates (safer than full apply)
- Config warnings checked on startup; address stale entries
- Recent cleanup: Removed disabled `memory-lancedb` plugin config (was generating warnings)

## Current Status (2026-03-09 15:13 GMT)

**Session Progress:**
- ✅ Identity system complete (SOUL.md, IDENTITY.md, USER.md)
- ✅ Memory system initialized (MEMORY.md, HEARTBEAT.md, daily logs)
- ✅ Tools & infrastructure documented (TOOLS.md with Julia now live)
- ✅ Config cleaned up (removed stale lancedb entries)
- ✅ Memory optimizer refreshed (98% recall, Q-values converging)
- ✅ Git history clean (9 commits, all meaningful)
- ✅ **Phase 2a LIVE:** First workflow executed, outcome logged
  - Task: code-review (morpheus system integration)
  - Agent selected: Veritas (0.94 confidence, high)
  - Result: SUCCESS
  - ROI: 1/1 predictions = 100% accuracy

**Blockers:** None. Phase 2a actively gathering real outcome data.

---

## Architecture Decisions

### Memory Search
- **Status:** Using OpenClaw's built-in memorySearch (local embeddings)
- **Why:** Already enabled, no setup needed, hybrid search (85% semantic + 15% keyword)
- **Cost:** Zero (local, no API calls)
- **Auto-sync:** Watches workspace files, re-indexes on changes
- **Decision made:** Qdrant integration was built but deemed redundant; removed all traces (2026-03-09)

### Workspace Organization
- **config/** — SOUL.md, USER.md, HEARTBEAT.md, identity files
- **agents/** — Agent definitions, process flows, config
- **docs/** — Guides (guides/, ml/, reference/, research/)
- **data/** — Memory logs, RL data, scan results
- **scripts/** — Core utilities, ML tools
- **prototype/** — Rapid development sandbox (new as of 2026-03-09)
- **Improvement:** 82% reduction in root clutter (66 files → 12 files)

## Key Learnings

### 1. Don't Over-Engineer Infrastructure
Built a full Qdrant integration (Python indexing, shell wrappers, docs) before realizing OpenClaw already handles it. Lesson: Check what's built in before adding layers.

### 2. Config Cleanup Matters
Small stale entries (disabled memory-lancedb config) generated repeated warnings. Regular config review prevents noise in logs.

### 3. Context Pruning & Performance
System is optimized for speed (Haiku model, local embeddings). Context pruning TTL is 4h. If response speed becomes a bottleneck, can reduce TTL to 1h or disable memorySearch (trades context richness for speed).

## Files to Know

- **SOUL.md** — My personality & execution rules
- **USER.md** — Your context (currently empty template)
- **AGENTS.md** — System workflow guidelines
- **TOOLS.md** — Local setup notes (camera names, SSH hosts, etc.)
- **IDENTITY.md** — My identity metadata (currently empty template)
- **HEARTBEAT.md** — Periodic check tasks (currently empty)
- **daily logs** → `memory/YYYY-MM-DD-*.md` (auto-generated)

## TODO / Next Steps

- [x] Fill in USER.md — Complete (Kamtorn "Art", data engineer, polyglot)
- [x] Fill in IDENTITY.md — Complete (Morpheus, AI orchestrator, direct/competent vibe)
- [x] Establish HEARTBEAT.md — Complete (system health, memory, agent Q-scores, syncs, knowledge)
- [x] Populate TOOLS.md — Complete (Julia installed ✅, Notion configured, workflows ready)
- [ ] **Next:** Activate Phase 2a/2b (run first workflow, log outcomes, track ROI)
- [ ] Review & update MEMORY.md weekly as learnings accumulate

## Hardware & Infrastructure

### Host System
- **OS:** Ubuntu Linux (6.8.0-101-generic, x64)
- **CPU:** Intel Core i5-6600T @ 2.70GHz (4 cores, 3.5GHz max)
- **Memory:** 15 GB total (35% used, 10GB available, 50% swap)
- **Disk:** 457 GB total, 127 GB used (30%)
- **Timezone:** Europe/London (GMT)
- **Hostname:** art-OptiPlex-ubu2

### Workspace Storage
| Directory | Size | Purpose |
|-----------|------|---------|
| node_modules | 318M | NPM dependencies |
| skills | 1.1M | OpenClaw extensions |
| docs | 436K | Documentation |
| data | 212K | Memory, RL, logs |
| scripts | 176K | Automation tools |
| archive | 96K | Legacy files |
| prototype | 28K | Dev sandbox (growing) |
| config | 28K | System config |
| **Total workspace** | **~600MB** | Lean & efficient |

### Memory Optimizer State
- **System:** Q-learning memory selection (4 memory stores)
- **Q-values:** mem_1=0.62, mem_2=0.58, mem_3=0.55, mem_4=0.51 (exploitation phase)
- **Config:** α=0.01, γ=0.99, λ=0.9, max_memories=1000
- **Stats:** 139 successful recalls / 142 total (98% success), 156 stores, 2ms avg lookup
- **Consolidation:** 3 runs, last at 2026-03-09 14:48 GMT (optimized)
- **Learning phase:** Exploitation (converging to best memory stores)
- **Last refreshed:** 2026-03-09 14:48 GMT ✅

## Recent Git History

Latest commits (active development):
```
ef2e2ff  update: meta .md file
24d2027  index update
96ceb1c  remove: qdrant integration; not required ← TODAY
a5966c8  feature: indexing for qdrant
864314c  reorder folder structure
ac83b11  memory update
6fc90a5  feat: Implement QualityPredictor and agent spawning
ea67482  feat: Agent validation, message optimization
cb56e6e  feat: Add AI Persistent Memory Systems
ab4da0f  feat(memory): Add heartbeat monitoring [Mar 3]
```

**Pattern:** Active experimentation, infrastructure cleanup, memory systems development.

## Key Documentation Available

- **SOUL.md** — Personality & execution philosophy
- **AGENTS.md** — System workflow guidelines
- **AGENTS_CONFIG.md** (docs/) — Agent specifications
- **PROCESS_FLOWS.md** (agents/) — Decision workflows
- **NEURAL_NETWORK_ANALYSIS.md** (docs/ml/) — NN architecture notes
- **SECURITY_HARDENING_GUIDE.md** (docs/guides/) — Security best practices
- **TOKEN_OPTIMIZATION.md** (docs/reference/) — Token efficiency strategies
- **RL-KNOWLEDGE-INTEGRATION.md** (workspace root) — RL/learning integration
- **TEAM_STRUCTURE.md** (workspace root) — Organizational context
- **LOCAL_EMBEDDINGS_SETUP.md** (workspace root) — Embedding configuration (legacy)

## Questions to Resolve

- What domain do you work in? (software, research, writing, etc.)
- What problems are you solving?
- What tools/languages matter to you?
- Any projects in progress that deserve attention?
- Should memory optimizer be refreshed/retrained?

---

*This memory file bridges daily sessions. Load it alongside SOUL.md and USER.md each time.*
