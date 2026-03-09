# Library Manifest — Complete Inventory

**Date:** 2026-02-28  
**Total files:** 109 markdown files  
**Status:** Mixed (12 active, ~30 legacy)

---

## 🟢 ACTIVE SYSTEM FILES (Current, In Use)

These files define how Morpheus operates right now.

### Identity & Purpose
| File | Size | Purpose |
|------|------|---------|
| SOUL.md | 3.7K | Mission, personality, execution discipline |
| IDENTITY.md | 946B | Name (Morpheus), vibe, emoji |
| USER.md | 678B | Art's profile, preferences, timezone |
| TOOLS.md | 860B | Environment-specific notes |

### Operations
| File | Size | Purpose |
|------|------|---------|
| AGENTS.md | 2.7K | Agent roster + ref to AGENTS_CONFIG |
| AGENTS_CONFIG.md | 21K | **Full specialization specs for all 12 agents** |
| PROCESS_FLOWS.md | 7.9K | **11 standard workflows (research, code, security, etc.)** |
| HEARTBEAT.md | 2.5K | Monitoring protocol + chat monitoring |

### Memory & Knowledge
| File | Size | Purpose |
|------|------|---------|
| MEMORY.md | 8.5K | Long-term memory index + system notes |
| LOCAL_EMBEDDINGS_SETUP.md | 12K | **Embeddings documentation (comprehensive)** |
| MEMORY-OPTIMIZER-INTEGRATION.md | 7.4K | Q-learning setup for memory prioritization |
| MORPHEUS_FAILURES.md | 2.2K | **Failure log (checked before every task)** |

**Total active:** ~68KB of core system documentation

---

## 🟡 RESEARCH LIBRARY (Ready to Use)

### Actual Research
| File | Size | Status | Refresh |
|------|------|--------|---------|
| **technology/api-security-2026.md** | 15K | ✅ Active | 2026-03-30 |

### Infrastructure (Ready for New Research)
| File | Size | Purpose |
|------|------|---------|
| RESEARCH_INDEX.md | 2.1K | Master catalog (searchable) |
| RESEARCH_TEMPLATE.md | 1.4K | Schema for all research files |
| RESEARCH_SYSTEM.md | 14K | Full research system documentation |
| README.md | 2.2K | Quick start guide |

### Empty Domain Folders (Ready for Research)
- algorithms/ (sorting, graph algorithms, ML, etc.)
- business/ (startups, marketing, operations)
- domain-knowledge/ (healthcare, fintech, ecommerce)
- data/ (data science, metrics, insights)
- security/ (security, compliance, infrastructure)
- other/ (misc topics)

**Total research:** 1 entry + infrastructure for many more

---

## 🔴 LEGACY FILES (Not Current, Kept for Reference)

These are from earlier work phases. **Not actively used or maintained.**

### Notion/Mission Control Docs (~10 files)
- NOTION_WORKSPACE_COMPLETE.md
- NOTION_MISSION_CONTROL_LIVE.md
- NOTION_LEGACY_DATA_LOADED.md
- MISSION_CONTROL.md
- MISSION_CONTROL_OVERVIEW.md
- CONTROL_CENTER_GUIDE.md
- NOTION_DASHBOARDS.md

**Status:** Described historical Notion integrations (no longer relevant)

### RL (Reinforcement Learning) Docs (~3 files)
- RL-KNOWLEDGE-INTEGRATION.md
- RL-SKILL-DEPLOYMENT.md
- RL-BOOK-ENHANCED.md

**Status:** RL knowledge base skill (not active in current system)

### Team & Sync Docs (~5 files)
- TEAM_STRUCTURE.md
- TEAM_ROSTER.md
- YOUR_AI_TEAM.md
- SYNC_SCRIPTS_MANIFEST.md
- DEPLOYMENT-READY.md

**Status:** Old team/deployment documentation (superseded)

### Agent Docs (~3 files)
- AGENT_NAVIGATOR.md
- AGENT_PRISM.md
- ACTIVATE-REAL-TIME-OPTIMIZER.md

**Status:** Superseded by AGENTS_CONFIG.md

### Other Legacy
- MEMORIES_GUIDE.md (old memory system)
- TASK_BOARD.md (empty task list)

**Total legacy:** ~30KB (kept for historical reference only)

---

## What's Actually Being Used?

### When Morpheus Starts a Session

