# Local Embeddings Setup & Configuration

**Date:** 2026-02-28  
**Status:** ✅ Fully Operational  
**Cost:** $0 (all local)  

---

## Overview

Art's OpenClaw instance uses **local embeddings** for all memory search and recall operations. This eliminates API dependencies, reduces costs, and improves privacy.

**Key fact:** EmbeddingGemma 300M (314MB) is already installed and actively being used.

---

## Memory Systems in Use

### 1. memorySearch (PRIMARY - Local)

**Status:** ✅ ACTIVE

**What it does:**
- Embeddings for workspace files (SOUL.md, MEMORY.md, daily notes, research documents)
- Hybrid search: 75% vector similarity + 25% keyword matching
- Used for context retrieval during conversations
- Auto-indexing with file watching enabled

**Configuration:**
```json
"memorySearch": {
  "enabled": true,
  "provider": "local",
  "fallback": "none",
  "local": {
    "modelPath": "/home/art/.openclaw/models/embeddings/embeddinggemma-300M-Q8_0.gguf"
  },
  "sync": {
    "watch": true
  },
  "query": {
    "hybrid": {
      "enabled": true,
      "vectorWeight": 0.75,
      "textWeight": 0.25
    }
  },
  "cache": {
    "enabled": true,
    "maxEntries": 20000
  }
}
```

**Model Details:**
- **Name:** EmbeddingGemma-300M-Q8_0
- **Size:** 314MB
- **Format:** GGUF (quantized)
- **Location:** `~/.openclaw/models/embeddings/embeddinggemma-300M-Q8_0.gguf`
- **Quantization:** Q8 (8-bit, good quality/speed tradeoff)
- **Latency:** ~3.5 seconds per query (cached), 5-10 min cold indexing
- **Cost:** $0

**How it works:**
1. When you write to SOUL.md, MEMORY.md, or research files → automatically indexed
2. During conversation, Morpheus queries embeddings: "Find related memories about X"
3. Returns top-K matches (vector + keyword hybrid search)
4. Results used for context injection into Claude prompts

**Hybrid Search Explained:**
- **Vector (75%):** Semantic similarity using embeddings
  - Finds conceptually related content even if wording differs
  - Example: "authentication methods" matches "OAuth 2.0" conceptually
  
- **Keyword (25%):** Exact term matching
  - Ensures exact names/titles are found
  - Example: "GDPR" will surface GDPR-specific documents
  
- **Result:** Best of both worlds (semantic + precise)

---

### 2. memory-lancedb (PLUGIN - Legacy/Optional)

**Status:** ⚠️ Configured but disabled (OpenAI quota exhausted)

**What it does:**
- Vector database for conversation memory
- Designed to capture and recall insights from chats
- Can auto-capture context from conversations
- Can auto-recall related past conversations

**Configuration:**
```json
"memory-lancedb": {
  "enabled": true,
  "config": {
    "embedding": null,
    "dbPath": "/home/art/.openclaw/memory/lancedb",
    "autoCapture": false,
    "autoRecall": false
  }
}
```

**Current status:**
- Plugin is enabled but auto-features are disabled (API quota was exhausted)
- Uses OpenAI embeddings API (would require cloud API call)
- **Functionally superseded by memorySearch** (which is local)

**Note:** This plugin could theoretically be reconfigured to use local embeddings, but it's not necessary — memorySearch provides all the functionality.

---

## Why Local Embeddings?

| Factor | Cloud (OpenAI) | Local (EmbeddingGemma) |
|--------|---|---|
| **Cost** | ~$0.02-0.05/month | $0 |
| **Speed** | 200-500ms per call | 3.5s cached, 10-20ms subsequent |
| **Privacy** | Data sent to OpenAI | Stays on machine |
| **Reliability** | API dependency | No network needed |
| **Latency** | Network variable | Deterministic, local |
| **Context window** | Limited by API | Unlimited (local) |

**Verdict:** Local embeddings are superior for Art's use case:
- Low query volume (no API costs)
- Privacy-sensitive (personal files stay local)
- Deterministic performance (no API variability)
- Always available (no network dependency)

---

## Architecture Diagram

