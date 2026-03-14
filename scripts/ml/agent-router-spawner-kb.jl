#!/usr/bin/env julia
"""
    agent-router-spawner-kb.jl

Agent Router with Hardware Context Injection

Combines agent selection (Phase 3B) with KB context (Arduino KB)
for smarter, context-aware spawning.

Usage:
    julia agent-router-spawner-kb.jl --task "compile esp32" --candidates "Codex,QA"

Output:
    Selected agent + method + confidence + injected KB context (if relevant)
"""

using JSON
using Statistics
using Dates

# ============================================================================
# Configuration
# ============================================================================

MODEL_PATH = "data/models/agent-router-model.json"
KB_PATH = "data/knowledge-bases/arduino-reference-kb.json"
KB_MIN_CONFIDENCE = 0.60

# ============================================================================
# Model Loading & Inference (from Phase 3B)
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
    """Convert task to 6-dim features"""
    features = zeros(Float32, feature_dim)
    
    vocab = Dict(
        "code" => 0,
        "research" => 1,
        "security" => 2,
        "test" => 3,
        "docs" => 4,
        "review" => 5,
    )
    
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
    
    norm = sqrt(sum(features .^ 2))
    if norm > 0
        features ./= norm
    end
    
    return features
end

function infer(model::AgentRouterModel, task::String)::Tuple{String, Float32, Vector}
    """Run NN inference on task"""
    features = featurize_task(task, size(model.layer1_W, 1))
    
    h1 = model.layer1_W' * features .+ model.layer1_b
    h1 = relu(h1)
    
    h2 = model.layer2_W' * h1 .+ model.layer2_b
    h2 = relu(h2)
    
    logits = model.layer3_W' * h2 .+ model.layer3_b
    probs = softmax(logits)
    
    best_idx = argmax(probs) - 1
    best_agent = get(model.agent_map, string(best_idx), "Unknown")
    confidence = probs[best_idx + 1]
    
    scores = [(get(model.agent_map, string(i-1), "Agent$i"), probs[i]) 
              for i in 1:length(probs)]
    
    return best_agent, Float32(confidence), scores
end

# ============================================================================
# KB Loading & Context Injection
# ============================================================================

function load_kb()
    """Load KB"""
    if !isfile(KB_PATH)
        return Dict()
    end
    return Dict(JSON.parsefile(KB_PATH))
end

function tokenize(text::String)::Vector{String}
    """Tokenize text"""
    words = lowercase(text) |>
        s -> split(s, r"[^a-z0-9_]+") |>
        words -> filter(w -> length(w) > 0, words)
    return words
end

function compute_relevance(query_tokens::Vector{String}, entry_tags::Vector{String})::Float32
    """Compute relevance score"""
    if isempty(query_tokens) || isempty(entry_tags)
        return 0.0f0
    end
    
    matches = 0
    for token in query_tokens
        for tag in entry_tags
            if token == tag || startswith(tag, token)
                matches += 1
            end
        end
    end
    
    max_possible = length(query_tokens)
    score = min(1.0f0, Float32(matches) / Float32(max_possible))
    return score
end

function query_kb(query::String, kb::Dict)::Vector
    """Query KB for relevant entries"""
    if isempty(kb)
        return []
    end
    
    query_tokens = tokenize(query)
    entries = get(kb, "entries", [])
    results = []
    
    for entry in entries
        tags = String.(get(entry, "tags", String[]))
        title = get(entry, "title", "")
        content = get(entry, "content", "")
        confidence = get(entry, "confidence", 0.5)
        
        relevance = compute_relevance(query_tokens, tags)
        combined_confidence = (relevance + Float32(confidence)) / 2.0f0
        
        if combined_confidence >= KB_MIN_CONFIDENCE
            push!(results, Dict(
                :id => get(entry, "id", 0),
                :title => title,
                :content => content,
                :tags => tags,
                :confidence => combined_confidence
            ))
        end
    end
    
    sort!(results, by = x -> x[:confidence], rev = true)
    return results
end

function format_kb_context(entries::Vector)::String
    """Format KB entries as context blocks"""
    if isempty(entries)
        return ""
    end
    
    context = "\n🔧 HARDWARE CONTEXT:\n"
    context *= "═" ^ 50 * "\n"
    
    for (i, entry) in enumerate(entries[1:min(3, length(entries))])
        conf_pct = Int(round(entry[:confidence] * 100))
        context *= "\n[$i] $(entry[:title]) ($(conf_pct)% confidence)\n"
        context *= "─" ^ 40 * "\n"
        context *= entry[:content] * "\n"
    end
    
    context *= "\n" * "═" ^ 50 * "\n"
    return context
