---
name: llmfit-infrastructure
description: Hardware-aware LLM model selection and deployment planning. Analyzes system specifications (RAM, CPU, GPU) and scores 345+ models for optimal fit, memory efficiency, and estimated speed (tokens/sec). Use when Sentinel needs to: (1) recommend models for available hardware, (2) plan infrastructure upgrades, (3) select quantization strategies, (4) estimate inference speed, (5) determine run modes (GPU/CPU), or (6) assess deployment feasibility.
---

# LLMfit Infrastructure — Sentinel's Hardware-Model Analyzer

This skill equips Sentinel with hardware-aware model selection and deployment planning. Given your system specs, it scores all 345+ models for fit, memory, and speed—enabling data-driven infrastructure decisions.

**Philosophy:** Choose the right model for your hardware, not the other way around.

## Quick Start

Analyze models for your system:

```bash
# Analyze hardware configuration
sentinel-llmfit analyze 32 8 8
# ^ 32GB RAM, 8GB VRAM (GPU), 8 CPU cores

# Search for models matching criteria
sentinel-llmfit search "mistral"

# Get models for a use case
sentinel-llmfit usecase "chat"

# Recommend upgrades for a model
sentinel-llmfit recommend "llama" 16 0
```

## How It Works

**Input:** Your hardware specs (RAM, VRAM, CPU cores)  
**Processing:** Score each model for fit, memory, speed  
**Output:** Ranked models with fit level + deployment recommendations

### Fit Levels

| Level | Meaning | RAM Usage |
|-------|---------|-----------|
| **Perfect** | Runs smoothly, plenty of headroom | < 70% of available |
| **Good** | Runs well, acceptable overhead | 70-90% of available |
| **Marginal** | Runs, but tight, may swap | 90-100% of available |
| **TooTight** | Runs with significant slowdown | 100-120% of available |
| **Impossible** | Won't run | > 120% of available |

### Run Modes

| Mode | Hardware | Speed | Use Case |
|------|----------|-------|----------|
| **GPU** | VRAM available | Fast (5-10x CPU) | Preferred, requires GPU |
| **CPU_OFFLOAD** | GPU + system RAM | Medium (2x CPU) | Fallback, GPU saturated |
| **CPU_ONLY** | System RAM only | Slow (baseline) | Last resort, no GPU |

## Available Commands

### analyze

Analyze your hardware and get ranked model recommendations.

```bash
sentinel-llmfit analyze <ram_gb> <vram_gb> <cpu_cores>
```

**Example:**
```bash
$ sentinel-llmfit analyze 32 8 8

[Output: Top 15 models ranked by fit]
{
  "name": "mistral-7b",
  "fit": "perfect",
  "run_mode": "GPU",
  "estimated_tps": 45,
  "memory": {
    "min_ram_gb": 8,
    "min_vram_gb": 4,
    "available_ram_gb": 32,
    "available_vram_gb": 8
  },
  "utilization": {
    "ram_percent": "25",
    "vram_percent": "50"
  }
}
```

### search

Find models by name, use case, or architecture.

```bash
sentinel-llmfit search <query>
```

**Examples:**
```bash
sentinel-llmfit search "mistral"
sentinel-llmfit search "chat"
sentinel-llmfit search "7b"
```

### usecase

Get all models suitable for a specific use case.

```bash
sentinel-llmfit usecase <usecase>
```

**Use Cases:**
- `chat` - Conversation, instruction following
- `code` - Code generation, debugging
- `function_calling` - Structured output, tool use
- `lightweight` - Edge deployment, embedded systems
- `moe` - Mixture of experts (sparse models)

**Example:**
```bash
$ sentinel-llmfit usecase "chat"
15 model(s) for "chat":

mistral-7b (7B)
  Context: 32000 | Min RAM: 8GB

llama-2-7b-chat (7B)
  Context: 4096 | Min RAM: 8GB
```

### architecture

Get all models with a specific architecture.

```bash
sentinel-llmfit architecture <architecture>
```

**Popular Architectures:**
- `mistral` - Mistral & derivatives
- `llama` - Llama 1, 2, 3 (Meta)
- `phi` - Phi (Microsoft)
- `moe` - Mixture of Experts

**Example:**
```bash
$ sentinel-llmfit architecture llama
23 model(s) with architecture "llama"
```

### recommend

Get hardware upgrade recommendations for a specific model.

```bash
sentinel-llmfit recommend <model_name> <ram_gb> <vram_gb>
```

**Example:**
```bash
$ sentinel-llmfit recommend "llama-13b" 16 0

{
  "model_name": "llama-13b",
  "current_fit": "marginal",
  "upgrades_needed": true,
  "upgrades": [
    {
      "type": "RAM",
      "current_gb": 16,
      "needed_gb": 18,
      "recommended_gb": 36,
      "delta_gb": "20"
    }
  ]
}
```

### list

List all available models in the database.

```bash
sentinel-llmfit list
```

Shows name, parameter count, use case, and architecture for all 345+ models.

### stats

Show database statistics and metadata.

```bash
sentinel-llmfit stats
```