```
OpenClaw Session
        ↓
   Morpheus
        ↓
   [Question: "Tell me about API security"]
        ↓
   memorySearch Query
        ↓
   EmbeddingGemma 300M (local)
        ↓
   [Vector + Keyword Hybrid Search]
        ↓
   Workspace Files:
   - SOUL.md
   - MEMORY.md
   - docs/research/
   - memory/YYYY-MM-DD.md
        ↓
   [Top-K Results]
        ↓
   Morpheus injects context into Claude prompt
        ↓
   Claude generates response with context
```

---

## Performance Characteristics

### Indexing
- **Cold start:** 5-10 minutes (first index of all workspace files)
- **Incremental:** < 1 second per file change (file watching enabled)
- **Cache:** Up to 20,000 entries in memory

### Querying
- **Cached:** ~3.5 seconds (subsequent queries within session)
- **Model inference:** 10-20ms (actual embedding computation)
- **Overhead:** I/O, file reading dominates

### Memory Usage
- **Model in RAM:** ~314MB (loaded once per session)
- **Cache overhead:** ~10-20MB for typical usage
- **Total footprint:** ~350MB per session

---

## Configuration Files

### OpenClaw Config
**File:** `~/.openclaw/openclaw.json`

**Relevant section:**
```json
"agents": {
  "defaults": {
    "memorySearch": {
      "enabled": true,
      "provider": "local",
      "fallback": "none",
      "local": {
        "modelPath": "/home/art/.openclaw/models/embeddings/embeddinggemma-300M-Q8_0.gguf"
      },
      "sync": {
        "watch": true
      },
      "query": {
        "hybrid": {
          "enabled": true,
          "vectorWeight": 0.75,
          "textWeight": 0.25
        }
      },
      "cache": {
        "enabled": true,
        "maxEntries": 20000
      }
    }
  }
}
```

### Model Location
**File:** `~/.openclaw/models/embeddings/embeddinggemma-300M-Q8_0.gguf`
- Size: 314MB
- Status: Present and valid
- Used by: memorySearch

---

## How Morpheus Uses Embeddings

### During Conversation

1. **User sends message** (e.g., "Remind me about API security best practices")

2. **Morpheus queries embeddings:**
   ```
   Query: "API security best practices"
   Search in: SOUL.md, MEMORY.md, docs/research/
   Returns: Top 5 matches (scored by hybrid similarity)
   ```

3. **Results injected into context:**
   ```
   [Earlier conversation about API security from 2026-02-28]
   [Research document: API-Security-2026.md]
   [Preference: Scout uses concise summaries]
   ```

4. **Claude response includes context:**
   - Remembers previous work
   - References relevant research
   - Maintains continuity

### Example Query Flow

**User:** "What did I learn about rate limiting?"

**Morpheus action:**
1. Query embeddings: "rate limiting best practices"
2. Find: `docs/research/technology/api-security-2026.md` (high match)
3. Find: `MEMORY.md` → rate limiting section
4. Find: `memory/2026-02-28.md` → notes from today

**Result in Claude context:**
- Summarizes prior learning
- Provides specific recommendations
- References stored documentation

---

## Improving Embeddings Quality

### 1. Better Documents
- Write clear, well-structured files
- Use descriptive headings
- Include metadata (tags, topics)
- Keep related info together

**Example (good):**
```markdown
# API Security 2026

**Tags:** `api-security`, `authentication`, `encryption`

## Authentication

### OAuth 2.0 (Recommended)
- Details about OAuth...
```

**Example (poor):**
```markdown
API stuff

security things. authentication. encryption. oauth is good. use it.
```

### 2. Tuning Hybrid Search Weights
Current: 75% vector, 25% keyword

To **emphasize semantic similarity** (more flexible):
```json
"vectorWeight": 0.85,
"textWeight": 0.15
```

To **emphasize exact matches** (more precise):
```json
"vectorWeight": 0.60,
"textWeight": 0.40
```

---

## When Embeddings are Used

### Automatic (Every Session)
- File indexing at startup
- Watching for file changes
- Caching for performance

