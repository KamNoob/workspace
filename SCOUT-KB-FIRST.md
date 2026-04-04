# Scout KB-First Search Protocol

**Agent:** Scout (Research Specialist)  
**Effective:** 2026-04-04 16:26 GMT+1  
**Status:** ✅ ACTIVE

---

## Protocol

When Scout is spawned for a research task:

1. **Check KB first** — Query SQLite KB for existing research, patterns, documented findings
2. **If KB has relevant research** — Use KB findings + enhance with web for current data
3. **If KB is partial** — Supplement KB with web search for completeness
4. **If KB has nothing** — Conduct full web research as before

---

## Implementation

### Agent Configuration

```julia
# In agent spawn logic or Scout initialization

const SCOUT_KB_FIRST = true

function spawn_scout_with_kb(research_task::String)::Dict
    # Step 1: Query KB
    kb_results = search_kb_sqlite(research_task; limit=5)
    
    # Step 2: Build context
    kb_context = if !isempty(kb_results)
        format_kb_context(kb_results)
    else
        ""
    end
    
    # Step 3: Inject KB context into prompt
    augmented_prompt = """
    RESEARCH TASK: $research_task
    
    $(if !isempty(kb_context)
        "BACKGROUND FROM KNOWLEDGE BASE:\n$kb_context\n\nAugment this research with current data."
    else
        "No prior research found in KB. Conduct comprehensive research."
    end)
    """
    
    # Step 4: Spawn Scout with KB context
    spawn_agent("Scout", augmented_prompt)
end

function format_kb_context(results::Vector{Dict})::String
    context = "Knowledge Base References:\n"
    for (i, result) in enumerate(results)
        context *= "$(i). [$(result["name"])] $(result["preview"])\n"
    end
    return context
end
```

---

## Search Priority for Scout

### Research Task Categories

| Task Type | KB First | Web Second | Reasoning |
|-----------|----------|-----------|-----------|
| **Historical research** | ✅ Yes | Verify dates | KB has verified facts |
| **Technology overview** | ✅ Yes | Current status | KB has architecture |
| **Framework/tool research** | ⚠️ Hybrid | Essential | KB outdated fast |
| **Current events** | ❌ No | ✅ Yes | Web required for news |
| **Academic papers** | ⚠️ Hybrid | Check KB | KB may have summaries |
| **Product/company research** | ⚠️ Hybrid | Current data | Mix KB + web |
| **Pattern extraction** | ✅ Yes | Compare | KB has patterns |

---

## Integration Points

### 1. At Spawn Time
```julia
# When Scout is selected/spawned
@info "Scout selected: Checking KB for relevant research..."
kb_docs = search_kb_sqlite(task)

if !isempty(kb_docs)
    @info "Found $(length(kb_docs)) KB documents. Including in context."
    # Include KB context in prompt
else
    @info "No KB match. Conducting independent research."
end
```

### 2. During Execution
```julia
# Scout's internal research loop
function scout_research(task::String; use_kb::Bool=true)
    results = []
    
    # Step 1: KB lookup (optional but recommended)
    if use_kb
        kb_research = search_kb_sqlite(task)
        push!(results, ("kb", kb_research))
    end
    
    # Step 2: Web research (always)
    web_research = web_search(task)
    push!(results, ("web", web_research))
    
    # Step 3: Synthesize
    synthesize_research(results)
end
```

### 3. At Completion
```julia
# Scout reports findings with source attribution
report = """
Research Report: $task

## Knowledge Base Findings
$(kb_findings)

## Current Research (Web)
$(web_findings)

## Synthesis
$(combined_analysis)

Sources:
- KB: $(kb_sources)
- Web: $(web_urls)
"""
```

---

## Citation Format for Scout

### KB-Only Finding
```
"According to KB (SOURCE: azure-foundry-guide.json, 2026-04-04): 
Azure Foundry is a fully managed service..."
```

### KB + Web Finding
```
"KB documents (SOURCE: extracted-patterns.json) show that pattern X works. 
Current research (SOURCE: URL) confirms this with recent benchmarks..."
```

### Web-Only Finding
```
"Current research (SOURCE: URL) indicates new development in X..."
```

---

## Prompt Template for Scout with KB

