#!/usr/bin/env julia
"""
    agent-router-spawner.jl

Phase 3B: Agent Router Integration with Spawner

Modifies agent selection logic to use neural network predictions
alongside Q-learning, with fallback to Q-learning for low-confidence
predictions.

Usage:
    julia agent-router-spawner.jl --task "code review" --candidates "Codex,QA,Veritas"

Output:
    Selected agent based on NN prediction or Q-learning fallback
"""

using JSON
using Statistics
using Dates

# ============================================================================
# Model Loading & Inference
# ============================================================================

struct AgentRouterModel
    layer1_W::Matrix{Float32}
    layer1_b::Vector{Float32}
    layer2_W::Matrix{Float32}
    layer2_b::Vector{Float32}
    layer3_W::Matrix{Float32}
    layer3_b::Vector{Float32}
    agent_map::Dict{String, String}
end

function load_model(path::String)::AgentRouterModel
    data = JSON.parsefile(path)
    
    vec_to_mat(vec::Vector) = hcat([Float32.(v) for v in vec]...)
    
    AgentRouterModel(
        vec_to_mat(data["weights"]["layer1_W"]),
        Float32.(data["weights"]["layer1_b"]),
        vec_to_mat(data["weights"]["layer2_W"]),
        Float32.(data["weights"]["layer2_b"]),
        vec_to_mat(data["weights"]["layer3_W"]),
        Float32.(data["weights"]["layer3_b"]),
        data["agent_map"]
    )
end

function relu(x::Vector{Float32})::Vector{Float32}
    max.(x, 0.0f0)
end

function softmax(x::Vector{Float32})::Vector{Float32}
    max_x = maximum(x)
    exp_x = exp.(x .- max_x)
    exp_x ./ sum(exp_x)
end

function featurize_task(task::String, feature_dim::Int)::Vector{Float32}
    """Convert task to 6-dim features (matching training vocab)."""
    features = zeros(Float32, feature_dim)
    
    vocab = Dict(
        "code" => 0,
        "research" => 1,
        "security" => 2,
        "test" => 3,
        "docs" => 4,
        "review" => 5,
    )
    
    # Simple tokenization
    words = lowercase(task) |> 
        s -> split(s, r"[^a-z0-9_]+") |>
        words -> filter(w -> length(w) > 0, words)
    
    for word in words
        if haskey(vocab, word)
            idx = vocab[word] + 1
            if idx <= feature_dim
                features[idx] += 1.0f0
            end
        end
    end
    
    # L2 normalize
    norm = sqrt(sum(features .^ 2))
    if norm > 0
        features ./= norm
    end
    
    return features
end

function infer(model::AgentRouterModel, task::String)::Tuple{String, Float32, Vector}
    """Run inference on task, return best agent + confidence + scores."""
    
    features = featurize_task(task, size(model.layer1_W, 1))
    
    # Forward pass
    h1 = model.layer1_W' * features .+ model.layer1_b
    h1 = relu(h1)
    
    h2 = model.layer2_W' * h1 .+ model.layer2_b
    h2 = relu(h2)
    
    logits = model.layer3_W' * h2 .+ model.layer3_b
    probs = softmax(logits)
    
    # Best agent
    best_idx = argmax(probs) - 1
    best_agent = get(model.agent_map, string(best_idx), "Unknown")
    confidence = probs[best_idx + 1]
    
    # All scores
    scores = [(get(model.agent_map, string(i-1), "Agent$i"), probs[i]) 
              for i in 1:length(probs)]
    
    return best_agent, Float32(confidence), scores
end

# ============================================================================
# Q-Learning Fallback
# ============================================================================

function get_qlearning_scores(task::String, candidates::Vector{String})::Dict{String, Float32}
    """
    Stub: Load Q-values from RL state file.
    For now, returns random scores (would integrate with actual Q-learning).
    """
    
    # In production, load from data/rl/rl-agent-selection.json
    scores = Dict{String, Float32}()
    
    for agent in candidates
        # Stub: default Q-value
        scores[agent] = 0.5f0
    end
    
    return scores
