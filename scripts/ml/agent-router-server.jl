#!/usr/bin/env julia
"""
    agent-router-server.jl

Morpheus Agent Router HTTP Inference Server (Julia)

Runs inference on trained neural network model and serves predictions via HTTP.

Usage:
    julia agent-router-server.jl

Endpoints:
    GET  /api/health  — Server status
    POST /api/predict — Predict agent for task

Example request:
    curl -X POST http://127.0.0.1:8000/api/predict \\
      -H 'Content-Type: application/json' \\
      -d '{\"task\": \"code review\"}'

Response:
    {
      "agent": "Codex",
      "confidence": 0.87,
      "scores": [["Codex", 0.87], ["Scout", 0.08], ...]
    }
"""

using HTTP
using JSON
using Statistics

# ============================================================================
# Model Loading
# ============================================================================

mutable struct AgentRouterModel
    layer1_W::Matrix{Float32}
    layer1_b::Vector{Float32}
    layer2_W::Matrix{Float32}
    layer2_b::Vector{Float32}
    layer3_W::Matrix{Float32}
    layer3_b::Vector{Float32}
    agent_map::Dict{String, String}
end

function load_model(path::String)::AgentRouterModel
    """Load trained model from JSON."""
    println("Loading model from $path...")
    
    data = JSON.parsefile(path)
    
    # Helper to convert nested arrays to matrices
    vec_to_mat(vec::Vector) = hcat([Float32.(v) for v in vec]...)
    
    model = AgentRouterModel(
        vec_to_mat(data["weights"]["layer1_W"]),  # input_dim × hidden_dim
        Float32.(data["weights"]["layer1_b"]),
        vec_to_mat(data["weights"]["layer2_W"]),  # hidden_dim × hidden_dim
        Float32.(data["weights"]["layer2_b"]),
        vec_to_mat(data["weights"]["layer3_W"]),  # hidden_dim × output_dim
        Float32.(data["weights"]["layer3_b"]),
        data["agent_map"]
    )
    
    println("✓ Model loaded successfully")
    println("  Input: $(size(model.layer1_W, 1)}")
    println("  Hidden: $(size(model.layer1_W, 2))")
    println("  Output: $(size(model.layer3_W, 2))")
    println("  Agents: $(length(model.agent_map))")
    
    return model
end

# ============================================================================
# Feature Engineering
# ============================================================================

function simple_tokenize(text::String)::Vector{String}
    """Tokenize text (same as training)."""
    words = String[]
    current = ""
    
    for c in lowercase(text)
        if ('a' <= c <= 'z') || ('0' <= c <= '9') || c == '_'
            current *= c
        else
            if !isempty(current)
                push!(words, current)
                current = ""
            end
        end
    end
    if !isempty(current)
        push!(words, current)
    end
    
    return filter(w -> length(w) > 0, words)
end

const VOCAB = Dict(
    "code" => 0,
    "research" => 1,
    "security" => 2,
    "test" => 3,
    "docs" => 4,
    "review" => 5,
)

function featurize_task(task::String, feature_dim::Int)::Vector{Float32}
    """Convert task to features (bag-of-words)."""
    features = zeros(Float32, feature_dim)
    
    for word in simple_tokenize(task)
        if haskey(VOCAB, word)
            idx = VOCAB[word] + 1  # 1-indexed
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

# ============================================================================
# Neural Network Inference
# ============================================================================

function relu(x::Vector{Float32})::Vector{Float32}
    return max.(x, 0.0f0)
end

function softmax(x::Vector{Float32})::Vector{Float32}
    """Softmax with numerical stability."""
    max_x = maximum(x)
    exp_x = exp.(x .- max_x)
    return exp_x ./ sum(exp_x)
end

function predict(model::AgentRouterModel, features::Vector{Float32})::Tuple{String, Float32, Vector}
    """Run inference on input features."""
    
    # Forward pass
    h1 = model.layer1_W' * features .+ model.layer1_b
    h1 = relu(h1)
    
    h2 = model.layer2_W' * h1 .+ model.layer2_b
    h2 = relu(h2)
    
    logits = model.layer3_W' * h2 .+ model.layer3_b
    probs = softmax(logits)
    
    # Find best agent
    best_idx = argmax(probs) - 1  # 0-indexed
    best_agent = get(model.agent_map, string(best_idx), "Unknown")
    confidence = probs[best_idx + 1]
    
    # Sorted scores
    scores = [(get(model.agent_map, string(i-1), "Agent$i"), Float32(probs[i])) 
              for i in 1:length(probs)]
    scores = sort(scores, by=x->-x[2])
    
    return best_agent, confidence, scores
end

# ============================================================================
# HTTP Server
# ============================================================================

function handle_health(model::AgentRouterModel)::String
    """Health check endpoint."""
    response = Dict(
        :status => "ok",
        :model_loaded => true,
        :input_dim => size(model.layer1_W, 1),
        :output_dim => size(model.layer3_W, 2),
        :agents => length(model.agent_map),
    )
    return JSON.json(response)
end

function handle_predict(model::AgentRouterModel, body::String)::String
    """Prediction endpoint."""
    try
        request = JSON.parse(body)
        task = get(request, "task", "")
        
        if isempty(task)
            error("Missing 'task' field")
        end
        
        # Featurize
        features = featurize_task(task, size(model.layer1_W, 1))
        
        # Predict
        agent, confidence, scores = predict(model, features)
        
        # Format response
        response = Dict(
            :agent => agent,
            :confidence => confidence,
            :scores => [[agent, score] for (agent, score) in scores],
            :task => task,
        )
        
        return JSON.json(response)
    catch e
        error_response = Dict(
            :error => string(e),
            :status => "error",
        )
        return JSON.json(error_response)
    end
end

function router(model::AgentRouterModel, req::HTTP.Request)::HTTP.Response
    """Route HTTP requests to handlers."""
    path = req.target
    method = req.method
    
    # Health check
    if path == "/api/health" && method == "GET"
        body = handle_health(model)
        return HTTP.Response(200, ["Content-Type" => "application/json"]; body=body)
    end
    
    # Prediction
    if path == "/api/predict" && method == "POST"
        try
            body_str = String(req.body)
            response_body = handle_predict(model, body_str)
            return HTTP.Response(200, ["Content-Type" => "application/json"]; body=response_body)
        catch e
            error_response = JSON.json(Dict(:error => string(e)))
            return HTTP.Response(400, ["Content-Type" => "application/json"]; body=error_response)
        end
    end
    
    # 404
    not_found = JSON.json(Dict(:error => "Not found", :path => path))
    return HTTP.Response(404, ["Content-Type" => "application/json"]; body=not_found)
end

# ============================================================================
# Main
# ============================================================================

function main()
    model_path = "data/models/agent-router-model.json"
    
    # Load model
    model = load_model(model_path)
    
    # Start server
    println("\n🚀 Starting Morpheus Agent Router API")
    println("📍 Listening on http://127.0.0.1:8000")
    println("📊 Endpoints:")
    println("   GET  /api/health")
    println("   POST /api/predict")
    println("\n📝 Example request:")
    println("   curl -X POST http://127.0.0.1:8000/api/predict \\")
    println("     -H 'Content-Type: application/json' \\")
    println("     -d '{\"task\": \"code review\"}'")
    println("\n✓ Ready. Press Ctrl+C to stop.\n")
    
    # Create request handler
    handler = req -> router(model, req)
    
    # Start HTTP server
    HTTP.serve(handler, "127.0.0.1", 8000)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
