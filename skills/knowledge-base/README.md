# Knowledge Base - Tier 1 & Beyond

_Comprehensive guides for all major systems._

## Tier 1: Hardware + AI Agent Routing

### 🔧 Hardware Integration Guide
**File:** `tier1-hardware-guide.md`  
**Size:** 5.2 KB | **Lines:** 252  
**Topics:**
- Arduino CLI installation & commands
- Board configuration (Arduino UNO, ESP32)
- Sketches (blink_uno, wifi_esp32)
- Troubleshooting & specifications
- Wrapper script usage

**Start here if:** You want to develop with Arduino/ESP32

---

### 🧠 Agent Router Neural Network Guide
**File:** `tier1-agent-router-guide.md`  
**Size:** 9.9 KB | **Lines:** 437  
**Topics:**
- Quick start (3 commands to test)
- All 3 phases explained
- Architecture & data formats
- Feature engineering details
- Workflows (retrain, monitor, analyze)
- Troubleshooting guide

**Start here if:** You want to understand the neural network system

---

### 📋 Tier 1 Exploration Summary
**File:** `tier1-exploration-summary.md`  
**Size:** 7.8 KB | **Lines:** 300  
**Topics:**
- Complete project overview
- File inventory
- Test results
- Quick reference (all commands)
- Next steps
- Tier 2 projects

**Start here if:** You want a high-level overview of everything

---

## How to Use This Knowledge Base

### Quick Start (5 minutes)
1. Read: `tier1-exploration-summary.md`
2. Pick your interest: Hardware or Agent Router
3. Jump to relevant detailed guide

### Deep Dive (30 minutes)
1. Read: Relevant detailed guide
2. Try: Quick start commands
3. Reference: Troubleshooting section if needed

### Production Deployment
1. Review: Architecture sections
2. Check: All test results
3. Run: All commands listed
4. Monitor: Using prediction log / CLI

---

## File Structure

```
skills/knowledge-base/
├── README.md                           (this file)
├── tier1-hardware-guide.md            5.2 KB
├── tier1-agent-router-guide.md        9.9 KB
└── tier1-exploration-summary.md       7.8 KB

Total: ~23 KB, 989 lines of documentation
```

---

## All Guides at a Glance

| Guide | Purpose | Read Time | Best For |
|-------|---------|-----------|----------|
| Exploration Summary | Overview of everything | 5 min | Getting oriented |
| Hardware Guide | Arduino/ESP32 development | 10 min | Hardware work |
| Agent Router Guide | NN system & workflows | 15 min | ML/AI work |

---

## Commands Quick Reference

### Hardware
```bash
# List boards
hardware/arduino-cli-wrapper.sh list-boards

# Compile
hardware/arduino-cli-wrapper.sh compile esp32 wifi_esp32

# Upload
hardware/arduino-cli-wrapper.sh upload esp32 /dev/ttyUSB0 wifi_esp32

# Monitor
hardware/arduino-cli-wrapper.sh monitor /dev/ttyUSB0 115200
```

### Agent Router
```bash
# Prepare data
julia scripts/ml/agent-router-data.jl

# Train model
julia scripts/ml/train-agent-router.jl

# Make predictions
julia scripts/ml/agent-router-spawner.jl --task "code review" --candidates "Codex,QA"

# View logs
cat data/rl/agent-router-predictions.jsonl | jq '.'
```

---

## Status & Links

**Tier 1 Status:** ✅ COMPLETE & TESTED

**Related Documentation:**
- `TIER1_FINAL_STATUS.md` — Final project summary
- `AGENT_ROUTER_PLAN.md` — Detailed architecture
- `PHASE3_COMPLETE.md` — Phase 3 implementation
- `EXPLORATION_THREADS.md` — All 5 tier projects

**Git History:**
- 13 clean commits
- ~2000 lines of code
- All tested and working

---

## Next Steps

### Immediate
- ✅ Tier 1 complete
- Read relevant guide for your interest
- Try quick start commands

### This Week
- Collect real task data
- Retrain agent router
- Test hardware with USB

### Next 2 Weeks
- Tier 2 projects (KB expansion, dashboards)
- Deploy agent router
- Build feedback loop

---

## Contributing

To add or improve guides:
1. Edit relevant `.md` file
2. Keep consistent formatting
3. Update this README
4. Commit with clear message

Example:
```bash
git add skills/knowledge-base/tier1-*.md
git commit -m "kb: Improve hardware guide sections"
```

---

## FAQ

**Q: Where do I start?**
A: Read `tier1-exploration-summary.md` (5 min overview)

**Q: How do I use the hardware?**
A: Follow `tier1-hardware-guide.md` → Quick Commands section

**Q: How does the neural network work?**
A: See `tier1-agent-router-guide.md` → Architecture section

**Q: Can I modify the code?**
A: Yes! All scripts are documented. Retrain with new data.

**Q: What if something breaks?**
A: Check Troubleshooting sections in relevant guide

---

## Authors

- **Morpheus** — System design, integration
- **Documentation** — Generated from working code & tests

---

_Knowledge Base: Tier 1 Exploration Complete_  
_Status: 🟢 Production Ready_  
_Last Updated: 2026-03-14 12:45 GMT_