```
You are Scout, the research specialist. Your task is to research: {TASK}

BACKGROUND CONTEXT FROM KNOWLEDGE BASE:
{KB_CONTEXT}

INSTRUCTIONS:
1. Start with the KB context above as foundation
2. Search the web for current information, recent developments, and verification
3. Compare KB findings with current research
4. If KB is outdated, note the updates
5. If KB is missing information, research and add it
6. Provide citations for all sources (KB source files and web URLs)
7. Synthesize into a clear, comprehensive report

Format your findings as:
## KB Foundation
[Summarize what you found in the KB]

## Current Research Findings
[What you found on the web]

## Analysis
[How they compare, what's new, what's verified]

## Sources
- KB: [list files]
- Web: [list URLs]

Begin research now.
```

---

## Q-Learning Integration

Scout's Q-scores by task type:

| Task Type | Q-Score | KB Value | Strategy |
|-----------|---------|----------|----------|
| research | 0.8476 | High | KB-first (verified) |
| documentation | 0.6263 | Medium | KB-first |
| analysis | 0.5000 | Medium | KB-first |
| training | 0.5000 | Medium | KB-first |

Scout's KB-first approach should **increase Q-scores** by:
- Reducing web search time (faster = higher score)
- Improving answer quality (KB foundation)
- Better source attribution (verifiable)

---

## Testing the Integration

### Test Case 1: Historical Research
```bash
# Spawn Scout with KB-first
julia scripts/ml/agent-spawner-qp.jl \
  --task "research nikola tesla" \
  --agent "Scout"

# Expected:
# 1. KB lookup finds nikola-tesla-verified.json
# 2. Scout includes KB as foundation
# 3. Web search verifies/updates facts
# 4. Report cites both KB and web
```

### Test Case 2: Current Events
```bash
# Spawn Scout for news
julia scripts/ml/agent-spawner-qp.jl \
  --task "research latest AI developments 2026" \
  --agent "Scout"

# Expected:
# 1. KB lookup finds AI patterns doc (partial match)
# 2. Web search for current 2026 developments
# 3. Scout synthesizes: KB foundation + web current events
```

### Test Case 3: Technology Research
```bash
# Spawn Scout for Azure
julia scripts/ml/agent-spawner-qp.jl \
  --task "research azure foundry deployment" \
  --agent "Scout"

# Expected:
# 1. KB lookup finds azure-foundry-guide.json
# 2. Scout uses as foundation
# 3. Web search for latest features/changes
# 4. Complete, current report with KB + web
```

---

## Behavior Changes

### Before (Web-Only)
```
Spawn Scout → "research nodejs async patterns"
→ web_search("nodejs async patterns")
→ Return latest web results
→ KB unused
→ Findings: Current but ungrounded
```

### After (KB-First)
```
Spawn Scout → "research nodejs async patterns"
→ Query KB for "nodejs" or "async"
→ Found: extracted-patterns.json (partial match)
→ Include KB patterns as foundation
→ web_search("nodejs async patterns 2026")
→ Return: KB foundation + current web findings
→ Findings: Grounded in verified patterns + current
```

---

## Configuration Options

### Scout Configuration
```yaml
scout:
  kb_enabled: true              # Enable KB-first
  kb_priority: "high"           # Always check KB first
  kb_fallback: "web"            # Fallback to web if KB insufficient
  web_supplement: true          # Always supplement KB with web
  citation_format: "full"       # Include source files + URLs
  research_depth: "comprehensive" # Thoroughly synthesize findings
  q_learning: true              # Track performance for Q-score updates
```

---

## Metrics & Tracking

Scout KB-first metrics (track in rl-task-execution-log.jsonl):

- **KB hit rate:** % of research tasks with KB matches
- **KB+Web rate:** % using both KB and web
- **Web-only rate:** % of tasks where KB had no match
- **Response time:** KB + web vs web-only
- **Citation count:** KB sources vs web sources
- **Q-score impact:** Change in Scout's research Q-score

Goal: **70%+ KB-first research tasks within 2 weeks** (Scout should be KB-heavy).

---

## Notes for Scout

- **KB is your foundation** — Verified, grounded research
- **Web is your supplement** — Current data, recent developments
- **Your strength:** Combining both for complete, current, verified research
- **Citation matters:** Always tell user where info came from
- **Updates matter:** Note when KB is old vs web is new
- **Synthesis matters:** Don't just list KB then web — integrate them

---

_Activated: 2026-04-04 16:26 GMT+1_  
_Agent: Scout (Research Specialist)_  
_Status: Live and active_  
_Tracking: data/rl/rl-task-execution-log.jsonl_
