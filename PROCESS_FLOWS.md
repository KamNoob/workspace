# Process Flows — Standard Operating Procedure

**Rule:** Before starting ANY task, identify the eventuality. Follow the process flow. No exceptions. No shortcuts.

**Agent Details:** See AGENTS_CONFIG.md for specialization, input/output expectations, success criteria, and common pitfalls for each agent.

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

**If ANY box is unchecked: Task is not complete. Say so explicitly.**

---

## FAILURE LOGGING

Any time I:
- Skip a process flow
- Declare something complete without verification
- Repeat a previous mistake

I immediately update `MORPHEUS_FAILURES.md` and reference it before next task.

---

**Effective:** 2026-02-28 15:45 GMT  
**Last Updated:** 2026-02-28 15:45 GMT  
**Status:** ACTIVE — No exceptions
