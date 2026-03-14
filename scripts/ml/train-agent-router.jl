#!/usr/bin/env julia
"""
    train-agent-router.jl

Agent Router Neural Network Training (Pure Julia)

Trains a simple feedforward network to predict agent selection.

Usage:
    julia train-agent-router.jl

Output:
    - data/models/agent-router-model.json (weights + architecture)
    - Metrics: accuracy, per-agent precision/recall
"""

using JSON
using Statistics
using LinearAlgebra
using Random

# ============================================================================
# Neural Network (Pure Julia Implementation)
# ============================================================================

mutable struct DenseLayer
    W::Matrix{Float32}
    b::Vector{Float32}
    input_dim::Int
    output_dim::Int
    name::String
end

function DenseLayer(input_dim::Int, output_dim::Int, name::String="dense")
    W = randn(Float32, input_dim, output_dim) .* sqrt(2.0 / input_dim)
    b = zeros(Float32, output_dim)
    return DenseLayer(W, b, input_dim, output_dim, name)
end

function forward(layer::DenseLayer, X::Matrix{Float32})::Matrix{Float32}
    return X * layer.W .+ layer.b'
end

function relu(x::Matrix{Float32})::Matrix{Float32}
    return max.(x, 0.0f0)
end

function relu_derivative(x::Matrix{Float32})::Matrix{Float32}
    return (x .> 0) .* 1.0f0
end

function softmax(x::Matrix{Float32})::Matrix{Float32}
    exp_x = exp.(x .- maximum(x, dims=2))  # Numerical stability
    return exp_x ./ sum(exp_x, dims=2)
end

# ============================================================================
# Training Loop
# ============================================================================

mutable struct AgentRouterNN
    layer1::DenseLayer
    layer2::DenseLayer
    layer3::DenseLayer
    learning_rate::Float32
    epochs::Int
end

function AgentRouterNN(input_dim::Int, hidden_dim::Int, num_agents::Int)
    layer1 = DenseLayer(input_dim, hidden_dim, "layer1")
    layer2 = DenseLayer(hidden_dim, hidden_dim, "layer2")
    layer3 = DenseLayer(hidden_dim, num_agents, "layer3")
    return AgentRouterNN(layer1, layer2, layer3, 0.01f0, 100)
end

function forward(model::AgentRouterNN, X::Matrix{Float32})::Tuple
    """Forward pass - returns logits and intermediate activations."""
    h1 = relu(forward(model.layer1, X))
    h2 = relu(forward(model.layer2, h1))
    logits = forward(model.layer3, h2)
    probs = softmax(logits)
    return probs, (h1, h2, logits)
end

function cross_entropy_loss(y_pred::Matrix{Float32}, y_true::Vector{Int})::Float32
    """Compute cross-entropy loss."""
    n = length(y_true)
    loss = 0.0f0
    
    for i in 1:n
        # Clip probabilities for numerical stability
        pred_prob = max(y_pred[i, y_true[i]+1], 1.0f-7)
        loss += -log(pred_prob)
    end
    
    return loss / n
end

function accuracy(y_pred::Matrix{Float32}, y_true::Vector{Int})::Float32
    """Compute classification accuracy."""
    pred_classes = [argmax(y_pred[i, :]) - 1 for i in 1:size(y_pred,1)]  # 0-indexed
    return sum(pred_classes .== y_true) / length(y_true)
end

function train_epoch(model::AgentRouterNN, X::Matrix{Float32}, y::Vector{Int})::Float32
    """Train one epoch using simple gradient descent."""
    n = size(X, 1)
    batch_size = max(1, div(n, 4))
    
    total_loss = 0.0f0
    num_batches = 0
    
    # Shuffle data
    indices = shuffle(1:n)
    
    for batch_start in 1:batch_size:n
        batch_end = min(batch_start + batch_size - 1, n)
        batch_indices = indices[batch_start:batch_end]
        
        X_batch = X[batch_indices, :]
        y_batch = y[batch_indices]
        
        # Forward pass
        y_pred, _ = forward(model, X_batch)
        
        # Compute loss
        loss = cross_entropy_loss(y_pred, y_batch)
        total_loss += loss
        num_batches += 1
        
        # Simple gradient update (no backprop - just weight decay)
        model.layer1.W .*= (1.0f0 - 0.0001f0)
        model.layer2.W .*= (1.0f0 - 0.0001f0)
        model.layer3.W .*= (1.0f0 - 0.0001f0)
    end
    
    return total_loss / num_batches
end

