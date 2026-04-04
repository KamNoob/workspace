# Knowledge Base (KB) Update Guide

**How to update data in the SQLite KB database**

---

## Quick Reference

| Method | Effort | Speed | Best For |
|--------|--------|-------|----------|
| **JSON File → Import** | 5 min | Fast | Adding new reference docs |
| **Direct SQL** | 3 min | Instant | Quick updates, corrections |
| **Python Script** | 10 min | Fast | Bulk updates, transformations |
| **kb-live-indexer** | Auto | Continuous | Real-time document sync |
| **Knowledge Extractor** | 15 min | Medium | Learning system integration |

---

## Method 1: Add JSON File & Import (Easiest)

### Step 1: Create JSON Document
Create `data/knowledge-base/my-topic.json`:

```json
{
  "metadata": {
    "title": "My Topic - Complete Guide",
    "type": "documentation",
    "source": "Your source",
    "created": "2026-04-04T16:00:00Z",
    "keywords": ["topic", "guide", "reference"]
  },
  "overview": "High-level summary...",
  "sections": [
    { "title": "Section 1", "content": "..." },
    { "title": "Section 2", "content": "..." }
  ],
  "best_practices": ["Practice 1", "Practice 2"],
  "resources": { "link1": "url1", "link2": "url2" }
}
```

### Step 2: Import to SQLite

**Option A: Use Python (recommended)**
```bash
python3 << 'EOF'
import sqlite3
import json
from pathlib import Path
from datetime import datetime

# Load JSON
with open('data/knowledge-base/my-topic.json', 'r') as f:
    doc = json.load(f)

# Connect & insert
conn = sqlite3.connect('data/morpheus.db')
cursor = conn.cursor()

cursor.execute('''
    INSERT INTO kb_documents (id, name, category, content, created_at, updated_at, version, source_file, file_size)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''', (
    doc['metadata']['title'].lower().replace(' ', '_'),
    doc['metadata']['title'],
    doc['metadata'].get('type', 'general'),
    json.dumps(doc, indent=2),
    doc['metadata']['created'],
    datetime.utcnow().isoformat(),
    1,
    'data/knowledge-base/my-topic.json',
    len(json.dumps(doc))
))

conn.commit()
doc_id = cursor.lastrowid
print(f"✅ Document indexed: ID {doc_id}")
conn.close()
EOF
```

**Option B: Use kb-live-indexer (automatic)**
```bash
bash scripts/kb-live-indexer.sh data/knowledge-base/my-topic.json
```

### Step 3: Verify & Commit

```bash
# Verify in SQLite
sqlite3 data/morpheus.db "SELECT id, name FROM kb_documents WHERE name LIKE '%my-topic%';"

# Commit to git
git add data/knowledge-base/my-topic.json
git commit -m "docs: Add my-topic guide to KB"
```

---

## Method 2: Direct SQL Update (Fastest)

### Update Existing Document Content

```bash
sqlite3 data/morpheus.db << 'EOF'
UPDATE kb_documents 
SET content = json('{"new": "content", "fields": "here"}'),
    updated_at = datetime('now')
WHERE id = 'document_id_here';
EOF
```

### Add New KB Entry

```bash
sqlite3 data/morpheus.db << 'EOF'
INSERT INTO kb_documents (id, name, category, content, created_at, updated_at, version)
VALUES (
  'my_doc_id',
  'My Document Title',
  'category_name',
  json('{"key": "value", "data": "here"}'),
  datetime('now'),
  datetime('now'),
  1
);
EOF
```

### Update Tags

```bash
sqlite3 data/morpheus.db << 'EOF'
INSERT INTO kb_tags (tag) VALUES ('new_tag');
INSERT INTO kb_document_tags (document_id, tag_id) 
SELECT 'doc_id', id FROM kb_tags WHERE tag = 'new_tag';
EOF
```

---

## Method 3: Python Script (Flexible)

Create `scripts/update-kb.py`:

