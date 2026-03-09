#!/usr/bin/env julia
# agent-spawner-qp.jl
# Phase 2a — Production integration: QualityPredictor → agent spawning pipeline
#
# Provides:
#   spawn_with_quality_prediction(task_type, candidates, task_desc) -> NamedTuple
#   log_prediction(...)
#   log_outcome(timestamp, actual_success)
#   roi_report()
#
# Invocation (standalone):
#   julia agent-spawner-qp.jl --task code --candidates "Codex,QA,Veritas" --desc "Build login endpoint"
#   julia agent-spawner-qp.jl --roi
#
# No external dependencies.

# ── Load QualityPredictor ─────────────────────────────────────────────────
const SCRIPT_DIR = @__DIR__
include(joinpath(SCRIPT_DIR, "QualityPredictor.jl"))
using .QualityPredictor

using Dates
using Printf

# ── Config ────────────────────────────────────────────────────────────────
const LOG_FILE = joinpath(SCRIPT_DIR, "..", "..", "rl-prediction-log.jsonl")
const SPAWN_THRESHOLD      = 0.70   # auto-spawn if prob >= this
const FALLBACK_THRESHOLD   = 0.50   # allow spawn if only one candidate

# ─────────────────────────────────────────────────────────────────────────
# Core API
# ─────────────────────────────────────────────────────────────────────────

"""
    spawn_with_quality_prediction(task_type, candidates, task_desc) -> NamedTuple

Select the best agent for `task_type` from `candidates`, apply decision logic,
log the prediction, and return a structured result.

Decision logic:
  • prob >= 0.70  → spawn (high confidence)
  • prob >= 0.50 AND length(candidates) == 1 → spawn (only option)
  • otherwise     → escalate (human review recommended)

Returns:
  (selected_agent, prob, confidence, decision, rationale, timestamp)
"""
function spawn_with_quality_prediction(
    task_type::AbstractString,
    candidates::Vector{String},
    task_desc::AbstractString = ""
)
    ts = string(now(UTC))

    # ── Score via QualityPredictor
    score = top_agent_for_task(task_type, candidates)

    # ── Decision logic
    n = length(candidates)
    if score.prob >= SPAWN_THRESHOLD
        decision = :spawn
        decision_reason = "prob $(round(score.prob, digits=2)) >= threshold $(SPAWN_THRESHOLD)"
    elseif score.prob >= FALLBACK_THRESHOLD && n == 1
        decision = :spawn
        decision_reason = "single candidate, prob $(round(score.prob, digits=2)) >= fallback $(FALLBACK_THRESHOLD)"
    else
        decision = :escalate
        decision_reason = "prob $(round(score.prob, digits=2)) below thresholds (n=$(n) candidates)"
    end

    rationale = "$(score.rationale) | decision=$(decision): $(decision_reason)"

    # ── Log prediction (actual_success = null until outcome known)
    log_prediction(ts, task_type, candidates, score.agent, score.prob, score.confidence)

    return (
        selected_agent = score.agent,
        prob           = score.prob,
        confidence     = score.confidence,
        decision       = decision,
        rationale      = rationale,
        timestamp      = ts,
    )
end

# ─────────────────────────────────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────────────────────────────────

"""
    log_prediction(timestamp, task_type, candidates, selected_agent, prob, confidence)

Append a JSONL record to rl-prediction-log.jsonl.
actual_success is initialised to null; update with log_outcome/2.
"""
function log_prediction(
    timestamp::AbstractString,
    task_type::AbstractString,
    candidates::Vector{String},
    selected_agent::AbstractString,
    prob::Float64,
    confidence::Symbol,
)
    mkpath(dirname(LOG_FILE))
    cand_json = "[" * join(["\"$(c)\"" for c in candidates], ",") * "]"
    record = """{"timestamp":"$(timestamp)","task_type":"$(task_type)","candidates":$(cand_json),"selected_agent":"$(selected_agent)","prob":$(round(prob, digits=4)),"confidence":"$(confidence)","actual_success":null}"""

    open(LOG_FILE, "a") do io
        println(io, record)
    end
end

"""
    log_outcome(timestamp, actual_success)

Update the most recent log entry matching `timestamp` with the actual outcome.
Rewrites the log file in place (small file; acceptable overhead).
"""
function log_outcome(timestamp::AbstractString, actual_success::Bool)
    !isfile(LOG_FILE) && return

    lines = readlines(LOG_FILE)
    updated = map(lines) do line
        if occursin("\"timestamp\":\"$(timestamp)\"", line) && occursin("\"actual_success\":null", line)
            replace(line, "\"actual_success\":null" => "\"actual_success\":$(actual_success ? "true" : "false")")
        else
            line
        end
    end

    open(LOG_FILE, "w") do io
        for l in updated
            println(io, l)
        end
    end
end

