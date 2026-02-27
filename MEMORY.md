# Memory System

## Three Independent Systems

**1. memorySearch (Workspace Files)**
- Local embeddings: EmbeddingGemma 300M (GGUF) at `~/.openclaw/models/embeddings/`
- Searches: SOUL.md, MEMORY.md, daily notes
- Cost: $0
- Performance: 5-10 min first index (cold), 3.5s cached

**2. memory-lancedb (Conversation Memory)**
- Embeddings: OpenAI text-embedding-3-small (hardcoded, cloud-only)
- Storage: LanceDB vector database at `~/.openclaw/memory/lancedb/`
- Cost: ~$0.02-0.05/month (or $0 if disabled)
- Schema: Flat structure only (OpenAI-only, no custom fallback chains)
- Status: autoCapture/autoRecall disabled (API quota exhausted)

**3. memory-optimizer (RL Prioritization)**
- Algorithm: Q-Learning + TD(λ), α=0.01, γ=0.99, λ=0.9
- Tracks: Memory value via Q-scores; learns from usage patterns
- Cost: $0 (local, in-memory)
- State persisted: `.memory-optimizer-state.json`

## System Configuration

- **Initialized:** 2026-02-23
- **Active:** All three operational (memory-lancedb auto-features disabled)
- **Architecture:** Hybrid (local + cloud, independent systems)
- **Note:** Not a fallback chain; each system serves separate purpose

## User Profile

- **Name:** Art
- **Timezone:** Europe/London
- **Primary interface:** WhatsApp
- **Preferred model:** Claude 3 Haiku (autonomous switching allowed)
- **Identity:** Morpheus 🕶️
- **Vibe:** Calm, authoritative, concise, distinct

## System Status

- **Gateway:** Auto-startup enabled (tested via reboot)
- **Cron jobs:** 2 active (Overdue alerts, security scans) — Notion syncs removed
- **Sub-agent tools:** web_fetch enabled
- **Security:** SSH, RDP, MySQL, PostgreSQL open locally; UFW not installed

## OpenClaw

- **Version:** v2026.2.2-3 (latest: v2026.2.17)
- **Update frequency:** Every few days to a week
- **Haiku:** Primary model with Sonnet/Gemini fallbacks

## Agent Collective (Subagents)

Spawned as one-shot tasks (mode=run). Each completes task and reports.

- **Codex** — Backend, Frontend, Code Review, Testing
- **Cipher** — Security Audit, Vulnerability Assessment
- **Scout** — Research, Analysis, Documentation
- **Chronicle** — Documentation, Technical Writing
- **Sentinel** — Infrastructure, Automation, Monitoring
- **Lens** — Data Analysis, Metrics, Insights
- **Echo** — Brainstorming, Design Thinking
- **Veritas** — Verification, Source Validation, Fact-Checking
- **Tester** — Testing, QA, Validation

## Configuration

- **Environment file:** ~/.openclaw/.env (auto-loaded by OpenClaw)
- **Config file:** ~/.openclaw/openclaw.json (manual JSON edits most reliable)
- **API keys:** All migrated to environment variables
- **Gateway:** localhost:18789, auth via gateway token

## Morpheus Working Notes