```python
#!/usr/bin/env python3
import sqlite3
import json
from datetime import datetime
from pathlib import Path

class KBUpdater:
    def __init__(self, db_path='data/morpheus.db'):
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
    
    def add_document(self, doc_id, name, category, content, source_file=None):
        """Add or update a KB document"""
        cursor = self.conn.cursor()
        
        cursor.execute('''
            INSERT OR REPLACE INTO kb_documents 
            (id, name, category, content, created_at, updated_at, version, source_file, file_size)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            doc_id,
            name,
            category,
            json.dumps(content) if isinstance(content, dict) else content,
            datetime.utcnow().isoformat(),
            datetime.utcnow().isoformat(),
            1,
            source_file,
            len(str(content))
        ))
        
        self.conn.commit()
        return cursor.lastrowid
    
    def update_content(self, doc_id, new_content):
        """Update document content only"""
        cursor = self.conn.cursor()
        
        cursor.execute('''
            UPDATE kb_documents 
            SET content = ?, updated_at = ?
            WHERE id = ?
        ''', (
            json.dumps(new_content) if isinstance(new_content, dict) else new_content,
            datetime.utcnow().isoformat(),
            doc_id
        ))
        
        self.conn.commit()
    
    def add_tag(self, doc_id, tag):
        """Add tag to document"""
        cursor = self.conn.cursor()
        
        # Add tag if not exists
        cursor.execute('INSERT OR IGNORE INTO kb_tags (tag) VALUES (?)', (tag,))
        
        # Link tag to document
        cursor.execute('''
            INSERT OR IGNORE INTO kb_document_tags (document_id, tag_id)
            SELECT ?, id FROM kb_tags WHERE tag = ?
        ''', (doc_id, tag))
        
        self.conn.commit()
    
    def search(self, query):
        """Search KB"""
        cursor = self.conn.cursor()
        cursor.execute('''
            SELECT * FROM kb_documents 
            WHERE name LIKE ? OR content LIKE ?
        ''', (f'%{query}%', f'%{query}%'))
        
        return [dict(row) for row in cursor.fetchall()]
    
    def close(self):
        self.conn.close()

# Usage
if __name__ == '__main__':
    updater = KBUpdater()
    
    # Add new doc
    updater.add_document(
        'my_topic',
        'My Topic Guide',
        'reference',
        {'overview': 'Topic overview...', 'sections': []}
    )
    
    # Add tags
    updater.add_tag('my_topic', 'guide')
    updater.add_tag('my_topic', 'reference')
    
    # Update content
    updater.update_content('my_topic', {'updated': 'content'})
    
    updater.close()
    print("✅ KB updated")
```

**Run it:**
```bash
python3 scripts/update-kb.py
```

---

## Method 4: KB Live Indexer (Automatic)

Automatically watch `data/knowledge-base/` and sync new/modified files:

```bash
# One-time index
bash scripts/kb-live-indexer.sh

# Or with specific file
bash scripts/kb-live-indexer.sh data/knowledge-base/my-topic.json
```

**What it does:**
- Scans `data/knowledge-base/*.json` for changes
- Auto-indexes new files to SQLite
- Updates FTS search index
- Handles versioning

---

## Method 5: Knowledge Extractor (Learning Integration)

Automatically extract patterns from task outcomes and update KB:

```bash
# Extract patterns from recent tasks
julia scripts/ml/knowledge-extractor.jl --extract --limit 10

# Add extracted patterns to KB
julia scripts/ml/knowledge-extractor.jl --kb-update
```

**What it does:**
- Analyzes task outcomes
- Extracts reusable patterns
- Adds to `data/knowledge-base/extracted-patterns.json`
- Indexes to SQLite
- Updates Q-learning training data

---

## Method 6: KB-RAG Injector (Agent Integration)

Automatically inject KB data during agent execution:

```julia
# Update KB based on agent outcomes
julia scripts/ml/kb-rag-injector.jl --agent Codex --inject-outcomes

# Refresh KB for specific query
julia scripts/ml/kb-rag-injector.jl --refresh --query "architecture patterns"
```

---

## Real-World Examples

### Example 1: Add AWS Bedrock Guide

```bash
# 1. Create JSON file
cat > data/knowledge-base/aws-bedrock-guide.json << 'EOF'
{
  "metadata": {
    "title": "AWS Bedrock - Complete Guide",
    "type": "platform_documentation",
    "source": "AWS Documentation",
    "created": "2026-04-04T16:30:00Z",
    "keywords": ["AWS", "Bedrock", "LLM", "API"]
  },
  "overview": "AWS Bedrock is a fully managed service that offers access to foundation models...",
  "sections": [
    {"title": "Getting Started", "content": "..."},
    {"title": "API Reference", "content": "..."}
  ]
}
EOF

# 2. Import to KB
python3 scripts/update-kb.py  # or bash scripts/kb-live-indexer.sh

# 3. Verify
sqlite3 data/morpheus.db "SELECT * FROM kb_documents WHERE name LIKE '%Bedrock%';"

# 4. Commit
git add data/knowledge-base/aws-bedrock-guide.json
git commit -m "docs: Add AWS Bedrock guide to KB"
```

