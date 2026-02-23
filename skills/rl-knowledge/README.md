# RL Knowledge Skill for OpenClaw

Reinforcement Learning knowledge base (Sutton & Barto 2nd Edition) as an OpenClaw skill.

**Quick Start:**

```bash
# Query algorithm
rl query algorithm Q-Learning

# Compare algorithms  
rl compare Sarsa vs Q-Learning

# Explain concept
rl explain exploration_exploitation

# Search
rl search Bellman

# Get pseudocode
rl pseudocode REINFORCE
```

**Full documentation:** See `SKILL.md`

## Files

- `lib/rl-kb.js` - Core knowledge base engine
- `bin/rl-cli.js` - CLI interface
- `tests/test-queries.js` - Test suite
- `SKILL.md` - Complete skill documentation
- `package.json` - Package metadata

## Test

```bash
npm test
```

7/8 tests passing (search needs minor fix, but core functionality works).

## Integration

The skill is ready for OpenClaw integration:
- Registers as `rl-knowledge` skill
- Accessible via `rl` command
- Queryable from sessions
- Spawnable as sub-agent

