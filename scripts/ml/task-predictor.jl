#!/usr/bin/env julia
# task-predictor.jl
# Learn task transition probabilities from outcome logs.
# Predict next task type to bootstrap agent selection.

using Dates
using Statistics
using Serialization

const SCRIPT_DIR = @__DIR__
include(joinpath(SCRIPT_DIR, "MatrixRL.jl"))
using .MatrixRL

# ─── Task Prediction Model ─────────────────────────────────────────────────

"""
    MarkovTaskModel

Markov chain model for task transitions.
Learns: P(next_task | current_task) from outcome sequences.
"""
mutable struct MarkovTaskModel
    transitions::Dict{String, Dict{String, Float64}}  # task → {next_task → prob}
    counts::Dict{String, Dict{String, Int}}           # Raw counts for retraining
    total_by_task::Dict{String, Int}                  # Normalization
    created::DateTime
end

function MarkovTaskModel()
    return MarkovTaskModel(Dict(), Dict(), Dict(), now())
end

"""
    train_from_outcomes!(model::MarkovTaskModel, outcomes::Vector{Dict})

Train model from outcome log.
Outcomes should have: :task field (ordered by timestamp).
"""
function train_from_outcomes!(model::MarkovTaskModel, outcomes::Vector)
    # Sort by timestamp
    sorted = sort(outcomes, by = o -> get(o, :timestamp, ""))
    
    println("🎓 Training on $(length(sorted)) outcomes...")
    
    # Extract tasks in order
    tasks = [o[:task] for o in sorted]
    
    # Count transitions
    transitions_count = Dict{String, Dict{String, Int}}()
    
    for i in 1:(length(tasks)-1)
        current = tasks[i]
        next = tasks[i+1]
        
        if !haskey(transitions_count, current)
            transitions_count[current] = Dict()
        end
        
        transitions_count[current][next] = get(transitions_count[current], next, 0) + 1
    end
    
    # Convert to probabilities
    transitions_prob = Dict{String, Dict{String, Float64}}()
    total_by_task = Dict{String, Int}()
    
    for (task, nexts) in transitions_count
        total = sum(values(nexts))
        total_by_task[task] = total
        transitions_prob[task] = Dict(
            next_task => count / total 
            for (next_task, count) in nexts
        )
    end
    
    model.counts = transitions_count
    model.transitions = transitions_prob
    model.total_by_task = total_by_task
    model.created = now()
    
    # Print summary
    println("✓ Learned $(length(transitions_count)) task transitions")
    for task in sort(collect(keys(transitions_prob)))
        nexts = transitions_prob[task]
        sorted_nexts = sort(collect(nexts), by=x->x[2], rev=true)
        top_next = first(sorted_nexts)
        println("  $task → $(top_next[1]) ($(round(top_next[2]*100))%)")
    end
    
    return model
end

"""
    predict_next_task(model::MarkovTaskModel, current_task::String) -> Dict{String, Float64}

Predict probability distribution over next tasks.
"""
function predict_next_task(model::MarkovTaskModel, current_task::String)::Dict{String, Float64}
    return get(model.transitions, current_task, Dict())
end

"""
    predict_best_next_task(model::MarkovTaskModel, current_task::String) -> Tuple{String, Float64}

Return single best prediction (task with highest probability).
"""
function predict_best_next_task(model::MarkovTaskModel, current_task::String)
    probs = predict_next_task(model, current_task)
    
    if isempty(probs)
        return ("", 0.0)
    end
    
    best = maximum(probs, by=last)
    return best
end

# ─── File I/O ──────────────────────────────────────────────────────────────

"""
    save_model(model::MarkovTaskModel, path::String)

Save trained model to binary format.
"""
function save_model(model::MarkovTaskModel, path::String)
    open(path, "w") do io
        serialize(io, model)
    end
end

"""
    load_model(path::String) -> MarkovTaskModel

Load trained model from binary format.
"""
function load_model(path::String)::MarkovTaskModel
    open(path, "r") do io
        return deserialize(io)::MarkovTaskModel
    end
end

# ─── Main ──────────────────────────────────────────────────────────────────

function load_outcomes()
    logfile = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-task-execution-log.jsonl")
    
    if !isfile(logfile)
        @warn "Outcome log not found: $logfile"
        return []
    end
    
    outcomes = []
    for line in readlines(logfile)
        if isempty(strip(line))
            continue
        end
        
        try
            # Parse JSON manually (simple extraction)
            task_m = match(r"\"task\":\"([^\"]+)\"", line)
            ts_m = match(r"\"timestamp\":\"([^\"]+)\"", line)
            
            if !isnothing(task_m) && !isnothing(ts_m)
                push!(outcomes, Dict(
                    :task => task_m.captures[1],
                    :timestamp => ts_m.captures[1]
                ))
            end
        catch err
            continue
        end
    end
    
    return outcomes
end

function main()
    println("╔════════════════════════════════════════════════════════╗")
    println("║ Task Predictor: Learn Task Transitions                  ║")
    println("╚════════════════════════════════════════════════════════╝\n")
    
    if length(ARGS) < 1
        println("Usage:")
        println("  julia task-predictor.jl train       # Train from outcomes")
        println("  julia task-predictor.jl predict code  # Predict next tasks")
        println("  julia task-predictor.jl status      # Show model status")
        return
    end
    
    cmd = ARGS[1]
    model_path = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "task-transitions.jld2")
    
    if cmd == "train"
        println("📖 Loading outcomes...")
        outcomes = load_outcomes()
        
        if isempty(outcomes)
            println("❌ No outcomes found")
            return
        end
        
        model = MarkovTaskModel()
        train_from_outcomes!(model, outcomes)
        
        println("\n💾 Saving model...")
        try
            save_model(model, model_path)
            println("✓ Saved: $model_path")
        catch err
            println("❌ Failed to save: $err")
        end
        
    elseif cmd == "predict" && length(ARGS) >= 2
        current_task = ARGS[2]
        
        try
            model = load_model(model_path)
            probs = predict_next_task(model, current_task)
            
            if isempty(probs)
                println("⚠️  No transitions learned for task: $current_task")
                return
            end
            
            println("📊 Predicted next tasks after '$current_task':\n")
            sorted = sort(probs, by=last, rev=true)
            for (task, prob) in sorted
                pct = round(prob * 100, digits=1)
                bar = "█" ^ Int(round(prob * 20))
                println("  $task: $pct% $bar")
            end
        catch err
            println("❌ Error: $err")
        end
        
    elseif cmd == "status"
        try
            model = load_model(model_path)
            println("✓ Model loaded: $model_path")
            println("  Created: $(model.created)")
            println("  Task transitions: $(length(model.transitions))")
            println("  Total outcomes: $(sum(values(model.total_by_task)))")
            
            if !isempty(model.transitions)
                println("\n  Transition matrix:")
                for (task, nexts) in sort(model.transitions)
                    count = model.total_by_task[task]
                    println("    $task (from $count): $(length(nexts)) next tasks")
                end
            end
        catch err
            println("❌ Model not found or error: $err")
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
