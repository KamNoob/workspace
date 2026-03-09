# TOON Encoding Skill for OpenClaw

Compress JSON by **30-60%** for efficient LLM prompts using Token-Oriented Object Notation (TOON).

## Quick Start

### Install Dependencies
```bash
npm install --save-dev @toon-format/toon @toon-format/cli tokenx
```

### CLI Usage

```bash
# Encode JSON to TOON
toon-encode agents.json

# Show token savings
toon-encode agents.json --stats

# Decode back to JSON
toon-decode data.toon

# Pipe operations
cat data.json | toon-encode | toon-decode
```

### In Bash Scripts

```bash
#!/bin/bash
# Encode RL data before sending to agents

AGENT_SCORES=$(./bin/toon-encode data/rl/rl-agent-selection.json)

sessions_send \
  --label navigator \
  --message "Q-scores available: $AGENT_SCORES"
```

### In Node.js

```javascript
import { encodeToon, decodeToon, encodeForAgent } from '@openclaw-skills/toon-encoding'

// Quick encode
const compact = encodeToon({ agents: [{ name: 'Codex', score: 0.94 }] })
console.log(compact)
// agents[1]{name,score}:
//   Codex,0.94

// Optimize for agent transmission
const agentReady = encodeForAgent(largeData)

// Decode if needed
const restored = decodeToon(compact)
```

## Common Patterns

### Pattern 1: Send RL Data to Agents

```bash
# Store canonical JSON
cat data/rl/rl-agent-selection.json

# Encode for transmission
COMPACT=$(toon-encode data/rl/rl-agent-selection.json)

# Send to agent with fewer tokens
sessions_send \
  --label "my-agent" \
  --message "Agent selection data: $COMPACT"
```

### Pattern 2: Cron Job with TOON Payload

```bash
# Create cron with compact encoding
cron add \
  --schedule '{ "kind": "cron", "expr": "0 9 * * MON" }' \
  --payload "{ \"kind\": \"systemEvent\", \"text\": \"Weekly review: $(toon-encode weekly-data.json)\" }"
```

### Pattern 3: Hybrid Storage + Transmission

```bash
# Store everything as JSON (git-friendly)
git add data/rl/rl-agent-selection.json

# Encode only when sending to agents (save tokens)
toon-send() {
  local json_file=$1
  local agent=$2
  local msg=$3
  
  local compact=$(toon-encode "$json_file")
  sessions_send --label "$agent" --message "$msg: $compact"
}

toon-send data/rl/rl-agent-selection.json navigator "Latest Q-scores"
```

## Token Savings Examples

### Agent Roster (85 → 52 tokens)
```json
// JSON: 85 tokens
{
  "agents": [
    {"name": "Codex", "role": "dev", "score": 0.94},
    {"name": "Scout", "role": "research", "score": 0.92}
  ]
}
```

```
// TOON: 52 tokens (39% savings)
agents[2]{name,role,score}:
  Codex,dev,0.94
  Scout,research,0.92
```

### RL Q-Scores (305 → 254 bytes)
```bash
$ toon-encode data/rl/rl-agent-selection.json --stats

task_types:
  code_review:
    Veritas: 0.94
    QA: 0.88
  research:
    Scout: 0.92

Token estimates: ~85 (JSON) → ~53 (TOON)
Saved ~32 tokens (-37.6%)
```

## When to Use

✅ **Use TOON:**
- Sending structured data to agents
- Tabular/array data (uniform rows)
- Memory payloads for cron jobs
- Fitting more data in context windows

❌ **Don't use TOON:**
- Persistent storage (keep as JSON)
- APIs/webhooks (use JSON)
- Config files (JSON standard)
- Non-uniform data
- When human editing is frequent

## Documentation

See [SKILL.md](./SKILL.md) for:
- Detailed format reference
- Advanced options
- Full CLI documentation
- Integration patterns
- Performance benchmarks

## References

- [TOON Specification](https://github.com/toon-format/spec)
- [TOON GitHub Repo](https://github.com/toon-format/toon)

---

**Created:** 2026-03-09  
**Status:** Production-ready  
**Tested with:** OpenClaw 2026.3.2
