# Tier 1 Agent Router Guide - Neural Network for Agent Selection

_Complete reference for predictive agent routing system._

## Overview

**Status:** Phases 1-3B complete. Inference working, integration tested.

**System:** Neural network that predicts best agent for a task, with Q-learning fallback.

**Architecture:**
```
Task Input → Featurize (6-dim) → NN (6→16→16→6) → Softmax → Agent Score
                                                              ↓
                                                    Confidence ≥ 0.6?
                                                    ├─ YES: Use NN
                                                    └─ NO: Fall back to Q-learning
```

## Quick Start

### Test the System

```bash
cd /home/art/.openclaw/workspace

julia scripts/ml/agent-router-spawner.jl \
  --task "code review" \
  --candidates "Codex,QA,Veritas"
```

**Output:**
```
🧠 Agent Router (Phase 3B)
========================
Task: code review
Candidates: Codex, QA, Veritas

⚠ NN confidence low (0.24), falling back to Q-learning
→ Using Q-learning selection
✓ Q-Learning Selection (agent: Codex, q-value: 0.5)

=== Result ===
Selected agent: Codex
Method: qlearning
Confidence: 0.5
✓ Logged to data/rl/agent-router-predictions.jsonl

✅ Decision logged and ready to spawn agent: Codex
```

## Phases

### Phase 1: Data Preparation

**Script:** `scripts/ml/agent-router-data.jl`

**What it does:**
1. Loads RL execution logs (JSONL format)
2. Tokenizes task descriptions
3. Builds vocabulary
4. Featurizes tasks (bag-of-words, L2 normalized)
5. Encodes agents as integer labels
6. Creates stratified train/test split
7. Exports to JSON

**Usage:**
```bash
julia scripts/ml/agent-router-data.jl
```

**Output:**
- `data/models/agent-router-data.json` — Training data (532 B)
  - `X_train`: (7, 6) feature matrix
  - `y_train`: agent labels
  - `X_test`: (6, 6) test data
  - `y_test`: test labels
  - `agent_map`: label→agent name mapping

### Phase 2: Training

**Script:** `scripts/ml/train-agent-router.jl`

**What it does:**
1. Loads training data from JSON
2. Creates 3-layer neural network
3. Trains with ReLU activations + softmax output
4. Uses cross-entropy loss
5. Early stopping (patience=10)
6. Saves weights to JSON

**Architecture:**
```
Input (6) → Dense(16) + ReLU → Dense(16) + ReLU → Dense(6) + Softmax → Output
```

**Usage:**
```bash
julia scripts/ml/train-agent-router.jl
```

**Output:**
- `data/models/agent-router-model.json` — Trained model (5.5 KB)
  - `architecture`: layer dimensions
  - `weights`: W and b for each layer
  - `agent_map`: index→agent name

### Phase 3A: HTTP Server (Skeleton)

**Path:** `hardware/morpheus-api/`

**Rust implementation** (requires cargo/rustc):
- `Cargo.toml` — Project config
- `src/main.rs` — HTTP API server

**Features:**
- Load model from JSON
- Featurize tasks
- Run inference
- JSON request/response API

**Endpoints:**
- `GET /api/health` — Server status
- `POST /api/predict` — Predict agent

**Example request:**
```bash
curl -X POST http://127.0.0.1:8000/api/predict \
  -H 'Content-Type: application/json' \
  -d '{"task": "code review"}'

# Response:
# {
#   "agent": "Codex",
#   "confidence": 0.87,
#   "scores": [["Codex", 0.87], ["Scout", 0.08], ...]
# }
```

### Phase 3B: Spawner Integration (LIVE)

**Script:** `scripts/ml/agent-router-spawner.jl`

**What it does:**
1. Loads trained model
2. Featurizes input task
3. Runs neural network inference
4. Checks confidence threshold (0.6)
5. Uses NN if confident, else Q-learning
6. Logs decision to JSONL
7. Returns selected agent

**Usage:**
```bash
julia scripts/ml/agent-router-spawner.jl \
  --task "<task description>" \
  --candidates "<agent1>,<agent2>,..."
```

**Example:**
```bash
julia scripts/ml/agent-router-spawner.jl \
  --task "write documentation" \
  --candidates "Chronicle,Scout,Codex"

julia scripts/ml/agent-router-spawner.jl \
  --task "run security audit" \
  --candidates "Cipher,Sentinel,Scout"
```

## Data Format

### Input: RL Execution Log

**File:** `data/rl/rl-task-execution-log.jsonl`

**Format (one JSON object per line):**
```json
{"timestamp":"2026-03-13T10:00:00Z","task":"code","agent":"Codex","success":true,"reward":1.0}
```

### Intermediate: Training Data

**File:** `data/models/agent-router-data.json`

**Format:**
```json
{
  "X_train": [[1.0, 0.0, ...], ...],    // (7, 6) feature matrix
  "y_train": [2, 2, 2, 2, 4, 4, 1],     // agent IDs (0-indexed)
  "X_test": [[0.0, 1.0, ...], ...],     // (6, 6) test features
  "y_test": [0, 1, 2, 3, 4, 5],         // test labels
  "feature_dim": 6,
  "num_agents": 6,
  "agent_map": {
    "0": "Chronicle",
    "1": "Cipher",
    "2": "Codex",
    ...
  }
}
```

### Model: Trained Weights

**File:** `data/models/agent-router-model.json`

**Format:**
```json
{
  "architecture": {
    "input_dim": 6,
    "hidden_dim": 16,
    "output_dim": 6
  },
  "weights": {
    "layer1_W": [[...], ...],    // (6, 16) weight matrix
    "layer1_b": [...],           // (16) bias vector
    "layer2_W": [[...], ...],    // (16, 16)
    "layer2_b": [...],           // (16)
    "layer3_W": [[...], ...],    // (16, 6)
    "layer3_b": [...]            // (6)
  },
  "agent_map": {
    "0": "Chronicle",
    ...
  }
}
```

