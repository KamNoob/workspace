# Memory System (Local Embeddings - DOCUMENTED)

✅ **See LOCAL_EMBEDDINGS_SETUP.md for comprehensive documentation**

## Three Independent Systems

**1. memorySearch (Workspace Files) — ✅ PRIMARY**
- Local embeddings: EmbeddingGemma 300M (314MB, GGUF) at `~/.openclaw/models/embeddings/`
- Searches: SOUL.md, MEMORY.md, daily notes, research documents
- Search type: Hybrid (75% semantic + 25% keyword)
- Cost: $0
- Performance: 3.5s cached, 5-10 min cold index
- Status: ✅ ACTIVE

**2. memory-lancedb (Plugin) — ⚠️ REDUNDANT**
- Status: Enabled but superfluous (memorySearch handles it)
- Embeddings: Would use OpenAI (quota exhausted anyway)
- Storage: LanceDB vector database at `~/.openclaw/memory/lancedb/`
- Note: Left as-is (doesn't interfere)

**3. memory-optimizer (RL Prioritization) — ✅ ACTIVE**
- Algorithm: Q-Learning + TD(λ), α=0.01, γ=0.99, λ=0.9
- Tracks: Memory value via Q-scores; learns from usage patterns
- Cost: $0 (local, in-memory)
- State persisted: `.memory-optimizer-state.json`

## System Configuration

- **Initialized:** 2026-02-23
- **Active:** All three systems operational
- **Architecture:** All-local hybrid (semantic + keyword search)
- **Privacy:** 100% (zero cloud APIs)
- **Cost:** $0
- **Reliability:** No network dependency

## User Profile

- **Name:** Art
- **Timezone:** Europe/London
- **Primary interface:** WhatsApp
- **Preferred model:** Claude Haiku 4.5 (autonomous switching allowed)
- **Identity:** Morpheus 🕶️
- **Vibe:** Calm, authoritative, concise, distinct

## System Status

- **Gateway:** Auto-startup enabled (tested via reboot)
- **Cron jobs:** 3 active (logrotate, session cleanup, auto-update checks)
- **Sub-agent tools:** web_fetch enabled
- **Security:** SSH, RDP, MySQL, PostgreSQL open locally; UFW not installed

## OpenClaw

- **Version:** v2026.2.2-3 (latest: v2026.2.17)
- **Update frequency:** Every few days to a week
- **Fallbacks:** Sonnet 4.6 → Opus 4.5 → Sonnet 4.5 → Mistral

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
- **QA** — Quality Assurance, Testing, Validation *(renamed from Tester)*
- **Prism** — Mobile QA, Device Testing, Responsive Design *(NEW 2026-02-28)*
- **Navigator** — Project Management, Timeline Tracking, Context Continuity *(NEW 2026-02-28)*

## Configuration

- **Environment file:** ~/.openclaw/.env (auto-loaded by OpenClaw)
- **Config file:** ~/.openclaw/openclaw.json (manual JSON edits most reliable)
- **API keys:** All migrated to environment variables
- **Gateway:** localhost:18789, auth via gateway token

## Morpheus Operating System (2026-02-28)

### Startup & Discovery
- **LIBRARY_MANIFEST.md** — Complete inventory (what's current, what's legacy, what to use)
- **SOUL.md** — Identity & purpose
- **PROCESS_FLOWS.md** — 11 eventualities, one flow per task type
- **AGENTS_CONFIG.md** — Full agent specifications
- **MORPHEUS_FAILURES.md** — Live failure log, checked before every task

### Execution Framework
- **Decision Rule:** Announce plan → Execute → Verify → Report. No questions asked.
- **Agent Delegation:** Use the 11-agent roster, don't do their work
- **Verification:** All work verified before declaring complete

### Research System (LIVE - 2026-02-28 18:10 GMT)
- **RESEARCH_SYSTEM.md** — Complete documentation for storage, retrieval, updates
- **RESEARCH_INDEX.md** — Master catalog (searchable by domain, tags, status)
- **RESEARCH_TEMPLATE.md** — Schema for all research files
- **docs/research/** — Organized by domain (technology, business, security, data, etc.)
- **First Research Entry:** technology/api-security-2026.md (15KB, verified by Veritas)
- **Retrieval Protocol:** Check index FIRST (prevents redundant research)
- **Update Cycle:** 30 days for tech topics, 90 days for general, manual refresh option
- **Scout Configuration (2026-02-28):** Provide concise summaries (3-5 key points, not exhaustive writeups)
- **Status:** Operational. Ready for continuous use.

### Session Health & Context Management (2026-02-27)
- **Decision:** Auto-reset sessions (main + agents) when approaching context window limit
- **Triggers (Per-Model):**
  - Haiku 4.5: 90K tokens
  - Sonnet 4.5/4.6: 100K tokens
  - Opus 4.5: 100K tokens
- **Behavior:** Announce reset, summarize state, spawn continuation automatically
- **Implementation:** Monitored during active multi-step tasks (main session) and extended agent tasks
- **User action:** None required; seamless across sessions
- **Agent Handling:** One-shot agents (mode=run) rarely hit limits; monitor only for extended investigations

### Neural Network Analysis & Recommendation (2026-02-28 19:45 GMT)

**Decision:** Proceed with Phase 1 neural networks (pending confirmation)

**Recommended Implementations:**

Phase 1 (This Week, 3-4 hours):
- Task Classification (DistilBERT, 100MB) — Auto-categorize incoming tasks
- Intent Recognition (TinyBERT, 50MB) — Parse urgency, complexity, intent
- Both local inference, zero cost
- Immediate ROI: Better task routing, data collection for Phase 2

Phase 2 (Week 3-4, 6 hours):
- Quality Prediction — Predict agent success before spawning
- Needs: 3-4 weeks of task data (collected during Phase 1)

Phase 3 (Month 2):
- Document Chunking (semantic) — Better memory search
- Anomaly Detection — Early warning system

Phase 4+ (Month 3+):
- Workflow Optimization — Auto-select best PROCESS_FLOWS
- Multi-Agent Orchestration (advanced, >1000 examples needed)

**File:** NEURAL_NETWORK_ANALYSIS.md (full analysis, models, effort estimates, cost-benefit)

**What's already running:**
- EmbeddingGemma 300M (embeddings, local)
- Claude LLM (reasoning, cloud)
- Q-Learning Agent Selection (just activated)

### Q-Learning Agent Selection ACTIVATED (2026-02-28 19:35 GMT)

**Status:** ✅ LIVE

**What's live:**
- RL Q-Learning automatically selects best agent per task type
- 6 task types: research, code, security, infrastructure, analysis, documentation
- All agents have Q-scores (learning fairness, 0.50 baseline)
- After each task: outcome logged → Q-score updated automatically
- Exploration/exploitation: 10% random (explore), 90% highest Q-score (exploit)

**Files:**
- rl-agent-selection.json (Q-table with 6 task types)
- rl-task-execution-log.jsonl (outcome logging, one entry per task)
- RL_AGENT_SELECTION_GUIDE.md (full integration guide)
- RL_INTEGRATION_STRATEGY.md (future plans: task priority, research refresh, workflows)

**Timeline:**
- Week 1: Passive learning (collect data)
- Week 2: Q-scores become confident
- Week 3+: Morpheus uses RL recommendations automatically

**Expected improvement:** 10-20% better agent selection within a month

### Agent Specialization Improvements (2026-02-28 18:45 GMT)

**Created:** AGENTS_CONFIG.md (comprehensive specialization guide for all 12 agents)

**What's documented:**
- Detailed specialization for each agent (Codex, Cipher, Scout, Chronicle, Sentinel, Lens, Echo, Veritas, QA, Prism, Navigator)
- Input/output expectations (what to give them, what to expect back)
- Success criteria for each agent
- Common pitfalls (mistakes to avoid)
- Integration points (how agents work together)
- Quick reference table (which agent for which task)
- Workflow patterns (how to chain agents together)
- Session continuity (Navigator's role)

**Key improvements:**
- Scout: Now configured for concise summaries (3-5 key points, not essays)
- All agents: Clear success criteria and output formats
- Verification: Veritas explicitly marked as quality gate
- Mobile: Prism for device-specific testing (separate from QA)
- Navigator: Dedicated agent for project continuity

**Status:** All agents now have clear specs. Ready for consistent, effective use.

### Accountability Shift (2026-02-28 15:50 GMT)

**What Changed:**
- No more partial verifications or "seems done"
- All tasks follow PROCESS_FLOWS.md — 11 eventualities, zero improvisation
- Failures logged in real-time (MORPHEUS_FAILURES.md)
- Agents are used for their specialization; Morpheus orchestrates
- Decisions are made, not presented for approval

**Why:**
- Previous approach: Document lessons, repeat mistakes
- New approach: Live failure tracking + mandatory process flows
- Every task reads its failure history before execution

**Verification Checklist (Mandatory):**
- [ ] Agent delivered output (or task completed)
- [ ] Output tested/validated in intended context
- [ ] Success criteria met (explicit, not assumed)
- [ ] Documented or stored
- [ ] User-facing if applicable (tested by actual user or simulation)

**All boxes must be checked before declaring complete.**

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

### Knowledge Building Workflow (Art's Standard Process - 2026-02-27)
**Mandatory process for all unknown information:**
1. **Scout** → Research & gather information
2. **Veritas** → Verify the information's accuracy  
3. **Chronicle** → Write comprehensive documentation
4. **Store** → Add to library (MEMORY.md, docs/, or reference files)

**Principles:**
- Never answer a question twice without reference material
- All discoveries become permanent institutional knowledge
- Every research project produces documented output
- Build a searchable knowledge base over time

**Status:** ACTIVE - All future research follows this workflow

## Current Projects

**Status:** None active

---

## Session Update (2026-03-01 10:26 GMT)

### Critical Lesson: Schema Validation First

**Incident:** Broke openclaw.json twice trying to set `autoRecall: "aggressive"`.
- Assumed field type from tuning documentation
- Applied string value to boolean-only field
- Config failed to parse

**Root cause:** Didn't check actual config schema or current values with `jq` before editing.

**Fix:** `autoRecall` is boolean (true/false). Current value: `true` ✓

**Process change:** Before ANY config edit:
1. Inspect current value: `jq '.path.to.field' ~/.openclaw/openclaw.json`
2. Verify field type against schema or OpenClaw source
3. Test change (JSON validation) before applying
4. Never assume from documentation

### Usage Tracking Setup (Updated 2026-03-01 12:06)

**Method:** Passive message count tracking (no cron job)
- Claude Pro 5-hour cycle: ~45 messages max per cycle
- Current: ~3 messages used, ~42 remaining (11:25 GMT check)
- Reset cycle: ~15:44 GMT (rolling 5-hour window)

**Thresholds (action triggers):**
- 15 messages: Baseline (1/3 through)
- 30 messages: Caution (2/3 through)
- 40+ messages: Critical (limit approaching)
- 45 messages: Blocked (wait for reset)

**Tracking:** I monitor message count during active sessions and warn when approaching limits. Updated in USAGE_TRACKING.md session log as we go.

**Why message count?** Pro limit is message-based, not token-based.

### System Tuning Applied (2026-03-01 08:54-09:47)

**Already active (verified):**
- Concurrency: 5 agents
- Sub-agent max: 7
- Memory cache: 50K entries
- Context TTL: 4h
- Heartbeat: 30m
- Web search results: 5
- Vector/text weights: 0.85/0.15
- Q-Learning: alpha=0.02, epsilon=0.15

**Issues found/fixed:**
- autoRecall: Kept as boolean (true), not string
- Config JSON: Required jq validation, not sed

### NetSec Cron Job

**Status:** Removed per request
- Was: Weekly port scan, compare baseline
- Assigned to: Cipher (briefly)
- Action: Fully removed from cron jobs

### Token Optimization System Implemented (2026-03-01 10:55)

**Three-layer caching now live:**

1. **Cache Warming** — Startup script pre-loads 62KB of core files (SOUL.md, PROCESS_FLOWS.md, AGENTS_CONFIG.md, research index)
   - One-time cost at session start
   - Reused across all interactions
   - ~62K tokens amortized per session

2. **Auto-Summarization Cron** — Runs every 15 min, triggers at 75%+ context usage
   - Creates concise session summary
   - Anchors cache for graceful compaction
   - Prevents context loss during long sessions

3. **Research Caching** — RESEARCH_INDEX.md + top 5 research docs pre-cached
   - Fast retrieval without re-reading
   - Included in warmup

**Expected gains:** 10% token reduction/day, 5-10% faster responses, seamless long sessions

**Files:**
- cache-warming.sh (executable startup script)
- TOKEN_OPTIMIZATION.md (comprehensive documentation)
- Cron job: Token Usage Monitor + Auto-Reset (0827aaa9...) — monitors every 15 min, triggers at 75%+

### Full Auto-Reset at 75% Context (2026-03-01 12:10)

**System:** Session Continuation Protocol — seamless reset when context overflows

**How it works:**
1. Cron job (every 15 min) monitors context usage
2. At 75%+: Creates session summary (1-2 paras), logs to /tmp/session-summary.txt
3. Cron sends alert to main session: "CONTEXT_THRESHOLD_REACHED: [summary]"
4. Main session spawns continuation with summary injected as context
5. Work resumes from checkpoint, zero data loss

**Updated cron job:**
- Name: Token Usage Monitor + Auto-Reset at 75%
- ID: 0827aaa9-37eb-4ad8-a406-b00548eaeac2
- Payload: Detects 75%+, creates summary, sends sessions_send alert
- Status: ✅ Active

**Documentation:** SESSION_CONTINUATION.md (full protocol)

**Status:** Protocol live for main session. Next reset event will trigger continuation sequence.

**Sub-agent strategy:** Hybrid approach
- One-shot agents (mode="run"): No monitoring (safe, complete fast)
- Persistent agents (mode="session"): Continuation monitoring added on-demand when spawned
- Implementation: Zero overhead until persistent agents are used