end

# ============================================================================
# Q-Learning Fallback (from Phase 3B)
# ============================================================================

function get_qlearning_scores(task::String, candidates::Vector{String})::Dict{String, Float32}
    """Q-learning fallback (stub)"""
    scores = Dict{String, Float32}()
    for agent in candidates
        scores[agent] = 0.5f0
    end
    return scores
end

# ============================================================================
# Agent Selection with KB Injection
# ============================================================================

function select_agent_with_kb(
    task::String,
    candidates::Vector{String};
    model::Union{AgentRouterModel, Nothing} = nothing,
    kb::Dict = Dict(),
    confidence_threshold::Float32 = 0.6f0,
)::Tuple{String, String, Float32, String}
    """
    Select agent with KB context injection.
    
    Returns: (agent, method, confidence, kb_context)
    """
    
    selected_agent = "Unknown"
    method = "fallback"
    confidence = 0.0f0
    kb_context = ""
    
    # Query KB for context (always, for any task)
    kb_results = query_kb(task, kb)
    kb_context = format_kb_context(kb_results)
    
    # Try NN first
    if model !== nothing
        nn_agent, nn_confidence, nn_scores = infer(model, task)
        
        if nn_confidence >= confidence_threshold
            selected_agent = nn_agent
            method = "neural_network"
            confidence = nn_confidence
            
            println("✓ NN Prediction (confidence: $(round(confidence, digits=2)))")
            println("  Top scores: $(nn_scores[1:min(3, length(nn_scores))])")
            
            return selected_agent, method, confidence, kb_context
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
    
    return selected_agent, method, confidence, kb_context
end

# ============================================================================
# Logging
# ============================================================================

function log_spawn_decision(task::String, agent::String, method::String, confidence::Float32, kb_entries::Int)
    """Log spawn decision with KB context count"""
    log_file = "data/rl/agent-router-spawns-with-kb.jsonl"
    
    record = Dict(
        :timestamp => now(),
        :task => task,
        :agent => agent,
        :method => method,
        :confidence => confidence,
        :kb_entries_injected => kb_entries
    )
    
    open(log_file, "a") do f
        write(f, JSON.json(record) * "\n")
    end
    
    println("✓ Logged to $log_file")
end

# ============================================================================
# Main: CLI Interface
# ============================================================================

function main()
    args = ARGS
    
    task = ""
    candidates_str = "Codex,Scout,Cipher,Chronicle,QA,Veritas"
    
    for (i, arg) in enumerate(args)
        if arg == "--task" && i < length(args)
            task = args[i+1]
        elseif arg == "--candidates" && i < length(args)
            candidates_str = args[i+1]
        end
    end
    
    if isempty(task)
        println("Usage: julia agent-router-spawner-kb.jl --task \"<task>\" --candidates \"<agent1>,<agent2>,...\"")
        println("\nExample:")
        println("  julia agent-router-spawner-kb.jl --task \"compile esp32 sketch\" --candidates \"Codex,QA\"")
        return
    end
    
    candidates = String.(split(candidates_str, ","))
    
    println("\n🧠 Agent Router with KB Context (Phase 3B + Arduino KB)")
    println("=" ^ 60)
    println("Task: $task")
    println("Candidates: $(join(candidates, ", "))")
    println()
    
    # Load model
    model = try
        load_model(MODEL_PATH)
    catch e
        println("⚠ Could not load model: $e")
        nothing
    end
    
    # Load KB
    kb = load_kb()
    
    # Select agent with KB context
    selected_agent, method, confidence, kb_context = select_agent_with_kb(
        task, 
        candidates;
        model=model,
        kb=kb,
        confidence_threshold=0.6f0
    )
    
    println("\n" * "=" ^ 60)
    println("SPAWN DECISION")
    println("=" ^ 60)
    println("Selected agent: $selected_agent")
    println("Method: $method")
    println("Confidence: $(round(confidence, digits=3))")
    
    # Show KB context
    if !isempty(kb_context)
        println("\n$kb_context")
    else
        println("\nℹ️  No hardware context found for this task")
    end
    
    # Log decision
    kb_entries_count = count(c -> c == '\n', kb_context)
    log_spawn_decision(task, selected_agent, method, confidence, kb_entries_count)
    
    println("\n✅ Ready to spawn agent: $selected_agent")
    println("   Augmented prompt includes KB context + task description")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
