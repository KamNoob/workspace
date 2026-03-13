# Quick Start - Knowledge Base System

A complete RAG (Retrieval-Augmented Generation) system with auto-learning and monitoring.

## Overview

- **kb-rag-injector.jl** — Query KB, get ranked results with confidence scores
- **query-reformulate.jl** — Expand queries, generate multi-angle variants
- **kb-live-indexer.jl** — Auto-extract learnings from agent outcomes (via cron)
- **kb-confidence-scorer.jl** — Score retrieval quality, flag knowledge gaps
- **kb-integration.jl** — Live KB context injection into spawner-matrix
- **kb-monitor.jl** — System monitoring dashboard & metrics

## Usage

### 1. Query the Knowledge Base

```bash
# Search for relevant KB entries
julia scripts/ml/kb-rag-injector.jl query "agent selection"

# List all KB entries
julia scripts/ml/kb-rag-injector.jl list

# Initialize sample KB data
julia scripts/ml/kb-rag-injector.jl init
```

### 2. Expand Queries

```bash
# Generate query variants
julia scripts/ml/query-reformulate.jl expand "agent selection"

# Get multi-angle perspectives
julia scripts/ml/query-reformulate.jl angles "learning"
```

### 3. Score Confidence

```bash
# Evaluate KB retrieval quality
julia scripts/ml/kb-confidence-scorer.jl score "agent selection"

# Check for knowledge gaps
julia scripts/ml/kb-live-indexer.jl gaps
```

### 4. Spawn with KB Context

```bash
# Automatically retrieves and injects KB context
julia scripts/ml/spawner-matrix.jl spawn code Codex,QA,Scout

# Returns:
# - agent: Selected agent
# - kb_context_found: true/false
# - kb_context_entries: Number of entries
# - kb_context_reason: Why context was/wasn't injected
```

### 5. Monitor System

```bash
# Show live dashboard
julia scripts/ml/kb-monitor.jl status

# Show growth history
julia scripts/ml/kb-monitor.jl growth

# Export metrics as JSON
julia scripts/ml/kb-monitor.jl --json | jq '.spawn_metrics'
```

## Auto-Learning Setup

### Enable Daily Auto-Learning via Cron

The system runs daily at 01:00 UTC to:
- Process RL execution logs
- Extract learnings from successful outcomes
- Auto-add entries to KB
- Update metrics

**Cron job:**
```bash
0 1 * * * /home/art/.openclaw/workspace/scripts/kb-live-indexer.sh
```

**Manually trigger:**
```bash
bash scripts/kb-live-indexer.sh
```

### Monitor Auto-Learning

```bash
# Check KB status
julia scripts/ml/kb-live-indexer.jl status

# View recent learnings
julia scripts/ml/kb-monitor.jl status | grep "recent"

# Check metrics
cat data/metrics/kb-system-metrics.json | jq '.kb_growth_history'
```

## Metrics & Reporting

Metrics are stored in: `data/metrics/kb-system-metrics.json`

### Key Metrics

- **KB Growth:** Entries added per day, by source
- **Spawn Success Rate:** % of successful agent spawns
- **KB Context Usage:** How often KB context is injected
- **Learning Progress:** Agent Q-value improvements
- **Confidence Distribution:** High/medium/low confidence result breakdown

### Example Dashboard

```
╔════════════════════════════════════════════════════════════════╗
║         KB SYSTEM - LIVE STATUS                              ║
╠════════════════════════════════════════════════════════════════╣
║ System Start:          2026-03-13T23:08:00Z                  ║
║ Total Spawns:          42                                     ║
║ Success Rate:          90.0%                                  ║
║ KB Context Usage:      38 queries (90.5%)                    ║
║                                                              ║
║ Agent Improvements:                                          ║
║  • Scout:    +18.0% (156 sessions)                           ║
║  • Cipher:   +22.0% (89 sessions)                            ║
║  • Codex:    +15.0% (143 sessions)                           ║
║                                                              ║
║ Top Agents by Task:                                          ║
║  • research:        Scout (Q=0.92)                           ║
║  • security_audit:  Cipher (Q=0.89)                          ║
║  • code_review:     Veritas (Q=0.85)                         ║
╚════════════════════════════════════════════════════════════════╝
```

## Architecture

```
Agent Spawn Request
    ↓
spawner-matrix.jl
    ├─ Load RL state (Q-scores)
    ├─ Call kb-integration.jl:get_kb_context()
    │   ├─ Load KB from JSON
    │   ├─ Score entries by relevance
    │   ├─ Filter by confidence (>= 0.6)
    │   └─ Return top 3 entries
    ├─ Select best agent
    ├─ Inject KB context into output
    └─ Return spawn result + metadata
        │
        ↓
Agent Execution + Outcome Logging
        │
        ↓
Daily Cron (01:00 UTC)
    ├─ kb-live-indexer.sh processes logs
    ├─ Extracts learnings
    ├─ Auto-adds to KB
    └─ Updates metrics
        │
        ↓
KB Monitor Reports
    └─ Show growth, success rates, agent improvements
```

## Files

```
scripts/ml/
├── kb-rag-injector.jl          (268 lines)  RAG context retrieval
├── query-reformulate.jl        (233 lines)  Query expansion
├── kb-live-indexer.jl          (288 lines)  Auto-learning
├── kb-confidence-scorer.jl     (283 lines)  Quality scoring
├── kb-integration.jl           (171 lines)  Spawner integration
└── kb-monitor.jl               (205 lines)  Monitoring dashboard

scripts/
└── kb-live-indexer.sh                       Daily cron job

data/
├── kb/
│   └── knowledge-base.json                  KB storage
└── metrics/
    └── kb-system-metrics.json               Metrics & analytics
```

## Next Steps

1. ✅ KB system deployed
2. ✅ Live spawner integration active
3. ✅ Monitoring dashboard ready
4. ⏳ **Enable daily cron job** (`kb-live-indexer.sh`)
5. ⏳ **Expand initial KB** with domain knowledge
6. ⏳ **Set up metrics export** to external dashboards

---

**Last Updated:** 2026-03-13 23:12 UTC
