# Qdrant Integration Setup Guide

## Overview

Qdrant is a local vector database used for semantic search across workspace documents. The indexing system automatically extracts text from `.md`, `.txt`, and `.json` files, generates embeddings using **sentence-transformers** (local, no API cost), and stores them in Qdrant for hybrid search.

**Current Status:** ✅ Live  
**Service:** http://localhost:6333  
**Collection:** `knowledge` (384-dim embeddings)  
**Storage:** `/home/art/.openclaw/data/qdrant/`

---

## Quick Start

### 1. Verify Qdrant is Running

```bash
curl http://localhost:6333/collections
```

Expected response:
```json
{"result":{"collections":[{"name":"knowledge"}]},"status":"ok"}
```

### 2. Install Dependencies

```bash
pip install qdrant-client sentence-transformers
```

### 3. Index Your Workspace

**Incremental indexing** (only changed files):
```bash
bash scripts/qdrant-index.sh
```

**Full indexing** (re-index everything):
```bash
bash scripts/qdrant-index.sh full
```

Expected output:
```
[2026-03-09 13:35:00] [INFO] Checking Qdrant health...
[2026-03-09 13:35:00] [INFO] ✓ Qdrant is running
[2026-03-09 13:35:00] [INFO] Starting Python indexer...
[2026-03-09 13:35:02] [INFO] ✓ Connected to Qdrant at http://localhost:6333
[2026-03-09 13:35:05] [INFO] Loading embedding model...
[2026-03-09 13:35:15] [INFO] ✓ Embedding model loaded
[2026-03-09 13:35:15] [INFO] Indexing 47 files...
...
[2026-03-09 13:36:30] [INFO] ========================================================
[2026-03-09 13:36:30] [INFO] INDEXING COMPLETE
[2026-03-09 13:36:30] [INFO] Files indexed: 47
[2026-03-09 13:36:30] [INFO] Total chunks: 523
[2026-03-09 13:36:30] [INFO] ========================================================
```

### 4. Test Search

```bash
python3 scripts/indexing/qdrant_indexer.py --test-query "how to configure agents"
```

Expected output:
```
[INFO] Testing search: 'how to configure agents'
[INFO]   Score: 0.812 | agents/AGENTS_CONFIG.md (chunk 0)
[INFO]   Score: 0.789 | agents/PROCESS_FLOWS.md (chunk 2)
[INFO]   Score: 0.756 | docs/ml/training.md (chunk 5)
```

---

## What Gets Indexed

The indexer scans these directories:
- `docs/` — Documentation, guides, research
- `agents/` — Agent definitions, workflows
- `config/` — System configuration
- `scripts/` — Automation scripts
- `memory/` — Session notes
- `prototype/` — Experiments and prototypes

File types: `.md`, `.txt`, `.json`  
**Skipped:** `node_modules/`, `.git/`, `__pycache__/`, etc.

---

## How It Works

### Embedding Model

- **Model:** `sentence-transformers/all-MiniLM-L6-v2`
- **Output:** 384-dimensional vectors
- **Size:** ~133MB (lightweight, CPU-friendly)
- **Cost:** $0 (runs locally)

### Text Chunking

- **Chunk size:** 500 words
- **Overlap:** 100 words
- **Rationale:** Overlapping chunks preserve context at boundaries

### Indexing State

- **State file:** `data/.qdrant_index_state.json`
- **Tracks:** SHA256 hash of each indexed file
- **Purpose:** Skip unchanged files on incremental runs
- **Example:**
```json
{
  "files": {
    "docs/guides/setup.md": "a3f4c...",
    "agents/AGENTS_CONFIG.md": "b9e2d..."
  },
  "last_full_index": "2026-03-09T13:35:00.000Z"
}
```

---

## Cron Setup (Optional)

Automatically re-index documents daily at 02:00 GMT:

```bash
# Edit crontab
crontab -e

# Add this line
0 2 * * * bash /home/art/.openclaw/workspace/scripts/qdrant-index.sh >> /home/art/.openclaw/workspace/data/logs/qdrant-cron.log 2>&1
```

Verify:
```bash
crontab -l | grep qdrant
```

---

## Troubleshooting

### Qdrant Not Running

```bash
# Check if running
ps aux | grep qdrant

# Restart
docker restart qdrant
# or if running as systemd service
sudo systemctl restart qdrant
```

### Dependency Errors

```
Error: qdrant-client not installed
Error: sentence-transformers not installed
```

**Fix:**
```bash
pip install --upgrade qdrant-client sentence-transformers
```

### Collection Empty After Indexing

```bash
# Check collection status
curl http://localhost:6333/collections/knowledge

# Look for "points_count": 0 (empty) or > 0 (has data)
```

**If empty:**
- Verify files exist in workspace directories
- Run with `--full` flag to force re-index
- Check logs: `tail -100 data/logs/qdrant-indexing.log`

### Slow Indexing

Normal performance:
- Small workspace (<50 files): ~2-5 minutes
- Medium workspace (50-200 files): ~5-15 minutes
- Large workspace (200+ files): ~15-60 minutes

**To speed up:**
- Run on a machine with more cores (embedding parallelizes)
- Check available disk space in `/home/art/.openclaw/data/qdrant/`

### High Memory Usage

The embedding model uses ~500MB RAM during indexing. If you hit memory limits:

```bash
# Check available RAM
free -h

# Reduce batch size in indexer (edit qdrant_indexer.py)
BATCH_SIZE = 16  # default is 32
```

---

## Python API Usage

### Manual Search

```python
from qdrant_client import QdrantClient

client = QdrantClient(url="http://localhost:6333")

# Search for documents
results = client.search(
    collection_name="knowledge",
    query_vector=[...384 dims...],
    limit=5
)

for result in results:
    print(f"Score: {result.score}")
    print(f"File: {result.payload['filename']}")
    print(f"Text: {result.payload['text'][:200]}")
```

### Check Collection Stats

```python
collection_info = client.get_collection("knowledge")
print(f"Documents: {collection_info.points_count}")
print(f"Vector size: {collection_info.config.params.vectors.size}")
```

---

## Advanced Configuration

### Tuning Hybrid Search

In `~/.openclaw/openclaw.json`:

```json
{
  "memorySearch": {
    "query": {
      "hybrid": {
        "enabled": true,
        "vectorWeight": 0.85,    // 85% semantic, 15% keyword
        "textWeight": 0.15
      }
    }
  }
}
```

**Semantic weight** (0.85): Favor meaning-based matches  
**Keyword weight** (0.15): Favor exact term matches

---

## Performance Metrics

Typical results on this system:

| Operation | Time |
|-----------|------|
| Index 50 documents | 5-10 min |
| Incremental sync (10 changed) | 1-2 min |
| Single search query | <100ms |
| Bulk search (10 queries) | ~1s |

---

## Maintenance

### Reset Everything

```bash
# Wipe the database
curl -X DELETE http://localhost:6333/collections/knowledge

# Re-index from scratch
bash scripts/qdrant-index.sh full
```

### Backup Qdrant Data

```bash
# Backup (Qdrant snapshots)
curl -X POST http://localhost:6333/collections/knowledge/snapshots

# List snapshots
curl http://localhost:6333/collections/knowledge/snapshots
```

### Export Indexed Files

```bash
cat data/.qdrant_index_state.json | jq '.files | keys[]'
```

---

## Questions?

- **Qdrant docs:** https://qdrant.tech/documentation/
- **Sentence-transformers:** https://www.sbert.net/
- **Workspace logs:** `data/logs/qdrant-indexing.log`
