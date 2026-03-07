# Message Optimization Rules — Reduce Message Usage by 50-60%

**Created:** 2026-03-07  
**Purpose:** Minimize message consumption while maintaining quality  
**Target:** <40 messages per complex session (down from ~80-100)  

---

## Core Principles

### 1. Batch Everything Possible
**Rule:** If 3+ similar operations, batch in single message

**Example:**
```
✅ GOOD (1 message):
- web_search("topic A")
- web_search("topic B")
- web_search("topic C")

❌ BAD (3 messages):
Message 1: web_search("topic A")
Message 2: web_search("topic B")
Message 3: web_search("topic C")
```

### 2. Trust Tool Success
**Rule:** Don't verify edits unless critical or error reported

**Example:**
```
✅ GOOD (1 message):
Edit(file.md, oldText, newText)
# Trust success, continue

❌ BAD (3 messages):
Message 1: Read(file.md)  # Check current state
Message 2: Edit(file.md, oldText, newText)
Message 3: Read(file.md)  # Verify edit worked
```

### 3. Use grep Instead of Read
**Rule:** Find content with grep, then use targeted Edit

**Example:**
```
✅ GOOD (2 messages):
grep -n "## Section" file.md  # Get line number
Edit(file.md, offset=42, ...)

❌ BAD (2 messages):
Read(file.md, limit=500)  # Read large file
Edit(file.md, oldText, newText)
```

### 4. Plan-Then-Execute Pattern
**Rule:** Announce + execute in same message (not separate)

**Example:**
```
✅ GOOD (1 message):
"Creating 3 research files..."
[Batch: Write file1, Write file2, Write file3]

❌ BAD (4 messages):
Message 1: "Creating 3 research files..."
Message 2: Write file1
Message 3: Write file2
Message 4: Write file3
```

### 5. Minimize Test Iterations
**Rule:** Design carefully, test once, accept result

**Example:**
```
✅ GOOD (1 test):
# Plan test cases mentally
# Run comprehensive test once
# Accept result (unless critical failure)

❌ BAD (3+ tests):
Test 1: Try approach A (fails)
Test 2: Try approach B (partial success)
Test 3: Try approach C (success)
```

---

## Decision Matrix

### When to Batch

| Scenario | Batch? | Example |
|----------|--------|---------|
| 3+ web searches | ✅ YES | Research library population |
| 3+ file writes | ✅ YES | Creating multiple docs |
| 3+ similar edits | ✅ YES | Updating multiple config files |
| Sequential dependent ops | ❌ NO | Read → process → write |
| Mixed tool types | ⚠️ MAYBE | Can batch if no dependencies |

### When to Verify

| File Type | Pre-Read? | Post-Verify? | Method |
|-----------|-----------|--------------|--------|
| MEMORY.md | ❌ NO | ❌ NO | Trust Edit |
| Research files | ❌ NO | ❌ NO | Trust Write |
| openclaw.json | ⚠️ MAYBE | ✅ YES | jq validation |
| Scripts (.sh/.js) | ❌ NO | ✅ YES | Syntax check only |
| Critical config | ✅ YES | ✅ YES | Full verification |

### When to Delegate (Sub-Agents)

| Task Complexity | Action | Reason |
|-----------------|--------|--------|
| >10 sequential ops | ✅ Delegate | Save main session messages |
| Iterative debugging | ✅ Delegate | Trial-and-error loops |
| Multi-step build/test | ✅ Delegate | Complex workflows |
| 1-5 simple ops | ❌ Direct | Overhead not worth it |
| Just reads/writes | ❌ Direct | Too simple for agent |

---

## Specific Workflows

### Research Library Creation

**Traditional (Bad):**
```
1. web_search("topic 1")         # Message 1
2. Write research-1.md           # Message 2
3. web_search("topic 2")         # Message 3
4. Write research-2.md           # Message 4
5. web_search("topic 3")         # Message 5
6. Write research-3.md           # Message 6
7. Edit RESEARCH_INDEX.md        # Message 7

Total: 7 messages
```

**Optimized (Good):**
```
1. Batch web_search x3           # Message 1
2. Batch Write x3                # Message 2
3. Edit RESEARCH_INDEX.md        # Message 3

Total: 3 messages (57% reduction)
```

### File Editing

**Traditional (Bad):**
```
1. Read MEMORY.md                # Message 1
2. Find section                  # (same message)
3. Edit section                  # Message 2
4. Read to verify                # Message 3

Total: 3 messages
```

**Optimized (Good):**
```
1. grep -n "## Section" MEMORY.md  # Message 1
2. Edit MEMORY.md, offset=N        # Message 2

Total: 2 messages (33% reduction)
```

### Multi-Step Tasks

**Traditional (Bad):**
```
1. "Starting task..."            # Message 1
2. Tool call A                   # Message 2
3. Tool call B                   # Message 3
4. "Task complete"               # Message 4

Total: 4 messages
```

