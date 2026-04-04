# System Prompt Injection Guide - Phase 13, Tier 3

**Status:** Implementation Guide  
**Created:** 2026-04-04 18:09 UTC  
**Phase:** 13, Tier 3

---

## Overview

System Prompt Injection is the process of loading domain knowledge into agent system prompts at spawn time. This makes agents "smarter" by giving them access to their own learned frameworks, pitfalls, and success patterns.

---

## How It Works

### Current Flow (Before)
```
Agent spawn request
    ↓
Load agent definition (name, role, capabilities)
    ↓
Load standard system prompt (generic)
    ↓
Spawn agent with generic knowledge
```

### New Flow (After)
```
Agent spawn request
    ↓
Load agent definition (name, role, capabilities)
    ↓
Load standard system prompt (generic)
    ↓
Load agent-specific domain knowledge (NEW)
    ↓
Inject domain knowledge into system prompt (NEW)
    ↓
Spawn agent with enhanced knowledge ← SMARTER
```

---

## Implementation Steps

### Step 1: Create Enhanced System Prompt (Done for Scout ✅)

**File:** `data/kb/agent-system-prompts/[agent]-system-prompt-enhanced.md`

**Contains:**
- Core identity (who the agent is)
- Proven frameworks (from pattern extraction)
- Success indicators (what good looks like)
- Known pitfalls (what to avoid)
- Task workflow (how to approach tasks)
- Confidence guidelines (when to be confident/cautious)
- Performance targets (based on Q-learning scores)

**For Scout:** `data/kb/agent-system-prompts/scout-system-prompt-enhanced.md` (10.3 KB)

**Status:** ✅ COMPLETE

### Step 2: Load Domain Knowledge at Spawn Time

**Where:** Agent spawning code (when a task is assigned to an agent)

**Pseudo-code:**
```julia
function spawn_agent(agent_name::String, task::Dict)
    # Standard agent loading
    agent_def = load_agent_definition(agent_name)
    base_prompt = load_system_prompt(agent_name)
    
    # NEW: Load domain knowledge
    domain_knowledge = load_domain_knowledge(agent_name)
    
    # NEW: Inject into prompt
    enhanced_prompt = inject_domain_knowledge(base_prompt, domain_knowledge)
    
    # Spawn with enhanced prompt
    spawn(agent_def, task, enhanced_prompt)
end
```

**Real implementation:** Would be in `scripts/ml/spawner.jl` or similar

### Step 3: Test with Scout

**Test Case 1: Research Task**
```
Task: "Research the latest ML frameworks and compare"

Scout receives:
├─ Standard prompt
├─ Enhanced prompt with:
│   ├─ 4 proven research frameworks
│   ├─ Success indicators (5+ sources, cross-reference, etc.)
│   ├─ Known pitfalls (single source, outdated info, missing trends)
│   └─ Performance targets (0.90+ reward, 90%+ success)
└─ Task instructions

Expected: Scout delivers research with:
✅ 5+ sources
✅ Cross-referenced findings
✅ High confidence notes
✅ Actionable recommendations
✅ Reward > 0.90
```

**Test Case 2: Monitor Q-Score**
```
Before system prompt injection:
  Scout Q-score: 0.8476
  Avg task time: ~25 minutes

After system prompt injection:
  Scout Q-score: 0.85+ (target)
  Avg task time: ~20 minutes (efficiency gain)
  Success rate: Maintain 100%
```

### Step 4: Scale to Other Agents

After Scout validation, create enhanced prompts for:

1. **Cipher (Security)** → `cipher-system-prompt-enhanced.md`
   - Frameworks: OWASP Top 10, CVE/CWE, CVSS v3.1
   - Pitfalls: Missed edge cases, weak privilege checks
   - Target Q: 0.85+

2. **Codex (Code)** → `codex-system-prompt-enhanced.md`
   - Frameworks: 9 code patterns
   - Pitfalls: Shallow analysis, missing edge cases
   - Target Q: 0.75+

3. **Veritas (Review)** → `veritas-system-prompt-enhanced.md`
   - Frameworks: 4 review patterns
   - Pitfalls: (none documented yet)
   - Target Q: 0.70+

---

## File Structure

### Directory: `data/kb/agent-system-prompts/`

```
scout-system-prompt-enhanced.md          (10.3 KB) ✅ DONE
cipher-system-prompt-enhanced.md         (pending) ⏳
codex-system-prompt-enhanced.md          (pending) ⏳
veritas-system-prompt-enhanced.md        (pending) ⏳
chronicle-system-prompt-enhanced.md      (pending) ⏳
qa-system-prompt-enhanced.md             (pending) ⏳
sentinel-system-prompt-enhanced.md       (pending) ⏳

_system-prompt-injection-guide.md         (this file)
```

---

## Integration with Agent Spawning

### Current Spawning Code

```julia
# Current (in spawner.jl or similar)
function spawn_agent(agent::String, task::Dict)
    agent_def = AGENTS[agent]
    return spawn(agent_def, task)
end
```

### Enhanced Spawning Code