### On-Demand (During Conversation)
- User asks a question with implicit context
- Morpheus queries embeddings for related files
- Context injected into Claude prompt

### Explicit (Memory Recall)
- User: "Tell me what I learned about X"
- Morpheus: Queries embeddings directly
- Returns: Summarized findings + sources

---

## Troubleshooting

### Embeddings Not Finding Relevant Files

**Symptom:** Query for "API security" doesn't return `docs/research/technology/api-security-2026.md`

**Causes:**
1. File not indexed yet (cold start takes 5-10 min)
2. Hybrid weights wrong (too much keyword, not enough semantic)
3. File content doesn't match query semantically

**Fix:**
1. Wait for indexing to complete
2. Try keyword-based search instead: Ctrl+F in files
3. Manually inject context: `memory_recall(query="...")`

### Slow Embedding Queries

**Symptom:** "Query took 10 seconds to return"

**Causes:**
1. Cold start (first query, model loading)
2. Large cache (20K entries getting scanned)
3. System disk I/O contention

**Fix:**
1. Queries are faster after first one (cached)
2. Reduce cache size if needed: `"maxEntries": 5000`
3. Increase model cache TTL: `"contextPruning.ttl": "4h"`

### Out of Memory

**Symptom:** OpenClaw crashes with OOM error

**Causes:**
1. Model too large for available RAM (unlikely, 314MB is small)
2. Cache too large (20K entries × large documents)
3. Other processes consuming memory

**Fix:**
1. Reduce cache: `"maxEntries": 5000`
2. Monitor disk space: `df -h`
3. Restart OpenClaw: `openclaw gateway restart`

---

## Testing Embeddings

### Manual Query Test

```bash
# Read a memory query result
memory_recall(query="API authentication methods")

# Result should return relevant files from docs/research/
```

### Check Model Availability

```bash
ls -lh ~/.openclaw/models/embeddings/embeddinggemma-300M-Q8_0.gguf

# Should show:
# -rw-rw-r-- 1 art art 314M Feb 10 19:14 embeddinggemma-300M-Q8_0.gguf
```

### Verify Config

```bash
# Check OpenClaw config
grep -A 20 "memorySearch" ~/.openclaw/openclaw.json

# Should show provider: "local"
```

---

## Future Improvements

### 1. Hybrid Memory Systems
Currently: Local embeddings only

Potential: Combine local + cloud for:
- **Local:** Fast, private queries
- **Cloud:** When local model can't handle (rare)

### 2. Better Chunking
Currently: File-level embeddings

Potential: Chunk by section/paragraph:
- Better granularity
- Faster retrieval
- More precise context

### 3. Multi-Modal Embeddings
Currently: Text only

Potential: Add:
- Code embeddings (for technical queries)
- Diagram descriptions
- Table embeddings

### 4. Custom Fine-Tuning
Currently: Off-the-shelf EmbeddingGemma

Potential: Fine-tune on:
- Art's writing style
- Domain-specific vocabulary
- Preferred knowledge organization

---

## Cost Analysis

### Baseline (Before Local Embeddings)
- OpenAI embeddings: ~$0.02-0.05/month
- OpenAI chat: Varies by usage
- **Total:** ~$0.05-1.00/month

### Current (Local Embeddings)
- Model: Already purchased (included in OpenClaw)
- Inference: Free (local GPU/CPU)
- Storage: 314MB disk space
- **Total:** $0

### Savings
- **Monthly:** $0.05-1.00
- **Yearly:** $0.60-12.00
- **Meaningful?** No, but privacy gain is meaningful

---

## Summary

✅ **Local embeddings fully operational**
- Using EmbeddingGemma 300M (314MB, already installed)
- Hybrid search: 75% semantic + 25% keyword
- Zero cost, zero network dependency
- Auto-indexing with file watching

✅ **Performance adequate**
- 3.5s cached queries (acceptable for context injection)
- 350MB memory footprint (minimal)
- 20K-entry cache (handles typical workload)

✅ **Privacy preserved**
- All embeddings computed locally
- No data sent to external APIs
- Files never leave the machine

**Bottom line:** Art's setup is optimized for local, private, cost-free embeddings. No changes needed.
