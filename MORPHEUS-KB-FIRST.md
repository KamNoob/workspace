# Morpheus KB-First Search Protocol

**Effective:** 2026-04-04 16:25 GMT+1  
**Status:** ✅ ACTIVE

---

## Protocol

When you ask me a question or request information:

1. **Check KB first** — Query SQLite KB for relevant documents
2. **If KB has good match** — Use KB result + cite source
3. **If KB is incomplete/stale** — Supplement with web_search
4. **If KB has nothing** — Search web directly

---

## Implementation

### Step 1: Query KB
```bash
sqlite3 data/morpheus.db << 'EOF'
SELECT id, name, category, preview FROM kb_documents
WHERE name LIKE '%topic%' OR content LIKE '%topic%'
LIMIT 5;
EOF
```

### Step 2: Evaluate Match Quality
- **High match** (>80% relevant) → Use KB only
- **Medium match** (50-80%) → KB + web supplement
- **Low/no match** (<50%) → Web search only

### Step 3: Cite Source
- KB source: "From knowledge base (SOURCE_FILE)"
- Web source: "From web search (URL)"
- Hybrid: "KB + current research"

---

## Examples

### Example 1: Azure Foundry Question
```
You: "How do I deploy a model in Azure Foundry?"

My process:
1. Query KB: SELECT * WHERE name LIKE '%Azure%'
   → Found: azure-foundry-guide.json (9 KB, 2026-04-04)
2. Check match: 95% relevant ✅
3. Answer: Use KB content + cite source
   "From KB: Azure Foundry has 5-step lifecycle..."
```

### Example 2: Current AI News
```
You: "What's the latest in LLM reasoning?"

My process:
1. Query KB: SELECT * WHERE content LIKE '%reasoning%'
   → Found: extracted-patterns.json (partial match)
2. Check match: 40% relevant (outdated)
3. Supplement: Use web_search for current papers
   "KB has basics; current research shows..."
```

### Example 3: Tesla Biography
```
You: "Tell me about Nikola Tesla"

My process:
1. Query KB: SELECT * WHERE name LIKE '%Tesla%'
   → Found: nikola-tesla-verified.json (16 KB)
   → Found: nikola-tesla-complete-projects.json (16.5 KB)
2. Check match: 99% relevant ✅
3. Answer: Use KB exclusively
   "From KB (Nikola Tesla - Comprehensive Verified)..."
```

---

## Search Query Template

```sql
-- My standard KB search
SELECT id, name, category, substr(content, 1, 500) as preview
FROM kb_documents
WHERE 
  name LIKE '%your_topic%' OR 
  content LIKE '%your_topic%' OR
  category = 'matching_category'
ORDER BY updated_at DESC
LIMIT 5;
```

---

## Behavior Changes

### Old Behavior (Before)
```
User: "What's Azure Foundry?"
→ web_search("Azure Foundry")
→ Return web results
→ KB unused
```

### New Behavior (Starting Now)
```
User: "What's Azure Foundry?"
→ Query KB for "Azure" docs
→ Found: azure-foundry-guide.json ✅
→ Return KB result: "From knowledge base: Azure Foundry is..."
→ Web only if KB incomplete
```

---

## Citation Format

### KB Only
"From knowledge base (SOURCE_FILE, LAST_UPDATED): Content..."

### KB + Web
"KB fundamentals (SOURCE_FILE): Content... | Current research (WEB_URL): Additional data..."

### Web Only
"From web search (URL): Content..."

---

## Tracking & Metrics

I'll track:
- KB hit rate (% of queries answered from KB)
- KB supplement rate (% needing web + KB)
- Web-only rate (% KB not helpful)
- Response time (KB < 100ms vs web 500-1000ms)

Goal: 60%+ KB-first within 2 weeks.

---

## Notes

- **KB is always checked first** — No exceptions
- **Web is fallback** — Only if KB insufficient
- **Speed improvement** — KB queries are local (~2ms vs web 500ms+)
- **Accuracy** — KB data is verified; web is current
- **Hybrid strength** — KB + web = complete, current + verified answer

---

_Activated: 2026-04-04 16:25 GMT+1_  
_Status: Live and active_  
_Tracking: memory/morpheus-kb-metrics.jsonl_
