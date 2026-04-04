# Next Steps: KB SQLite Integration Complete

**Status:** Phase 1 Complete (Migration + Query Engine)  
**Time:** 2026-04-04 08:53 UTC  
**Completed Commits:** 7

---

## What's Done ✅

### Phase 1: Migration & Infrastructure (COMPLETE)
1. **KB Data Migration** — All 6 documents → SQLite ✅
   - Commit: 60c28c3
   - 69.7 KB → morpheus.db (indexed, FTS-enabled)
   
2. **Database Schema Extended** — KB tables added ✅
   - Commit: 60c28c3 + 6048680
   - kb_documents, kb_sections, kb_tags, kb_search, indexes
   
3. **Query Engines Created** — Two implementations ✅
   - Commit: 993ed34 (Python: phase7b-sqlite-adapter)
   - Commit: 7b5c044 (Julia: kb-integration-sqlite)
   - Both support FTS5, CLI, JSON output

4. **Documentation Complete** ✅
   - Commit: 6048680 (KB-MIGRATION-COMPLETE.md)
   - Integration instructions included

---

## What's Next (3 Steps, 90 minutes total)

### Step 1: Update knowledge-extractor.jl (30 min)
**File:** `scripts/ml/knowledge-extractor.jl`

**Current approach (JSON file reads):**
```julia
kb_data = JSON.parsefile("data/knowledge-base/extracted-patterns.json")
kb_list = readdir("data/kb/")
```

**New approach (SQLite queries):**
```julia
include("kb-integration-sqlite.jl")

kb_data = get_kb_document_sqlite("extracted_patterns")
kb_list = list_kb_documents_sqlite()
patterns = search_kb_sqlite("optimization")
```

**What to change:**
- Line ~30: Add `include("kb-integration-sqlite.jl")`
- Line ~200: Replace JSON file reads with function calls
- Line ~250: Update pattern synthesis to use KB from SQLite
- Remove: Direct file I/O to data/kb/*, data/knowledge-base/*

**Testing:**
```bash
julia scripts/ml/knowledge-extractor.jl --extract
```

**Expected result:** Extracts patterns from KB in <500ms (vs 1-2s with JSON)

---

### Step 2: Update kb-vector-search.jl (30 min)
**File:** `scripts/ml/kb-vector-search.jl`

**Current:** Reads JSON files for vector embeddings

**New:** Query vectors + metadata from SQLite, compute embeddings

**What to change:**
- Add SQLite query for document vectors
- Use kb-integration-sqlite functions
- Cache vectors in morpheus.db (optional Phase 2)

**Testing:**
```bash
julia scripts/ml/kb-vector-search.jl --search "cloud database"
```

---

### Step 3: Update kb-rag-injector.jl (30 min, OPTIONAL)
**File:** `scripts/ml/kb-rag-injector.jl`

**Current:** Injects KB context from JSON

**New:** Queries KB from SQLite for RAG injection

**What to change:**
- Replace KB file reads with SQLite queries
- Use kb_stats_sqlite() for health checks
- Optional: Cache recent injections

**Testing:**
```bash
julia scripts/ml/kb-rag-injector.jl --task "research" --agent Scout
```

---

## Timeline

| Phase | Task | Effort | Time | Status |
|-------|------|--------|------|--------|
| 1 | Migration + schema | 2h | Done | ✅ 2026-04-03 22:51 |
| 1 | Query engines | 1.5h | Done | ✅ 2026-04-03 23:54 |
| 1 | Documentation | 1h | Done | ✅ 2026-04-03 23:54 |
| **2** | **knowledge-extractor.jl** | **30 min** | **This session** | ⏳ Pending |
| **2** | **kb-vector-search.jl** | **30 min** | **This session** | ⏳ Pending |
| **2** | **kb-rag-injector.jl** | **30 min (optional)** | **Next** | ⏳ Pending |
| 3 | Test agent queries | 30 min | Mon | 📋 Planned |
| 3 | Archive JSON KB files | 15 min | Mon | 📋 Planned |

---

## Reference: Integration Helper

**File:** `scripts/ml/kb-integration-sqlite.jl` (ready to use)

**Import in your script:**
```julia
include("kb-integration-sqlite.jl")
```

**Available functions:**
```julia
search_kb_sqlite(query; limit=10)          # FTS5 search
get_kb_document_sqlite(doc_id)             # Full document
list_kb_documents_sqlite(category="")      # List docs
search_kb_by_tag_sqlite(tag; limit=10)     # Tag search
kb_stats_sqlite()                          # Stats
```

**All return JSON-serializable Dict{}**

---

## Performance Expectations

| Operation | Before (JSON) | After (SQLite) | Speedup |
|-----------|---------------|----------------|---------|
| Search | 5-10 ms | <1 ms | **10x** |
| Get document | 3-5 ms | <100 μs | **50x** |
| List documents | 10 ms | <1 ms | **10x** |
| Tag search | N/A (manual) | <1 ms | ✅ **New** |
| Total KB load | 50-100 ms | 0 ms (lazy) | ✅ **Always fast** |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Script breakage | Low | Medium | Update one script, test, commit, move next |
| Performance regression | Very low | Low | Indexed DB proven faster |
| Data loss | None | — | JSON backups kept, migration verified |
| JSON file dependency | Low | Low | Fallback: restore from JSON if needed |

---

## Validation Checklist

Before moving to Phase 3:

- [ ] knowledge-extractor.jl updated (uses kb_sqlite functions)
- [ ] knowledge-extractor.jl tests pass (patterns extracted)
- [ ] kb-vector-search.jl updated (queries SQLite)
- [ ] kb-vector-search.jl tests pass (search works)
- [ ] kb-rag-injector.jl updated (optional, but recommended)
- [ ] All 3 scripts produce JSON output
- [ ] Query times < 1 ms (spot check)
- [ ] No ERROR logs in agent runs
- [ ] Git commits clean

---

## Phase 3: Cleanup (30 min, Next Week)

Once Phase 2 scripts validated:

1. **Test with Scout agent** (real KB query in task)
   ```bash
   julia scripts/ml/spawner-matrix.jl search "oracle cloud architecture"
   ```

2. **Archive JSON KB files** (keep as backup)
   ```bash
   tar -czf data/kb-backup-2026-04-04.tar.gz data/kb/ data/knowledge-base/ data/knowledge-bases/
   rm -rf data/kb/
   ```

3. **Update TOOLS.md** — Document KB location change

4. **Final commit** — "KB fully migrated to SQLite"

---

## Summary

**KB Migration Journey:**
- ✅ Phase 1: All data in SQLite (69.7 KB → morpheus.db)
- ⏳ Phase 2: Update 3 scripts (90 min, starting now)
- ⏳ Phase 3: Validation + archive (30 min next week)

**Then:** All agents query KB from unified database. 10x faster. Fully indexed. FTS enabled.

---

## How to Proceed

1. **Open** `scripts/ml/knowledge-extractor.jl`
2. **Add** `include("kb-integration-sqlite.jl")` at top
3. **Find** JSON file reads (search for `JSON.parsefile`, `readdir`)
4. **Replace** with `search_kb_sqlite()` / `get_kb_document_sqlite()` / etc.
5. **Test:** `julia knowledge-extractor.jl --extract`
6. **Commit** when working
7. **Repeat** for kb-vector-search.jl and kb-rag-injector.jl

**Estimated total time:** 90 minutes (3×30 min)

---

_Status: PHASE 2 READY TO START_  
_Next action: Update knowledge-extractor.jl_  
_Target: Complete all 3 script updates this session_