### Session Health & Context Management (2026-02-27)
- **Decision:** Auto-reset sessions when approaching context window limit
- **Trigger:** 90K+ tokens (80% of Haiku 4.5's safe estimate)
- **Behavior:** Announce reset, summarize state, spawn continuation automatically
- **Implementation:** Monitored during active multi-step tasks
- **User action:** None required; seamless across sessions

### Art's Preferences (Session 2026-02-25)

1. **Action > Permission** — Announce the plan, then execute with confidence. Don't ask "would you like me to...?" unless there's real uncertainty.
2. **Concise > Thorough** — Summaries, not essays. Get to the point.
3. **Decides for himself** — Doesn't need hedging or hand-holding. Use judgment, tell him what you're doing.
4. **Values safety audits** — Before external actions, scope the risks explicitly. But do the audit, don't just propose it.
5. **Practical > Theoretical** — Ship something, show results. Skip the philosophy.

### Learned Behaviors
- Proactivity beats politeness
- Update MEMORY.md after significant sessions to build continuity
- Flag uncertainty explicitly; don't waffle
- Don't assume causation — verify before claiming something worked
- Security discipline: be transparent about actions, not paralyzed by caution
- Only block myself if there's genuine risk; otherwise announce and let Art decide
- **Verify completion indicators** — All agents must report back via system messages, not just exist in session logs
- Pay attention to patterns: if 5 agents delivered but 3 didn't, that's a problem to flag immediately

## Current Projects (Session 2026-02-26)

### Commander Project ✅ LIVE & ORGANIZED
- **Project Root:** ~/projects/commander/
- **Dashboard Location:** ~/projects/commander/commander-dashboard/
- **API Location:** ~/projects/commander/projects-tasks-api/
- **URL:** http://100.92.181.22:3000 (Tailscale)
- **Tech:** React + Vite (frontend) | Node/Express (backend)
- **Status:** Both running, fully integrated

### Frontend: Commander Dashboard ✅
- **Tech:** React 18 + Vite + TypeScript + Tailwind CSS
- **Port:** 3000 (Tailscale) / 5173 (Vite dev)
- **Features:** Agent roster, projects view, project detail, responsive UI
- **Data Source:** http://localhost:4000/api/projects

### Backend: Projects/Tasks API ✅
- **Tech:** Node/Express
- **Port:** 4000
- **Mode:** In-memory (production-ready)
- **Data:** 4 projects + 4 tasks (sample)
- **Endpoints:** All CRUD ops tested ✓
- **Response time:** <50ms per request

### Deployment & Documentation
- **Systemd Services:** commander-api.service, commander-dashboard.service
- **Database:** In-memory (temp) + PostgreSQL setup script ready
- **Documentation:** 
  - README.md — Project overview & quick start
  - API.md — Full endpoint reference
  - ARCHITECTURE.md — System design & data models
  - DEPLOYMENT.md — Setup & deployment guide
  - commander-dashboard/README.md — Frontend guide

### Validation Results (Tester, 2026-02-26 09:00)
✅ All API endpoints functional
✅ All CRUD operations working
✅ Error handling graceful
✅ Dashboard HTTP 200, rendering
✅ API response time <100ms
✅ Project data persisting across requests

**Final Status: PRODUCTION READY** 🚀
- Dashboard: http://100.92.181.22:3000 (React + Vite, Tailscale live)
  - Local dev: http://localhost:5173
  - All features working (agent roster, projects view, detail page)
- API: http://localhost:4000 (Node/Express, in-memory mode, validated)
  - All CRUD endpoints tested ✓
  - Sub-100ms response times
  - 4 projects + 4 tasks
- Location: ~/projects/
- Deployment docs: ~/projects/DEPLOYMENT.md
- Database: In-memory (temporary, fully functional)
  - PostgreSQL setup script available (setup-postgres.sql) for optional migration later

### Documentation & Structure (Session 2026-02-26)

**Core Files (Best Practices Aligned):**
✅ .gitignore — Git ignore rules (node_modules, .env, dist, logs)
✅ LICENSE — MIT License for open sharing
✅ CHANGELOG.md — Version history and release notes
✅ CONTRIBUTING.md — Contribution guidelines for team

**Documentation (Organized in /docs):**
✅ README.md — Project overview & quick start
✅ API.md — Full endpoint reference with examples
✅ ARCHITECTURE.md — System design, data models, networking
✅ DEPLOYMENT.md — Setup guide, systemd, database, troubleshooting

**Scripts (Organized in /scripts):**
✅ setup-dev.sh — Initial development environment setup
✅ start-dev.sh — Start both services (API + Dashboard)
✅ stop-dev.sh — Stop development services
✅ health-check.sh — Monitor health of both services
✅ deploy.sh — Deploy to systemd (production)

**Deployment Files (Organized in /docs/deployment):**
✅ /systemd/commander-api.service — API systemd unit
✅ /systemd/commander-dashboard.service — Dashboard systemd unit
✅ /postgres/setup-postgres.sql — Optional PostgreSQL setup

**Configuration:**
✅ .env.example (backend) — Template for environment variables
✅ README.md files in each component

**Project Root Structure:**
```
~/projects/commander/
├── .gitignore, LICENSE, CHANGELOG.md, CONTRIBUTING.md
├── README.md, docs/, scripts/
├── commander-dashboard/, projects-tasks-api/
```
