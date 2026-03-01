# Upgrade Options — Settings & Hardware

**Date:** 2026-02-28  
**Current System:** Dell OptiPlex i5-6600T, 15GB RAM, 457GB disk, Intel HD 530  

---

## SOFTWARE SETTINGS (Zero Cost)

### OpenClaw Configuration

| Setting | Current | Upgradable To | Impact | Effort |
|---------|---------|---------------|--------|--------|
| **Model Fallbacks** | Haiku → Sonnet → Opus → Mistral | Add Claude 3.5 Sonnet | Faster reasoning | 5 min |
| **Sub-agent Concurrency** | 3 max | 5 max | Parallel speedup | 5 min |
| **Memory Cache TTL** | 2 hours | 4 hours | Better context retention | 5 min |
| **Web Search Results** | 3 max | 5-10 max | More research depth | 5 min |
| **Context Pruning Mode** | cache-ttl | safeguard | More aggressive optimization | 10 min |
| **Session Timeout** | 55 minutes | 90 minutes | Longer conversations | 5 min |
| **Token Limits (Haiku)** | 90K threshold | 80K threshold | More proactive resets | 5 min |

**Recommendation:** Increase sub-agent concurrency (3→5), increase memory TTL (2h→4h), add Claude 3.5 to fallbacks

---

### Q-Learning Parameters

| Parameter | Current | Upgrade | Impact | Effort |
|-----------|---------|---------|--------|--------|
| **Alpha (learning rate)** | 0.01 | 0.02 | Learn 2x faster | 5 min |
| **Epsilon (exploration)** | 0.1 (10%) | 0.15 (15%) | More diverse learning | 5 min |
| **Gamma (future discounting)** | 0.99 | 0.95 | More immediate-focused | 5 min |
| **Update Interval** | Daily | Every 6 hours | Faster iteration | 10 min |

**Recommendation:** Increase alpha to 0.02 (faster learning), increase epsilon to 0.15 (explore more), reduce update interval to 6 hours (faster feedback)

---

### Memory System

| Setting | Current | Upgrade | Impact | Effort |
|---------|---------|---------|--------|--------|
| **Cache Max Entries** | 20K | 50K | Larger context window | 5 min |
| **Vector Weight (hybrid)** | 0.75 | 0.85 | More semantic matching | 5 min |
| **Text Weight (hybrid)** | 0.25 | 0.15 | Less keyword matching | 5 min |
| **Auto-capture** | False | True | Capture conversations | 5 min |
| **Auto-recall** | True | Aggressive | More proactive context | 5 min |

**Recommendation:** Increase cache (20K→50K), increase vector weight (0.75→0.85), enable auto-capture, set auto-recall to aggressive

---

### Process & Logging

| Setting | Current | Upgrade | Impact | Effort |
|---------|---------|---------|--------|--------|
| **Task Logging Detail** | Basic | Comprehensive | Better analytics | 10 min |
| **Failure Logging** | Manual | Automatic | Never miss patterns | 5 min |
| **Research Refresh Interval** | 30/90 days | 14/45 days | Fresher data | 5 min |
| **Verification Threshold** | Implicit | Explicit (0.7 score) | Clearer quality gates | 10 min |
| **Cron Job Frequency** | 55 min heartbeat | 30 min heartbeat | Faster response | 5 min |

**Recommendation:** Enable comprehensive logging, set explicit verification threshold (0.70), reduce heartbeat to 30 min

---

### Gateway Settings

| Setting | Current | Upgrade | Impact | Effort |
|---------|---------|---------|--------|--------|
| **Port** | 18789 | Keep same | — | — |
| **Auth Mode** | Token | Add IP whitelist | Better security | 10 min |
| **Tailscale Mode** | Off | On | Remote access | 15 min |
| **Rate Limiting** | None | Add per-IP limits | Prevent abuse | 10 min |
| **HTTPS/TLS** | Loopback only | Full TLS cert | Secure remote | 20 min |

**Recommendation:** Enable IP whitelist, enable Tailscale (if want remote access), add rate limiting

---

**Settings Upgrade Time (All):** ~2 hours, Zero cost, Immediate improvements

---

## HARDWARE UPGRADES

### Storage Upgrades

#### Option 1: Add SSD (Recommended)

| Item | Cost | Size | Impact | Effort |
|------|------|------|--------|--------|
| **2TB SATA SSD** | $120-150 | 2TB | 5+ year headroom | 30 min |
| **2TB NVMe M.2** | $100-140 | 2TB | Faster disk I/O, 5+ year headroom | 30 min |
| **1TB NVMe** | $50-80 | 1TB | Good sweet spot | 30 min |

