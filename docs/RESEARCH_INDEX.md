# Research Index — Master Catalog

**Last Updated:** 2026-03-09  
**Purpose:** Searchable inventory of all research documents. Prevents redundant research.

---

## Active Research Projects

### 1. Knowledge & Memory Storage Systems (2026)
- **File:** `docs/research/knowledge-memory-storage-2026.md`
- **Status:** ✅ Complete (verified pending)
- **Domain:** Technology (Storage, AI Architecture)
- **Tags:** memory, vector-databases, RAG, storage-architecture, personal-assistant
- **Created:** 2026-03-09
- **Refresh Interval:** 90 days (architecture evolves slowly)
- **Key Findings:**
  - Three-tier memory model standard (short-term, working, long-term)
  - Hybrid search (semantic + keyword) is industry standard for RAG
  - LanceDB optimal for personal assistants (<10K docs)
  - Local storage wins for privacy and cost
  - Context window management critical for token efficiency
- **Next Action:** Prototype LanceDB hybrid search implementation

---

## Archive (Completed or Deprecated)

_(None yet; will grow as research projects complete)_

---

## Search by Domain

### Technology
- Knowledge & Memory Storage Systems (2026)

### Business
_(None yet)_

### Security
_(None yet)_

### Data & Analysis
_(None yet)_

### Infrastructure
_(None yet)_

---

## Refresh Schedule

| Domain | Interval | Last Checked |
|--------|----------|--------------|
| Technology | 30 days | 2026-03-09 |
| Business | 90 days | — |
| Security | 30 days | — |
| Data | 60 days | — |
| Infrastructure | 30 days | — |

**Automatic refresh job:** `check-research-refresh.py` runs weekly (Sunday 18:00 GMT)

---

## Usage Instructions

1. **Before researching:** Check index first (prevents duplicate work)
2. **Creating new research:** Add entry to this index
3. **Updating existing:** Note in "Key Findings" and refresh date
4. **Archiving:** Move to "Archive" section when superseded

---

**Maintained by:** Morpheus  
**Privacy:** All research is stored locally, no external exposure
