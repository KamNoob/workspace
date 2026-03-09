# Upgrade Quick Reference Card

**Do This First (TODAY - $0):**

```json
OpenClaw Config Changes:
  - Sub-agent concurrency: 3 → 5
  - Memory cache: 20K → 50K
  - Memory TTL: 2h → 4h
  - Heartbeat: 55m → 30m
  - Web search results: 3 → 5

Q-Learning Changes:
  - Alpha: 0.01 → 0.02
  - Epsilon: 0.1 → 0.15
  - Update interval: Daily → 6h

Logging Changes:
  - Enable comprehensive logging
  - Auto-detect failures
  - Set quality threshold: 0.70
```

**Expected Benefit:** 15-20% faster iteration, better learning

---

**Q1 2026 (If Needed - $60):**

```
1TB NVMe SSD
Cost: $60
Time: 30 min
Benefit: 5+ year storage headroom
```

---

**Q2 2026 (If Needed - $50):**

```
8GB DDR4 RAM
Cost: $50
Time: 15 min
Benefit: Support 5-7 concurrent agents
```

---

**Q3+ 2026 (Optional - $100-200):**

```
GPU Upgrade (GTX 1050 Ti or better)
Cost: $100-200
Time: 1 hour
Benefit: 2-3x Mistral speed (not needed)
```

---

**2027 (Optional - $500-1000):**

```
Full System Replacement
Current system fine through end 2026
Plan in Q1 2027 if desired
```

---

**Files:**
- UPGRADE_OPTIONS.md (detailed analysis)
- HARDWARE_SPECS.md (current specs)
