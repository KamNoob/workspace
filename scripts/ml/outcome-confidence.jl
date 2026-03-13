#!/usr/bin/env julia
# outcome-confidence.jl
# Monte Carlo confidence bounds for P(success | task, agent)
# Bootstrap resample outcome logs to get uncertainty intervals

using Statistics
using Dates
using Serialization

# ─── Outcome Confidence Model ────────────────────────────────────────────

"""
    OutcomeConfidenceModel

Holds P(success) point estimate + confidence bounds via bootstrap sampling.
"""
mutable struct OutcomeConfidenceModel
    point_estimate::Dict{Tuple{String, String}, Float64}  # (task, agent) → P(success)
    ci_lower::Dict{Tuple{String, String}, Float64}        # 5th percentile
    ci_median::Dict{Tuple{String, String}, Float64}       # 50th (median)
    ci_upper::Dict{Tuple{String, String}, Float64}        # 95th percentile
    bootstrap_samples::Int
    created::DateTime
end

function OutcomeConfidenceModel(bootstrap_samples=1000)
    return OutcomeConfidenceModel(
        Dict(),
        Dict(),
        Dict(),
        Dict(),
        bootstrap_samples,
        now()
    )
end

"""
    sigmoid(z::Float64) -> Float64
"""
function sigmoid(z::Float64)
    return 1.0 / (1.0 + exp(-z))
end

"""
    logistic_regression(outcomes::Vector, task::String, agent::String) -> Float64

Simple logistic regression: P(success | task, agent)
"""
function logistic_regression(outcomes::Vector, task::String, agent::String)::Float64
    # Count successes for this (task, agent)
    matching = filter(o -> get(o, :task, "") == task && get(o, :agent, "") == agent, outcomes)
    
    if isempty(matching)
        return 0.5  # No data, neutral estimate
    end
    
    success_count = sum(get(o, :success, false) ? 1 : 0 for o in matching)
    total = length(matching)
    
    return success_count / total
end

"""
    train_with_bootstrap!(model::OutcomeConfidenceModel, outcomes::Vector)

Train model using bootstrap resampling.
Estimates P(success) with confidence intervals.
"""
function train_with_bootstrap!(model::OutcomeConfidenceModel, outcomes::Vector)
    println("🎓 Training outcome model with bootstrap resampling...")
    println("   Resampling $(model.bootstrap_samples) times...")
    
    if isempty(outcomes)
        @warn "No outcomes to train on"
        return model
    end
    
    # Get unique (task, agent) pairs
    pairs = Set{Tuple{String, String}}()
    for outcome in outcomes
        task = get(outcome, :task, "")
        agent = get(outcome, :agent, "")
        if !isempty(task) && !isempty(agent)
            push!(pairs, (task, agent))
        end
    end
    
    println("   Found $(length(pairs)) (task, agent) pairs")
    
    # Bootstrap
    for (task, agent) in pairs
        bootstrap_estimates = Float64[]
        
        # Resample 1000 times
        for b in 1:model.bootstrap_samples
            # Resample outcomes with replacement
            resampled = outcomes[rand(1:length(outcomes), length(outcomes))]
            
            # Estimate P(success) on resampled data
            p_success = logistic_regression(resampled, task, agent)
            push!(bootstrap_estimates, p_success)
        end
        
        # Calculate point estimate (mean)
        point = mean(bootstrap_estimates)
        
        # Calculate percentiles
        sorted = sort(bootstrap_estimates)
        lower_idx = max(1, Int(round(0.05 * length(sorted))))
        median_idx = Int(round(0.5 * length(sorted)))
        upper_idx = min(length(sorted), Int(round(0.95 * length(sorted))))
        
        lower = sorted[lower_idx]
        median = sorted[median_idx]
        upper = sorted[upper_idx]
        
        key = (task, agent)
        model.point_estimate[key] = point
        model.ci_lower[key] = lower
        model.ci_median[key] = median
        model.ci_upper[key] = upper
    end
    
    println("✓ Bootstrap complete: $(length(model.point_estimate)) estimates with confidence bounds")
    return model