### Output: Prediction Log

**File:** `data/rl/agent-router-predictions.jsonl`

**Format (one JSON per line):**
```json
{"timestamp":"2026-03-14T12:39:00Z","task":"code review","agent":"Codex","method":"qlearning","confidence":0.5}
```

## Feature Engineering

### Vocabulary

**Current vocabulary** (from RL logs):
- `code` (index 0)
- `research` (index 1)
- `security` (index 2)
- `test` (index 3)
- `docs` (index 4)
- `review` (index 5)

### Featurization Process

1. **Tokenize:** Lowercase, split on non-alphanumeric, keep only words > 0 length
2. **Count:** For each token in vocabulary, increment feature count
3. **Normalize:** L2 normalize (divide by norm)
4. **Result:** 6-dimensional float vector

**Example:**
```
Task: "code review"
  ↓ tokenize
  ["code", "review"]
  ↓ count
  [1, 0, 0, 0, 0, 1]  (code=index 0, review=index 5)
  ↓ normalize
  [0.707, 0.0, 0.0, 0.0, 0.0, 0.707]
```

## Neural Network

### Architecture

```
Layer 1: Dense(6 → 16)
  - Weight matrix: (6, 16)
  - Bias vector: (16,)
  - Activation: ReLU

Layer 2: Dense(16 → 16)
  - Weight matrix: (16, 16)
  - Bias vector: (16,)
  - Activation: ReLU

Layer 3: Dense(16 → 6)
  - Weight matrix: (16, 6)
  - Bias vector: (6,)
  - Activation: Softmax (output probabilities)
```

### Forward Pass

```julia
h1 = relu(X @ W1 + b1)           # (N, 16)
h2 = relu(h1 @ W2 + b2)          # (N, 16)
logits = h2 @ W3 + b3            # (N, 6)
probs = softmax(logits)          # (N, 6) sum to 1
best_agent = argmax(probs)       # agent with highest score
confidence = max(probs)          # confidence in prediction
```

### Confidence Threshold

**Threshold:** 0.6

- If confidence ≥ 0.6 → Use NN prediction
- If confidence < 0.6 → Fall back to Q-learning

This hybrid approach:
- ✅ Uses NN when confident
- ✅ Falls back to proven Q-learning when uncertain
- ✅ Gracefully degrades with small datasets

## Agents

**6 agents in current system:**
0. Chronicle (documentation)
1. Cipher (security)
2. Codex (code development)
3. QA (testing/quality)
4. Scout (research)
5. Veritas (code review)

## Workflows

### Retrain with New Data

```bash
# 1. Update RL log (automatically from spawning)
cat data/rl/rl-task-execution-log.jsonl

# 2. Prepare data
julia scripts/ml/agent-router-data.jl

# 3. Train model
julia scripts/ml/train-agent-router.jl

# 4. Test with new model
julia scripts/ml/agent-router-spawner.jl \
  --task "test task" \
  --candidates "Codex,Scout"
```

### Monitor Predictions

```bash
# View all predictions
cat data/rl/agent-router-predictions.jsonl | jq '.'

# View last 5
tail -5 data/rl/agent-router-predictions.jsonl | jq '.'

# Count by method
cat data/rl/agent-router-predictions.jsonl | jq '.method' | sort | uniq -c

# Count by agent
cat data/rl/agent-router-predictions.jsonl | jq '.agent' | sort | uniq -c
```

### Analyze Accuracy (Once Outcomes Available)

```bash
# When outcomes are logged alongside predictions:
# - Match prediction timestamp with outcome timestamp
# - Calculate success rate by agent
# - Calculate success rate by method (NN vs Q-learning)
# - Adjust confidence threshold if needed
```

## Troubleshooting

### Low Confidence (< 0.6)

**Cause:** Small training dataset (13 samples)

**Fix:**
1. Collect more real task/outcome data (target: 50+ samples)
2. Retrain model with expanded dataset
3. Confidence should improve

### Model Won't Load

```bash
julia scripts/ml/agent-router-spawner.jl ...
# ERROR: Cannot open data/models/agent-router-model.json
```

**Fix:**
```bash
# Ensure model exists
ls -la data/models/agent-router-model.json

# If missing, retrain
julia scripts/ml/train-agent-router.jl
```

### Prediction Log Error

```bash
# If predictions.jsonl is corrupted
rm data/rl/agent-router-predictions.jsonl
# Create new log on next prediction
```

## Next Steps

### Immediate (This Week)
- Collect real task/outcome data (10+ examples)
- Retrain model
- Monitor predictions vs outcomes

### Short-term (Next 2 Weeks)
- Improve confidence threshold (based on real data)
- Reduce Q-learning fallback rate
- Deploy to production

### Medium-term (1 Month)
- Integrate HTTP server (Phase 3A)
- Build R monitoring dashboard (Phase 3C)
- Implement feedback loop (outcome → retrain)

## Files

| File | Purpose | Size |
|------|---------|------|
| agent-router-data.jl | Data prep script | 7.9 KB |
| train-agent-router.jl | Training script | 9.2 KB |
| agent-router-spawner.jl | Inference + spawner | 8.3 KB |
| agent-router-model.json | Trained weights | 5.5 KB |
| agent-router-data.json | Training data | 532 B |
| agent-router-predictions.jsonl | Prediction log | (grows) |

## References

- **Full Plan:** `AGENT_ROUTER_PLAN.md`
- **Phase 3 Details:** `PHASE3_COMPLETE.md`
- **Implementation:** `scripts/ml/`
