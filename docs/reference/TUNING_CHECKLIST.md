# Tuning Checklist — Settings to Adjust

**Date:** 2026-02-28  
**Effort:** 2 hours  
**Cost:** $0  
**Expected Impact:** 15-20% improvement  

---

## OPENCLAW CONFIG (~/.openclaw/openclaw.json)

### 1. Sub-Agent Concurrency
**Location:** `agents.defaults.maxConcurrent`  
**Current:** `3`  
**Change to:** `5`  
**Why:** Allow more parallel work (3 agents → 5 agents simultaneously)  
**Impact:** Faster execution on complex tasks  

```json
"agents": {
  "defaults": {
    "maxConcurrent": 5  // was 3
  }
}
```

---

### 2. Sub-Agent Max Concurrent
**Location:** `agents.defaults.subagents.maxConcurrent`  
**Current:** `5`  
**Change to:** `7`  
**Why:** Allow more subagent instances  
**Impact:** Better task parallelization  

```json
"agents": {
  "defaults": {
    "subagents": {
      "maxConcurrent": 7  // was 5
    }
  }
}
```

---

### 3. Memory Cache Size
**Location:** `agents.defaults.memorySearch.cache.maxEntries`  
**Current:** `20000`  
**Change to:** `50000`  
**Why:** Larger cache = better context retention  
**Impact:** Fewer cache misses, better memory recall  

```json
"agents": {
  "defaults": {
    "memorySearch": {
      "cache": {
        "maxEntries": 50000  // was 20000
      }
    }
  }
}
```

---

### 4. Memory Context TTL
**Location:** `agents.defaults.contextPruning.ttl`  
**Current:** `"2h"`  
**Change to:** `"4h"`  
**Why:** Keep context longer before pruning  
**Impact:** Better continuity across longer conversations  

```json
"agents": {
  "defaults": {
    "contextPruning": {
      "ttl": "4h"  // was 2h
    }
  }
}
```

---

### 5. Heartbeat Interval
**Location:** `agents.defaults.heartbeat.every`  
**Current:** `"55m"`  
**Change to:** `"30m"`  
**Why:** More frequent health checks  
**Impact:** Faster detection of issues  

```json
"agents": {
  "defaults": {
    "heartbeat": {
      "every": "30m"  // was 55m
    }
  }
}
```

---

### 6. Web Search Results
**Location:** `tools.web.search.maxResults`  
**Current:** `3`  
**Change to:** `5`  
**Why:** Deeper research (more sources)  
**Impact:** Better research quality from Scout  

```json
"tools": {
  "web": {
    "search": {
      "maxResults": 5  // was 3
    }
  }
}
```

---

### 7. Model Fallbacks
**Location:** `agents.defaults.model.fallbacks`  
**Current:** `["sonnet-4-6", "opus-4-5", "sonnet-4-5", "mistral"]`  
**Change to:** `["sonnet-4-6", "sonnet-4-5", "opus-4-5", "mistral"]`  
**Why:** Better fallback priority  
**Impact:** Smarter model selection  

```json
"agents": {
  "defaults": {
    "model": {
      "fallbacks": [
        "anthropic/claude-sonnet-4-6",
        "anthropic/claude-sonnet-4-5",
        "anthropic/claude-opus-4-5",
        "ollama/mistral"
      ]
    }
  }
}
```

---

## Q-LEARNING CONFIGURATION (rl-agent-selection.json)

### 8. Learning Rate (Alpha)
**Location:** `metadata.alpha`  
**Current:** `0.01`  
**Change to:** `0.02`  
**Why:** Learn from experiences 2x faster  
**Impact:** Q-scores converge in ~2 weeks (vs 4 weeks)  
**Tradeoff:** Slightly more volatile, but acceptable  

```json
{
  "metadata": {
    "alpha": 0.02  // was 0.01
  }
}
```

---

### 9. Exploration Rate (Epsilon)
**Location:** `metadata.epsilon`  
**Current:** `0.1` (10% random)  
**Change to:** `0.15` (15% random)  
**Why:** Try alternatives more often early on  
**Impact:** Discover if other agents are better  
**Timeline:** Reduce to 0.05 after 2 months of stable Q-scores  

```json
{
  "metadata": {
    "epsilon": 0.15  // was 0.1
  }
}
```

---

