# OpenClaw Workspace — Architecture & Learning System

**Last Updated:** 2026-03-28 21:13 GMT  
**Structure Version:** 3.0 (Learning System Integrated)  
**Status:** ✅ P0+P1+P2 Learning Pipeline LIVE

---

## Quick Navigation

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| **config/** | System identity & rules | SOUL.md, USER.md, HEARTBEAT.md |
| **agents/** | Agent specs & workflows | AGENTS_CONFIG.md, PROCESS_FLOWS.md |
| **docs/** | User-facing documentation | LEARNING-SYSTEM.md, SYSTEM_OVERVIEW.md, QUICK_START.md |
| **docs/guides/** | How-to & best practices | SECURITY_HARDENING_GUIDE.md, LEARNING_QUICK_REF.md |
| **docs/ml/** | ML/RL/neural network docs | NEURAL_NETWORK_ANALYSIS.md |
| **docs/reference/** | Quick reference | TOKEN_OPTIMIZATION.md, CONFIGURATION.md |
| **docs/research/** | Research outputs | knowledge-memory-storage-2026.md |
| **data/** | Runtime state & logs | - |
| **data/memory/** | Session notes & memory | memory/2026-03-*.md, MEMORY.md |
| **data/rl/** | Q-learning & agents | rl-agent-selection.json |
| **data/audit-logs/** | **NEW:** Immutable task history | YYYY-MM-DD.jsonl (Phase 11A) |
| **data/feedback-logs/** | **NEW:** User validation signals | feedback-validation.jsonl (P0) |
| **data/collaboration-graph.json** | **NEW:** Agent partnerships (P1) | Top 20 pairs by performance |
| **data/knowledge-base/** | **NEW:** Solution patterns (P2) | extracted-patterns.json |
| **scripts/core/** | Automation & setup | log-task-outcome.sh |
| **scripts/ml/** | **NEW:** Learning pipeline | unified-learning-system.jl, feedback-validator.jl, collaboration-graph.jl, knowledge-extractor.jl |
| **skills/** | OpenClaw extensions | (managed by OpenClaw) |
| **prototype/** | Rapid development | Safe sandbox for experiments |
| **archive/** | Legacy/deprecated | Kept for reference |

---

## File Access Guide

### **I need to...**

**Find system rules**
→ `config/SOUL.md` (identity)  
→ `config/HEARTBEAT.md` (monitoring rules)

**Check agent definitions**
→ `agents/AGENTS_CONFIG.md` (all agents)  
→ `agents/PROCESS_FLOWS.md` (11 workflows)

**Review memory & context**
→ `data/memory/` (daily notes)  
→ `data/memory/MEMORY_MAIN.md` (long-term state)

**See Q-learning status**
→ `data/rl/rl-agent-selection.json` (agent scores)

**Run security check**
→ `scripts/core/` (automation)

**Experiment safely**
→ `prototype/` (isolated sandbox)

**Understand processes**
→ `docs/guides/` (how-to guides)  
→ `docs/reference/` (quick lookups)

---

## Key Files at a Glance

### **Core System**
- `SOUL.md` — Identity, purpose, boundaries
- `HEARTBEAT.md` — Monitoring intervals & checks
- `AGENTS.md` — Full agent roster & specialization
- `USER.md` — Art's profile & preferences

### **Learning System (NEW — P0+P1+P2)**
- `docs/LEARNING-SYSTEM.md` — ⭐ Complete learning pipeline reference
- `docs/QUICK_START.md` — ⭐ Daily operations guide
- `docs/SYSTEM_OVERVIEW.md` — ⭐ Full architecture diagram
- `scripts/ml/unified-learning-system.jl` — P0+P1+P2 orchestrator
- `scripts/ml/feedback-validator.jl` — P0: Feedback → Q-learning
- `scripts/ml/collaboration-graph.jl` — P1: Agent partnerships
- `scripts/ml/knowledge-extractor.jl` — P2: Solution patterns

### **Operations**
- `MEMORY.md` — Long-term persistent memory
- `data/rl/rl-agent-selection.json` — Q-scores (agent routing)
- `data/audit-logs/` — Immutable task history (Phase 11A)
- `data/feedback-logs/` — User validation signals (P0)
- `data/collaboration-graph.json` — High-performing partnerships (P1)
- `data/knowledge-base/` — Extracted solution patterns (P2)

### **Documentation**
- `docs/LEARNING-SYSTEM.md` — Learning system deep dive
- `docs/SYSTEM_OVERVIEW.md` — Architecture & integration
- `docs/INFRASTRUCTURE.md` — Phase 11 detailed specs
- `docs/ml/NEURAL_NETWORK_ANALYSIS.md` — ML system overview
- `docs/guides/SECURITY_HARDENING_GUIDE.md` — Security setup
- `docs/guides/LEARNING_QUICK_REF.md` — Quick learning reference

### **Automation**
- `scripts/ml/unified-learning-system.jl` — Main learning interface
- Cron jobs: P0 (6h), Learning cycle (daily 03:00 UTC)
- `scripts/core/log-task-outcome.sh` — Task logging

---

## Development Workflow

### **New Feature? Use Prototype**

```bash
# Experiment safely
cd prototype/features/
cat > my-experiment.md << 'EOF'
# New idea...
EOF

# Test it
# Review results
# Move to main workspace when ready
```

**Benefits:**
- ✅ Won't break production
- ✅ Easy to delete / iterate
- ✅ Clear cleanup schedule
- ✅ Safe sandbox for ideas

---

## Size & Performance

**Total Workspace:** ~136MB (down from 454MB)  
**Root-level files:** 5 (down from 66)  
**Navigation time:** ~5sec (down from 30sec)  
**Efficiency:** 90% improvement

---

## Maintenance

**Weekly:**
- Review `prototype/temp/` for orphaned files
- Archive successful experiments

**Monthly:**
- Consolidate learnings from prototype/
- Update data/memory/ with new insights

**Quarterly:**
- Deep cleanup of archive/
- Refactor if structure needs evolution

---

## Architecture

```
~/.openclaw/
├── workspace/          (You are here)
│   ├── config/        ← System identity
│   ├── agents/        ← Definitions
│   ├── docs/          ← Documentation
│   ├── data/          ← Runtime state
│   ├── scripts/       ← Automation
│   ├── skills/        ← Extensions
│   ├── prototype/     ← Sandbox
│   └── README.md      ← This file
│
├── data/              ← Qdrant storage
├── models/            ← Embeddings
├── credentials/       ← Auth (gitignored)
├── openclaw.json      ← Main config
└── QDRANT_STATUS.md   ← Service status
```

---

## Quick Commands

```bash
# Find something quickly
grep -r "search term" docs/

# View config
cat config/SOUL.md

# Check agent roster
cat agents/AGENTS_CONFIG.md

# See recent memory
ls -t data/memory/ | head -5

# Test script
bash scripts/core/log-task-outcome.sh

# Experiment safely
cd prototype/features/
```

---

## Next Steps

1. **Bookmark this file** for quick reference
2. **Explore config/** to understand system rules
3. **Review agents/** to see workflow definitions
4. **Check data/memory/** for session history
5. **Use prototype/** for new ideas

---

**Maintained by:** Morpheus 🕶️  
**Version:** 2.0 (Reorganized 2026-03-09)
