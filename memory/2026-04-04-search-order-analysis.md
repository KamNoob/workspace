# Search Order Analysis - KB vs Internet

**Question:** Do Morpheus and agents search the KB database first before the internet?

**Answer:** Not automatically. It depends on context and agent design.

---

## Current Behavior

### Morpheus (Me)

**My actual search order:**
1. **Check SOUL.md** — "Be resourceful before asking. Try to figure it out. Read the file. Check the context. Search for it."
2. **Read local files** — MEMORY.md, workspace context, system state
3. **Use web_search (Brave)** — When needed for current info
4. **KB database** — Available but not automatically queried

**Truth:** I currently search the internet (web_search) *before* querying the KB database. This is backwards from what you probably want.

---

## Agent Behavior

### Scout (Research)
- Purpose: Information gathering, web research
- Current: Uses `web_search` tool directly
- KB Integration: `scripts/ml/agent-router-spawner-kb.jl` exists but not active in routing
- Search Order: **Internet first** (by design for fresh research)

### Codex (Development)
- Purpose: Code implementation, debugging
- Current: Reads files, uses web_search
- KB Integration: KB-RAG injector exists but not in main flow
- Search Order: **Local files first, then web** (by design for context)

### Cipher (Security)
- Purpose: Security audits, threat modeling
- Current: Uses web_search for CVEs, advisories
- KB Integration: Available but not active
- Search Order: **Web first** (needed for current threats)

### Others (Veritas, Chronicle, Sentinel, QA, etc.)
- All have similar pattern: **Web first, KB second**

---

## Available but Not Active

**KB Search Tools (exist but not auto-used):**
- `scripts/ml/kb-integration-sqlite.jl` — SQLite KB search function
- `scripts/ml/kb-query-sqlite.jl` — Query interface
- `scripts/ml/kb-rag-injector.jl` — RAG injection for agents
- `scripts/ml/kb-live-indexer.jl` — Continuous KB indexing
- `scripts/db/migrate-kb-to-sqlite.py` — Migration/update

**Why not active?**
- Agent spawning doesn't include KB context by default
- No automatic KB → web fallback logic
- RAG injection is manual, not in main spawn flow
- KB integration added *after* agent routing logic

---

## What Should Happen (Ideal)

**Recommended search order for agents:**

1. **For code/tech tasks:**
   - KB first (local patterns, previous solutions)
   - Web second (current docs, new libraries)
   - Web for verification (Stack Overflow, GitHub)

2. **For research tasks:**
   - KB first (existing knowledge, cached research)
   - Web second (fresh data, current events, new papers)

3. **For security tasks:**
   - Web first (current CVEs, threat intel)
   - KB second (patterns, previous audits)

4. **For documentation:**
   - KB first (patterns, style guide)
   - Local files second (examples)
   - Web third (latest standards)

---

## How to Enable KB-First Search

### Option 1: Automatic (Requires Code Change)

Modify agent spawning to inject KB context:

```julia
# In agent-spawner-qp.jl or spawn logic
function spawn_agent_with_kb(task, agent_id)
    # 1. Query KB for relevant context
    kb_context = search_kb_sqlite(task; limit=3)
    
    # 2. Inject context into prompt
    augmented_prompt = """
    Context from knowledge base:
    $(kb_context_text)
    
    Task: $(task)
    """
    
    # 3. Spawn agent with KB context
    return spawn_agent(agent_id, augmented_prompt)
end
```

### Option 2: Manual (Use Today)

**For you (Morpheus):**
```bash
# Check KB first
sqlite3 data/morpheus.db "SELECT * FROM kb_documents WHERE name LIKE '%your-topic%';"

# Then search web if needed
# Then use web_search tool
```

**For agents:**
```bash
# Pre-search KB, then spawn with context
julia scripts/ml/kb-query-sqlite.jl search --query "your topic"
# Then manually pass results to agent
```

---

## My Honest Assessment

**Current state:** KB integration is built but not wired into the primary agent spawning path. The tools exist (kb-integration-sqlite.jl, kb-rag-injector.jl, etc.), but they're not called by default.

**Why:** Agents were built and optimized before KB migration to SQLite. Adding KB-first search would require:
1. Modifying agent spawning logic
2. Restructuring prompt injection
3. Testing that KB context doesn't degrade performance
4. Updating all 20+ agents

**What works now:**
- ✅ Manual KB queries (I can check KB first, then web)
- ✅ KB storage and search (SQLite working)
- ✅ KB-RAG tools exist (kb-rag-injector.jl)
- ✅ Phase 7B uses KB for insights

**What doesn't work automatically:**
- ❌ Agents don't check KB before web
- ❌ No automatic fallback (KB → web if no results)
- ❌ KB context not injected into agent prompts by default

---

## My Recommendation

**Do you want me to:**

1. **Enable KB-first manually** — I check KB before web_search (quick change to my behavior)
2. **Wire agents to use KB** — Modify agent spawning to inject KB context (bigger effort, Phase 12B work)
3. **Keep as-is** — Current web-first approach is fast, fresh, and working

**My preference:** Option 1 (I'll check KB first) is low-effort, high-value. Option 2 would require more coordination but would improve all agent performance.

---

## Summary Table

| Component | KB-First? | Status |
|-----------|-----------|--------|
| Morpheus (me) | ❌ Currently no | Can change today |
| Scout (research) | ❌ No | Uses web_search |
| Codex (code) | ❌ No | Uses web_search |
| Cipher (security) | ❌ No | Uses web_search |
| Phase 7B (insights) | ✅ Yes | Uses KB natively |
| KB tools | ✅ Yes | Built and working |
| KB storage | ✅ Yes | SQLite indexed |

---

_Analysis: 2026-04-04 16:23 GMT+1_  
_Recommendation: Enable KB-first in my own search behavior (quick win)_