```julia
# Enhanced with domain knowledge injection
function spawn_agent_enhanced(agent::String, task::Dict)
    agent_def = AGENTS[agent]
    
    # Load domain knowledge
    domain_file = "data/kb/agent-domain-knowledge/agent-$(lowercase(agent))-domain-knowledge.json"
    system_prompt_file = "data/kb/agent-system-prompts/$(lowercase(agent))-system-prompt-enhanced.md"
    
    if isfile(domain_file) && isfile(system_prompt_file)
        domain_knowledge = JSON.parse(read(domain_file, String))
        enhanced_prompt = read(system_prompt_file, String)
        
        # Inject context
        context = "Based on $(domain_knowledge["metadata"]["source"]):\n" * enhanced_prompt
        
        return spawn(agent_def, task, context=context)
    else
        # Fallback to standard spawn if files not found
        return spawn(agent_def, task)
    end
end
```

---

## Impact Assessment

### Agent Performance
- **Scout:** +0.01-0.05 Q improvement (from 0.8476 → 0.85+)
- **Cipher:** +0.01-0.03 Q improvement (from 0.8500 → 0.85+)
- **Codex:** +0.02-0.05 Q improvement (from 0.7244 → 0.75+)
- **Others:** +0.01-0.03 Q improvement (baseline increase)

### System Performance
- **Agent spawn time:** +50-100ms (loading + injection)
- **Context overhead:** +8-10 KB per spawn (system prompt + domain knowledge)
- **Model performance:** Negligible (well under 200k token limit)

### User Experience
- **Task quality:** +5-15% improvement expected
- **Completion time:** -10-20% improvement (agents work more efficiently)
- **Reliability:** +5-10% improvement (fewer pitfalls)

---

## Rollout Plan

### Phase 1: Scout (This Week)
- ✅ Create enhanced system prompt
- [ ] Integrate into spawning code
- [ ] Test with 5 research tasks
- [ ] Validate Q-score improvement
- [ ] Document results

### Phase 2: Cipher, Codex (Next Week)
- [ ] Create enhanced system prompts
- [ ] Integrate into spawning code
- [ ] Test with real tasks
- [ ] Scale rollout

### Phase 3: Others (Week 3)
- [ ] Create remaining enhanced prompts
- [ ] Full team rollout
- [ ] Monitor Phase 7B learning

---

## Success Criteria

### Scout (Test Agent)
- [ ] Enhanced prompt deployed successfully
- [ ] Research tasks complete with enhanced knowledge
- [ ] Q-score maintains 0.84+ (or improves to 0.85+)
- [ ] Success rate maintains 100%
- [ ] Average task time ≤ 25 minutes
- [ ] Confidence assessments more accurate

### Team-Wide (After Scaling)
- [ ] All 7 agents have enhanced prompts
- [ ] Average Q-score improves by +0.02
- [ ] Success rate remains 85%+
- [ ] No performance regression
- [ ] Learning system integrates cleanly
- [ ] Pitfall tracking shows improvement

---

## Monitoring & Validation

### Weekly Checks
```
Monday 10:00 UTC:
  [ ] Review Scout's recent research tasks
  [ ] Check Q-score trend (0.8476 → higher)
  [ ] Monitor average task time
  [ ] Check success rate (should stay 100%)
  
Friday 15:00 UTC:
  [ ] Q-Learning report (Check 3)
  [ ] Compare pre/post injection metrics
  [ ] Flag any regressions
```

### Metrics to Track
- Q-score per agent
- Task completion time (should decrease)
- Success rate per agent
- Pitfall occurrence (should decrease)
- User satisfaction (if available)
- Phase 7B cycle time (should not regress)

---

## Rollback Plan

If system prompt injection causes issues:

**Immediate Rollback:**
1. Disable domain knowledge injection in spawn code
2. Revert to standard system prompts
3. Confirm Q-scores stable
4. Investigate issue

**Prevention:**
- Test with Scout first (lowest risk)
- Monitor metrics closely
- Have fallback code path ready
- Can disable per-agent if needed

---

## Next Steps

1. ✅ **Scout system prompt created** (10.3 KB, includes 4 frameworks + pitfalls)
2. [ ] **Integrate into spawning code** (add domain knowledge loader)
3. [ ] **Test with Scout** (5 research tasks, measure Q improvement)
4. [ ] **Create Cipher prompt** (security frameworks + pitfalls)
5. [ ] **Create Codex prompt** (code patterns + pitfalls)
6. [ ] **Scale to team** (all 7 agents by week 4)

---

## Files & Locations

| Component | Location | Status |
|-----------|----------|--------|
| Scout enhanced prompt | `data/kb/agent-system-prompts/scout-system-prompt-enhanced.md` | ✅ DONE |
| Domain knowledge (Scout) | `data/kb/agent-domain-knowledge/agent-scout-domain-knowledge.json` | ✅ DONE |
| Implementation guide | `docs/SYSTEM-PROMPT-INJECTION-GUIDE.md` | ✅ THIS FILE |
| Spawn code (integration) | `scripts/ml/spawner.jl` (or similar) | ⏳ TODO |

---

_System Prompt Injection Guide_  
_Phase 13, Tier 3 - Implementation Documentation_  
_Created: 2026-04-04 18:09 UTC_  
_Status: Ready for integration_