end

"""
    predict_with_confidence(model::OutcomeConfidenceModel, task::String, agent::String)
    -> (point::Float64, lower::Float64, median::Float64, upper::Float64)

Get P(success) with 5%-95% confidence interval.
"""
function predict_with_confidence(model::OutcomeConfidenceModel, task::String, agent::String)
    key = (task, agent)
    
    point = get(model.point_estimate, key, 0.5)
    lower = get(model.ci_lower, key, 0.3)
    median = get(model.ci_median, key, 0.5)
    upper = get(model.ci_upper, key, 0.7)
    
    return (point, lower, median, upper)
end

"""
    confidence_level(prob::Float64, lower::Float64, upper::Float64) -> Symbol

Classify confidence based on interval width.
"""
function confidence_level(prob::Float64, lower::Float64, upper::Float64)::Symbol
    width = upper - lower
    
    if width < 0.15  # Tight interval
        return :high
    elseif width < 0.35  # Medium interval
        return :medium
    else  # Wide interval = high uncertainty
        return :low
    end
end

# ─── File I/O ──────────────────────────────────────────────────────────────

function save_model(model::OutcomeConfidenceModel, path::String)
    open(path, "w") do io
        serialize(io, model)
    end
end

function load_model(path::String)::OutcomeConfidenceModel
    open(path, "r") do io
        return deserialize(io)::OutcomeConfidenceModel
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
    println("║ Outcome Confidence: Bootstrap P(success ± CI)           ║")
    println("╚════════════════════════════════════════════════════════╝\n")
    
    if length(ARGS) < 1
        println("Usage:")
        println("  julia outcome-confidence.jl train         # Train model")
        println("  julia outcome-confidence.jl predict code Codex  # Predict with CI")
        println("  julia outcome-confidence.jl status        # Show model")
        return
    end
    
    cmd = ARGS[1]
    model_path = joinpath(@__DIR__, "..", "..", "data", "rl", "outcome-confidence.jld2")
    
    if cmd == "train"
        println("📖 Loading outcomes...")
        outcomes = load_outcomes()
        
        if isempty(outcomes)
            println("❌ No outcomes found")
            return
        end
        
        model = OutcomeConfidenceModel(1000)  # 1000 bootstrap samples
        train_with_bootstrap!(model, outcomes)
        
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
            point, lower, median, upper = predict_with_confidence(model, task, agent)
            conf = confidence_level(point, lower, upper)
            
            point_pct = round(point * 100, digits=1)
            lower_pct = round(lower * 100, digits=1)
            upper_pct = round(upper * 100, digits=1)
            
            println("📊 P(success | task=$task, agent=$agent)")
            println("   Point estimate: $point_pct%")
            println("   90% Confidence Interval: [$lower_pct% - $upper_pct%]")
            println("   Median: $(round(median*100, digits=1))%")
            println("   Confidence: $conf")
            
            # Decision
            decision = if point >= 0.75
                "spawn (high confidence)"
            elseif point >= 0.60
                "spawn (medium confidence)"
            else
                "escalate (low confidence)"
            end
            
            println("   Decision: $decision")
        catch err
            println("❌ Error: $err")
        end
        
    elseif cmd == "status"
        try
            model = load_model(model_path)
            println("✓ Model loaded: $model_path")
            println("  Created: $(model.created)")
            println("  Bootstrap samples: $(model.bootstrap_samples)")
            println("  Estimates: $(length(model.point_estimate))")
            
            if !isempty(model.point_estimate)
                println("\n  Sample predictions:")
                for (i, (key, point)) in enumerate(sort(model.point_estimate, by=last, rev=true))
                    if i > 5
                        break
                    end
                    task, agent = key
                    lower = model.ci_lower[key]
                    upper = model.ci_upper[key]
                    println("    $task × $agent: $(round(point*100, digits=1))% [$(round(lower*100, digits=1))-$(round(upper*100, digits=1))%]")
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
