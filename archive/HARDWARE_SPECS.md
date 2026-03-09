# Hardware Specifications

**Date:** 2026-02-28  
**Machine:** Dell OptiPlex (art-OptiPlex-ubu2)

---

## CPU

- **Model:** Intel Core i5-6600T @ 2.70GHz
- **Cores:** 4
- **Threads:** 4
- **TDP:** 35W (low-power)
- **Generation:** 6th Gen (Skylake, 2015)
- **Current scaling:** 80%

---

## Memory

| Type | Total | Used | Available |
|------|-------|------|-----------|
| RAM | 15GB | 5.7GB | 9.7GB |
| Swap | 2.0GB | 1.4GB | 619MB |

**Assessment:**
- Current system uses ~5.7GB
- Q-Learning + embeddings: ~350MB
- Claude + Mistral: Cached in memory as needed
- Safe headroom: 9.7GB available
- Monitor if spawning >10 concurrent agents

---

## Storage

- **Filesystem:** /dev/sda5
- **Total:** 457GB
- **Used:** 73GB (17%)
- **Available:** 362GB (83%)
- **Type:** Likely SATA SSD or HDD (not identified)

**Assessment:**
- Plenty of space for research library (currently <1MB)
- Safe for multi-year operation at current usage

---

## GPU

- **Integrated:** Intel HD Graphics 530
- **Dedicated:** None (no NVIDIA, AMD, or discrete GPU)
- **VRAM:** Shared from system RAM (no separate allocation)

**Impact:**
- Embeddings compute slower than GPU-enabled systems
- Claude inference via cloud (not local, so GPU irrelevant)
- Mistral local fallback: ~2-3x slower than with GPU, but acceptable
- Neural networks will run fine without GPU (50-200ms latency)

---

## Operating System

- **Distro:** Ubuntu 22.04 LTS
- **Kernel:** 6.8.0-101-generic
- **Architecture:** x86_64 (Intel)

---

## Network

- **Gateway connectivity:** Via TCP/IP
- **Bandwidth:** Typical home/office network (not measured)
- **OpenClaw latency:** Internal (LAN), minimal impact

---

## Workload Assessment

### Current Usage (Live)

| Component | Memory | CPU | Disk |
|-----------|--------|-----|------|
| OpenClaw Gateway | ~200MB | <5% | — |
| Claude LLM (cloud) | Minimal (cloud) | <1% | — |
| Q-Learning tables | ~10MB | <1% | ~6KB |
| EmbeddingGemma 300M | 314MB | 5-10% (when queried) | 314MB |
| Research library | <1MB | — | <50MB |
| System & OS | ~1.5GB | 5-10% | ~40GB |
| **Total** | **~5.7GB** | **~10-15%** | **~73GB** |

### Headroom

- **RAM:** 9.7GB available (can handle 3-5 more concurrent agents)
- **CPU:** 4 cores at 80% (can handle increased workload)
- **Disk:** 362GB available (5+ years at current growth rate)

---

## Suitability for Current & Future Workloads

### ✅ Current Setup (Optimal)

- Q-Learning Agent Selection ✅
- Research library with local embeddings ✅
- Sub-agent orchestration (2-3 concurrent) ✅
- Process flows & memory management ✅

### ✅ Near-Term Additions (Fine)

- Neural networks Phase 1-2 (Task Classification, Intent Recognition) ✅
- Quality Prediction model ✅
- Anomaly Detection ✅
- Document semantic chunking ✅
- **Total additional footprint:** ~250MB (easily fits)

### ⚠️ Medium-Term Scalability (Monitor)

- 5+ concurrent agents → Monitor memory usage
- Mistral local LLM running constantly → Consider GPU
- Workflow Optimization neural net → Acceptable without GPU
- Multi-Agent Orchestration → Acceptable without GPU

### ❌ Not Recommended (GPU Needed)

- Training custom embeddings (should stick with pre-trained)
- Fine-tuning large language models locally (use cloud providers)
- High-frequency GPU-accelerated inference (>100/second)

---

## Recommendations

### Short-term (Next Month)
- **No hardware upgrades needed**
- Current system sufficient for all planned work
- Monitor memory if spawning >5 concurrent agents

### Medium-term (3-6 Months)
- **GPU addition optional but beneficial**
  - Cost: $100-300 (used GPU like GTX 1050 or RTX 2060)
  - Benefit: 3-5x faster Mistral inference, 2-3x faster embeddings
  - Not critical (system works without)

### Long-term (6-12 Months)
- **Consider replacement if:**
  - Scaling to 20+ concurrent agents
  - Training custom models locally
  - Need real-time GPU inference (>100 req/sec)
- Current system is 2015-era; still solid for 2026

---

## Notes

- **Dell OptiPlex:** Business-class desktop, known for reliability
- **i5-6600T:** Low-power variant (35W), good for 24/7 operation
- **No issues detected:** System running smoothly, temperatures normal
- **Swap usage (1.4GB):** Indicates memory pressure at times, but within acceptable range

---

## Future Hardware Upgrades (Optional)

### GPU Addition (If Desired)

**Recommended:**
- NVIDIA GTX 1050 Ti (~$80-120 used) → 2x improvement
- NVIDIA RTX 2060 (~$150-250 used) → 3-4x improvement
- AMD RX 6600 (~$150-200 used) → 2.5-3x improvement

**Not needed for:**
- Q-Learning (CPU-bound)
- Research library (I/O-bound)
- Claude inference (cloud-based)

**Useful for:**
- Mistral local inference (3-5x speedup)
- Embeddings (2-3x speedup)
- Neural network training (if ever needed)

---

**Status:** Hardware is adequate for all planned work through 2026. No upgrades necessary.
