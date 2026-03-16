# Predictive Agent Router - Implementation Plan

_Neural network for intelligent agent selection. Expected ROI: 20-30% improvement over Q-learning._

---

## Overview

**Goal:** Replace Q-learning with neural network predictions for agent selection.

**Why it matters:**
- Q-learning is heuristic (all scores start at 0.5)
- Neural net learns feature interactions (task type + context → best agent)
- Better early predictions = faster convergence
- Explainable (can see what task features matter)

**Timeline:** 3 days to first production model

---

## Architecture

```
Task Input (string)
    ↓
Feature Engineering (tokenize, n-grams, embeddings)
    ↓
PyTorch Neural Net (3-layer MLP)
    ↓
Agent Scores [0.0-1.0] for each agent
    ↓
Rust Inference Server (localhost:8000)
    ↓
Julia spawner-matrix.jl (query before spawning)
    ↓
Execute & Log Outcome
    ↓
Update RL Q-values + retrain NN monthly
```

---

## Phase 1: Data Preparation (Day 1 morning)

### Collect Training Data

**Source:** Your RL logs + new synthetic data

```bash
# Location: data/rl/rl-task-execution-log.jsonl
# Each line: task, agent, outcome, tokens, cost
```

**What we need:**
1. Task descriptions (strings)
2. Agent name (Codex, Cipher, Scout, etc.)
3. Outcome (success/failure, 0-1 score)
4. Context (optional): task complexity, token estimate

**Example data structure:**
```json
{
  "task": "code_review",
  "complexity": "medium",
  "context": "python flask rest api",
  "agent": "Veritas",
  "outcome": 1.0,
  "tokens_used": 12500,
  "timestamp": "2026-03-14T10:00:00Z"
}
```

### Python Script: Data Loader

Create `scripts/ml/agent-router-data.py`:
```python
import json
import pandas as pd
from sklearn.preprocessing import LabelEncoder

# Load RL logs
def load_training_data(path="data/rl/rl-task-execution-log.jsonl"):
    data = []
    with open(path) as f:
        for line in f:
            data.append(json.loads(line))
    
    df = pd.DataFrame(data)
    
    # Encode agents as numbers
    agent_encoder = LabelEncoder()
    df['agent_id'] = agent_encoder.fit_transform(df['agent'])
    
    return df, agent_encoder

# Feature engineering
def featurize_tasks(df):
    # TF-IDF on task descriptions
    from sklearn.feature_extraction.text import TfidfVectorizer
    
    vectorizer = TfidfVectorizer(max_features=100)
    tfidf = vectorizer.fit_transform(df['task'])
    
    return tfidf, vectorizer
```

**Outcome:** 
- Train/test split (80/20)
- TF-IDF features (100-dim)
- Agent labels (0-9 for each agent)

---

## Phase 2: PyTorch Model (Day 1 afternoon)

### Neural Network Architecture

**Model: 3-layer MLP**
```python
class AgentRouterNN(nn.Module):
    def __init__(self, input_dim=100, hidden=64, num_agents=9):
        super().__init__()
        self.fc1 = nn.Linear(input_dim, hidden)
        self.fc2 = nn.Linear(hidden, hidden)
        self.fc3 = nn.Linear(hidden, num_agents)
        self.relu = nn.ReLU()
        self.dropout = nn.Dropout(0.2)
    
    def forward(self, x):
        x = self.relu(self.fc1(x))
        x = self.dropout(x)
        x = self.relu(self.fc2(x))
        x = self.dropout(x)
        x = self.fc3(x)  # Logits (one per agent)
        return x
```

**Training:**
- Loss: CrossEntropyLoss (multi-class classification)
- Optimizer: Adam (lr=0.001)
- Epochs: 100 (with early stopping)
- Batch size: 32

**Output:** 
- Trained model saved as `models/agent-router.pt`
- Metrics: accuracy, precision per agent, confusion matrix

### Python Script: Training

Create `scripts/ml/train-agent-router.py`:
```python
import torch
import torch.nn as nn
from torch.utils.data import TensorDataset, DataLoader
import pytorch_lightning as pl

class AgentRouterTrainer(pl.LightningModule):
    def __init__(self, input_dim=100, hidden=64, num_agents=9):
        # Model definition
        # Training loop
        # Validation loop
    
    def configure_optimizers(self):
        return torch.optim.Adam(self.parameters(), lr=0.001)

# Usage:
# trainer = pl.Trainer(max_epochs=100)
# trainer.fit(model, train_loader, val_loader)
# torch.save(model.state_dict(), "models/agent-router.pt")
```

**Outcome:**
- Trained model (~10MB)
- Training curves (loss, accuracy)
- Per-agent precision/recall

---

## Phase 3: Rust Inference API (Day 2)

### Rust Server: High-Performance Inference

Create `hardware/morpheus-api/src/main.rs`:

```rust
use actix_web::{web, App, HttpServer, HttpResponse};
use ort::Session;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
struct PredictRequest {
    task: String,
    context: Option<String>,
}

#[derive(Serialize)]
struct PredictResponse {
    agent: String,
    confidence: f32,
    scores: Vec<(String, f32)>,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load ONNX model (exported from PyTorch)
    let session = Session::builder()?
        .commit_from_file("models/agent-router.onnx")?;
    
    HttpServer::new(move || {
        App::new()
            .route("/api/predict", web::post().to(predict))
    })
    .bind("127.0.0.1:8000")?
    .run()
    .await
}

async fn predict(req: web::Json<PredictRequest>) -> HttpResponse {
    // 1. Featurize task (TF-IDF)
    // 2. Run inference on ONNX model
    // 3. Return top agent + scores
    
    HttpResponse::Ok().json(PredictResponse {
        agent: "Codex".to_string(),
        confidence: 0.87,
        scores: vec![...],
    })
}
```

