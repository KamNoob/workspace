# Research System

Art's institutional knowledge base. All research conducted by Scout, verified by Veritas, documented by Chronicle.

## Quick Start

**Need information on a topic?**
1. Check `RESEARCH_INDEX.md` — search by domain
2. If found and recent: Read the research file
3. If not found or stale: Request new research (I'll use Scout → Veritas → Chronicle)

**Example:** Need to learn about "prompt engineering"?
- Search RESEARCH_INDEX.md for "technology" domain
- Find `technology/prompt-engineering.md`
- Read the findings

## Structure

```
research/
├── RESEARCH_INDEX.md (master catalog — START HERE)
├── RESEARCH_TEMPLATE.md (format for new research)
├── technology/
├── business/
├── security/
├── data/
├── domain-knowledge/
├── algorithms/
└── other/
```

## How Research Gets Here

1. **You request research** → I check RESEARCH_INDEX.md
2. **If not found or stale** → I spawn Scout to research
3. **Scout researches** → Veritas validates → Chronicle documents
4. **Chronicle saves** → docs/research/[domain]/[topic].md
5. **Index updated** → RESEARCH_INDEX.md gets new entry
6. **Knowledge preserved** → Available for future use

## Update Schedule

- **Technology topics:** Refresh every 30 days if actively used
- **General knowledge:** Refresh every 90 days
- **Archived:** Old/irrelevant research marked as archived (not deleted)

## Schema

Each research file includes:
- Metadata (domain, date, status, confidence, source count)
- Summary (1-3 sentences)
- Key Findings (bullet points)
- Details (full breakdown by sub-topic)
- Sources (with URLs)
- Related Topics (cross-references)

See RESEARCH_TEMPLATE.md for complete example.

## Integration

This system is part of **PROCESS_FLOWS.md** (Section 1: Research / Investigation).

Before any research task:
1. Step 0: Check RESEARCH_INDEX.md
2. Step 1-5: Scout → Veritas → Chronicle (if needed)
3. Step 6: Store in docs/research/[domain]/[topic].md
4. Step 7: Update RESEARCH_INDEX.md

---

**Managed by:** Morpheus (orchestration) + Scout + Veritas + Chronicle agents  
**Status:** Active as of 2026-02-28