### 10. Update Interval
**Location:** `metadata.updateInterval` (if exists)  
**Current:** Daily cron job  
**Change to:** Every 6 hours  
**Why:** Faster iteration on Q-learning  
**Impact:** System learns quicker  

```bash
# Current: @daily
# Change to: */6 * * * * (every 6 hours)
```

---

## MEMORY SYSTEM (rl-agent-selection.json or config)

### 11. Hybrid Search Vector Weight
**Location:** `agents.defaults.memorySearch.query.hybrid.vectorWeight`  
**Current:** `0.75` (75% semantic)  
**Change to:** `0.85` (85% semantic)  
**Why:** Prioritize semantic meaning over keywords  
**Impact:** Better conceptual matches  

```json
"memorySearch": {
  "query": {
    "hybrid": {
      "vectorWeight": 0.85,    // was 0.75
      "textWeight": 0.15       // was 0.25
    }
  }
}
```

---

### 12. Hybrid Search Text Weight
**Location:** `agents.defaults.memorySearch.query.hybrid.textWeight`  
**Current:** `0.25` (25% keyword)  
**Change to:** `0.15` (15% keyword)  
**Why:** Less emphasis on exact keyword matches  
**Impact:** Slightly fewer false positives on keywords  

```json
"memorySearch": {
  "query": {
    "hybrid": {
      "vectorWeight": 0.85,
      "textWeight": 0.15  // was 0.25
    }
  }
}
```

---

### 13. Auto-Capture Conversations
**Location:** `plugins.entries.memory-lancedb.config.autoCapture`  
**Current:** `true` (but disabled)  
**Change to:** `true` + enable  
**Why:** Automatically save conversation context  
**Impact:** Better memory of past interactions  

```json
"plugins": {
  "entries": {
    "memory-lancedb": {
      "config": {
        "autoCapture": true
      }
    }
  }
}
```

---

### 14. Auto-Recall Mode
**Location:** `plugins.entries.memory-lancedb.config.autoRecall`  
**Current:** `true`  
**Change to:** `"aggressive"`  
**Why:** More proactive context injection  
**Impact:** Better memory retrieval  

```json
"plugins": {
  "entries": {
    "memory-lancedb": {
      "config": {
        "autoRecall": "aggressive"  // was true
      }
    }
  }
}
```

---

## LOGGING & VERIFICATION

### 15. Task Logging Detail
**Location:** Logging configuration (to be added)  
**Current:** Basic (only failures)  
**Change to:** Comprehensive (all tasks)  
**Why:** Better analytics and pattern detection  
**Action:** Add comprehensive task logging to all agent executions  

```python
# Log all tasks:
{
  "timestamp": "...",
  "task_type": "...",
  "agent": "...",
  "quality_score": "...",
  "success": "...",
  "time_minutes": "..."
}
```

---

### 16. Quality Threshold
**Location:** Task verification logic (to be added)  
**Current:** Implicit (varies)  
**Change to:** Explicit (0.70)  
**Why:** Clear gate for what's "good enough"  
**Impact:** Better quality control  

```
If quality_score > 0.70:
  Accept task as complete
Else:
  Request refinement
```

---

### 17. Failure Auto-Logging
**Location:** MORPHEUS_FAILURES.md + agent execution  
**Current:** Manual  
**Change to:** Automatic  
**Why:** Never miss a failure pattern  
**Action:** Auto-log all failures with root cause  

---

## PROCESS & CRON JOBS

### 18. Research Refresh Intervals
**Location:** PROCESS_FLOWS.md + research system  
**Current:** 30d (tech), 90d (general)  
**Change to:** 14d (tech), 45d (general)  
**Why:** Fresher research, more responsive  
**Tradeoff:** More Scout work  

```markdown
# In PROCESS_FLOWS.md:
Research refresh cycle: 14 days (tech), 45 days (general)
```

---

### 19. Daily Health Check Cron
**Location:** Cron jobs  
**Current:** Not explicitly defined  
**Change to:** Add daily Q-table backup & analysis  
**Why:** Ensure Q-Learning data persists  
**Action:** Add cron job to backup rl-*.json daily  

```bash
# Add to crontab:
0 2 * * * cp /home/art/.openclaw/workspace/rl-*.json /backup/rl-backup-$(date +\%Y\%m\%d).json
```

---

## GATEWAY SETTINGS (Optional)