# ─────────────────────────────────────────────────────────────────────────
# ROI / Analytics
# ─────────────────────────────────────────────────────────────────────────

"""
    roi_report()

Parse rl-prediction-log.jsonl and print:
  • Total predictions
  • Success rate (where actual_success != null)
  • Success rate by confidence tier
  • Top agents selected
"""
function roi_report()
    !isfile(LOG_FILE) && (println("No log file found at $(LOG_FILE)"); return)

    lines = filter(!isempty, readlines(LOG_FILE))
    isempty(lines) && (println("Log file is empty."); return)

    total        = length(lines)
    with_outcome = 0
    successes    = 0
    conf_stats   = Dict("high"=>Dict("total"=>0,"success"=>0),
                        "medium"=>Dict("total"=>0,"success"=>0),
                        "low"=>Dict("total"=>0,"success"=>0))
    agent_counts = Dict{String,Int}()

    for line in lines
        # Extract fields with simple string matching
        m_conf  = match(r"\"confidence\":\"([^\"]+)\"", line)
        m_agent = match(r"\"selected_agent\":\"([^\"]+)\"", line)
        m_succ  = match(r"\"actual_success\":([^,}]+)", line)
        
        conf = m_conf !== nothing ? m_conf.captures[1] : "unknown"
        agent = m_agent !== nothing ? m_agent.captures[1] : "unknown"
        
        if m_succ !== nothing && m_succ.captures[1] != "null"
            with_outcome += 1
            success = m_succ.captures[1] == "true"
            successes += success ? 1 : 0
            conf_stats[conf]["total"] += 1
            conf_stats[conf]["success"] += success ? 1 : 0
        end
        
        agent_counts[agent] = get(agent_counts, agent, 0) + 1
    end

    println("\n📊 Quality Prediction ROI Report")
    println("=" ^ 70)
    println("Total predictions : $total")
    println("With outcomes    : $with_outcome")
    if with_outcome > 0
        acc = successes / with_outcome * 100
        println("Success rate     : $(successes)/$with_outcome  ($(@sprintf("%.1f", acc))%)")
        println()
        println("By confidence tier:")
        println("─" ^ 70)
        for conf in ["high", "medium", "low"]
            stat = conf_stats[conf]
            if stat["total"] > 0
                rate = stat["success"] / stat["total"] * 100
                println("  $conf\t\t$(stat["success"])/$(stat["total"])  ($(@sprintf("%.1f", rate))%)")
            else
                println("  $conf\t\t(no data)")
            end
        end
    else
        println("(No outcomes recorded yet)")
    end

    println()
    println("Top agents selected:")
    println("─" ^ 70)
    sorted_agents = sort(collect(agent_counts), by=x->x[2], rev=true)[1:min(5, length(agent_counts))]
    for (agent, count) in sorted_agents
        println("  $agent\t\t$count selections")
    end
    println()
end

# ─────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────

function main()
    args = ARGS
    isempty(args) && (println("Usage: julia agent-spawner-qp.jl --task <type> --candidates <agents>"); return)

    if "--help" in args || "-h" in args
        println("Usage:")
        println("  julia agent-spawner-qp.jl --task <type> --candidates <agents>")
        println("  julia agent-spawner-qp.jl --log-outcome <timestamp> true|false")
        println("  julia agent-spawner-qp.jl --roi")
        println()
        println("Examples:")
        println("  julia agent-spawner-qp.jl --task code --candidates 'Codex,QA,Veritas'")
        println("  julia agent-spawner-qp.jl --roi")
        return
    end

    if "--roi" in args
        roi_report()
        return
    end

    if "--log-outcome" in args
        idx = findfirst(x->x=="--log-outcome", args)
        ts = args[idx+1]
        success = args[idx+2] == "true"
        log_outcome(ts, success)
        println("Outcome logged: timestamp=$(ts), success=$(success)")
        return
    end

    # Parse --task and --candidates
    task_idx = findfirst(x->x=="--task", args)
    cand_idx = findfirst(x->x=="--candidates", args)
    desc_idx = findfirst(x->x=="--desc", args)

    task_idx === nothing && error("--task required")
    cand_idx === nothing && error("--candidates required")

    task_type = args[task_idx+1]
    candidates = String.(split(args[cand_idx+1], ",") .|> strip)
    task_desc = desc_idx !== nothing ? args[desc_idx+1] : ""

    result = spawn_with_quality_prediction(task_type, candidates, task_desc)

    println("Selected: $(result.selected_agent)")
    println("  Probability: $(round(result.prob, digits=3))")
    println("  Confidence: $(result.confidence)")
    println("  Decision: $(result.decision)")
    println("  Timestamp: $(result.timestamp)")
    println()
    println("Rationale:")
    println("  $(result.rationale)")

    if result.decision == :spawn
        exit(0)
    else
        exit(2)  # Escalate exit code
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
