# Process Flows — Standard Operating Procedure

**Rule:** Before starting ANY task, identify the eventuality. Follow the process flow. No exceptions. No shortcuts.

**Agent Details:** See AGENTS_CONFIG.md for specialization, input/output expectations, success criteria, and common pitfalls for each agent.

---

## QUICK REFERENCE: Task → Flow Mapping

| User Request Keywords | Flow # | Primary Agents | Duration |
|----------------------|--------|----------------|----------|
| "research", "investigate", "find out", "analyze" | #1 | Scout → Veritas → Chronicle | 3-5 min |
| "build", "create", "develop", "code", "implement" | #2 | Codex → QA | 5-15 min |
| "security", "audit", "vulnerability", "harden" | #3 | Cipher → Sentinel | 5-10 min |
| "verify", "check", "validate", "test" | #4 | Veritas or QA | 1-2 min |
| "document", "write docs", "explain" | #5 | Chronicle | 2-3 min |
| "automate", "monitor", "deploy", "infrastructure" | #6 | Sentinel → Veritas | 5-10 min |
| "analyze data", "metrics", "insights", "report" | #7 | Lens | 2-4 min |
| "brainstorm", "ideas", "design", "conceptualize" | #8 | Echo | 1-2 min |
| "test on mobile", "device testing", "responsive" | #9 | Prism → QA | 3-5 min |
| "project status", "timeline", "track progress" | #10 | Navigator | 1-2 min |
| Simple questions, calculations, lookups | #11 | Direct (no agent) | <1 min |

---

## PRE-DEFINED WORKFLOW CHAINS

**These chains can execute in parallel where noted:**

### Chain A: Knowledge Pipeline (Research → Verification → Documentation)
```
Scout → Veritas → Chronicle
Duration: 3-5 min | Use: Any research task
Parallel opportunity: None (sequential dependencies)
```

### Chain B: Code Development (Build → Test → Fix → Verify)
```
Codex → QA → [Fix Loop: Codex ↔ QA, max 2 retries] → Veritas (MANDATORY)
Duration: 8-18 min | Use: Feature development
Parallel opportunity: None (sequential with retry logic)
Success Criteria:
  - Codex: Code compiles, dependencies resolved, matches requirements
  - QA: All tests pass, no critical issues
  - Fix Loop: Max 2 iterations, escalate if still failing
  - Veritas: Verification MANDATORY (code works, secure, documented)
Timeout: 18 min (escalate if exceeded)
```

### Chain C: Security Hardening (Audit → Fix → Re-verify)
```
Cipher → Sentinel → Cipher (re-audit)
Duration: 10-15 min | Use: Security reviews
Parallel opportunity: None (sequential dependencies)
```

### Chain D: Research + Implementation (Investigate → Build → Verify)
```
Scout → Codex → QA
Duration: 10-20 min | Use: "Research how to do X, then build it"
Parallel opportunity: After Scout completes, spawn Codex + Veritas in parallel
```

### Chain E: Data Analysis + Documentation (Analyze → Document)
```
Lens → Chronicle
Duration: 4-6 min | Use: "Analyze X and document findings"
Parallel opportunity: None (Chronicle needs Lens output)
```

### Chain F: Mobile + Web Testing (Multi-platform QA)
```
Prism (mobile) + QA (web) → Veritas (consolidate)
Duration: 4-6 min | Use: Cross-platform testing
Parallel opportunity: Prism + QA run in parallel, Veritas waits for both
```

---

## DECISION TREE: Complex Multi-Step Tasks

**When user gives multi-step request:**

1. **Parse intent:** Identify all required flows
2. **Check dependencies:** Can any steps run in parallel?
3. **Execute chain:**
   - Sequential: Spawn → Wait → Spawn → Wait
   - Parallel: Spawn multiple → Wait for all → Continue
4. **Report progress:** After each major step
5. **Verify at checkpoints:** Use Veritas or QA between major transitions

**Example 1:** "Research API security, then implement best practices"
```
Flow: #1 (Research) → #2 (Code Development)
Chain: Scout → Veritas → Chronicle → Codex → QA
Parallel: None (implementation needs research first)
Duration: 8-20 min
```

