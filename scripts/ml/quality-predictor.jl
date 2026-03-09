# quality-predictor.jl — QualityPredictor module
# Bayesian success-probability estimator, calibrated on rl-task-execution-log.jsonl.
# No external dependencies — plain Julia stdlib only.

module QualityPredictor

using Printf

export predict_success, load_log, calibrate!, top_agent_for_task, print_summary, validate

# ── Internal state ──────────────────────────────────────────────────────────
const _counts       = Dict{Tuple{String,String}, Tuple{Int,Int}}()  # (agent, task) → (wins, total)
const _agent_counts = Dict{String, Tuple{Int,Int}}()                # agent → (wins, total)
const _task_counts  = Dict{String, Tuple{Int,Int}}()                # task  → (wins, total)

# ── Minimal JSON field extractor ────────────────────────────────────────────
function _extract(line::String, key::String)::String
    idx = findfirst("\"$key\":", line)
    isnothing(idx) && return ""
    rest = lstrip(line[last(idx)+1:end])
    if startswith(rest, '"')
        rest = rest[2:end]
        stop = findfirst('"', rest)
        isnothing(stop) && return ""
        return rest[1:stop-1]
    else
        stop = findfirst(r"[,}\s]", rest)
        isnothing(stop) && return strip(rest)
        return strip(rest[1:first(stop)-1])
    end
end

# ── Log loading ─────────────────────────────────────────────────────────────
"""
    load_log(path) → Int

Parse a JSONL execution log; return number of records consumed.
Required fields per line: task_type, agent, success (bool).
"""
function load_log(path::String)::Int
    empty!(_counts)
    empty!(_agent_counts)
    empty!(_task_counts)
    
    count = 0
    open(path, "r") do fh
        for line in eachline(fh)
            line = strip(line)
            isempty(line) && continue
            
            task_type = _extract(line, "task_type")
            agent     = _extract(line, "agent")
            success_s = _extract(line, "success")
            
            (isempty(task_type) || isempty(agent) || isempty(success_s)) && continue
            
            success = success_s == "true"
            s = success ? 1 : 0
            
            key = (agent, task_type)
            (prev_s, prev_t) = get(_counts, key, (0, 0))
            _counts[key] = (prev_s + s, prev_t + 1)
            
            (as, at) = get(_agent_counts, agent, (0, 0))
            _agent_counts[agent] = (as + s, at + 1)
            
            (ts, tt) = get(_task_counts, task_type, (0, 0))
            _task_counts[task_type] = (ts + s, tt + 1)
            
            count += 1
        end
    end
    count
end

# ── Prediction ──────────────────────────────────────────────────────────────
"""
    predict_success(task_type, agent) → (probability, confidence)

Laplace-smoothed Bayesian estimate: P = (successes + 1) / (total + 2).
Falls back to marginal priors if no joint data exist.
Confidence: "high" (≥10 obs), "medium" (3–9), "low" (<3).
"""
function predict_success(task_type::String, agent::String)::Tuple{Float64, String}
    key = (agent, task_type)
    
    if haskey(_counts, key)
        (s, t) = _counts[key]
        prob = (s + 1.0) / (t + 2.0)
        conf = t >= 10 ? "high" : t >= 3 ? "medium" : "low"
        return (prob, conf)
    end
    
    # Fallback: blend agent marginal + task marginal
    agent_p = _marginal_prob(_agent_counts, agent)
    task_p  = _marginal_prob(_task_counts, task_type)
    
    if isnan(agent_p) && isnan(task_p)
        return (0.5, "low")  # total cold-start
    elseif isnan(agent_p)
        return (task_p, "low")
    elseif isnan(task_p)
        return (agent_p, "low")
    else
        return ((agent_p + task_p) / 2.0, "low")
    end
end

function _marginal_prob(d::Dict, key::String)::Float64
    haskey(d, key) || return NaN
    (s, t) = d[key]
    return (s + 1.0) / (t + 2.0)
end

# ── Utilities ───────────────────────────────────────────────────────────────
"""
    top_agent_for_task(task_type, candidates) → (agent, prob, conf)

Given a list of candidate agent names, return the one with highest 
predicted success probability for the given task type.
"""
function top_agent_for_task(task_type::String, candidates::Vector{String})::Tuple{String, Float64, String}
    best_agent = ""
    best_prob  = -1.0
    best_conf  = "low"
    for agent in candidates
        (p, c) = predict_success(task_type, agent)
        if p > best_prob
            best_prob  = p
            best_agent = agent
            best_conf  = c
        end
    end
    return (best_agent, best_prob, best_conf)
