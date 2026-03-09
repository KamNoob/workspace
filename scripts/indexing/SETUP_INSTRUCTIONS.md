# Qdrant Indexer Setup

## Environment Issue

The indexing system requires Python packages that aren't available in the current environment:

- `qdrant-client` — Qdrant vector database client
- `sentence-transformers` — Embedding model library

## Solution: Create Virtual Environment

Follow these steps to set up a dedicated Python environment:

### 1. Create Virtual Environment

```bash
cd /home/art/.openclaw/workspace
python3 -m venv venv
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install --upgrade pip
pip install qdrant-client sentence-transformers
```

### 3. Run Indexer in Virtual Environment

**Quick indexing:**
```bash
source /home/art/.openclaw/workspace/venv/bin/activate
python3 scripts/indexing/qdrant_indexer.py --full --workspace /home/art/.openclaw/workspace
```

**Or use the wrapper script:**
```bash
# Temporarily activate venv for this command
source /home/art/.openclaw/workspace/venv/bin/activate && bash scripts/qdrant-index.sh full
```

### 4. Test Indexing

```bash
source /home/art/.openclaw/workspace/venv/bin/activate
python3 scripts/indexing/qdrant_indexer.py --test-query "agent configuration"
```

---

## Alternative: Use System Package Manager (Debian/Ubuntu)

If you have sudo access:

```bash
sudo apt-get update
sudo apt-get install python3-qdrant python3-sentence-transformers python3-pip
```

Then run normally:
```bash
python3 scripts/indexing/qdrant_indexer.py --full
```

---

## Cron Setup with Virtual Environment

If using the venv approach, update crontab to activate it:

```bash
# Edit crontab
crontab -e

# Add this line (all on one line):
0 2 * * * source /home/art/.openclaw/workspace/venv/bin/activate && bash /home/art/.openclaw/workspace/scripts/qdrant-index.sh >> /home/art/.openclaw/workspace/data/logs/qdrant-cron.log 2>&1
```

---

## Verification

Once dependencies are installed, verify:

```bash
python3 -c "from qdrant_client import QdrantClient; from sentence_transformers import SentenceTransformer; print('✓ Ready!')"
```

Then proceed with indexing.