**Example 2:** "Test the app on mobile and web, then document any issues"
```
Flow: #9 (Testing) → #5 (Documentation)
Chain: [Prism + QA in parallel] → Chronicle
Parallel: Prism + QA (no dependencies)
Duration: 5-8 min
```

**Example 3:** "Audit security and analyze performance metrics"
```
Flow: #3 (Security) + #7 (Data Analysis)
Chain: [Cipher + Lens in parallel] → Chronicle (combined report)
Parallel: Cipher + Lens (independent tasks)
Duration: 5-7 min
```

---

## 1. RESEARCH / INVESTIGATION

**When:** Need to understand something, find information, analyze a topic

**Process:**

**Step 0: RETRIEVAL (MANDATORY FIRST STEP)**
- Check `docs/research/RESEARCH_INDEX.md` for existing research on topic
- If found and active (< 30 days tech, < 90 days general): Use cached knowledge, skip to step 6
- If found but stale: Note as "pending refresh" and proceed to step 1
- If not found: Proceed to step 1 (new research)

**Step 1-5: RESEARCH PIPELINE**
1. Spawn **Scout** (runtime=subagent, mode=run)
   - Task: Research X, provide CONCISE summary of key findings (not exhaustive)
   - Format: 3-5 key points max per topic, with sources cited
   - Avoid: Long-form writeups, repetition, tangential details
   - Focus: Actionable insights only
   - Timeout: Reasonable to task (120s typical)
2. Await Scout report
3. Spawn **Veritas** (runtime=subagent, mode=run)
   - Task: Verify Scout's findings, validate sources, flag inconsistencies
   - Timeout: 60-90s
4. Await Veritas report
5. Spawn **Chronicle** (runtime=subagent, mode=run)
   - Task: Write comprehensive documentation of findings per RESEARCH_SYSTEM.md schema
   - Include: Metadata, summary, key findings, details, sources, related topics
   - Timeout: 60s

**Step 6: STORAGE & INDEXING**
- Chronicle saves to: `docs/research/[domain]/[topic].md`
- Update `docs/research/RESEARCH_INDEX.md`:
  - Add entry under appropriate domain
  - Set status: "active"
  - Add current date
- If new domain created: Add section to index

**Step 7: REPORTING**
- Deliver findings to user
- Reference file location: `docs/research/[domain]/[topic].md`

**Success criteria:** 
- Retrieval checked first (zero redundant research)
- Scout report + Veritas validation + Chronicle documentation
- File stored in schema-compliant format
- Index updated
- User has reference link to research file

---

## 2. CODE DEVELOPMENT / FEATURE BUILDING

**When:** Building new features, refactoring, creating apps, fixing non-trivial bugs

**Process:**
1. Define requirements clearly (infer from context if not explicit)
2. Spawn **Codex** (runtime=subagent, mode=run or session for large projects)
   - Task: Build feature/app with full implementation
   - Include: Tests, error handling, documentation inline
   - Timeout: Depends on scope
3. Await Codex delivery
4. Spawn **QA** (runtime=subagent, mode=run)
   - Task: Test on intended platform (web, mobile, CLI)
   - Include: User-facing testing, edge cases, error states
   - Timeout: 60-90s
5. If QA finds issues → Loop back to Codex with specific fixes
6. Final verification: Test myself or have user test
7. **Success criteria:** Code works on intended platform, tests pass, no unverified claims

---

## 3. SECURITY AUDIT / VULNERABILITY REVIEW

**When:** Reviewing code for security, assessing threat exposure, hardening systems

**Process:**
1. Spawn **Cipher** (runtime=subagent, mode=run)
   - Task: Security audit of X (code, infrastructure, config)
   - Include: Vulnerability assessment, risk ranking, remediation steps
   - Timeout: 90-120s
2. Await Cipher report with findings and recommendations
3. If critical issues found → Spawn **Sentinel** to implement fixes
4. **Verification:** Re-audit or have Cipher re-verify fixes
5. **Success criteria:** All critical/high issues addressed, audit complete with sign-off

