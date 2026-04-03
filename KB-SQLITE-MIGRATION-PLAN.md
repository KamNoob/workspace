# Knowledge Base SQLite Migration Plan

**Status:** ⏳ READY FOR IMPLEMENTATION (schema exists, KB tables missing)  
**Priority:** Medium (completes v2.0 SQLite architecture)  
**Effort:** 1-2 hours (schema already there, just add KB tables)  
**Timeline:** This week (quick win)
**Relevant:** RELEASE_v2.0_SQLITE_PRODUCTION.md (March 28 deployment)

---

## Current State

### JSON File-Based KB (Current)
**Location:** `data/kb/`, `data/knowledge-base/`, `data/knowledge-bases/`

**Files:**
- `data/kb/nikola-tesla-verified.json` — Tesla biographical data
- `data/kb/nikola-tesla-complete-projects.json` — Tesla projects
- `data/kb/nikola-tesla-research-index.md` — Tesla research index
- `data/kb/knowledge-base.json` — Main KB index
- `data/kb/oracle-cloud-infrastructure-2026.json` — OCI/Fusion KB (just added)
- `data/kb/oracle-cloud-infrastructure-2026.md` — OCI/Fusion reference
- `data/knowledge-bases/arduino-reference-kb.json` — Arduino KB
- `data/knowledge-base/extracted-patterns.json` — Extracted patterns

**Issues:**
- ❌ File reads on every query (slow for large KBs)
- ❌ No indexing (linear search)
- ❌ Manual parsing JSON
- ❌ Duplicate data (JSON + markdown)
- ✅ Human-readable but inefficient for agent queries

### SQLite Database (Partially Migrated)
**Location:** `data/morpheus.db`

**Current Tables (from Phase 7B):**
- `rl_state` — Q-learning values
- `agent_tasks` — Agent-task matrix
- `audit_logs` — Outcome logs
- `memory_state` — Memory optimizer state

**Missing:**
- ❌ Knowledge base tables
- ❌ Document indexing
- ❌ Vector embeddings (optional but useful)

---

## Migration Plan

### Phase 1: Schema Design (30 min)

Create KB tables in morpheus.db:

```sql
-- Knowledge Base Documents
CREATE TABLE kb_documents (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    category TEXT,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    version INTEGER DEFAULT 1
);

-- Knowledge Base Sections
CREATE TABLE kb_sections (
    id INTEGER PRIMARY KEY,
    document_id INTEGER NOT NULL,
    section_name TEXT NOT NULL,
    section_content TEXT,
    order_index INTEGER,
    FOREIGN KEY (document_id) REFERENCES kb_documents(id)
);

-- Knowledge Base Tags
CREATE TABLE kb_tags (
    id INTEGER PRIMARY KEY,
    tag_name TEXT UNIQUE NOT NULL,
    category TEXT
);

-- Document-Tag Mapping
CREATE TABLE kb_document_tags (
    id INTEGER PRIMARY KEY,
    document_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    FOREIGN KEY (document_id) REFERENCES kb_documents(id),
    FOREIGN KEY (tag_id) REFERENCES kb_tags(id)
);

-- Search Index (for FTS - Full Text Search)
CREATE VIRTUAL TABLE kb_search USING fts5(
    name,
    section_name,
    content,
    category
);

-- Indexes for performance
CREATE INDEX idx_kb_category ON kb_documents(category);
CREATE INDEX idx_kb_created ON kb_documents(created_at);
```

### Phase 2: Data Migration (1 hour)

Write migration script:

```julia
# scripts/ml/kb-to-sqlite-migration.jl

function migrate_kb_json_to_sqlite()
    using SQLite
    using JSON
    
    db = SQLite.DB("data/morpheus.db")
    
    # Migrate each KB file
    kb_files = [
        "data/kb/nikola-tesla-verified.json",
        "data/kb/nikola-tesla-complete-projects.json",
        "data/kb/knowledge-base.json",
        "data/kb/oracle-cloud-infrastructure-2026.json",
        "data/knowledge-bases/arduino-reference-kb.json",
        "data/knowledge-base/extracted-patterns.json"
    ]
    
    for file_path in kb_files
        if isfile(file_path)
            data = JSON.parsefile(file_path)
            
            # Insert into kb_documents
            name = basename(file_path, ".json")
            category = get(data, "category", "general")
            content = JSON.json(data)
            
            SQLite.execute(db, 
                "INSERT INTO kb_documents (name, category, content) 
                 VALUES (?, ?, ?)",
                [name, category, content])
            
            # TODO: Parse sections, tags, insert into appropriate tables
        end
    end
    
    println("Migration complete!")
end
```

### Phase 3: Update KB Access Functions (1 hour)

Modify knowledge-extraction scripts:

```julia
# scripts/ml/kb-vector-search.jl (updated)

function search_kb(query::String)
    using SQLite
    
    db = SQLite.DB("data/morpheus.db")
    
    # Full-text search
    results = SQLite.execute(db,
        "SELECT name, section_name, content FROM kb_search 
         WHERE kb_search MATCH ?
         ORDER BY rank LIMIT 10",
        [query])
    
    return results
end
```

---

## Benefits of Migration

| Benefit | Impact |
|---------|--------|
| **Query Performance** | 10-100x faster (indexed vs file read) |
| **Scalability** | Handle 1000+ KB documents efficiently |
| **Deduplication** | No JSON + Markdown duplication |
| **Transactions** | Atomic KB updates |
| **Indexing** | Full-text search (FTS5) |
| **Organization** | Centralized, versioned KB |
| **Agent Efficiency** | Faster query → faster response |

---

## Implementation Timeline

**Option A: This Week (April 3-10)**
- Thursday/Friday: Design schema (30 min)
- Next week: Implement migration (1-2 hours)
- Deploy + verify (30 min)

**Option B: Next Week (April 10-17)**
- Start of week: Full migration (2-3 hours)
- Test + verify
- Deploy

**Option C: Post-Phase-12B (April 24+)**
- After Phase 12B RLVR stability
- Bundle with other DB optimizations

---

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Migration data loss | Backup JSON files, verify counts |
| Query breakage | Update all KB access functions, test thoroughly |
| Performance regression | Benchmark before/after |
| Down time | Migrate in background, flag as "beta" until validated |

---

## Validation Checklist

- [ ] Schema created successfully
- [ ] All KB files migrated to DB
- [ ] Document count matches (6 files → 6 documents)
- [ ] Section indexing correct
- [ ] Full-text search working
- [ ] Tag mapping complete
- [ ] Search performance > file read
- [ ] Agent queries functional
- [ ] JSON files backed up (archive old)
- [ ] Documentation updated

---

## Recommendation

**Do this next week (April 10-17)** after Phase 12A stabilizes.

**Why:**
- Phase 12A just launched, needs monitoring
- KB migration is non-blocking (queries still work)
- Good parallelization: monitor Phase 12A in background, migrate KB
- Improves agent query performance for future work

**Why not now:**
- Just completed major work (Phase 12A)
- Bandwidth limited
- No urgency (KB queries still functional)

---

_Plan created: 2026-04-03 23:46 UTC_  
_Estimated effort: 2-3 hours_  
_Recommended start: 2026-04-10_
