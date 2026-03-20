# SKILLS INVENTORY - Morpheus & Team

Last updated: 2026-03-20 22:28 GMT

---

## 🏗️ CUSTOM IN-HOUSE SKILLS (11 total)

### Core Self-Improving System (Active Daily)

**1. llmfit-infrastructure**
- Purpose: Agent spawning, Q-learning routing, cost optimization
- Core files: spawner-matrix.jl, rl-agent-selection.json
- Used by: Morpheus (all spawning decisions)
- Status: ✅ ACTIVE - Powers Phases 5-7 optimization

**2. memory-optimizer**
- Purpose: Persistent memory optimization with Q-learning + TD(λ)
- Core files: .memory-optimizer-state.json, memory-optimizer.jl
- Used by: Morpheus (session context), Phase 7A learning
- Status: ✅ ACTIVE - Daily optimization

**3. rl-knowledge**
- Purpose: Queryable RL knowledge base (Sutton & Barto 2nd Ed, 548 pages)
- Core files: RL-BOOK-ENHANCED.json, rl-kb.js
- Used by: Scout (research), Codex (ML work)
- Status: ✅ ACTIVE - Ready for context injection

**4. session-logs**
- Purpose: Structured execution logging, audit trails, daily notes
- Core files: memory/*.md, sessions/sessions.json
- Used by: All agents + Morpheus (continuity)
- Status: ✅ ACTIVE - Daily logging system

**5. model-usage**
- Purpose: Cost tracking per model, token accounting
- Core files: data/metrics/*, codexbar JSON
- Used by: Codex, Veritas (cost optimization)
- Status: ✅ AVAILABLE - CLI accessible

### Specialized ML/Analysis (Optional, On-Demand)

**6. monte-carlo-sim**
- Purpose: Uncertainty quantification, probability simulation
- Used by: Optional for complex stochastic tasks
- Status: ✅ AVAILABLE - Ready to use

**7. knowledge-base**
- Purpose: Knowledge indexing, semantic retrieval
- Used by: Phase 7B insights, memory search
- Status: ⚠️ CHECK - May be integrated into memory-optimizer

### Content Processing (Available)

**8. nano-pdf**
- Purpose: Lightweight PDF processing (research papers)
- Used by: Scout, Chronicle (PDF analysis)
- Status: ✅ AVAILABLE - Ready

**9. toon-encoding**
- Purpose: Video encoding, format conversion, transformation
- Used by: Prism (video processing)
- Status: ✅ AVAILABLE - Ready

**10. video-frames**
- Purpose: Extract frames, temporal analysis, thumbnail generation
- Used by: Prism (responsive design, video analysis)
- Status: ✅ AVAILABLE - Ready

**11. nano-banana-pro**
- Purpose: Unknown (legacy?)
- Status: ⚠️ INVESTIGATE - Purpose unclear

---

## 📦 STANDARD SKILLS AVAILABLE (35 total)

Installed but not custom-built. Access via CLI.

### Communication & Messaging (5)
- **bird** — Twitter/X integration
- **imsg** — iMessage integration
- **bluebubbles** — iMessage/SMS via BlueBubbles
- **wacli** — WhatsApp CLI (system integration, not user msgs)
- **slack** — Slack integration

### Note Taking & Knowledge (4)
- **apple-notes** — Apple Notes management
- **bear-notes** — Bear Notes management
- **obsidian** — Obsidian vault (Markdown notes)
- **notion** — Notion workspace integration

### Music & Audio (5)
- **spotify-player** — Spotify integration
- **sonoscli** — Sonos speaker control
- **songsee** — Music discovery/streaming
- **openai-whisper** — Audio transcription (Whisper API)
- **sag** — ElevenLabs text-to-speech

### Automation & Home (5)
- **things-mac** — Things 3 task management
- **trello** — Trello board integration
- **github** — GitHub CLI (issues, PRs, repos)
- **openhue** — Philips Hue lights control
- **eightctl** — Eight Sleep control

### Content & Analysis (5)
- **summarize** — Content summarization (URLs, PDFs, video)
- **build-your-own-x** — 345+ tutorials (databases, web servers, etc.)
- **blogwatcher** — Blog monitoring
- **gifgrep** — GIF search/management
- **peekaboo** — Security/camera monitoring

### Infrastructure & Data (6)
- **himalaya** — Email client CLI
- **goplaces** — Maps/places integration
- **tmux** — Tmux session management
- **1password** — Password/secret management
- **gog** — GOG game library
- **local-places** — Local place data

### Utilities (5)
- **ordercli** — Order management
- **eightctl** — Sleep/health tracking
- **blucli** — Bluetooth CLI
- **camsnap** — Camera snapshots
- **video-frames** — Frame extraction (also custom)

---

## 🤖 AGENT CAPABILITIES

### Morpheus (Lead Orchestrator)
**Specialization:** System routing, decision-making, learning

Skills:
- llmfit-infrastructure (spawn decisions)
- memory-optimizer (context retrieval)
- session-logs (continuity)
- rl-knowledge (decision context)

### Scout (Researcher)
**Specialization:** Research, discovery, analysis

Skills:
- rl-knowledge (RL research papers)
- nano-pdf (PDF analysis)
- summarize (synthesis)
- build-your-own-x (tutorials, learning)
- Slack (publish findings)

### Codex (Developer)
**Specialization:** Implementation, coding, debugging

Skills:
- llmfit-infrastructure (ML projects)
- rl-knowledge (RL implementations)
- model-usage (cost tracking)
- GitHub (PR/issue management)
- session-logs (code traces)

### Veritas (QA/Review)
**Specialization:** Code review, validation, quality

Skills:
- session-logs (test execution traces)
- model-usage (regression cost checking)
- rl-knowledge (validate correctness)
- GitHub (PR review)

### Cipher (Security)
**Specialization:** Security audits, threat modeling

Skills:
- model-usage (security testing costs)
- session-logs (audit trails)
- rl-knowledge (threat analysis)

### Prism (Mobile/Responsive)
**Specialization:** UI/UX, mobile, responsive design

Skills:
- toon-encoding (video processing)
- video-frames (frame extraction)
- summarize (design spec synthesis)

### Chronicle (Documentation)
**Specialization:** Technical writing, documentation

Skills:
- nano-pdf (reference materials)
- summarize (doc synthesis)
- obsidian (markdown notes)
- notion (knowledge base)

### Sentinel (Infrastructure/DevOps)
**Specialization:** Deployment, automation, infrastructure

Skills:
- github (CI/CD, deployments)
- openhue/eightctl (smart home orchestration)
- tmux (server management)

### Echo (Creative/Ideation)
**Specialization:** Brainstorming, conceptual thinking

Skills:
- build-your-own-x (architectural patterns)
- rl-knowledge (probabilistic ideation)

---

## 💡 KEY SYSTEM CAPABILITIES

### Self-Improving Loop
1. **Execution:** Agents complete tasks → outcomes logged
2. **Analysis:** Phase 7B analyzes daily at 01:30 UTC
3. **Learning:** Q-scores updated via memory-optimizer + rl-knowledge
4. **Routing:** Next session reads learnings, improves spawning

### Cost Optimization (Phase 5-6)
- Cache warmup: 12.5% savings
- Specialized prompts: 17.5% savings
- Task batching: 20-30% savings
- Memory pruning: 10% savings
- Multi-model routing: 15% additional
- **Total: 60-65% cost reduction**

### Stability Guardrails (Phase 8A)
- Agent drift detector (hourly, scripts/agent-drift-detector.py)
- Task validator (daily, scripts/task-validator.py)
- Rollback safety procedures documented in STABILITY.md

### Knowledge Integration
- RL-knowledge skill: Full textbook queryable
- Memory-optimizer: Persistent learning
- Phase 7B: Daily insights generation
- Session startup: Reads all learnings

---

## 📊 SKILL DEPLOYMENT STATUS

| Skill | Status | Used By | Priority |
|-------|--------|---------|----------|
| llmfit-infrastructure | ✅ ACTIVE | Morpheus | 🔴 CRITICAL |
| memory-optimizer | ✅ ACTIVE | All agents | 🔴 CRITICAL |
| rl-knowledge | ✅ ACTIVE | Scout, Codex | 🟡 HIGH |
| session-logs | ✅ ACTIVE | All agents | 🟡 HIGH |
| model-usage | ✅ AVAILABLE | Codex, Veritas | 🟡 HIGH |
| agent-drift-detector | ✅ READY | Morpheus | 🟡 HIGH |
| task-validator | ✅ READY | Morpheus | 🟡 HIGH |
| monte-carlo-sim | ✅ AVAILABLE | Optional | 🟢 MEDIUM |
| nano-pdf | ✅ AVAILABLE | Scout, Chronicle | 🟢 MEDIUM |
| toon-encoding | ✅ AVAILABLE | Prism | 🟢 MEDIUM |
| video-frames | ✅ AVAILABLE | Prism | 🟢 MEDIUM |

---

## 🎯 NEXT OPPORTUNITIES

**Phase 8B:** Accelerate Phase 7B (daily → hourly)
- Faster learning cycle
- Better drift detection
- Cost: +1% compute

**Phase 8C:** Address routing misalignments
- Chronicle: Focus on documentation, not research
- Sentinel: Focus on infrastructure, not security
- Codex: Reduce security work, focus on implementation

**Phase 9:** Enterprise features
- Dashboards (Phase 7B)
- SLA tracking
- Audit logs
- Cost reporting

---

## Summary

**Total Skills:**
- 11 custom in-house (core + specialized)
- 35 standard available (integrations)
- **46 total**

**Most Critical:**
- llmfit-infrastructure (routing engine)
- memory-optimizer (learning system)
- rl-knowledge (context + expertise)

**Status:** System fully operational, self-improving, 60-65% cost reduction active.
