#!/usr/bin/env julia
# outcome-predictor.jl
# Predict success probability P(success | task, agent, metadata)
# Logistic regression trained on outcome logs.

using Statistics
using Dates
using Serialization

# ─── Logistic Regression Model ─────────────────────────────────────────────

"""
    LogisticOutcomeModel

Logistic regression for P(success | features).
Trained on outcome logs.
"""
mutable struct LogisticOutcomeModel
    weights::Dict{String, Float64}
    intercept::Float64
    feature_names::Vector{String}
    created::DateTime
end

function LogisticOutcomeModel()
    return LogisticOutcomeModel(Dict(), 0.0, String[], now())
end

"""
    sigmoid(z::Float64) -> Float64

Sigmoid function: 1 / (1 + exp(-z))
"""
function sigmoid(z::Float64)
    return 1.0 / (1.0 + exp(-z))
end

"""
    train_from_outcomes!(model::LogisticOutcomeModel, outcomes::Vector)

Train logistic regression from outcome logs.
Simple approach: Count success rates per (task, agent) pair.
"""
function train_from_outcomes!(model::LogisticOutcomeModel, outcomes::Vector)
    println("🎓 Training logistic regression...")
    
    # Count successes per (task, agent)
    task_agent_outcomes = Dict{Tuple{String, String}, Tuple{Int, Int}}()  # (success, total)
    
    for outcome in outcomes
        task = get(outcome, :task, "unknown")
        agent = get(outcome, :agent, "unknown")
        success = get(outcome, :success, false)
        
        key = (task, agent)
        if !haskey(task_agent_outcomes, key)
            task_agent_outcomes[key] = (0, 0)
        end
        
        success_count, total = task_agent_outcomes[key]
        success_count += success ? 1 : 0
        total += 1
        task_agent_outcomes[key] = (success_count, total)
    end
    
    # Convert to weights
    # Simple: weight per (task, agent) = log(success_rate / (1 - success_rate))
    weights = Dict{String, Float64}()
    
    for ((task, agent), (success_count, total)) in task_agent_outcomes
        if total > 0
            success_rate = success_count / total
            
            # Avoid log(0)
            success_rate = clamp(success_rate, 0.01, 0.99)
            
            # Log-odds weight
            weight = log(success_rate / (1 - success_rate))
            
            feature_key = "$(task)_$(agent)"
            weights[feature_key] = weight
        end
    end
    
    # Overall intercept (baseline success rate)
    total_success = sum(c for (c, _) in values(task_agent_outcomes))
    total_outcomes = sum(t for (_, t) in values(task_agent_outcomes))
    
    if total_outcomes > 0
        baseline_rate = clamp(total_success / total_outcomes, 0.01, 0.99)
        model.intercept = log(baseline_rate / (1 - baseline_rate))
    else
        model.intercept = 0.0
    end
    
    model.weights = weights
    model.feature_names = collect(keys(weights))
    model.created = now()
    
    println("✓ Trained on $(length(task_agent_outcomes)) (task, agent) pairs")
    println("✓ Baseline success rate: $(round(total_success/total_outcomes, digits=3))")
    
    return model
end

"""
    predict_success(model::LogisticOutcomeModel, task::String, agent::String) -> Float64

Predict P(success | task, agent).
"""
function predict_success(model::LogisticOutcomeModel, task::String, agent::String)::Float64
    # Start with intercept
    z = model.intercept
    
    # Add feature weight
    feature_key = "$(task)_$(agent)"
    if haskey(model.weights, feature_key)
        z += model.weights[feature_key]
    end
    
    # Apply sigmoid
    return sigmoid(z)
end

"""
    predict_confidence(prob::Float64) -> Symbol

Classify confidence level.
"""
function predict_confidence(prob::Float64)::Symbol
    if prob >= 0.80
        return :high
    elseif prob >= 0.60
        return :medium
    else
        return :low
    end
end

# ─── File I/O ──────────────────────────────────────────────────────────────

function save_model(model::LogisticOutcomeModel, path::String)
    open(path, "w") do io
        serialize(io, model)
    end
end

function load_model(path::String)::LogisticOutcomeModel
    open(path, "r") do io
        return deserialize(io)::LogisticOutcomeModel
    end
end

# ─── Main ──────────────────────────────────────────────────────────────────

function load_outcomes()
    logfile = joinpath(@__DIR__, "..", "..", "data", "rl", "rl-task-execution-log.jsonl")
    
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
            task_m = match(r"\"task\":\"([^\"]+)\"", line)
            agent_m = match(r"\"agent\":\"([^\"]+)\"", line)
            success_m = match(r"\"success\":(true|false)", line)
            
            if !isnothing(task_m) && !isnothing(agent_m) && !isnothing(success_m)
                push!(outcomes, Dict(
                    :task => task_m.captures[1],
                    :agent => agent_m.captures[1],
                    :success => success_m.captures[1] == "true"
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
    println("║ Outcome Predictor: P(success | task, agent)            ║")
    println("╚════════════════════════════════════════════════════════╝\n")
    
    if length(ARGS) < 1
        println("Usage:")
        println("  julia outcome-predictor.jl train         # Train model")
        println("  julia outcome-predictor.jl predict code Codex  # Predict P(success)")
        println("  julia outcome-predictor.jl status        # Show model")
        return
    end
    
    cmd = ARGS[1]
    model_path = joinpath(@__DIR__, "..", "..", "data", "rl", "outcome-model.jld2")
    
    if cmd == "train"
        println("📖 Loading outcomes...")
        outcomes = load_outcomes()
        
        if isempty(outcomes)
            println("❌ No outcomes found")
            return
        end
        
        model = LogisticOutcomeModel()
        train_from_outcomes!(model, outcomes)
        
        println("\n💾 Saving model...")
        try
            save_model(model, model_path)
            println("✓ Saved: $model_path")
        catch err
            println("❌ Failed: $err")
        end
        
    elseif cmd == "predict" && length(ARGS) >= 3
        task = ARGS[2]
        agent = ARGS[3]
        
        try
            model = load_model(model_path)
            prob = predict_success(model, task, agent)
            conf = predict_confidence(prob)
            
            pct = round(prob * 100, digits=1)
            decision = prob >= 0.70 ? "spawn" : "escalate"
            
            println("📊 P(success | task=$task, agent=$agent)")
            println("   Probability: $pct%")
            println("   Confidence: $conf")
            println("   Decision: $decision")
        catch err
            println("❌ Error: $err")
        end
        
    elseif cmd == "status"
        try
            model = load_model(model_path)
            println("✓ Model loaded: $model_path")
            println("  Created: $(model.created)")
            println("  Features: $(length(model.weights))")
            println("  Intercept (baseline): $(round(model.intercept, digits=3))")
            
            if !isempty(model.weights)
                println("\n  Top 10 (task, agent) predictors:")
                sorted = sort(model.weights, by=last, rev=true)[1:min(10, length(model.weights))]
                for (feature, weight) in sorted
                    println("    $feature: $(round(weight, digits=3))")
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
