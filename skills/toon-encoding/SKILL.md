# TOON Encoding Skill

**Token-Oriented Object Notation** — Compress JSON by 30-60% for efficient LLM prompts.

## Overview

TOON is a lossless encoding format that reduces JSON token count while maintaining full fidelity. Perfect for sending structured data to agents with minimal context bloat.

**Token savings:**
- Uniform arrays: **40-60% reduction**
- Tabular data: **50-60% reduction**
- Nested objects: **20-35% reduction**

## Usage

### CLI Commands

```bash
# Encode JSON to TOON
toon-encode [input.json] [-o output.toon]

# Decode TOON to JSON
toon-decode [input.toon] [-o output.json]

# Show token savings
toon-encode [input.json] --stats

# Pipe operations
cat data.json | toon-encode | toon-decode
```

### In Bash Scripts

```bash
# Encode a file
toon-encode data/rl/rl-agent-selection.json -o /tmp/compact.toon

# Encode from stdin
cat large-dataset.json | toon-encode

# Encode with stats
toon-encode agents.json --stats
```

### In Node.js / TypeScript

```javascript
import { encode, decode } from '@toon-format/toon'

// Compress before sending to agent
const json = { agents: [{ name: 'Codex', score: 0.94 }] }
const compact = encode(json)
// agents[1]{name,score}:
//   Codex,0.94

// Decode if needed
const restored = decode(compact)
```

## When to Use TOON

### ✅ Use TOON For:

- **Sending data to agents:** Reduce token cost of structured data in prompts
- **Tabular/array data:** Uniform rows of objects (agent scores, event logs, results)
- **Memory payloads:** Compact RL Q-scores before cron jobs
- **Streaming data:** Event logs, large JSON arrays
- **Context optimization:** Fit more data in fixed token budgets

### ❌ Don't Use TOON For:

- **Persistent storage:** Keep canonical data as JSON (git, databases)
- **APIs/webhooks:** External systems expect JSON
- **Config files:** JSON is standard (openclaw.json, etc.)
- **Non-uniform data:** Different object shapes per row
- **Human editing:** JSON is more familiar

## Real-World Examples

### Example 1: Sending Agent Roster

```bash
# Original JSON (85 tokens)
{
  "agents": [
    {"name": "Codex", "role": "dev", "score": 0.94},
    {"name": "Scout", "role": "research", "score": 0.92}
  ]
}

# TOON encoding (52 tokens) — 39% savings
agents[2]{name,role,score}:
  Codex,dev,0.94
  Scout,research,0.92

# Send to agent
sessions_send \
  --label navigator \
  --message "Route based on: $(toon-encode agents.json)"
```

### Example 2: RL Task Outcomes

```bash
# Store in JSON (canonical)
cat data/rl/rl-task-execution-log.jsonl

# Encode for cron job payload (token savings)
toon-encode data/rl/rl-agent-selection.json

# Result (254 bytes vs 305 bytes original)
task_types:
  code_review:
    Veritas: 0.94
    QA: 0.88
  research:
    Scout: 0.92
```

### Example 3: In a Workflow Script

```bash
#!/bin/bash
# scripts/workflows/code-review-qp.sh

# Encode Q-scores compactly
AGENT_SCORES=$(toon-encode data/rl/rl-agent-selection.json)

# Spawn agent with compact encoding (saves tokens)
sessions_spawn \
  --task "Review code. Available agents: $AGENT_SCORES" \
  --label code-review-task
```

## Workflow Integration

### Hybrid Strategy (Recommended)

1. **Store** everything as JSON (universal format)
2. **Encode to TOON** when sending to agents
3. **Decode if needed** for manipulation

```bash
# Helper function for ~/.bashrc
toon-send() {
  local agent=$1
  local json_file=$2
  local message=$3
  
  local compact=$(toon-encode "$json_file")
  sessions_send --label "$agent" --message "$message: $compact"
}

# Usage:
# toon-send navigator data/rl/rl-agent-selection.json "Latest Q-scores"
```

### Cron Job Integration

```bash
# Create a cron job with TOON payload
cron add \
  --schedule '{ "kind": "cron", "expr": "0 9 * * MON" }' \
  --payload "{ \"kind\": \"systemEvent\", \"text\": \"Review weekly data: $(toon-encode weekly-data.json)\" }"
```

## CLI Reference

```bash
toon-encode [options] [input]
  Options:
    -o, --output <path>      Write to file instead of stdout
    --stats                  Show token savings estimate
    --delimiter <char>       Use , (comma), \t (tab), or | (pipe)
    --indent <number>        Indentation size (default: 2)
    --key-folding <mode>     off (default) or safe
    --flatten-depth <n>      Max folded segments

toon-decode [options] [input]
  Options:
    -o, --output <path>      Write to file instead of stdout
    --indent <number>        Indentation size (default: 2)
    --strict                 Enable strict mode (default: true)
    --expand-paths <mode>    off (default) or safe
```

## Format Reference

TOON combines YAML-like indentation for objects with CSV-style arrays:

```toon
# Object properties
metadata:
  version: 2.1.0
  active: true

# Array of objects (CSV-like)
agents[3]{name,role,score}:
  Codex,developer,0.94
  Scout,researcher,0.92
  Cipher,security,0.95

# Nested structures
teams:
  backend:
    lead: Codex
    members[2]{name,level}:
      Alice,senior
      Bob,junior
```

## Performance & Savings

| Data Type | JSON | TOON | Savings |
|-----------|------|------|---------|
| Agent roster (3 agents) | 85 tokens | 52 tokens | **38%** |
| Event log (100 events) | ~1200 | ~480 | **60%** |
| GitHub repos (50 repos) | ~2000 | ~1060 | **47%** |
| RL Q-scores (11 agents) | 305 bytes | 254 bytes | **16%** |

**When to use:**
- **40%+ savings** → Always worth it (send to agents)
- **20-40% savings** → Worth it if context is tight
- **< 20% savings** → Use JSON (simpler, more compatible)

## Limitations & Notes

- **Non-uniform data:** TOON assumes array rows have consistent structure
- **Deep nesting:** JSON may be more efficient for 5+ levels of nesting
- **Ecosystem:** Fewer tools support TOON; convert back to JSON for processing
- **Human readability:** TOON requires knowledge of format; JSON is universal

## See Also

- [TOON Specification](https://github.com/toon-format/spec)
- [TOON GitHub Repo](https://github.com/toon-format/toon)
- [My TOON Review](../../docs/TOON_SECURITY_REVIEW.md)

---

**Created:** 2026-03-09  
**Author:** Morpheus (CLI wrapper automation)  
**Status:** Production-ready