end

# ============================================================================
# Agent Selection Logic
# ============================================================================

function select_agent(
    task::String,
    candidates::Vector{String};
    model::Union{AgentRouterModel, Nothing} = nothing,
    confidence_threshold::Float32 = 0.6f0,
)::Tuple{String, String, Float32}
    """
    Select best agent using hybrid approach:
    1. Try NN prediction if loaded
    2. If confidence > threshold, use NN prediction
    3. Otherwise, fall back to Q-learning
    
    Returns: (selected_agent, method, confidence)
    """
    
    selected_agent = "Unknown"
    method = "fallback"
    confidence = 0.0f0
    
    # Try NN first
    if model !== nothing
        nn_agent, nn_confidence, nn_scores = infer(model, task)
        
        if nn_confidence >= confidence_threshold
            selected_agent = nn_agent
            method = "neural_network"
            confidence = nn_confidence
            
            println("✓ NN Prediction (confidence: $(round(confidence, digits=2)))")
            println("  Scores: $(nn_scores[1:min(3, length(nn_scores))])")
            
            return selected_agent, method, confidence
        else
            println("⚠ NN confidence low ($(round(nn_confidence, digits=2))), falling back to Q-learning")
        end
    end
    
    # Fall back to Q-learning
    println("→ Using Q-learning selection")
    q_scores = get_qlearning_scores(task, candidates)
    
    best_score = 0.0f0
    for candidate in candidates
        score = get(q_scores, candidate, 0.0f0)
        if score > best_score
            best_score = score
            selected_agent = candidate
        end
    end
    
    method = "qlearning"
    confidence = best_score
    
    println("✓ Q-Learning Selection (agent: $selected_agent, q-value: $(round(confidence, digits=2)))")
    
    return selected_agent, method, confidence
end

# ============================================================================
# Logging
# ============================================================================

function log_prediction(task::String, agent::String, method::String, confidence::Float32)
    """Log prediction to audit trail."""
    
    log_file = "data/rl/agent-router-predictions.jsonl"
    
    record = Dict(
        :timestamp => now(),
        :task => task,
        :agent => agent,
        :method => method,
        :confidence => confidence,
    )
    
    # Append to JSONL log
    open(log_file, "a") do f
        write(f, JSON.json(record) * "\n")
    end
    
    println("✓ Logged to $log_file")
end

# ============================================================================
# Main: CLI Interface
# ============================================================================

function main()
    # Parse command line args
    task = ""
    candidates_str = "Codex,Scout,Cipher,Chronicle,QA,Veritas"
    
    for (i, arg) in enumerate(ARGS)
        if arg == "--task" && i < length(ARGS)
            task = ARGS[i+1]
        elseif arg == "--candidates" && i < length(ARGS)
            candidates_str = ARGS[i+1]
        end
    end
    
    if isempty(task)
        println("Usage: julia agent-router-spawner.jl --task \"<task>\" --candidates \"<agent1>,<agent2>,...\"")
        println("\nExample:")
        println("  julia agent-router-spawner.jl --task \"code review\" --candidates \"Codex,QA,Veritas\"")
        return
    end
    
    candidates = String.(split(candidates_str, ","))
    
    println("\n🧠 Agent Router (Phase 3B)")
    println("========================")
    println("Task: $task")
    println("Candidates: $(join(candidates, ", "))")
    println()
    
    # Load model
    model_path = "data/models/agent-router-model.json"
    model = try
        load_model(model_path)
    catch e
        println("⚠ Could not load model: $e")
        nothing
    end
    
    # Select agent
    selected_agent, method, confidence = select_agent(
        task, 
        candidates;
        model=model,
        confidence_threshold=0.6f0
    )
    
    println("\n=== Result ===")
    println("Selected agent: $selected_agent")
    println("Method: $method")
    println("Confidence: $(round(confidence, digits=3))")
    
    # Log for tracking
    log_prediction(task, selected_agent, method, confidence)
    
    println("\n✅ Decision logged and ready to spawn agent: $selected_agent")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