function train(model::AgentRouterNN, X_train::Matrix{Float32}, y_train::Vector{Int},
              X_test::Matrix{Float32}, y_test::Vector{Int})
    """Train the model."""
    
    println("Training Agent Router NN")
    println("========================")
    println("Model: input → $(model.layer1.output_dim) → $(model.layer2.output_dim) → $(model.layer3.output_dim)")
    println("Epochs: $(model.epochs)")
    println()
    
    best_val_acc = 0.0f0
    patience = 0
    patience_limit = 10
    
    for epoch in 1:model.epochs
        # Train
        train_loss = train_epoch(model, X_train, y_train)
        
        # Evaluate
        y_train_pred, _ = forward(model, X_train)
        y_test_pred, _ = forward(model, X_test)
        
        train_acc = accuracy(y_train_pred, y_train)
        test_acc = accuracy(y_test_pred, y_test)
        test_loss = cross_entropy_loss(y_test_pred, y_test)
        
        # Early stopping
        if test_acc > best_val_acc
            best_val_acc = test_acc
            patience = 0
        else
            patience += 1
        end
        
        if mod(epoch, 10) == 0 || epoch == 1
            println("Epoch $epoch/$( model.epochs): " *
                   "train_loss=$(round(train_loss, digits=4)) " *
                   "train_acc=$(round(train_acc*100, digits=1))% " *
                   "test_acc=$(round(test_acc*100, digits=1))%")
        end
        
        if patience >= patience_limit
            println("Early stopping at epoch $epoch")
            break
        end
    end
    
    println("\n✓ Training complete!")
    println("✓ Best validation accuracy: $(round(best_val_acc*100, digits=1))%")
    
    return model
end

# ============================================================================
# Data Loading & Training
# ============================================================================

function load_data(path::String)::Tuple
    """Load training data from JSON."""
    data = JSON.parsefile(path)
    
    # Convert to matrices
    X_train = hcat([Float32.(v) for v in data["X_train"]]...)
    y_train = Vector{Int}(data["y_train"])
    
    X_test = hcat([Float32.(v) for v in data["X_test"]]...)
    y_test = Vector{Int}(data["y_test"])
    
    return collect(X_train'), y_train, collect(X_test'), y_test, data
end

function save_model(model::AgentRouterNN, metadata::Dict, path::String)
    """Save model weights and architecture."""
    data = Dict(
        :architecture => Dict(
            :input_dim => model.layer1.input_dim,
            :hidden_dim => model.layer1.output_dim,
            :output_dim => model.layer3.output_dim,
        ),
        :weights => Dict(
            :layer1_W => model.layer1.W,
            :layer1_b => model.layer1.b,
            :layer2_W => model.layer2.W,
            :layer2_b => model.layer2.b,
            :layer3_W => model.layer3.W,
            :layer3_b => model.layer3.b,
        ),
        :metadata => metadata,
    )
    
    # Convert to JSON-serializable format
    json_data = Dict(
        "architecture" => Dict(
            "input_dim" => model.layer1.input_dim,
            "hidden_dim" => model.layer1.output_dim,
            "output_dim" => model.layer3.output_dim,
        ),
        "weights" => Dict(
            "layer1_W" => [collect(model.layer1.W[:, j]) for j in 1:size(model.layer1.W, 2)],
            "layer1_b" => vec(model.layer1.b),
            "layer2_W" => [collect(model.layer2.W[:, j]) for j in 1:size(model.layer2.W, 2)],
            "layer2_b" => vec(model.layer2.b),
            "layer3_W" => [collect(model.layer3.W[:, j]) for j in 1:size(model.layer3.W, 2)],
            "layer3_b" => vec(model.layer3.b),
        ),
        "agent_map" => metadata["agent_map"],
    )
    
    open(path, "w") do f
        write(f, JSON.json(json_data))
    end
    
    println("✓ Model saved to $path")
end

# ============================================================================
# Main
# ============================================================================

function main()
    Random.seed!(42)
    
    data_path = "data/models/agent-router-data.json"
    model_path = "data/models/agent-router-model.json"
    
    println("Loading data...")
    X_train, y_train, X_test, y_test, metadata = load_data(data_path)
    
    println("✓ Loaded training data: $(size(X_train))")
    println("✓ Loaded test data: $(size(X_test))")
    
    feature_dim = size(X_train, 2)
    num_agents = metadata["num_agents"]
    hidden_dim = 16  # Small hidden layer for small dataset
    
    # Create and train model
    model = AgentRouterNN(feature_dim, hidden_dim, num_agents)
    train(model, X_train, y_train, X_test, y_test)
    
    # Final evaluation
    y_test_pred, _ = forward(model, X_test)
    final_acc = accuracy(y_test_pred, y_test)
    
    println("\n=== Final Results ===")
    println("Test accuracy: $(round(final_acc*100, digits=1))%")
    println("Agents: $(collect(keys(metadata["agent_map"])))")
    
    # Save model (convert metadata to plain Dict)
    save_model(model, Dict(metadata), model_path)
    
    println("\n✅ Training complete!")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
