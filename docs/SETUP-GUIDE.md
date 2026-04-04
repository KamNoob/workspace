# Complete Setup Guide: From Initial State to Current System (2026-04-04)

**Status:** ✅ Production System (Phase 12A Live)  
**Last Updated:** 2026-04-04 17:30 GMT+1  
**Documentation Version:** 1.0

---

## Table of Contents

1. [Quick Start (5 minutes)](#quick-start)
2. [Phase 0: Initial Setup](#phase-0-initial-setup)
3. [Phase 1-6: Core Agent System](#phase-1-6-core-agent-system)
4. [Phase 7B: Learning Pipeline](#phase-7b-learning-pipeline)
5. [Phase 11A/B/C: Audit & Compliance](#phase-11abc-audit--compliance)
6. [Phase 12A: Multi-Agent Production](#phase-12a-multi-agent-production)
7. [KB System (2026-04-04)](#kb-system-2026-04-04)
8. [Verification & Testing](#verification--testing)
9. [Troubleshooting](#troubleshooting)

---

## Quick Start (5 minutes)

If you're setting up this system fresh:

```bash
# 1. Clone workspace
git clone https://github.com/KamNoob/workspace.git ~/.openclaw/workspace
cd ~/.openclaw/workspace

# 2. Install OpenClaw
npm install -g openclaw

# 3. Start gateway
openclaw gateway start
openclaw status

# 4. Install Julia (required for Phase 2a/b)
sudo snap install julia --classic

# 5. Verify system
./scripts/ml/agent-spawner-qp.jl --help
python3 scripts/db/phase7b-sqlite-adapter.py

# Done. System operational.
```

---

## Phase 0: Initial Setup

### Prerequisites

| Requirement | Version | Status |
|-------------|---------|--------|
| Node.js | v24.11.0+ | ✅ |
| Python | 3.12.3+ | ✅ |
| Git | 2.40+ | ✅ |
| Julia | 1.12.5+ | ✅ (snap) |
| Docker | 20.10+ | ✅ (optional for Phase 12A) |
| OpenClaw CLI | 2026.4.2+ | ✅ |

### Directory Structure

```
/home/art/.openclaw/workspace/
├── SOUL.md                          # Identity & philosophy
├── IDENTITY.md                      # Team roster, agent descriptions
├── MEMORY.md                        # Long-term memory (consolidated)
├── USER.md                          # Your profile (Art/Kamtorn)
├── TOOLS.md                         # Development setup reference
├── AGENTS.md                        # Agent management rules
├── HEARTBEAT.md                     # Periodic health checks
├── BOOTSTRAP.md                     # (Deleted after first run)
│
├── data/
│   ├── morpheus.db                  # SQLite KB + search index
│   ├── knowledge-base/              # KB JSON documents
│   │   ├── azure-foundry-guide.json
│   │   ├── fusion-agent-studio-azure-foundry.json
│   │   ├── oracle-fusion-agent-studio-azure-llm.json
│   │   └── [6 more KB docs]
│   ├── rl/                          # Q-learning data
│   │   ├── rl-agent-selection.json
│   │   ├── rl-task-execution-log.jsonl
│   │   └── rl-prediction-log.jsonl
│   ├── feedback-logs/               # User feedback trail
│   ├── collaboration-graph.json     # Agent pair analysis
│   └── kb_search_cache.json         # Search optimization
│
├── scripts/
│   ├── ml/                          # Machine learning
│   │   ├── unified-learning-system.jl      # P0+P1+P2 orchestrator
│   │   ├── feedback-validator.jl           # P0: Q-learning
│   │   ├── collaboration-graph.jl          # P1: Agent pairs
│   │   ├── knowledge-extractor.jl          # P2: Patterns
│   │   ├── agent-spawner-qp.jl             # Quality predictor CLI
│   │   ├── spawner-sandboxed.jl            # Container sandbox
│   │   └── QualityPredictor.jl             # Core prediction engine
│   ├── db/
│   │   ├── phase7b-sqlite-adapter.py       # Hourly insights
│   │   ├── kb-integration-sqlite.jl        # KB queries
│   │   └── kb-rag-injector.jl              # RAG context
│   └── workflows/
│       ├── code-review-qp.sh
│       ├── research-qp.sh
│       └── security-audit-qp.sh
│
├── configs/
│   ├── sandbox-default.toml         # Container limits
│   └── phase7b-sqlite-schema.sql    # KB schema
│
├── docs/
│   ├── LEARNING-SYSTEM.md           # P0+P1+P2 pipeline
│   ├── KB-UPDATE-GUIDE.md           # 6 methods to update KB
│   ├── SETUP-GUIDE.md               # This file
│   └── [Phase documentation]
│
├── memory/
│   ├── 2026-04-04-*.md              # Daily logs (59 files)
│   ├── CONSOLIDATED-INDEX.md        # Navigation
│   └── heartbeat-state.json         # Check tracking
│
├── MORPHEUS-KB-FIRST.md             # KB search protocol
├── MORPHEUS-KB-VERIFICATION.md      # Freshness checking
├── SCOUT-KB-FIRST.md                # Research optimization
│
└── .git/                            # 100+ commits, clean history
```

---

## Phase 0-1: Initial Agent Setup

### 1.1 Install OpenClaw & Configure Gateway

```bash
# Install CLI
npm install -g openclaw

# Initialize workspace
openclaw status

# Configure gateway (loopback-only for local work)
openclaw gateway install --force
openclaw gateway start

# Verify
openclaw status  # Should show: Gateway running, RPC OK
```

**Outcome:** Gateway running on `127.0.0.1:18789`

### 1.2 Initialize Git Repository

```bash
cd ~/.openclaw/workspace
git init
git remote add origin https://github.com/KamNoob/workspace.git
git config user.name "Claude Code"
git config user.email "claude@anthropic.com"
```

**Outcome:** Clean git history, ready for commits

### 1.3 Create Core Configuration Files

Create these files:

**SOUL.md** — Your philosophy & approach
```markdown
# SOUL.md - Who You Are

Be genuinely helpful, not performatively helpful.
Have opinions. Be resourceful.
Earn trust through competence.
```

**USER.md** — Profile of your human (Art/Kamtorn)
```markdown
# USER.md - About Your Human

- Name: Kamtorn (goes by Art)
- Role: Data Engineer exploring AI
- Timezone: Europe/London
```

**IDENTITY.md** — Team roster & agent roles
```markdown
# IDENTITY.md - Lead Orchestrator

- Morpheus (Lead): Orchestration, strategy
- Scout: Research, web search, analysis
- Codex: Development, debugging
- Cipher: Security audits
- [... 8 more agents]
```

**Outcome:** Identity established, team defined

---

## Phase 1-6: Core Agent System (Weeks 1-2, 2026-03-09 to 2026-03-23)

### 2.1 Install Julia & ML Runtime

```bash
# Install Julia via snap
sudo snap install julia --classic

# Verify
julia --version  # Should show: julia version 1.12.5+

# Create symlink for convenience
sudo ln -s /snap/julia/165/bin/julia /usr/local/bin/julia
```

**Outcome:** Julia runtime ready for ML scripts

### 2.2 Build Agent Quality Prediction System

**Files created:**
- `scripts/ml/QualityPredictor.jl` — Core prediction engine
- `scripts/ml/agent-spawner-qp.jl` — CLI for agent selection
- `data/rl/rl-agent-selection.json` — Q-learning profiles

**Concept:** Use Q-learning to predict which agent is best for a given task.

```bash
# Test agent selection
julia scripts/ml/agent-spawner-qp.jl --task code --candidates "Codex,QA,Veritas"
# Output: "Codex (Q=0.7244)" — highest Q-value wins
```

**Key Metrics Created:**
- Task types: code, security, research, infrastructure, documentation, review, testing, optimization, compliance, training
- Agent pool: Scout, Codex, Cipher, Sentinel, Chronicle, Lens, Veritas, Echo, QA, Prism
- Q-learning: TD(λ) update rule, 240 agent-task pairs

**Outcome:** Agent routing system operational, Q-scores initialized

### 2.3 Setup Memory Optimizer (Phase 2b)

**Files created:**
- `data/rl/rl-agent-selection.json` — Q-value storage
- `.memory-optimizer-state.json` — Performance tracking
- `memory/heartbeat-state.json` — Periodic check state

**Features:**
- Recall rate: 98% accuracy (139/142 successful)
- Lookup time: 2ms average
- Q-learning with TD(λ): Values converging toward optimal

```bash
# Check memory optimizer
cat .memory-optimizer-state.json | jq '.stats'
# Output: { "total_recalls": 142, "failed": 3, "avg_lookup_ms": 2.0 }
```

**Outcome:** Memory system online, Q-learning active

### 2.4 Setup Learning Pipeline (P0+P1+P2)

**Phase 0 (Feedback Validator):**
- User feedback → Q-learning updates
- 6-hour cycle
- File: `scripts/ml/feedback-validator.jl`

**Phase 1 (Collaboration Detection):**
- Agent pair performance analysis
- Identifies high-performing combos
- File: `scripts/ml/collaboration-graph.jl`

**Phase 2 (Knowledge Extraction):**
- Task outcomes → reusable patterns
- Pattern database for warm-start
- File: `scripts/ml/knowledge-extractor.jl`

**Orchestrator (Unified System):**
- File: `scripts/ml/unified-learning-system.jl`
- Daily 03:00 UTC full cycle
- Cron job: `49f85737-b6bf-4255-ba70-43bdefca282d`

```bash
# Run learning system
julia scripts/ml/unified-learning-system.jl --report

# Check outcomes
tail -20 data/rl/rl-task-execution-log.jsonl
```

**Outcome:** P0+P1+P2 pipeline live, learning continuously

---

## Phase 7B: Learning Pipeline & SQLite Migration (2026-03-28)

### 3.1 Migrate KB to SQLite

**Problem:** JSON KB was growing, queries slow (5-10ms)

**Solution:** SQLite with FTS (full-text search)

**Files:**
- `data/morpheus.db` — SQLite database (1.0 MB)
- `scripts/db/phase7b-sqlite-adapter.py` — Hourly indexing
- `configs/phase7b-sqlite-schema.sql` — Database schema

**Schema:**
```sql
CREATE TABLE kb_documents (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    content TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE VIRTUAL TABLE kb_search USING fts5(
    name, content, metadata
);
```

**Performance:**
- Query time: <1ms (vs 5-10ms JSON)
- Phase 7B runtime: <500ms (vs 2-3s)
- FTS enabled: Full-text search operational

```bash
# Query KB via SQLite
python3 scripts/db/phase7b-sqlite-adapter.py

# Check DB health
sqlite3 data/morpheus.db ".tables"
# Output: kb_documents kb_search kb_search_idx kb_search_content
```

**Outcome:** SQLite KB migration complete, 10x performance improvement

### 3.2 Setup Hourly Insights Cycle

**Cron job:** Phase 7B SQLite Adapter  
**Frequency:** Every hour (e.g., 10:02, 11:02, 12:02 UTC)  
**Purpose:** Analyze outcomes, generate insights, update KB

**Process:**
1. Query task execution log (rl-task-execution-log.jsonl)
2. Aggregate outcomes by agent/task
3. Update Q-learning scores
4. Index new KB documents
5. Generate insights report

**Outcome:** Hourly automated analysis active

---

## Phase 11A/B/C: Audit & Compliance (2026-03-23)

### 4.1 Audit Logging System

**Files:**
- `data/audit-log.jsonl` — All system operations logged
- `scripts/audit/generate-report.jl` — Monthly reports
- Cron job: `a1c1f39c-2c30-473a-9894-03c7e06e64ee` (hourly)

**Logged Events:**
- Agent spawning (who, when, task, result)
- Q-learning updates (score changes)
- KB modifications (docs added/updated)
- System errors and warnings
- User feedback recorded

**Format:**
```json
{
  "timestamp": "2026-04-04T16:02:00Z",
  "event": "phase7b_cycle",
  "agents_updated": 12,
  "outcomes_processed": 8,
  "kb_indexed": 2,
  "status": "ok"
}
```

**Outcome:** Full audit trail, compliance ready

### 4.2 SLA Monitoring

**Thresholds:**
- Agent success rate > 85%
- Memory recall > 97%
- Q-learning convergence healthy
- Gateway uptime > 99.9%

**Monitoring:** HEARTBEAT.md checks, weekly Q-score review

**Outcome:** SLA monitoring active, alerting configured

---

## Phase 12A: Multi-Agent Production (2026-04-03 23:28 UTC)

### 5.1 Scale from 11 to 20 Agents

**Original Agents (11):**
- Scout (research): Q=0.8476
- Cipher (security): Q=0.8500
- Veritas (review): Q=0.7771
- Codex (code): Q=0.7244
- QA (testing): Q=0.7000
- Chronicle (documentation): Q=0.6263
- Sentinel (infrastructure): Q=0.5561
- Navigator, Lens, Prism, Echo

**New Agents (9, cold start Q=0.5):**
- Navigator-Ops: Optimization specialist
- Analyst-Perf: Performance & compliance
- Ghost: (TBD)
- Triage: Task routing
- Mentor: Training & guidance
- + 4 more

**Total: 20 agents in production, 240 agent-task pairs**

**Outcome:** Agent pool scaled, Q-learning active for all

### 5.2 Container Sandboxing for Security

**Problem:** 20 agents need isolation, resource limits, security

**Solution:** Docker containers with capability dropping

**Implementation:**
- Image: `myclaw:agent-latest` (1.23 GB)
- Base: Julia + minimal deps
- Spawner: `scripts/ml/spawner-sandboxed.jl`
- Config: `configs/sandbox-default.toml`

**Security Features:**
- Unprivileged user (no root)
- Capability dropping (drop CAP_NET_ADMIN, etc.)
- Filesystem isolation (bind mount to workspace only)
- Network disabled (no external connections)
- Resource limits: 2GB RAM, 2 CPU, 30min timeout
- Read-only root filesystem

**Validation Tests:**
1. Container startup: ✅
2. Network isolation: ✅
3. Resource limits: ✅
4. Integration with spawner: ✅

**All 4 tests passed before launch**

```bash
# Build sandbox image
docker build -t myclaw:agent-latest .

# Spawn agent in sandbox
julia scripts/ml/spawner-sandboxed.jl --agent Codex --task code
```

**Outcome:** Sandboxing complete, 20 agents secure

### 5.3 Post-Launch Optimization Roadmap

**P0 (This week):**
- Validation gateway (prevent failed spawns)

**P1 (Week 1-2):**
- Container pool reuse (-400ms/task)
- Sandbox profiles (-50% memory)

**P3 (Week 2-3):**
- Parallel spawning (4x batch throughput)

**Outcome:** Phase 12A live, optimizations queued

---

## KB System (2026-04-04)

### 6.1 Knowledge Base Architecture

**Overview:**
- SQLite database: `data/morpheus.db` (1.0 MB)
- JSON source docs: `data/knowledge-base/*.json` (9 documents)
- Synced and indexed, FTS enabled
- Phase 7B auto-indexes hourly

**Current KB Documents (9):**

| Name | Size | Added | Purpose |
|------|------|-------|---------|
| azure-foundry-guide.json | 9.0 KB | 2026-04-04 | Azure Foundry quickstart + examples |
| fusion-agent-studio-azure-foundry.json | 8.2 KB | 2026-04-04 | Fusion Agent Studio integration |
| oracle-fusion-agent-studio-azure-llm.json | 5.0 KB | 2026-04-04 | Oracle Fusion + Azure setup |
| extracted-patterns.json | — | 2026-03-28 | Task outcome patterns (P2) |
| nikola-tesla-verified.json x2 | — | Historical | Historical reference |
| tesla-369.md | — | Historical | Tesla biography |
| knowledge-base.json | — | Base | Core KB index |

**Query Performance:**
- Freshness check: <1ms
- Keyword search: <2ms
- FTS search: <2ms
- Total lookup: ~2ms average

**Outcome:** KB operational, 9 documents, SQLite indexed

### 6.2 KB-First Search Protocol (2026-04-04 16:25 UTC)

**What Changed:**
1. **Morpheus KB-first:** Search KB before web
2. **Scout KB-first:** Research agent optimized for KB + web synthesis
3. **Verification protocol:** Always check KB freshness before answering

**Implementation:**
- File: `MORPHEUS-KB-FIRST.md` (protocol documentation)
- File: `MORPHEUS-KB-VERIFICATION.md` (freshness checks)
- File: `SCOUT-KB-FIRST.md` (agent optimization)
- Updated: `SOUL.md` + `IDENTITY.md`

**Freshness Rules:**
- < 1 week old: Use KB directly
- 1-2 weeks old: Use KB + verify with web
- 2-4 weeks old: Use KB as foundation, supplement with web
- > 1 month old: Web search only

**Fast-Changing Topics (Always Verify):**
- Security (CVEs, vulnerabilities)
- Pricing (cloud costs, subscriptions)
- Current events (news, releases)
- API changes (platform updates)

**Stable Topics (KB Safe):**
- Historical facts
- Architecture patterns
- Best practices
- Theory/education

**Outcome:** KB-first protocol active, freshness verified

### 6.3 KB Update Methods (6 Available)

**Method 1: JSON + Import (5 minutes)**
```bash
# 1. Edit data/knowledge-base/myguide.json
# 2. Import to SQLite
python3 scripts/db/phase7b-sqlite-adapter.py --import myguide.json
# 3. Commit
git add data/knowledge-base/myguide.json
git commit -m "docs: Add myguide to KB"
```

**Method 2: SQL Direct (2 minutes)**
```bash
# Fast correction for existing docs
sqlite3 data/morpheus.db "UPDATE kb_documents SET content = '...' WHERE name = 'doc'"
git add data/morpheus.db
git commit -m "fix: KB update via SQL"
```

**Methods 3-6:** Advanced (RAG, batch, API, cron-scheduled)

**See:** `docs/KB-UPDATE-GUIDE.md` for full details

**Outcome:** 6 KB update methods available

---

## Verification & Testing

### 7.1 System Health Checks

**Daily (Morning):**
```bash
openclaw status              # Gateway, sessions, config
openclaw gateway status      # Loopback, RPC, token
```

**Weekly:**
```bash
# Q-Scores
cat data/rl/rl-agent-selection.json | jq '.task_types | to_entries[] | select(.value.agents != null)'

# Memory optimizer
cat .memory-optimizer-state.json | jq '.stats'

# KB freshness
sqlite3 data/morpheus.db "SELECT name, date(updated_at) FROM kb_documents ORDER BY updated_at DESC"
```

**Cron Cycles:**
```bash
# Phase 7B (hourly) — Last execution
tail -1 data/phase7b-executions.log

# P0 Feedback (6h) — Last execution
tail -1 data/feedback-validator-executions.log

# Unified Learning (daily 03:00 UTC) — Last execution
tail -1 data/learning-system-executions.log
```

### 7.2 Testing Workflows

**Code Review (Codex + Veritas):**
```bash
./scripts/workflows/code-review-qp.sh "my feature" medium
```

**Research (Scout):**
```bash
./scripts/workflows/research-qp.sh "my topic" standard
```

**Security Audit (Cipher):**
```bash
./scripts/workflows/security-audit-qp.sh "my service" full
```

**Outcome:** Workflows operational, testing on-demand

### 7.3 Success Metrics

**Agent Performance:**
- Scout: 100% success rate (17/17 outcomes), Q=0.8476
- Cipher: High success rate, Q=0.8500
- Veritas: 100% success rate (12/12 outcomes), Q=0.7771
- Codex: 88.9% success rate (8/9 outcomes), Q=0.7244

**System Metrics:**
- Memory recall: 97.9% (139/142 successful)
- Lookup time: 2ms average
- Gateway uptime: 100% since 2026-04-01
- Q-learning: 15 top agent-task pairs converging
- KB: 9 documents, <2ms query time

**Cost (7-day window):** $0.00 (local system)

**Outcome:** All metrics green, system healthy

---

## Troubleshooting

### Gateway Connection Error

**Symptoms:** "Connection refused" on port 18789

**Fix:**
```bash
openclaw gateway restart
# Wait 5 seconds
openclaw status
```

### Memory Recall Low (< 95%)

**Symptoms:** Memory optimizer showing <95% success

**Fix:**
```bash
# Consolidate memory
julia scripts/ml/unified-learning-system.jl --consolidate

# Verify
cat .memory-optimizer-state.json | jq '.stats.recall_rate'
```

### Q-Learning Stuck (All Scores 0.5)

**Symptoms:** All Q-values near 0.5, not converging

**Fix:**
```bash
# Check feedback log
tail -20 data/rl/rl-task-execution-log.jsonl

# Manually trigger learning cycle
julia scripts/ml/unified-learning-system.jl --force

# Verify scores
cat data/rl/rl-agent-selection.json | jq '.task_types.code.agents | sort_by(.q) | .[-5:]'
```

### Phase 7B Cycle Failed

**Symptoms:** Hourly cycle missing, KB not updated

**Fix:**
```bash
# Check logs
tail -20 /tmp/openclaw/openclaw-*.log | grep phase7b

# Manual run
python3 scripts/db/phase7b-sqlite-adapter.py --verbose

# Re-schedule cron
openclaw cron run <job-id>  # Job ID from: openclaw cron list
```

### KB Document Not Searchable

**Symptoms:** New KB doc added, but not appearing in searches

**Fix:**
```bash
# Re-index KB
python3 scripts/db/phase7b-sqlite-adapter.py --reindex

# Verify
sqlite3 data/morpheus.db "SELECT COUNT(*) FROM kb_search WHERE name LIKE '%mydoc%'"
```

---

## Next Steps & Roadmap

### Immediate (Week 1-2)
- [x] Phase 12A validation gateway
- [ ] Container pool reuse optimization
- [ ] Sandbox profile tuning (-50% memory)

### Q2 2026 (Phase 13)
- Autonomous task routing (agents self-negotiate)
- Multi-agent consensus voting
- Emergent task categorization

### Q3 2026 (Phase 14)
- Multi-tenant scaling (team instances)
- Fine-tuning with Unsloth
- Knowledge distillation

### Q4 2026 (Phase 15)
- Knowledge emergence (novel agent archetypes)
- Self-healing system (automated fixes)
- Recursive self-improvement

---

## Quick Reference

### Commands

```bash
# System Status
openclaw status
openclaw gateway status

# Agent Selection
julia scripts/ml/agent-spawner-qp.jl --task code --candidates "Codex,QA"

# Learning System
julia scripts/ml/unified-learning-system.jl --report

# KB Queries
python3 scripts/db/phase7b-sqlite-adapter.py
sqlite3 data/morpheus.db "SELECT * FROM kb_documents"

# Memory Check
cat .memory-optimizer-state.json | jq '.stats'

# Git Status
git status
git log --oneline -10

# Cron Jobs
openclaw cron list
openclaw cron run <job-id>

# Workflows
./scripts/workflows/code-review-qp.sh "feature" medium
./scripts/workflows/research-qp.sh "topic" standard
./scripts/workflows/security-audit-qp.sh "service" full
```

### Important Files

| File | Purpose |
|------|---------|
| SOUL.md | Philosophy & approach |
| IDENTITY.md | Team roster & agents |
| MEMORY.md | Long-term memory |
| HEARTBEAT.md | Health check schedule |
| TOOLS.md | Development setup |
| data/morpheus.db | KB + search index |
| data/rl/rl-agent-selection.json | Q-learning scores |
| scripts/ml/unified-learning-system.jl | P0+P1+P2 pipeline |
| scripts/db/phase7b-sqlite-adapter.py | Hourly insights |
| docs/KB-UPDATE-GUIDE.md | KB management |
| docs/LEARNING-SYSTEM.md | P0+P1+P2 details |

### Cron Jobs

| Job | Frequency | Purpose |
|-----|-----------|---------|
| Phase 7B SQLite | Hourly (:02) | KB indexing, insights |
| P0 Feedback | Every 6h | Q-learning updates |
| Unified Learning | Daily 03:00 UTC | Full P0+P1+P2 cycle |
| Audit Report | Monthly | Compliance reporting |
| Weekly Tests | Friday 09:00 UTC | Agent validation |

---

## Conclusion

You now have a production-grade multi-agent system with:

✅ **20 agents** distributed across 12 task types  
✅ **Q-learning routing** (optimal agent selection)  
✅ **Continuous learning** (P0 feedback, P1 collaboration, P2 patterns)  
✅ **Audit compliance** (full logging, SLA monitoring)  
✅ **Container security** (sandboxing, isolation, resource limits)  
✅ **Knowledge base** (9 docs, SQLite FTS, KB-first search)  
✅ **Automated workflows** (code review, research, security)  

**System Status:** ✅ **PHASE 12A LIVE** (2026-04-03 23:28 UTC)

**Metrics (as of 2026-04-04 17:30 UTC):**
- Memory: 97.9% recall, 2ms lookup
- Q-Learning: 15 top pairs, avg Q=0.548
- Gateway: 100% uptime since 2026-04-01
- KB: 9 documents, <2ms queries
- Sandboxing: 20 agents secure, resource-limited

---

_Setup Guide v1.0_  
_Created: 2026-04-04 17:30 GMT+1_  
_Based on: 100+ commits, 6 weeks of development, 3 major phases_  
_Next: Finalize Phase 12B optimizations, begin Phase 13 planning_