**Build steps:**
```bash
# 1. Export PyTorch to ONNX
python3 scripts/ml/export-agent-router.py

# 2. Build Rust server
cd hardware/morpheus-api
cargo build --release

# 3. Run server
./target/release/morpheus-api
# Listening on http://127.0.0.1:8000
```

**Outcome:**
- API server running
- <10ms inference latency
- JSON request/response

---

## Phase 4: Julia Integration (Day 2 afternoon)

### Modify spawner-matrix.jl

**Add prediction step before spawning:**

```julia
function spawn_with_router(task::String, candidates::Vector{String})
    # 1. Query agent router
    prediction = query_agent_router(task)
    
    # 2. Filter candidates based on prediction
    scored = [(agent, prediction.scores[agent]) for agent in candidates]
    
    # 3. Sort by score
    best_agents = sort(scored, by=x->x[2], rev=true)
    
    # 4. Spawn top agent (or use RL if confidence < 0.6)
    if prediction.confidence > 0.6
        return spawn(best_agents[1][1], task)
    else
        # Fall back to Q-learning
        return spawn_with_rl(task, candidates)
    end
end

function query_agent_router(task::String)
    # HTTP POST to localhost:8000
    response = HTTP.post(
        "http://127.0.0.1:8000/api/predict",
        ["Content-Type" => "application/json"],
        JSON.json(Dict("task" => task))
    )
    return JSON.parse(String(response.body))
end
```

**Update spawner-matrix.jl:**
- Replace direct Q-learning with router query
- Fall back to Q-learning if confidence < 0.6
- Log predictions + outcomes for monthly retraining

**Outcome:**
- Spawner uses neural net predictions
- Hybrid approach (NN + RL fallback)
- Data collection for improvement

---

## Phase 5: Monitoring & Iteration (Day 3)

### Metrics Dashboard (R)

Create `scripts/analytics/agent-router-monitor.R`:

```r
# Track NN predictions vs actual outcomes
# Plot:
# - Accuracy over time (is it improving?)
# - Confidence distribution
# - Per-agent success rates
# - Comparison: NN vs Q-learning

ggplot(outcomes) +
  geom_point(aes(x=confidence, y=outcome, color=agent)) +
  facet_wrap(~agent) +
  labs(title="Agent Router: Prediction Confidence vs Outcome")
```

### Monthly Retraining

**Cron job:** Every month, retrain on new data

```julia
# scripts/ml/retrain-agent-router.jl
# 1. Collect last 30 days of predictions + outcomes
# 2. Run Python training script
# 3. Export to ONNX
# 4. Restart Rust server
```

---

## File Structure (End State)

```
/home/art/.openclaw/workspace/
├── scripts/ml/
│   ├── agent-router-data.py          (data loading + featurization)
│   ├── train-agent-router.py         (PyTorch training)
│   ├── export-agent-router.py        (PyTorch → ONNX)
│   ├── retrain-agent-router.jl       (monthly retraining)
│   └── spawner-matrix.jl             (MODIFIED - add router query)
│
├── hardware/morpheus-api/            (Rust inference server)
│   ├── Cargo.toml
│   ├── src/main.rs
│   └── models/agent-router.onnx      (compiled model)
│
├── scripts/analytics/
│   └── agent-router-monitor.R        (performance dashboard)
│
├── models/
│   ├── agent-router.pt               (PyTorch checkpoint)
│   └── agent-router.onnx             (ONNX for Rust)
│
└── data/rl/
    └── agent-router-predictions.jsonl (prediction log)
```

---

## Success Criteria

- [ ] NN trained on historical data (>80% accuracy)
- [ ] Rust API responds in <10ms
- [ ] Julia integration working (spawner queries router)
- [ ] Predictions logged for analysis
- [ ] R dashboard shows improvement vs baseline Q-learning
- [ ] Monthly retraining automated

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Low accuracy on new tasks | Use Q-learning fallback (confidence threshold) |
| Rust server crashes | systemd service with auto-restart |
| Model drift over time | Monthly retraining on recent outcomes |
| Inference latency | Cache predictions + batch requests |

---

## Timeline

| Day | Phase | Deliverable |
|-----|-------|-------------|
| 1 AM | Data prep | Training data ready (CSV/tensors) |
| 1 PM | PyTorch | Trained model + metrics |
| 2 AM | Rust | API server running on localhost:8000 |
| 2 PM | Julia | spawner-matrix.jl queries router |
| 3 | Monitor & Polish | Dashboard + docs + cron job |

---

## Quick Commands (After Setup)

```bash
# Train model
python3 scripts/ml/train-agent-router.py

# Export to ONNX
python3 scripts/ml/export-agent-router.py

# Run Rust API server
cd hardware/morpheus-api && cargo run --release

# Query API (test)
curl -X POST http://127.0.0.1:8000/api/predict \
  -H "Content-Type: application/json" \
  -d '{"task": "code review"}'

# Monitor predictions
Rscript scripts/analytics/agent-router-monitor.R

# Retrain monthly
julia scripts/ml/retrain-agent-router.jl
```

---

_Plan created: 2026-03-14 12:26 GMT_  
_Ready to start Phase 1 (data prep) immediately._