### Example 2: Update Existing Document

```bash
# Direct SQL update
sqlite3 data/morpheus.db << 'EOF'
UPDATE kb_documents 
SET content = json_set(content, '$.sections[0].updated', '2026-04-04'),
    updated_at = datetime('now')
WHERE name = 'Azure Foundry - Complete Guide';
EOF
```

### Example 3: Bulk Import Multiple Files

```bash
for file in data/knowledge-base/*.json; do
  bash scripts/kb-live-indexer.sh "$file"
done
echo "✅ All KB files indexed"
```

---

## Monitoring & Verification

### Check KB Status

```bash
# List all documents
sqlite3 data/morpheus.db "SELECT id, name, created_at FROM kb_documents;"

# Count by category
sqlite3 data/morpheus.db "SELECT category, COUNT(*) FROM kb_documents GROUP BY category;"

# Search for topic
sqlite3 data/morpheus.db "SELECT * FROM kb_documents WHERE name LIKE '%topic%';"

# Check FTS index
sqlite3 data/morpheus.db "SELECT COUNT(*) FROM kb_search;"
```

### Validate Updates

```bash
# Check last modified
ls -lh data/knowledge-base/*.json

# Verify JSON syntax
python3 -m json.tool data/knowledge-base/my-topic.json > /dev/null && echo "✅ Valid JSON"

# Check SQLite integrity
sqlite3 data/morpheus.db "PRAGMA integrity_check;"
```

---

## Best Practices

### Do ✅
- **Commit JSON files to git** (source of truth)
- **Use meaningful doc IDs** (lowercase, underscores)
- **Add metadata** (title, source, date, keywords)
- **Tag documents** (for easier search)
- **Verify after updates** (check SQLite)
- **Use FTS for search** (fast full-text queries)
- **Keep JSON readable** (4-space indent)

### Don't ❌
- Edit SQLite directly without backups
- Skip git commits (lose history)
- Mix JSON and SQL as dual sources
- Forget to update `updated_at` timestamp
- Leave untagged documents (harder to find)
- Import invalid JSON without validation
- Assume changes persisted without verify

---

## Troubleshooting

### Document Not Appearing in Search

```bash
# Reindex FTS
sqlite3 data/morpheus.db "VACUUM; ANALYZE;"

# Or use kb-live-indexer
bash scripts/kb-live-indexer.sh data/knowledge-base/my-doc.json
```

### Duplicate Documents

```bash
# Find duplicates
sqlite3 data/morpheus.db "SELECT name, COUNT(*) FROM kb_documents GROUP BY name HAVING COUNT(*) > 1;"

# Delete duplicate (keep latest)
sqlite3 data/morpheus.db "DELETE FROM kb_documents WHERE id NOT IN (SELECT id FROM kb_documents ORDER BY updated_at DESC LIMIT 1);"
```

### Corrupted JSON in SQLite

```bash
# Export and validate
sqlite3 data/morpheus.db ".mode json" "SELECT * FROM kb_documents WHERE id='doc_id';" > backup.json

# Fix manually, then re-import
python3 scripts/update-kb.py
```

---

## Summary

| Task | Method | Time |
|------|--------|------|
| Add new reference doc | Method 1 (JSON + import) | 5 min |
| Quick correction | Method 2 (SQL) | 2 min |
| Bulk update | Method 3 (Python script) | 10 min |
| Auto-sync folder | Method 4 (kb-live-indexer) | Continuous |
| Learning integration | Method 5 (Knowledge extractor) | 15 min |
| Agent integration | Method 6 (RAG injector) | 10 min |

**Recommended:** Start with Method 1 (JSON + import) for new docs, use Method 2 (SQL) for quick corrections, and Method 4 (kb-live-indexer) for automatic sync.

---

_Created: 2026-04-04 16:18 GMT+1_  
_Reference: Phase 7B SQLite Migration Complete_
