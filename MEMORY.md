# MEMORY.md - Long-Term Memory (Condensed)

Last updated: 2026-04-03 23:28 UTC — Phase 12A Production Launch + Memory Condensation  
Status: ✅ PHASE 12A LIVE | SYSTEM STABLE | ALL CHECKS PASSED

---

## SYSTEM STATUS (Current)

| Component | Status | Detail |
|-----------|--------|--------|
| Gateway | ✅ Running | Port 18789, 100% uptime since 2026-04-01 |
| WhatsApp | ⚠️ Disabled | Auth issue pending fix |
| Memory | ✅ Healthy | 97.9% recall, 2ms avg lookup |
| Q-Learning | ✅ Converging | All task types active |
| Phase 7B | ✅ Live | Hourly SQLite adapter running |
| Phase 12A | ✅ **LAUNCHED** | 2026-04-03 23:28 UTC |
| Sandboxing | ✅ Live | myclaw:agent-latest, Docker isolation |

---

## PHASE 12A LAUNCH (2026-04-03 23:28 UTC)

**20 agents in production. Container sandboxing enabled.**

### Agent Q-Scores at Launch

| Agent | Domain | Q-Score | Success Rate | Status |
|-------|--------|---------|--------------|--------|
| Cipher | security | 0.8500 | High | ⭐ Lead |
| Scout | research | 0.8476 | 100% (17/17) | ⭐ Lead |
| Veritas | review | 0.7771 | 100% (12/12) | ⭐ Lead |
| Codex | code | 0.7244 | 88.9% (8/9) | ✅ Strong |
| QA | testing/review | 0.7000 | — | ✅ Strong |
| Chronicle | documentation | 0.6263 | — | ✅ Good |
| Sentinel | infrastructure | 0.5561 | — | ✅ Baseline |
| Navigator-Ops | optimization | 0.5000 | Cold start | 🆕 New |
| Analyst-Perf | compliance | 0.5000 | Cold start | 🆕 New |
| Ghost | — | 0.5000 | Cold start | 🆕 New |
| Triage | — | 0.5000 | Cold start | 🆕 New |
| Mentor | training | 0.5000 | Cold start | 🆕 New |
| + 4 others | TBD | 0.5000 | Cold start | 🆕 New |

### Container Sandboxing (Implemented Tonight)
- **Image:** `myclaw:agent-latest` (1.23 GB, Julia + minimal deps)
- **Config:** `configs/sandbox-default.toml` (2GB mem, 2 CPU, no network, 30min timeout)
- **Spawner:** `scripts/ml/spawner-sandboxed.jl`
- **Security:** Capability dropping, unprivileged user, filesystem isolation
- **Validation:** All 4 tests passed (containers, network isolation, resource limits, integration)
- **Commits:** a586642, bae4c08, b4fc38b

### Post-Launch Optimization Roadmap
| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| P0 | Validation gateway | 30 min | Prevent failed spawns |
| P1 | Container pool reuse | 2h | -400ms/task |
| P2 | Sandbox profiles | 1.5h | -50% memory |
| P3 | Parallel spawning | 1.5h | 4x batch throughput |

---

## ARCHITECTURE OVERVIEW

### Agent Team (20 agents)
**Established (11):** Scout, Veritas, Codex, Cipher, Sentinel, Chronicle, Lens, Navigator, QA, Prism, Echo  
**New Phase 12A (9):** Navigator-Ops, Analyst-Perf, Ghost, Triage, Mentor + 4 others

**Task Types (12):** research, code, security, infrastructure, analysis, documentation, review, testing, optimization, compliance, training + 1 more

**Learning:** Q-learning with TD(λ), 240 agent-task pairs, hourly feedback loop (Phase 7B)

### Infrastructure
- **OpenClaw Gateway:** Port 18789, loopback
- **Julia:** 1.12.5 (snap install)
- **Python:** 3.12.3
- **Node:** v24.11.0
- **Docker:** Running, myclaw:agent-latest built
- **Git:** Active, clean history

### Learning Pipeline (P0+P1+P2 — Live)
- **P0 Feedback Validator:** User feedback → Q-learning (every 6h)
- **P1 Collaboration Graph:** Agent pair detection
- **P2 Knowledge Extractor:** Pattern synthesis from outcomes
- **Unified:** Daily 03:00 UTC full cycle