**Optimized (Good):**
```
1. [Announce] + [Batch: Tool A, Tool B] + [Report]  # Message 1

Total: 1 message (75% reduction)
```

### Configuration Changes

**Traditional (Bad):**
```
1. jq '.models' openclaw.json    # Message 1 (check current)
2. jq '.models.default = "..."'  # Message 2 (update)
3. jq '.models' openclaw.json    # Message 3 (verify)

Total: 3 messages
```

**Optimized (Good):**
```
1. jq '.models.default = "X"' > tmp && mv tmp openclaw.json  # Message 1
2. jq '.models.default' openclaw.json  # Message 2 (verify only)

Total: 2 messages (33% reduction)
```

---

## Behavioral Guidelines

### DO

✅ **Batch independent operations** (no dependencies)  
✅ **Trust Edit/Write success** (unless critical config)  
✅ **Use grep for targeted reads** (avoid full file reads)  
✅ **Announce + execute in same message** (plan-then-execute)  
✅ **Design tests carefully** (minimize iterations)  
✅ **Delegate complex multi-step work** (>10 ops → sub-agent)  

### DON'T

❌ **Verify every edit** (wastes messages)  
❌ **Read entire files** (use grep/offset instead)  
❌ **Separate planning from execution** (combine in 1 message)  
❌ **Test multiple times** (unless critical)  
❌ **Execute sequentially** (batch when possible)  
❌ **Spawn agents for simple tasks** (overhead not worth it)  

---

## Exception Cases

### When Verification IS Required

1. **openclaw.json edits** — JSON must be valid, gateway depends on it
2. **Cron job installation** — `crontab -l` to verify entry added
3. **Critical scripts** — Syntax check with `bash -n script.sh`
4. **Permission changes** — `ls -lh` to verify chmod worked
5. **Network changes** — Test connectivity after firewall changes

### When Sequential IS Better

1. **Dependencies between operations** — Result of step 1 feeds step 2
2. **Error handling required** — Need to check status before continuing
3. **User interaction** — May need clarification mid-workflow
4. **Complex logic** — Batching makes code unclear

### When Sub-Agents NOT Worth It

1. **Simple 1-5 operations** — Overhead > savings
2. **Just file reads** — No computation needed
3. **Quick verifications** — Faster to do directly
4. **User is waiting** — Sub-agents add latency

---

## Measurement & Tracking

### Session Metrics

Track in **USAGE_TRACKING.md**:
```
Date: 2026-03-07
Session: Research library population
Messages used: ~40 (estimated)
Tasks completed: 5 research files
Ratio: 8 messages/task

Optimizations applied:
- ✅ Batched web searches (5 → 1 message)
- ✅ Batched file writes (5 → 1 message)
- ❌ Still reading files unnecessarily (improve next time)

Next session target: <35 messages
```

### Weekly Review

Every Sunday:
1. Count total messages used this week
2. Count total tasks completed
3. Calculate messages per task
4. Identify inefficient patterns
5. Update optimization rules

**Target:** <10 messages per task (currently ~15-20)

---

## Common Pitfalls

### ❌ Pitfall 1: Over-Verification
**Symptom:** Reading file before and after every edit  
**Fix:** Trust Edit tool, only verify critical files

### ❌ Pitfall 2: Sequential Bias
**Symptom:** Executing operations one at a time by default  
**Fix:** Ask "Can these be batched?" before executing

### ❌ Pitfall 3: Excessive Testing
**Symptom:** Running 3-5 tests to get it perfect  
**Fix:** Design once, test once, accept 80% solution

### ❌ Pitfall 4: Micro-Updates
**Symptom:** Sending status updates between every operation  
**Fix:** Announce → execute batch → report final result

### ❌ Pitfall 5: Full File Reads
**Symptom:** Reading 500-line files to find one section  
**Fix:** grep to find line number, Edit with offset

---

## Quick Reference Card

```
BEFORE executing any task, ask:

1. Can I batch these operations? (3+ similar?)
2. Do I need to verify? (critical config only?)
3. Can I use grep instead of Read? (large files?)
4. Should I delegate? (>10 sequential ops?)
5. Can I design better to avoid re-testing?

DEFAULT:
- Batch if possible
- Trust tools
- Use grep
- Execute directly (unless complex)
- Test once
```

---

## Success Metrics

**Baseline (Before Optimization):**
- Messages per task: ~15-20
- Messages per session: ~80-100
- Tasks per 5-hour cycle: 1-2

**Target (After Optimization):**
- Messages per task: <10 (50% reduction)
- Messages per session: <40 (60% reduction)
- Tasks per 5-hour cycle: 3-4 (2x improvement)

**Next Review:** 2026-03-14 (after 1 week of practice)

---

## Tags

message-optimization, efficiency, batching, tool-calls, workflows, best-practices

---

**Status:** ✅ ACTIVE — Apply to all future tasks  
**Created:** 2026-03-07  
**Last Updated:** 2026-03-07