**Current:** 362GB available / 73GB used (17%)  
**Recommendation:** Add 1TB NVMe ($60, 30 min) → Total 1.5TB free space (5+ years runway)

**Installation:**
1. Back up current data (optional, ~1 hour)
2. Install SSD into SATA slot or M.2 slot (5 min)
3. Format & mount (10 min)
4. Move research library + RL tables to new disk (5 min)

---

#### Option 2: Replace Existing Drive

| Item | Cost | Benefit |
|------|------|---------|
| 4TB SATA SSD | $200-250 | Full system replacement, 10+ year headroom |
| 2TB NVMe | $100-140 | Faster + larger than current |

**Not necessary now, consider in 2027 if needed**

---

### Memory Upgrades

#### Option 1: Add More RAM

| Item | Cost | Upgrade | Impact | Effort |
|------|------|---------|--------|--------|
| **8GB DDR4** | $40-60 | 15GB → 23GB | 50% more headroom | 15 min |
| **16GB DDR4** | $80-120 | 15GB → 31GB | 2x headroom | 15 min |

**Current:** 15GB total, 9.7GB available (adequate)  
**When needed:** If spawning 10+ concurrent agents  
**Recommendation:** Hold off for now, add 8GB in Q3 2026 if needed ($50)

**Installation:**
1. Shut down system (2 min)
2. Open case (2 min)
3. Install RAM into open slot (3 min)
4. Power on, verify in BIOS (5 min)

---

#### Option 2: Full RAM Replacement

| Item | Cost | Upgrade | Benefit |
|------|------|---------|---------|
| 32GB DDR4 Kit | $150-200 | 15GB → 32GB | Future-proof (5+ years) |
| 64GB DDR4 Kit | $250-350 | 15GB → 64GB | Overkill for current work |

**Not necessary now, consider in 2027**

---

### GPU Upgrades (Optional)

#### Option 1: Dedicated GPU (For Speed, Not Necessity)

| Item | Cost | VRAM | Impact | Effort |
|------|------|------|--------|--------|
| **NVIDIA GTX 1050 Ti** | $80-120 | 2GB | 2x Mistral speed | 1 hour |
| **NVIDIA GTX 1650** | $100-150 | 4GB | 2.5x speed | 1 hour |
| **NVIDIA RTX 2060** | $150-250 | 6GB | 3x speed | 1 hour |
| **AMD RX 6600 XT** | $150-200 | 6GB | 2.5x speed | 1 hour |

**Current:** Intel HD 530 (integrated, shared RAM)  
**When needed:** If Mistral queries become bottleneck (rare)  
**Recommendation:** Not needed, skip for now

**Benefits:**
- Mistral inference: 2-5s → 0.5-2s
- Embeddings: 3.5s cached → 0.5-1.5s
- No benefit for Q-Learning or Claude (cloud)

**Installation:**
1. Shut down, unplug (2 min)
2. Open case (2 min)
3. Insert GPU in PCIe slot (3 min)
4. Connect power (2 min)
5. Install NVIDIA/AMD drivers (20-30 min)
6. Configure in OpenClaw (10 min)

---

#### Option 2: Integrated GPU Upgrade (Not Possible)

Cannot upgrade integrated GPU without replacing motherboard/CPU (not worth it)

---

### CPU Upgrades

#### Option 1: CPU Only (Requires Motherboard)

Not feasible - i5-6600T is soldered in OptiPlex. Would require replacing entire machine.

---

#### Option 2: Full System Replacement (Future)

| Item | Cost | Specs | When |
|------|------|-------|------|
| **Dell OptiPlex 7090** | $300-500 | i7-10700, 16GB, 512GB SSD | 2027 |
| **Lenovo ThinkCentre M90** | $250-400 | i7-10700, 16GB, 256GB SSD | 2027 |
| **Custom Build** | $600-1000 | Ryzen 7 5700, 32GB, NVMe | 2027+ |

**Recommendation:** Current system fine through 2026, plan replacement in Q1 2027 if needed

---

### Network Upgrades

#### Option 1: Ethernet (If Not Already)

| Item | Cost | Speed | Impact |
|------|------|-------|--------|
| Cat6 Cable | $10-20 | 1Gbps | Stable connection |
| USB Ethernet Adapter | $15-30 | 1Gbps | If no RJ45 port |