end

"""
    calibrate!(path) — convenience alias for load_log.
"""
calibrate!(path::String) = load_log(path)

"""Print a summary of all learned (agent, task_type) pairs."""
function print_summary()
    println("\n📊 QualityPredictor — learned distributions")
    println("─────────────────────────────────────────────────────")
    @printf("%-15s %-18s %6s  %5s  %10s\n", "Agent", "Task Type", "Wins", "Total", "P(success)")
    println("─────────────────────────────────────────────────────")
    for ((agent, task), (s, t)) in sort(collect(_counts), by=x->x[1])
        p = (s + 1.0) / (t + 2.0)
        @printf("%-15s %-18s %6d  %5d  %9.1f%%\n", agent, task, s, t, p * 100)
    end
    println()
end

"""
    validate(log_path) — leave-one-out accuracy validation.

For each record, predicts using all *other* records, then checks if the 
top prediction (p ≥ 0.5 ↔ success) matches actual outcome.
"""
function validate(log_path::String)
    # Load all records first
    records = []
    open(log_path, "r") do fh
        for line in eachline(fh)
            line = strip(line)
            isempty(line) && continue
            task_type = _extract(line, "task_type")
            agent     = _extract(line, "agent")
            success_s = _extract(line, "success")
            (isempty(task_type) || isempty(agent) || isempty(success_s)) && continue
            push!(records, (task_type, agent, success_s == "true"))
        end
    end
    
    correct = 0
    for (i, (task_type, agent, actual)) in enumerate(records)
        # Build counts excluding record i
        empty!(_counts); empty!(_agent_counts); empty!(_task_counts)
        for (j, (tt, ag, ok)) in enumerate(records)
            j == i && continue
            s = ok ? 1 : 0
            key = (ag, tt)
            (ps, pt) = get(_counts, key, (0,0)); _counts[key] = (ps+s, pt+1)
            (as, at) = get(_agent_counts, ag, (0,0)); _agent_counts[ag] = (as+s, at+1)
            (ts, tt2) = get(_task_counts, tt, (0,0)); _task_counts[tt] = (ts+s, tt2+1)
        end
        (p, _) = predict_success(task_type, agent)
        predicted = p >= 0.5
        if predicted == actual; correct += 1; end
    end
    
    acc = correct / length(records) * 100
    println("\n✅ Leave-one-out validation")
    println("   Records : $(length(records))")
    println("   Correct : $correct")
    @printf("   Accuracy: %.1f%%\n\n", acc)
    
    # Reload full model for sample predictions
    load_log(log_path)
end

end  # module QualityPredictor

# ──────────────────────────────────────────────────────────────────────────────
# Script entry point: julia quality-predictor.jl
# ──────────────────────────────────────────────────────────────────────────────
if abspath(PROGRAM_FILE) == @__FILE__
    log_path = joinpath(@__DIR__, "rl-task-execution-log.jsonl")
    
    println("Loading log: $log_path")
    n = QualityPredictor.load_log(log_path)
    println("Loaded $n records.\n")
    
    QualityPredictor.print_summary()
    QualityPredictor.validate(log_path)
    
    println("🔍 Sample predictions:")
    samples = [
        ("code",           "Codex"),
        ("research",       "Scout"),
        ("security",       "Cipher"),
        ("documentation",  "Chronicle"),
        ("analysis",       "Lens"),
        ("code",           "Scout"),      # cross-agent mismatch
        ("research",       "Codex"),      # cross-agent mismatch
        ("brainstorm",     "Veritas"),    # cold-start
    ]
    @printf("%-20s %-12s  %10s  %10s\n", "Task Type", "Agent", "P(success)", "Confidence")
    println("─" ^ 58)
    for (task, agent) in samples
        (p, c) = QualityPredictor.predict_success(task, agent)
        @printf("%-20s %-12s  %9.1f%%  %10s\n", task, agent, p*100, c)
    end
    println()
    
    println("🏆 Best agent per task (from roster):")
    roster = ["Codex","Scout","Cipher","Chronicle","Sentinel","Lens","Veritas","QA","Echo"]
    for task in ["code","research","security","documentation","analysis","brainstorm"]
        (best, p, c) = QualityPredictor.top_agent_for_task(task, roster)
        @printf("  %-18s → %-12s (%.1f%%, %s)\n", task, best, p*100, c)
    end
    println()
end
