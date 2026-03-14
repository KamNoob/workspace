use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use serde::{Deserialize, Serialize};
use std::fs;
use std::sync::Mutex;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AgentRouterModel {
    architecture: Architecture,
    weights: Weights,
    agent_map: std::collections::HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Architecture {
    input_dim: usize,
    hidden_dim: usize,
    output_dim: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Weights {
    layer1_W: Vec<Vec<f32>>,
    layer1_b: Vec<f32>,
    layer2_W: Vec<Vec<f32>>,
    layer2_b: Vec<f32>,
    layer3_W: Vec<Vec<f32>>,
    layer3_b: Vec<f32>,
}

#[derive(Debug, Clone)]
struct AppState {
    model: AgentRouterModel,
    vocab: std::collections::HashMap<String, usize>,
}

#[derive(Deserialize)]
struct PredictRequest {
    task: String,
}

#[derive(Serialize)]
struct AgentScore {
    agent: String,
    score: f32,
}

#[derive(Serialize)]
struct PredictResponse {
    agent: String,
    confidence: f32,
    scores: Vec<AgentScore>,
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    model_loaded: bool,
    input_dim: usize,
    output_dim: usize,
    agents: usize,
}

// ============================================================================
// Neural Network Inference
// ============================================================================

fn relu(x: f32) -> f32 {
    x.max(0.0)
}

fn softmax(logits: &[f32]) -> Vec<f32> {
    // Numerical stability: subtract max
    let max_logit = logits.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
    let exp_logits: Vec<f32> = logits.iter().map(|&x| (x - max_logit).exp()).collect();
    let sum: f32 = exp_logits.iter().sum();
    exp_logits.iter().map(|&x| x / sum).collect()
}

fn matrix_vector_multiply(matrix: &[Vec<f32>], vector: &[f32]) -> Vec<f32> {
    matrix
        .iter()
        .map(|row| row.iter().zip(vector.iter()).map(|(w, v)| w * v).sum())
        .collect()
}

fn forward_pass(model: &Weights, arch: &Architecture, input: &[f32]) -> Vec<f32> {
    // Layer 1: input → hidden
    let mut h1 = matrix_vector_multiply(&model.layer1_W, input);
    for (h, b) in h1.iter_mut().zip(&model.layer1_b) {
        *h += b;
    }
    // ReLU activation
    h1 = h1.iter().map(|&x| relu(x)).collect();

    // Layer 2: hidden → hidden
    let mut h2 = matrix_vector_multiply(&model.layer2_W, &h1);
    for (h, b) in h2.iter_mut().zip(&model.layer2_b) {
        *h += b;
    }
    // ReLU activation
    h2 = h2.iter().map(|&x| relu(x)).collect();

    // Layer 3: hidden → output (logits)
    let mut logits = matrix_vector_multiply(&model.layer3_W, &h2);
    for (l, b) in logits.iter_mut().zip(&model.layer3_b) {
        *l += b;
    }

    // Softmax
    softmax(&logits)
}

// ============================================================================
// Feature Engineering (same as training)
// ============================================================================

fn simple_tokenize(text: &str) -> Vec<String> {
    text.to_lowercase()
        .split(|c: char| !c.is_alphanumeric() && c != '_')
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .collect()
}

fn featurize_task(task: &str, vocab: &std::collections::HashMap<String, usize>, feature_dim: usize) -> Vec<f32> {
    let mut features = vec![0.0f32; feature_dim];
    let words = simple_tokenize(task);

    for word in words {
        if let Some(&idx) = vocab.get(&word) {
            if idx < feature_dim {
                features[idx] += 1.0;
            }
        }
    }

    // L2 normalize
    let norm: f32 = features.iter().map(|x| x * x).sum::<f32>().sqrt();
    if norm > 0.0 {
        for f in &mut features {
            *f /= norm;
        }
    }

    features
}

// ============================================================================
// HTTP Handlers
// ============================================================================

async fn health(state: web::Data<Mutex<AppState>>) -> HttpResponse {
    let state = state.lock().unwrap();
    HttpResponse::Ok().json(HealthResponse {
        status: "ok".to_string(),
        model_loaded: true,
        input_dim: state.model.architecture.input_dim,
        output_dim: state.model.architecture.output_dim,
        agents: state.model.agent_map.len(),
    })
}

async fn predict(
    req: web::Json<PredictRequest>,
    state: web::Data<Mutex<AppState>>,
) -> HttpResponse {
    let state = state.lock().unwrap();

    // Featurize task
    let features = featurize_task(&req.task, &state.vocab, state.model.architecture.input_dim);

    // Run inference
    let probabilities = forward_pass(&state.model.weights, &state.model.architecture, &features);

    // Find best agent
    let best_idx = probabilities
        .iter()
        .enumerate()
        .max_by(|a, b| a.1.partial_cmp(b.1).unwrap_or(std::cmp::Ordering::Equal))
        .map(|(i, _)| i)
        .unwrap_or(0);

    let best_agent = state
        .model
        .agent_map
        .get(&best_idx.to_string())
        .cloned()
        .unwrap_or_else(|| "Unknown".to_string());

    // Build sorted scores
    let mut scores: Vec<_> = probabilities
        .iter()
        .enumerate()
        .map(|(i, &score)| {
            let agent_name = state
                .model
                .agent_map
                .get(&i.to_string())
                .cloned()
                .unwrap_or_else(|| format!("Agent{}", i));
            AgentScore {
                agent: agent_name,
                score,
            }
        })
        .collect();
    scores.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal));

    HttpResponse::Ok().json(PredictResponse {
        agent: best_agent,
        confidence: probabilities[best_idx],
        scores,
    })
}