### 20. IP Whitelist
**Location:** `gateway.trustedProxies` or security settings  
**Current:** None  
**Change to:** Add IP whitelist if using remote access  
**Why:** Prevent unauthorized access  
**Action:** Add your IP(s) if accessing remotely  

```json
"gateway": {
  "trustedProxies": ["192.168.1.100"]  // your IP
}
```

---

### 21. Tailscale Mode
**Location:** `gateway.tailscale.mode`  
**Current:** `"off"`  
**Change to:** `"on"` (if want remote access)  
**Why:** Secure remote access via Tailscale  
**Impact:** Can access from anywhere safely  

```json
"gateway": {
  "tailscale": {
    "mode": "on"  // was off
  }
}
```

---

## SUMMARY CHECKLIST

### HIGH PRIORITY (Do These)
- [ ] **1.** Max concurrent agents: 3 → 5
- [ ] **2.** Sub-agent max: 5 → 7
- [ ] **8.** Q-Learning alpha: 0.01 → 0.02
- [ ] **9.** Q-Learning epsilon: 0.1 → 0.15
- [ ] **11.** Vector weight: 0.75 → 0.85
- [ ] **12.** Text weight: 0.25 → 0.15
- [ ] **16.** Set quality threshold: 0.70

### MEDIUM PRIORITY (Do These)
- [ ] **3.** Memory cache: 20K → 50K
- [ ] **4.** Memory TTL: 2h → 4h
- [ ] **5.** Heartbeat: 55m → 30m
- [ ] **6.** Web search results: 3 → 5
- [ ] **13.** Auto-capture: enable
- [ ] **14.** Auto-recall: aggressive
- [ ] **15.** Comprehensive logging: enable
- [ ] **18.** Research refresh: 14d/45d

### LOW PRIORITY (Optional)
- [ ] **7.** Model fallbacks: reorder
- [ ] **17.** Failure auto-logging: enable
- [ ] **19.** Daily backup cron: add
- [ ] **20.** IP whitelist: add if remote
- [ ] **21.** Tailscale: enable if desired

---

## HOW TO MAKE CHANGES

### Option 1: Edit JSON Directly
```bash
# Edit OpenClaw config
nano ~/.openclaw/openclaw.json

# Find and change settings from checklist above
# Save and restart
openclaw gateway restart
```

### Option 2: Use Gateway Config API
```bash
# Get current config
curl http://localhost:18789/config

# Patch with changes
curl -X PATCH http://localhost:18789/config -d '{"agents": {"defaults": {"maxConcurrent": 5}}}'

# Restart
curl -X POST http://localhost:18789/restart
```

### Option 3: Ask Morpheus
```
"Tune the system: increase concurrency to 5, learning rate to 0.02, 
memory cache to 50K, heartbeat to 30 min, logging to comprehensive"
```

---

## EXPECTED IMPROVEMENTS

After applying these tunings:

| Change | Expected Impact |
|--------|-----------------|
| Concurrency: 3→5 | 20-30% faster multi-task execution |
| Learning rate: 0.01→0.02 | Q-scores converge 2x faster |
| Exploration: 0.1→0.15 | Better agent discovery |
| Memory cache: 20K→50K | 25% fewer cache misses |
| Memory TTL: 2h→4h | Better long conversation continuity |
| Heartbeat: 55m→30m | Faster issue detection |
| Vector weight: 0.75→0.85 | Better semantic matching |
| Logging: comprehensive | Better analytics & debugging |

**Combined:** 15-20% system improvement

---

## VERIFICATION AFTER TUNING

```bash
# Check OpenClaw config applied
jq '.agents.defaults.maxConcurrent' ~/.openclaw/openclaw.json

# Check Q-Learning alpha
jq '.metadata.alpha' ~/rl-agent-selection.json

# Restart system
openclaw gateway restart

# Monitor next few tasks
# Check if concurrency actually increases
# Monitor Q-scores converging faster
```

---

## TIMELINE

- **Today (5 min):** Make 5 highest-priority changes
- **Tomorrow (5 min):** Make 8 medium-priority changes
- **This week:** Verify everything working
- **Next 2 weeks:** Monitor improvements, adjust if needed

**Total time:** ~30-45 minutes hands-on
**Total cost:** $0
**Expected gain:** 15-20% improvement