**Output:**
```json
{
  "total_models": 345,
  "architectures": ["llama", "mistral", "phi", ...],
  "use_cases": ["chat", "code", "function_calling", ...],
  "parameters": {
    "min": 80000,
    "max": 405000000000,
    "median": 7000000000
  }
}
```

## Use Cases for Sentinel

### 1. Deployment Planning

**Scenario:** "I want to deploy a chat model locally."

```bash
$ sentinel-llmfit usecase "chat"
$ sentinel-llmfit analyze 32 8 8
# → Returns: "Perfect fit for Mistral-7B (GPU mode, 45 tps)"
```

**Decision:** Provision hardware for Mistral-7B.

### 2. Hardware Upgrade Assessment

**Scenario:** "Should I upgrade to 24GB GPU VRAM?"

```bash
$ sentinel-llmfit analyze 64 16 16  # Current: 64GB RAM, 8GB VRAM
$ sentinel-llmfit analyze 64 24 16  # After upgrade: 24GB VRAM
# → Compare fit levels and speed improvements
```

**Decision:** Upgrade if speed improvement > cost.

### 3. Resource Allocation

**Scenario:** "What models can I run on a 16GB laptop?"

```bash
$ sentinel-llmfit analyze 16 0 8  # Integrated GPU, no discrete VRAM
# → Returns models with "good" or "perfect" fit on CPU/integrated GPU
```

**Decision:** Allocate only tight-fitting models to this machine.

### 4. Cost Optimization

**Scenario:** "What's the smallest model that meets performance requirements?"

```bash
$ sentinel-llmfit search "7b"
$ sentinel-llmfit usecase "code"
# → Returns lightest model in "code" category that fits your hardware
```

**Decision:** Use lightweight model, reduce resource waste.

### 5. Multi-GPU Planning

**Scenario:** "Can I run 2 models in parallel on dual GPUs?"

```bash
$ sentinel-llmfit analyze 128 32 16  # 2 x 16GB GPUs
# → Check fit levels for model pairs
```

**Decision:** Load-balance across GPUs.

## Fit Analysis Details

### Memory Calculation

Each model specifies:
- `min_ram_gb` — Minimum system RAM for CPU-only inference
- `recommended_ram_gb` — Recommended RAM for smooth operation
- `min_vram_gb` — Minimum VRAM for GPU inference

**Formula for fit:**
```
GPU available?
  ├─ VRAM >= min_vram_gb? → GPU path
  │   ├─ VRAM >= min_vram_gb * 1.5? → PERFECT
  │   └─ else → GOOD
  │
  └─ CPU-only path
      ├─ RAM >= recommended_ram_gb? → PERFECT
      ├─ RAM >= min_ram_gb? → GOOD
      ├─ RAM >= min_ram_gb * 0.8? → MARGINAL
      ├─ RAM >= min_ram_gb * 0.5? → TOOTIGHT
      └─ else → IMPOSSIBLE
```

### Speed Estimation

Estimated tokens/second (TPS) factors:
- **Model size** — Larger models = slower inference
- **Quantization** — Q4_K_M (default) = balanced quality/speed
- **Hardware** — GPU > CPU offload > CPU-only
- **CPU cores** — More cores = faster CPU inference

**Rough multipliers:**
- GPU inference: ~5-10x faster than CPU
- CPU offload: ~2x faster than pure CPU

## Integration with Sentinel Workflows

### Deployment Decision Tree

```
User requests: Deploy model X
  ↓
Sentinel calls: sentinel-llmfit analyze [hardware]
  ↓
Results returned: Model X fit = "good" on GPU
  ↓
Sentinel decides: Provision GPU, allocate 8GB VRAM
  ↓
Infrastructure updated: Model runs at 45 tps
```

### Resource Planning

```
Scenario: "Support 10 concurrent users"
  ↓
Sentinel calculates: 10 users × 45 tps = 450 tps capacity needed
  ↓
Check fit: Current hardware → 45 tps per model
  ↓
Decision: Need 10 GPU instances OR larger GPU
```

### Cost-Benefit Analysis

```
Model options: Mistral-7B vs Llama-2-13B
  ↓
Analyze fit on 16GB machine:
  - Mistral-7B: Good fit, 30 tps
  - Llama-2-13B: Marginal fit, 15 tps
  ↓
Decision: Mistral-7B: better speed, better fit
```

## Database Schema

Each model includes:

```json
{
  "name": "mistral-7b",
  "provider": "mistralai",
  "parameter_count": "7B",
  "parameters_raw": 7000000000,
  "min_ram_gb": 8,
  "recommended_ram_gb": 16,
  "min_vram_gb": 4,
  "quantization": "Q4_K_M",
  "context_length": 32000,
  "use_case": "Chat, instruction following",
  "architecture": "mistral",
  "hf_downloads": 1000000,
  "hf_likes": 5000,
  "release_date": "2023-12-15"
}
```

## Notes

- All estimates are conservative (account for overhead)
- Actual TPS varies by quantization, CPU model, batch size
- GPU inference assumes CUDA/ROCm support
- CPU offloading only works with sufficient system RAM
- Apple Silicon (unified memory) treated as GPU path

## See Also

- **build-your-own-x** skill: Learn how LLMs work internally
- **Codex** agent: Code review for model integration
- **Lens** agent: Performance profiling after deployment

