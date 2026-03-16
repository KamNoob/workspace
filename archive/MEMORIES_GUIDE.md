# MEMORIES - Knowledge Base & Search

A beautiful, searchable document store for all our memories, learnings, and system knowledge.

## Database
- **URL:** https://www.notion.so/0b6460d831604e7eb66607070c7f4040
- **Database ID:** `0b6460d8-3160-4e7e-b666-07070c7f4040`

---

## What Gets Stored Here

Everything Morpheus learns or knows, organized by type:

### Categories
- **Long-term Knowledge** 🔵 - System facts, procedures, permanent reference
- **Daily Note** ⚫ - Session logs, daily summaries, temporary notes
- **Learning** 🟢 - New techniques, discoveries, skill improvements
- **Decision** 🟣 - Important choices made and rationale
- **Entity** 🟠 - Profiles of people, systems, external services
- **System** 🔴 - Internal architecture, config, technical details

### Importance Levels
- **High** 🔴 - Critical knowledge (security, architecture, user prefs)
- **Medium** 🟡 - Important but not urgent
- **Low** ⚫ - Reference material, optional context

### Tags (For Quick Filtering)
- Architecture, Configuration, Security, OpenClaw, User Preferences
- Tasks, Credentials, API Integration, Debugging, Performance
- Add custom tags as needed

---

## How to Use

### 🔍 Search & Browse
1. **Open:** https://www.notion.so/0b6460d831604e7eb66607070c7f4040
2. **Search:** Click the search icon, type anything
3. **Filter:** Use Category/Importance/Tags to narrow down
4. **Sort:** By Date, Importance, or Creation

### ➕ Add a New Memory

**Quick method (manual in Notion):**
1. Click "+ Add a page" in the database
2. Fill in: Memory (title), Category, Content
3. Set Importance and add Tags

**Command line (fastest):**
```bash
cd ~/.openclaw/workspace
./add-memory.sh "Memory Title" "Category" "Your content here" "tags: tag1,tag2"
```

**Example:**
```bash
./add-memory.sh "Redis caching strategy" "Learning" "Use TTL of 5min for session data, 24h for configs" "tags: Performance,Architecture"
```

### 📋 Properties Reference

| Property | Type | Example | Required |
|----------|------|---------|----------|
| **Memory** | Title | "Art's Preferences" | ✓ |
| **Category** | Select | Long-term Knowledge | ✓ |
| **Date** | Date | 2026-02-20 | ✓ |
| **Importance** | Select | High, Medium, Low | ✓ |
| **Content** | Text | Full memory content (2000 char limit) | ✓ |
| **Tags** | Multi-select | [Architecture, Security] | ✗ |
| **Source** | Text | MEMORY.md, manual entry, etc. | ✗ |

---

## How Morpheus Uses It

1. **Learning:** When I discover something useful, I save it here
2. **Decisions:** When we decide something important, I document it
3. **System changes:** All config/architecture updates logged here
4. **Art's preferences:** Learned behaviors, preferences, requests
5. **Reference:** I can search and recall memories without token overhead

---

## Integration with Memory Files

Two systems work together:

### Primary: Workspace Files (Fast, Local)
- `MEMORY.md` - Persistent long-term knowledge
- `memory/YYYY-MM-DD.md` - Daily session notes
- ⚡ **Fast:** No API calls, instant access
- 🔒 **Private:** Stays on this machine
- 📄 **Format:** Markdown

### Secondary: Notion Database (Beautiful, Searchable)
- **Beautiful:** Human-friendly interface
- **Searchable:** Full-text + filter + tags
- **Shared:** Art can browse anytime
- **Organized:** Categorized, tagged, dated
- 🔄 **Sync:** Can import from workspace files

---

## Workflow Example

**Scenario:** Discover that Art prefers short replies

1. **Day of discovery:**
   - Add to daily note: `memory/2026-02-20.md`
   - Local, fast, session context

2. **End of week:**
   - Promote to MEMORY.md (long-term)
   - Add to Memories database with High importance
   - Tag: `User Preferences`

3. **Going forward:**
   - Search Memories: "Art preferences"
   - See all similar memories instantly
   - Maintain consistency

---

## Import Existing Memories

To populate from existing workspace files:

```bash
# Simple version (basic sections)
./import-memories.sh

# Full version with parsing (requires Node)
node import-memories.js
```

This imports:
- All sections from MEMORY.md → Category: Long-term Knowledge
- Last 10 daily notes → Category: Daily Note
- Automatically extracts dates and tags

---

## Tips & Best Practices

✅ **DO:**
- Use clear, concise titles
- Include dates (Notion does this automatically)
- Tag generously for discoverability
- Store technical details (configs, IDs, formats)
- Document decisions with reasoning

❌ **DON'T:**
- Store secrets (use .env or Vault instead)
- Keep duplicate info (reference MEMORY.md instead)
- Overwrite system knowledge without reason
- Ignore importance levels (helps filtering)

---

## Quick Commands

```bash
# Add a memory from command line
./add-memory.sh "Title" "Category" "Content" "tags: tag1,tag2"

# View raw workspace memory
cat ~/.openclaw/workspace/MEMORY.md

# View today's notes
cat ~/.openclaw/workspace/memory/$(date +%Y-%m-%d).md

# Import all workspace memories to Notion
./import-memories.sh
```

---

## Your Oversight (Art)

✅ You can:
- Search all memories anytime
- Add your own memories (feedback, decisions)
- Update Morpheus's learnings if needed
- Delete memories no longer relevant
- See what Morpheus learns about you

---

**Last updated:** 2026-02-20 10:03 GMT  
**Total memories:** Growing as we work
**Next sync:** Manual as-needed
