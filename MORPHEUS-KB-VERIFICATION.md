# Morpheus KB Verification Protocol

**Effective:** 2026-04-04 17:05 GMT+1  
**Status:** ✅ ACTIVE

---

## Protocol

When I (Morpheus) use KB data to answer your question:

1. **Check KB first** — Query SQLite for relevant documents
2. **Verify freshness** — Check `updated_at` timestamp
3. **Assess currency** — Is this info still accurate?
4. **If fresh (< 2 weeks old)** — Use KB answer directly, cite source
5. **If stale (> 2 weeks old)** — Supplement with web search for current info
6. **If critical/fast-changing topic** — Always supplement with web (security, current events, pricing)
7. **Always cite both** — If using KB + web, make it explicit

---

## Freshness Guidelines

| Age | Status | Action |
|-----|--------|--------|
| **< 1 week** | ✅ Fresh | Use KB, cite source |
| **1-2 weeks** | ⚠️ Aging | Use KB + verify via web |
| **2-4 weeks** | ⚠️ Stale | Use KB as foundation, supplement with web |
| **> 1 month** | ❌ Outdated | Web search only, mention KB is old |

---

## Topic-Specific Rules

### Always Verify First (Fast-Changing)
- **Security:** CVEs, vulnerabilities, exploits (daily updates)
- **Pricing:** Cloud costs, subscription models (change frequently)
- **Current events:** News, releases, announcements (real-time)
- **API changes:** Platform updates, deprecations (sudden)
- **Product features:** SaaS releases, new capabilities (frequent)

### Safe to Use KB (Stable)
- **Historical facts:** Nikola Tesla biography, historical events
- **Architecture:** System design patterns, fundamental concepts
- **Best practices:** Established patterns, proven methodologies
- **Theory:** Educational content, foundational knowledge
- **Completed projects:** Finished work, documented outcomes

### Always Supplement (Hybrid Topics)
- **Technology overviews:** KB foundation + current status
- **Framework guides:** KB patterns + latest version features
- **Research summaries:** KB context + recent papers
- **Industry analysis:** KB background + current trends

---

## Implementation

### Before Answering from KB

```python
def answer_from_kb(query: str, kb_doc: Dict) -> str:
    # 1. Check freshness
    updated = kb_doc['updated_at']
    age_days = (datetime.now() - datetime.fromisoformat(updated)).days
    
    # 2. Assess topic type
    topic = classify_topic(query)  # security, pricing, history, architecture, etc.
    
    # 3. Decide action
    if age_days < 7:
        action = "use_kb_only"
    elif age_days < 14 and topic not in FAST_CHANGING:
        action = "use_kb_verify_web"
    elif age_days < 30:
        action = "kb_foundation_web_supplement"
    else:
        action = "web_search_only"
    
    # 4. Execute
    if action == "use_kb_only":
        return format_kb_answer(kb_doc, age_days)
    elif action == "use_kb_verify_web":
        web_result = web_search(query)
        return compare_kb_and_web(kb_doc, web_result)
    elif action == "kb_foundation_web_supplement":
        web_result = web_search(query)
        return synthesize_kb_and_web(kb_doc, web_result)
    else:
        return web_search_only(query)
```

---

## Answer Format with Freshness

### Example 1: Fresh KB (< 1 week)
```
From KB (Azure Foundry guide, updated 2026-04-04):
Azure Foundry is a fully managed service that provides...
[Answer with full details]
```

### Example 2: Aging KB (1-2 weeks)
```
From KB (Azure Foundry guide, updated 2026-03-28 — 7 days old):
Azure Foundry is a fully managed service that provides...

[I verified this with current web data — still accurate as of 2026-04-04]
```

### Example 3: Stale KB (> 2 weeks)
```
KB Foundation (TensorFlow guide, from 2026-03-20 — 15 days old):
TensorFlow is an open-source ML library...

Current Status (from web, 2026-04-04):
TensorFlow 3.0 was released with these new features...

[Synthesis of both]
```

### Example 4: Fast-Changing Topic (Always Web First)
```
CVE Security Alert (current as of 2026-04-04):
[Web source 1: Official CVE details]
[Web source 2: Patch availability]

KB Background (older): This type of vulnerability...
```

---

## Verification Checklist

Before answering from KB, I verify:

- ✅ Is KB doc < 2 weeks old? If not, supplement with web
- ✅ Is this a fast-changing topic? If yes, always verify with web
- ✅ Did info change since KB was updated? (Check web for contradictions)
- ✅ Are there new developments? (Especially for technology/products)
- ✅ Is pricing/pricing still accurate? (Check current)
- ✅ Are deprecations/breaking changes? (Check current API docs)

---

## Examples of What I'll Do Now

### Query: "How do I use Azure Foundry?"
1. Query KB → Found: azure-foundry-guide.json (updated 2026-04-04)
2. Check age → 0 days old ✅
3. Topic type → Technology platform (moderately stable)
4. Decision → Use KB, cite with timestamp
5. Answer: "From KB (updated today): [Complete answer]"

### Query: "What's the latest CVE in OpenSSL?"
1. Query KB → Found: nothing recent
2. Check age → N/A (no doc)
3. Topic type → Security (fast-changing, always verify) ⚠️
4. Decision → Web search only
5. Answer: "Current security alert (as of today): [Web source with URL]"

### Query: "Tell me about Nikola Tesla"
1. Query KB → Found: nikola-tesla-verified.json (updated 2026-04-04)
2. Check age → 0 days old ✅
3. Topic type → Historical (very stable)
4. Decision → Use KB only
5. Answer: "From KB (Verified sources): [Complete answer]"

### Query: "How do I deploy to AWS?"
1. Query KB → Found: extracted-patterns.json (updated 2026-03-28)
2. Check age → 7 days old ✅ (borderline)
3. Topic type → Technology/Cloud (updates frequently)
4. Decision → Use KB + verify key facts with web
5. Answer: "KB foundation (7 days old): [Core steps] | Current updates (2026-04-04): [Recent changes from web]"

---

## Exception: User Explicit Request

If you explicitly say:
- "Just use the KB" — I'll use KB without web verification (you take responsibility)
- "Get current data" — I'll always do web search + KB comparison
- "Quick answer" — I'll use fresh KB without web (assumes < 1 week old)

---

## Metrics & Tracking

I'll track:
- KB freshness at query time (how old is the doc?)
- Verification method used (KB only, KB+web, web only)
- Updates needed (when KB is stale, note for future update)
- Confidence level (based on freshness + topic type)

Goal: **100% verified KB answers** — fresh when accurate, supplemented when needed.

---

_Activated: 2026-04-04 17:05 GMT+1_  
_Status: Live and active_  
_Rule: Always verify KB freshness before answering_
