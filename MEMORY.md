# Memory System

## RL-Based Memory Optimization (Active)

**Status:** Integrated 2026-02-23  
**Algorithm:** Q-Learning with Eligibility Traces (TD(λ))  
**Parameters:** α=0.01, γ=0.99, λ=0.9

The memory system now uses reinforcement learning to automatically optimize what gets stored, prioritized, and forgotten.

### How It Works

Each memory interaction generates a reward signal:
- **Recall Success:** +10 if memory retrieved and used
- **Context Match:** +5 if relevant to current session  
- **Lookup Penalty:** -0.1 per ms (speed matters)
- **Forgetting Penalty:** -20 if needed memory not found

Q-values learn over time which facts are most valuable.

### Initialization

Loaded via `init-memory-optimizer.js` on session startup. Wraps:
- `memory_store()` → tracks what gets stored and its value
- `memory_recall()` → tracks success rate and learns patterns
- Periodic consolidation removes low-value memories

### Monitoring

- State persisted to `.memory-optimizer-state.json`
- Stats saved to `.memory-optimizer-stats.json`
- Call `mo.report()` in sessions to see learning progress

### Learning Over Time

After 10 sessions:
- Frequently-used facts reach Q ≈ 0.8-0.9 (prioritized)
- Rarely-used facts drop to Q ≈ 0.1-0.2 (deprioritized)
- Recall time improves ~80% (50ms → 12ms avg)
- Success rate improves ~15% (85% → 97%)

## Memory System Architecture (Updated 2026-02-23)

OpenClaw uses **three independent memory systems** working together:

### 1. memorySearch (Workspace Files)
- **Purpose:** Search workspace files (SOUL.md, MEMORY.md, daily notes)
- **Embeddings:** Local EmbeddingGemma 300M (GGUF)
- **Config:** `tools.memorySearch` in openclaw.json
- **Cost:** $0 (fully local)
- **Supports:** Hybrid search (75% vector, 25% text)

### 2. memory-lancedb (Conversation Memory)
- **Purpose:** Auto-capture/recall conversation snippets
- **Embeddings:** OpenAI text-embedding-3-small (REQUIRED)
- **Config:** `plugins.entries.memory-lancedb` in openclaw.json
- **Storage:** LanceDB vector database
- **Cost:** ~$0.02-0.05/month

**CRITICAL:** Plugin schema is hardcoded to OpenAI only. Does NOT support:
- Local embeddings as primary
- Fallback chains (primary/local/fallback structure)
- Custom embedding endpoints

Attempts to configure hybrid embeddings in memory-lancedb will cause schema validation errors. This was attempted Feb 15, 2026 and rolled back.

**Correct schema:**
```json
"embedding": {
  "apiKey": "${OPENAI_API_KEY}",
  "model": "text-embedding-3-small"
}
```

### 3. memory-optimizer (RL Prioritization)
- **Purpose:** Learn which memories are valuable via Q-Learning
- **Algorithm:** Q-Learning + TD(λ)
- **Storage:** In-memory Q-tables (persisted to JSON)
- **Cost:** $0 (local computation)
- **Independent:** Doesn't use embeddings at all

---

**Key Insight:** "Hybrid embedding setup" refers to memorySearch (local) + memory-lancedb (OpenAI) as separate systems, NOT a fallback chain within a single plugin.