---

## 4. VERIFICATION / VALIDATION

**When:** Need to confirm something works, validate claims, check completeness

**Process:**
1. Spawn **Veritas** (runtime=subagent, mode=run)
   - Task: Verify X (list specifics to check)
   - Include: Test results, validation report, flag discrepancies
   - Timeout: 60s
2. Await report
3. Act on findings (fix, escalate, or confirm)
4. **Success criteria:** Explicit pass/fail for each validation point

---

## 5. DOCUMENTATION

**When:** Need to write guides, API docs, architecture docs, runbooks

**Process:**
1. Spawn **Chronicle** (runtime=subagent, mode=run)
   - Task: Write documentation for X
   - Include: Examples, diagrams (as ASCII/Markdown), clear sections
   - Timeout: 90s
2. Await deliverable
3. Review for completeness and clarity
4. Store in docs/ or reference location
5. **Success criteria:** Comprehensive, examples included, searchable

---

## 6. INFRASTRUCTURE / MONITORING / AUTOMATION

**When:** Setting up systems, automation, health checks, deployment

**Process:**
1. Spawn **Sentinel** (runtime=subagent, mode=run)
   - Task: Set up X (automation, monitoring, infrastructure)
   - Include: Config files, deployment steps, verification commands
   - Timeout: 120-180s
2. Await Sentinel delivery with full documentation
3. Spawn **Veritas** to verify the setup works
4. Test in actual environment
5. **Success criteria:** System running, health checks passing, auto-restart confirmed

---

## 7. DATA ANALYSIS / METRICS / REPORTING

**When:** Need to analyze data, generate insights, build reports

**Process:**
1. Spawn **Lens** (runtime=subagent, mode=run)
   - Task: Analyze X, generate insights, provide metrics
   - Include: Raw data + interpretation + recommendations
   - Timeout: 90s
2. Await Lens report
3. Store findings in reference location
4. **Success criteria:** Data-backed insights, clear visualizations/tables, actionable

---

## 8. DESIGN / BRAINSTORMING / CREATIVE

**When:** Need ideas, design direction, creative solutions

**Process:**
1. Spawn **Echo** (runtime=subagent, mode=run)
   - Task: Brainstorm X, generate design options, conceptual direction
   - Timeout: 60-90s
2. Await deliverable with multiple options
3. Select direction or refine with Echo
4. **Success criteria:** Multiple options presented, rationale clear

---

## 9. TESTING / QA / QUALITY ASSURANCE

**When:** Need comprehensive testing, device testing, responsive design verification

**Process:**
1. Spawn **QA** for general testing
2. Spawn **Prism** for mobile/device-specific testing
   - Task: Test on actual devices (iOS, Android, desktop)
   - Include: Screenshots, device list, responsive breakdown
   - Timeout: 90-120s
3. Await reports
4. Fix issues found or escalate
5. Re-test if changes made
6. **Success criteria:** All test cases pass, zero unverified functionality

---

## 10. PROJECT MANAGEMENT / CONTEXT / TIMELINE

**When:** Tracking project progress, managing context, timeline continuity

**Process:**
1. Spawn **Navigator** (runtime=subagent, mode=run)
   - Task: Track/update project X (progress, timeline, blockers, context)
   - Timeout: 60s
2. Await status report
3. Use for decision-making on next steps
4. **Success criteria:** Clear picture of where project stands, next steps defined

---

## 11. SIMPLE QUESTIONS / QUICK TASKS

**When:** Quick lookup, one-off calculation, minor questions

**Process:**
1. **Do it myself** (no agent needed)
2. Use web_search if needed
3. Report back

---

## OVERRIDE SCENARIOS

**When you explicitly ask me to:**
- Do something myself (I comply)
- Use a specific agent (I use that agent)
- Bypass a flow (I acknowledge the risk and do it)

---

## VERIFICATION CHECKLIST (REQUIRED FOR ALL DELIVERABLES)