### SQLite Migration (Phase 7B)
- Schema V3 production-ready
- Query performance: <1ms (was 5-10ms)
- Phase 7B runtime: <500ms (was 2-3s)

---

## KEY DECISIONS LOG

| Date | Decision | Reason |
|------|----------|--------|
| 2026-04-03 | Phase 12A launched with container sandboxing | Sandboxing complete, all 4 tests passed, 92% confidence |
| 2026-04-03 | Keep bind mounts (not Docker volumes) | Simpler, debuggable, host filesystem access |
| 2026-03-29 | Disabled WhatsApp (flapping) | Auth validation issue, gateway stability priority |
| 2026-03-29 | Container sandboxing added as Phase 12A blocker | Security required for 20-agent scale |
| 2026-03-29 | OpenJarvis evaluated — not adopted | Your system more specialized; stole container pattern only |
| 2026-03-29 | Unsloth fine-tuning deferred to Phase 14-15 | Q-learning routing superior for now; no GPU |
| 2026-03-29 | Gateway service secrets removed | Found 7 embedded API keys in systemd service file |
| 2026-03-28 | SQLite migration for Phase 7B | 10x query performance improvement |
| 2026-03-28 | Legacy data ingestion (28 outcomes) | Warm-start Q-learning with 6 weeks of history |
| 2026-03-23 | Phase 12A Week 1 deployed (5 new agents) | Team scaling from 11→20 agents |
| 2026-03-09 | Removed Qdrant (redundant with OpenClaw memorySearch) | Eliminated unnecessary complexity |
| 2026-03-09 | Disabled Notion sync (3 cron jobs) | No longer needed, reduces complexity |

---

## PHASE ROADMAP

| Phase | Status | Description |
|-------|--------|-------------|
| 1-6 | ✅ Complete | Core agent system, Q-learning, memory |
| 7B | ✅ Live | SQLite adapter, hourly insights |
| 11A/B/C | ✅ Live | Audit logging, SLA monitoring, compliance |
| 12A | ✅ **LAUNCHED** | 20 agents, container sandboxing |
| 12B | ⏳ Planned | Agent pair optimization |
| 12C | ⏳ Planned | Cross-agent knowledge sharing |
| 13 | 🔭 Q2 2026 | Autonomous task routing (agents self-negotiate) |
| 14 | 🔭 Q3 2026 | Multi-tenant scaling (team instances) |
| 15 | 🔭 Q4 2026 | Knowledge emergence (novel agent archetypes) |

---

## HEARTBEAT STATE

| Check | Frequency | Last Run | Next Due |
|-------|-----------|----------|----------|
| Gateway & Messaging | Daily | 2026-04-01 | 2026-04-04 (tomorrow) |
| Memory & Learning | Wed/Sun | 2026-04-01 | 2026-04-05 (Sun) |
| Agent Performance | Friday | 2026-04-03 | 2026-04-10 |
| Memory Maintenance | Sunday | 2026-04-01 | 2026-04-05 (Sun) |
| Infrastructure & Syncs | Monday | 2026-03-31 | 2026-04-06 (Mon) |

---

## ART'S PREFERENCES (Operational)

- **Truth over comfort** — Direct feedback, no softening (directive 2026-03-20)
- **No bloat** — Minimal dependencies, elegant solutions
- **Evidence-based** — Measure before scaling
- **Fast iteration** — Prototype, test, ship
- **Automation that works** — Not "almost" automation
- **Complete work** — Half-baked solutions get deleted

---

## BACKLOG

| Item | Priority | Notes |
|------|----------|-------|
| P0: Validation gateway | High | 30 min, this week |
| P1: Container pool | Medium | 2h, week 1-2 post-launch |
| P2: Sandbox profiles | Medium | 1.5h, week 2-3 |
| P3: Parallel spawning | High | 1.5h, week 3-4 |
| WhatsApp re-enable | Medium | Investigate auth token |
| Memory compression | Backlog | 50-80% size reduction |
| Phase 12B | Planned | Agent pair optimization |

---

_Condensed: 2026-04-03 23:28 UTC (84KB → ~5KB, ~94% reduction)_  
_Previous: Full daily log history in memory/YYYY-MM-DD.md files_  
_Next review: Sunday 2026-04-05 (memory maintenance heartbeat)_