**Current:** Unknown (likely already Ethernet)  
**Benefit:** More stable than WiFi, ~10-20ms latency improvement  
**Recommendation:** Verify current setup, upgrade to Cat6 if using Cat5

---

#### Option 2: WiFi 6 (If Needed)

| Item | Cost | Speed | Impact |
|------|------|-------|--------|
| WiFi 6 Router | $80-150 | 1.2Gbps | Future-proof, not needed now |
| WiFi 6 USB Adapter | $30-50 | 600Mbps | Overkill for API calls |

**Current:** Likely WiFi 5 or Ethernet  
**Benefit:** Lower latency (not critical for this workload)  
**Recommendation:** Skip, not bottleneck

---

## RECOMMENDED UPGRADE PATH

### Immediate (This Week, $0)

**Settings only, 2 hours work:**
1. ✅ Increase sub-agent concurrency (3→5)
2. ✅ Increase memory cache TTL (2h→4h)
3. ✅ Add Claude 3.5 to fallbacks
4. ✅ Increase alpha in Q-Learning (0.01→0.02)
5. ✅ Enable comprehensive task logging
6. ✅ Reduce heartbeat to 30 min
7. ✅ Set explicit quality threshold (0.70)

**Expected benefit:** 15-20% faster iteration, better learning, better logging

---

### Short-Term (Q1 2026, $60-100)

**If storage becomes concern:**
1. Add 1TB NVMe SSD ($60) — 30 min installation
2. Move research library + RL tables to new drive
3. Keep original drive as backup

**Expected benefit:** 5+ year headroom on storage

---

### Medium-Term (Q2-Q3 2026, $40-120)

**If need more RAM:**
1. Add 8GB DDR4 RAM ($50) — 15 min installation
2. Upgrade cache settings (20K→50K)
3. Enable more concurrent agents (3→5→7)

**Expected benefit:** Smoother operation with 5-7 concurrent agents

---

### Long-Term (Q4 2026 - Q1 2027, Optional)

**If Mistral becomes bottleneck:**
1. Add GTX 1050 Ti or better ($100-200) — 1 hour installation
2. 2-3x speed improvement on Mistral & embeddings
3. Not critical, only if running Mistral constantly

**Expected benefit:** Faster local inference if heavily used

---

### Replacement (2027, $500-1000)

**Full system replacement:**
1. Upgrade to i7-10700 or Ryzen 7 5700 system
2. 32GB RAM, NVMe SSD standard
3. Integrated graphics adequate
4. 5-7 year lifespan ahead

**When:** Q1-Q2 2027 if desired, current system still fine

---

## Priority Matrix

| Upgrade | Cost | Effort | Impact | Priority |
|---------|------|--------|--------|----------|
| Settings tuning | $0 | 2h | High | 🔴 NOW |
| 1TB SSD | $60 | 30m | Medium | 🟡 Q1 |
| 8GB RAM | $50 | 15m | Medium | 🟡 Q2 |
| GPU (optional) | $100-200 | 1h | Low | 🔵 Q3+ |
| Full replacement | $500-1000 | N/A | N/A | 🔵 2027 |

---

## Cost Summary

| Category | Cost | Timeline |
|----------|------|----------|
| **Settings (0)** | $0 | This week |
| **Storage (1)** | $60 | Q1 2026 |
| **Memory (1)** | $50 | Q2 2026 |
| **GPU (opt)** | $100-200 | Q3+ 2026 |
| **Replace (opt)** | $500-1000 | 2027 |

**Total through 2026:** $110-160 (if doing SSD + RAM)  
**No upgrades required:** System works fine as-is

---

## Recommendation Summary

### Do This Week ($0)
- ✅ Tune OpenClaw settings
- ✅ Adjust Q-Learning parameters
- ✅ Enable comprehensive logging
- **Expected gain:** 15-20% improvement

### Do in Q1 2026 ($60)
- ✅ Add 1TB SSD if storage concern
- **Expected gain:** 5+ year runway

### Consider in Q2 2026 ($50)
- ✅ Add 8GB RAM if spawning 5+ concurrent agents
- **Expected gain:** Smoother scaling

### Consider Later
- ❌ GPU upgrade (nice to have, not needed)
- ❌ Full replacement (current system good through 2026)

---

**Bottom Line:** System is well-optimized. Settings tuning is free and high-impact. Hardware upgrades are optional and not needed until 2027.