Before declaring ANY task complete:
- [ ] Agent delivered output
- [ ] Output tested/validated in intended context
- [ ] Success criteria met (explicit, not assumed)
- [ ] Documented or stored
- [ ] User-facing if applicable (tested by real user or me simulating user)
- [ ] **Outcome logged** (task + workflow via scripts) — MANDATORY

**If ANY box is unchecked: Task is not complete. Say so explicitly.**

---

## OUTCOME LOGGING (MANDATORY — 2026-03-06)

**After every agent task:**
```bash
scripts/log-task-outcome.sh <task_type> <agent> <success> <quality> <time>
```

**After every workflow:**
```bash
scripts/log-workflow.sh "<flow_name>" <success> <time> "<notes>"
```

**Quality scoring:**
- 0.9-1.0: Excellent (exceeded expectations)
- 0.7-0.9: Good (met expectations)
- 0.5-0.7: Acceptable (usable, needs refinement)
- 0.3-0.5: Poor (multiple issues)
- 0.0-0.3: Failed (unusable)

**Result:** Q-Learning improves agent selection, workflow analysis identifies optimizations.

---

## FAILURE LOGGING

Any time I:
- Skip a process flow
- Declare something complete without verification
- Repeat a previous mistake

I immediately update `MORPHEUS_FAILURES.md` and reference it before next task.

---

## EFFICIENCY PATTERNS

### Pattern 1: Batch Similar Tasks
**When:** Multiple requests of same type (e.g., "research A, B, and C")
**Optimization:** Spawn single agent with batched task list
**Savings:** 40-60% time vs sequential spawns

### Pattern 2: Parallel Independent Work
**When:** Tasks have no dependencies (security audit + data analysis)
**Optimization:** Spawn both agents simultaneously, consolidate at end
**Savings:** 50% time (tasks complete in parallel)

### Pattern 3: Cache-First Research
**When:** Any research task
**Optimization:** ALWAYS check RESEARCH_INDEX.md first
**Savings:** 100% time if cached (0 min vs 3-5 min)

### Pattern 4: Early Verification
**When:** Complex builds or multi-step work
**Optimization:** Insert Veritas checkpoints between major steps
**Savings:** Prevents cascade failures, 20-30% time saved on rework avoidance

### Pattern 5: Progressive Disclosure
**When:** Large projects
**Optimization:** Break into phases, verify each before next
**Savings:** Prevents dead-end work, maintains context quality

---

## COMMON ANTI-PATTERNS (AVOID)

❌ **Sequential when parallel possible** → Check for independence first  
❌ **Research without checking index** → Always retrieval-first  
❌ **Verification at the end only** → Insert checkpoints throughout  
❌ **Spawning wrong agent** → Use Quick Reference table  
❌ **No timeout specified** → Always set reasonable timeouts  
❌ **Assuming completion** → Verify explicitly  

---

## PATTERN RECOGNITION EXAMPLES

### Example: "Can you find information about X and implement it in the codebase?"
**Pattern detected:** Research + Implementation (Chain D)  
**Execution:**
1. Check RESEARCH_INDEX.md for X
2. If not found: Scout → Veritas → Chronicle (Flow #1)
3. Codex (Flow #2, uses research output)
4. QA (Flow #9, verifies implementation)
5. Report with research file + code location

### Example: "Test on mobile, web, and document any bugs"
**Pattern detected:** Multi-platform testing + Documentation (Chain F → Flow #5)  
**Execution:**
1. Spawn Prism (mobile) + QA (web) **in parallel**
2. Wait for both reports
3. Chronicle consolidates findings
4. Report with documentation location

### Example: "Secure the API and set up monitoring"
**Pattern detected:** Independent parallel work (Flow #3 + Flow #6)  
**Execution:**
1. Spawn Cipher (security audit) + Sentinel (monitoring setup) **in parallel**
2. Wait for both completions
3. Veritas verifies both (can be batched)
4. Report status of both systems

---

**Effective:** 2026-02-28 15:45 GMT  
**Last Updated:** 2026-03-06 13:54 GMT  
**Status:** ACTIVE — No exceptions
