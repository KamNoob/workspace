#!/usr/bin/env julia
"""
    agent-router-data.jl

Agent Router Data Preparation (Pure Julia, minimal deps)

Loads RL execution logs, featurizes tasks.

Usage:
    julia agent-router-data.jl

Output:
    - data/models/agent-router-data.json
    - Includes: X_train, y_train, X_test, y_test, metadata
"""

using JSON
using Random

# ============================================================================
# Data Loading
# ============================================================================

function load_execution_log(path::String)::Vector{Dict}
    """Load JSONL execution log."""
    data = []
    
    open(path) do f
        for (i, line) in enumerate(eachline(f))
            try
                push!(data, JSON.parse(line))
            catch e
                println("Warning: Skipping line $i")
            end
        end
    end
    
    return data
end

function summarize_data(data::Vector{Dict})
    """Print data summary."""
    n = length(data)
    
    # Extract fields
    tasks = [d["task"] for d in data]
    agents = [d["agent"] for d in data]
    successes = [d["success"] for d in data]
    
    println("\n=== Data Summary ===")
    println("Total records: $n")
    
    # Count tasks
    task_counts = Dict{String,Int}()
    for t in tasks
        task_counts[t] = get(task_counts, t, 0) + 1
    end
    
    println("\nTask distribution:")
    for (task, count) in sort(collect(task_counts), by=x->-x[2])
        println("  $task: $count")
    end
    
    # Count agents
    agent_counts = Dict{String,Int}()
    for a in agents
        agent_counts[a] = get(agent_counts, a, 0) + 1
    end
    
    println("\nAgent distribution:")
    for (agent, count) in sort(collect(agent_counts), by=x->-x[2])
        println("  $agent: $count")
    end
    
    success_rate = sum(successes) / n
    println("\nSuccess rate: $(round(success_rate*100, digits=1))%")
    
    return task_counts, agent_counts
end

# ============================================================================
# Feature Engineering
# ============================================================================

function simple_tokenize(text::String)::Vector{String}
    """Simple word tokenization."""
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

function build_vocabulary(tasks::Vector{String}, min_count::Int=1)::Dict{String,Int}
    """Build vocabulary from task strings."""
    word_counts = Dict{String,Int}()
    
    for task in tasks
        for word in simple_tokenize(task)
            word_counts[word] = get(word_counts, word, 0) + 1
        end
    end
    
    # Filter by min_count and create vocab
    vocab = Dict{String,Int}()
    idx = 1
    for (word, count) in sort(collect(word_counts), by=x->-x[2])
        if count >= min_count
            vocab[word] = idx
            idx += 1
        end
    end
    
    return vocab
end

function featurize_tasks(tasks::Vector{String}, vocab::Dict{String,Int})::Matrix{Float32}
    """Convert tasks to bag-of-words features."""
    n_tasks = length(tasks)
    n_features = length(vocab)
    
    X = zeros(Float32, n_tasks, n_features)
    
    for (i, task) in enumerate(tasks)
        words = simple_tokenize(task)
        for word in words
            if haskey(vocab, word)
                j = vocab[word]
                X[i, j] += 1.0
            end
        end
    end
    
    # L2 normalize
    for i in 1:n_tasks
        norm = sqrt(sum(X[i, :] .^ 2))
        if norm > 0
            X[i, :] ./= norm
        end
    end
    
    return X
end

function encode_labels(labels::Vector{String})::Tuple{Vector{Int}, Dict{Int,String}}
    """Encode categorical labels as integers."""
    unique_labels = unique(labels)
    sort!(unique_labels)
    
    encoder = Dict(label => i-1 for (i, label) in enumerate(unique_labels))
    encoded = [encoder[label] for label in labels]
    reverse_encoder = Dict(i-1 => label for (i, label) in enumerate(unique_labels))
    
    return encoded, reverse_encoder
end

# ============================================================================
# Train/Test Split
# ============================================================================

function stratified_split(X::Matrix, y::Vector, test_ratio::Float32=0.2; seed::Int=42)
    """Create stratified train/test split."""
    Random.seed!(seed)
    
    train_idx = Int[]
    test_idx = Int[]
    
    for class in unique(y)
        class_indices = findall(==(class), y)
        # Shuffle
        shuffled = class_indices[randperm(length(class_indices))]
        n_test_class = ceil(Int, length(shuffled) * test_ratio)
        
        append!(test_idx, shuffled[1:n_test_class])
        append!(train_idx, shuffled[n_test_class+1:end])
    end
    
    return train_idx, test_idx
end

# ============================================================================
# Main Script
# ============================================================================

function main()
    
    data_path = "data/rl/rl-task-execution-log.jsonl"
    output_dir = "data/models"
    
    # Create output directory
    mkpath(output_dir)
    
    # Load data
    println("Loading from $data_path...")
    raw_data = load_execution_log(data_path)
    println("✓ Loaded $(length(raw_data)) records")
    
    # Summarize
    summarize_data(raw_data)
    
    # Extract fields
    tasks = [d["task"] for d in raw_data]
    agents = [d["agent"] for d in raw_data]
    
    # Featurize
    println("\nBuilding vocabulary...")
    vocab = build_vocabulary(tasks)
    println("✓ Vocabulary size: $(length(vocab))")
    
    println("Featurizing tasks...")
    X = featurize_tasks(tasks, vocab)
    println("✓ Feature shape: $(size(X))")
    
    # Encode agents
    println("Encoding agents...")
    y, agent_map = encode_labels(agents)
    println("✓ Number of agents: $(length(agent_map))")
    for (idx, agent) in sort(collect(agent_map))
        count = sum(y .== idx)
        println("  $idx: $agent (n=$count)")
    end
    
    # Split
    println("\nCreating train/test split (80/20)...")
    train_idx, test_idx = stratified_split(X, y, Float32(0.2))
    
    X_train = X[train_idx, :]
    y_train = y[train_idx]
    X_test = X[test_idx, :]
    y_test = y[test_idx]
    
    println("✓ Train: $(length(train_idx)) samples")
    println("✓ Test: $(length(test_idx)) samples")
    println("✓ Feature dimension: $(size(X, 2))")
    println("✓ Number of agents: $(length(unique(y)))")
    
    # Save to JSON
    output_file = joinpath(output_dir, "agent-router-data.json")
    println("\nSaving to $output_file...")
    
    json_data = Dict(
        "X_train" => [[X_train[i, j] for j in 1:size(X_train,2)] for i in 1:size(X_train,1)],
        "y_train" => y_train,
        "X_test" => [[X_test[i, j] for j in 1:size(X_test,2)] for i in 1:size(X_test,1)],
        "y_test" => y_test,
        "feature_dim" => size(X_train, 2),
        "num_agents" => length(unique(y)),
        "agent_map" => agent_map,
    )
    
    open(output_file, "w") do f
        write(f, JSON.json(json_data))
    end
    
    println("✓ Saved to $output_file")
    
    println("\n--- Summary ---")
    println("Training samples: $(size(X_train, 1))")
    println("Test samples: $(size(X_test, 1))")
    println("Feature dimension: $(size(X_train, 2))")
    println("Agent classes: $(sort(collect(keys(agent_map))))")
    
    println("\n✅ Data preparation complete!")
end

# ============================================================================
# Entry Point
# ============================================================================

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
