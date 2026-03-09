# TOON Encoding — Quick Start

## Install (Already Done ✅)
```bash
npm install -g @toon-format/cli
# CLI available globally
```

## 30-Second Usage

### Encode JSON
```bash
toon-encode data.json
# or pipe:
cat data.json | toon-encode
```

### Decode TOON
```bash
toon-decode data.toon
# or:
toon-encode data.json | toon-decode
```

### See Token Savings
```bash
toon-encode data.json --stats
```

## Common Commands

### Send agent data compactly
```bash
# Store: JSON (canonical)
cat data/rl/rl-agent-selection.json

# Send: TOON (compact)
COMPACT=$(toon-encode data/rl/rl-agent-selection.json)
sessions_send --label agent --message "Data: $COMPACT"
```

### Use in scripts
```bash
#!/bin/bash
# Encode RL scores before passing to agent

AGENT_SCORES=$(toon-encode data/rl/rl-agent-selection.json)

sessions_spawn \
  --task "Route task: $AGENT_SCORES" \
  --label navigator
```

### Add to ~/.bashrc
```bash
# Quick helpers
toon-send() {
  local agent=$1 json=$2 msg=$3
  local compact=$(toon-encode "$json")
  sessions_send --label "$agent" --message "$msg: $compact"
}

# Usage: toon-send navigator data/rl/rl-agent-selection.json "Q-scores"
```

## When to Use

✅ **Use TOON:**
- Sending data to agents (save 30-60% tokens)
- RL Q-scores to cron jobs
- Tabular data (arrays of objects)

❌ **Don't use TOON:**
- Persistent storage (keep JSON)
- Config files (use JSON)
- APIs (use JSON)

## Real Savings Examples

```
Agent roster:        85 tokens → 52 tokens  (39% savings)
RL Q-scores:        305 bytes → 254 bytes  (16% savings)
Event log (100x):  ~1200 → ~480 tokens    (60% savings)
```

## Practical Patterns

### Pattern 1: Agent Roster
```bash
echo '{"agents": [{"name": "Codex", "score": 0.94}]}' | toon-encode
# agents[1]{name,score}:
#   Codex,0.94
```

### Pattern 2: RL Data Transmission
```bash
toon-encode data/rl/rl-agent-selection.json | \
  xargs -I{} cron add --payload '{"text": "{}"}'
```

### Pattern 3: Batch Processing
```bash
for file in data/*.json; do
  toon-encode "$file" --stats
done
```

## Documentation

- **SKILL.md** — Full reference (format, CLI, integration)
- **README.md** — Integration patterns
- **examples/** — Practical workflows

## Location

```
~/.openclaw/workspace/skills/toon-encoding/
├── bin/
│   ├── toon-encode      # CLI wrapper
│   └── toon-decode      # CLI wrapper
├── lib/
│   └── index.js         # Node.js API
├── examples/
│   └── workflow-integration.sh  # 5 patterns
├── SKILL.md             # Full documentation
├── README.md
├── QUICKSTART.md        # This file
└── package.json
```

## Verification

```bash
# Test encoding
echo '{"test": [1, 2, 3]}' | toon-encode

# Test with your data
toon-encode data/rl/rl-agent-selection.json --stats
```

---

**Status:** Production-ready  
**Created:** 2026-03-09 21:25 GMT  
**Next step:** Use in agent messages & cron jobs for token savings