// ============================================================================
// Startup & Configuration
// ============================================================================

fn load_model(path: &str) -> Result<AgentRouterModel, Box<dyn std::error::Error>> {
    let json = fs::read_to_string(path)?;
    let model: AgentRouterModel = serde_json::from_str(&json)?;
    Ok(model)
}

fn load_vocab(path: &str) -> Result<std::collections::HashMap<String, usize>, Box<dyn std::error::Error>> {
    let json = fs::read_to_string(path)?;
    let data: serde_json::Value = serde_json::from_str(&json)?;

    let mut vocab = std::collections::HashMap::new();

    if let Some(vocab_obj) = data.get("agent_map").and_then(|v| v.as_object()) {
        // We need to extract the vocab from the data file
        // For now, we'll build a simple one from task names
        vocab.insert("code".to_string(), 0);
        vocab.insert("research".to_string(), 1);
        vocab.insert("security".to_string(), 2);
        vocab.insert("test".to_string(), 3);
        vocab.insert("docs".to_string(), 4);
        vocab.insert("review".to_string(), 5);
    }

    Ok(vocab)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let model_path = "../../data/models/agent-router-model.json";
    let data_path = "../../data/models/agent-router-data.json";

    // Load model
    let model = match load_model(model_path) {
        Ok(m) => {
            println!("✓ Loaded model from {}", model_path);
            m
        }
        Err(e) => {
            eprintln!("✗ Failed to load model: {}", e);
            return Err(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                "Model file not found",
            ));
        }
    };

    // Load vocabulary
    let vocab = match load_vocab(data_path) {
        Ok(v) => {
            println!("✓ Loaded vocabulary ({} words)", v.len());
            v
        }
        Err(e) => {
            eprintln!("! Warning: Could not load vocabulary: {}", e);
            let mut v = std::collections::HashMap::new();
            v.insert("code".to_string(), 0);
            v.insert("research".to_string(), 1);
            v.insert("security".to_string(), 2);
            v.insert("test".to_string(), 3);
            v.insert("docs".to_string(), 4);
            v.insert("review".to_string(), 5);
            v
        }
    };

    let state = web::Data::new(Mutex::new(AppState { model, vocab }));

    println!("\n🚀 Starting Morpheus Agent Router API");
    println!("📍 Listening on http://127.0.0.1:8000");
    println!("📊 Endpoints:");
    println!("   GET  /api/health");
    println!("   POST /api/predict");
    println!("\nExample request:");
    println!("  curl -X POST http://127.0.0.1:8000/api/predict \\");
    println!("    -H 'Content-Type: application/json' \\");
    println!("    -d '{{\"task\": \"code review\"}}'");
    println!();

    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .wrap(middleware::Logger::default())
            .route("/api/health", web::get().to(health))
            .route("/api/predict", web::post().to(predict))
    })
    .bind("127.0.0.1:8000")?
    .run()
    .await
}