1. **Read:** SOUL.md (who am I)
2. **Read:** PROCESS_FLOWS.md (what's my task)
3. **Read:** MORPHEUS_FAILURES.md (what should I avoid)
4. **Available:** AGENTS_CONFIG.md (when spawning agents)
5. **Available:** MEMORY.md (long-term context)
6. **Available:** LOCAL_EMBEDDINGS_SETUP.md (if embeddings question)
7. **Available:** RESEARCH_INDEX.md (before researching)

### When Doing Work

**Research task:**
- Check RESEARCH_INDEX.md
- Use docs/research/technology/api-security-2026.md as example
- Follow RESEARCH_SYSTEM.md for workflow
- Store in docs/research/[domain]/[topic].md

**Code task:**
- Reference AGENTS_CONFIG.md (Codex section)
- Follow PROCESS_FLOWS.md (Section 2)
- Spawn Codex, then QA

**Security audit:**
- Reference AGENTS_CONFIG.md (Cipher section)
- Follow PROCESS_FLOWS.md (Section 3)
- Spawn Cipher

**Any task:**
- Check PROCESS_FLOWS.md for the right flow
- Reference AGENTS_CONFIG.md for agent specs
- Log failures to MORPHEUS_FAILURES.md

---

## Size Breakdown

| Category | Files | Size | Status |
|----------|-------|------|--------|
| Active core | 12 | ~68KB | ✅ Current |
| Research | 4 + folders | ~19KB | ✅ Growing |
| Legacy | ~30 | ~130KB | ⚠️ Historical |
| Logs & other | ~60 | ~100KB | — Session logs |

**Total:** ~109 files, ~317KB documentation

---

## What's Missing?

### Research Topics (Planned, Not Started)
- Zero-trust architecture
- OAuth 2.0 implementation guide
- Mutual TLS for microservices
- OWASP API Top 10 remediation
- Compliance frameworks (GDPR, PCI-DSS, SOC 2)
- Market analysis (any domain)
- Competitive intelligence
- Algorithm deep-dives

### Documentation (Should Exist)
- Workspace structure guide (this is it)
- Quick reference card (could create)
- Glossary of terms
- Common patterns & anti-patterns

---

## How to Use This Manifest

### To Find Something
1. **System behavior?** → AGENTS_CONFIG.md or PROCESS_FLOWS.md
2. **About research?** → RESEARCH_SYSTEM.md or RESEARCH_INDEX.md
3. **About embeddings?** → LOCAL_EMBEDDINGS_SETUP.md
4. **About memory?** → MEMORY.md
5. **About failures?** → MORPHEUS_FAILURES.md

### To Clean Up (Optional)
1. Archive legacy files to `/docs/archive/`
2. Keep RESEARCH_LIBRARY growing
3. Add new research entries as needed
4. Update RESEARCH_INDEX.md when adding research

### To Grow the Library
1. **Identify research need** (user asks, or proactive)
2. **Check RESEARCH_INDEX.md** (already have it?)
3. **Spawn Scout** (research)
4. **Spawn Veritas** (validate)
5. **Spawn Chronicle** (document)
6. **Store** in docs/research/[domain]/[topic].md
7. **Update RESEARCH_INDEX.md**

---

## Quick Reference

### Most Important Files (Read These First)
1. **SOUL.md** — Know who you are
2. **PROCESS_FLOWS.md** — Know what to do
3. **AGENTS_CONFIG.md** — Know who to delegate to
4. **MORPHEUS_FAILURES.md** — Know what to avoid

### Most Updated Files (Check These During Work)
1. **RESEARCH_INDEX.md** — Growing research library
2. **MORPHEUS_FAILURES.md** — New failures logged
3. **MEMORY.md** — Long-term learnings

### Most Useful for Specific Tasks
- **Research?** → RESEARCH_SYSTEM.md
- **Code?** → AGENTS_CONFIG.md (Codex) + PROCESS_FLOWS.md (Section 2)
- **Security?** → AGENTS_CONFIG.md (Cipher) + PROCESS_FLOWS.md (Section 3)
- **Embeddings?** → LOCAL_EMBEDDINGS_SETUP.md
- **Agents?** → AGENTS_CONFIG.md

---

## Status

✅ **Current system well-documented** (active files are complete)  
✅ **Research infrastructure ready** (1 entry, 6 folders, full workflow)  
⚠️ **Legacy files present** (kept for history, can be archived if desired)  
✅ **Everything accessible** (this manifest shows where to find things)  

**Library is operational and organized. Ready for continuous research additions.**
