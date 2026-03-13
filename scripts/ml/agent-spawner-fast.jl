#!/usr/bin/env julia
# agent-spawner-fast.jl
# Phase 1 production integration: Real-time Q-learning agent spawning via MatrixRL
#
# Usage (standalone):
#   julia agent-spawner-fast.jl --task code --candidates "Codex,QA,Veritas" --desc "Build login endpoint"
#   julia agent-spawner-fast.jl --log code Codex true
#   julia agent-spawner-fast.jl --status
#
# Usage (in bash):
#   selected=$(julia agent-spawner-fast.jl --task code --candidates "Codex,QA,Veritas" | jq -r .agent)

using Dates
import JSON
import ArgParse

const SCRIPT_DIR = @__DIR__
include(joinpath(SCRIPT_DIR, "MatrixRL.jl"))
using .MatrixRL

# ─── Config ───────────────────────────────────────────────────────────────

const RL_STATE_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-state.jld2")
const RL_JSON_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-agent-selection.json")
const LOG_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-prediction-log.jsonl")
const SPAWN_THRESHOLD = 0.70
const FALLBACK_THRESHOLD = 0.50

# ─── Main API ──────────────────────────────────────────────────────────────

"""
    spawn_with_quality_prediction(task_type, candidates) -> Dict

Select best agent for task from candidates using current Q-values.
Returns decision metadata (agent, q_score, confidence, decision, timestamp).
"""
function spawn_with_quality_prediction(
    task_type::String,
    candidates::Vector{String};
    description::String = ""
)::Dict{String, Any}
    
    timestamp = now()
    
    # Load current RL state
    rl = try
        load_state(RL_STATE_PATH)
    catch err
        @warn "Could not load RL state from $RL_STATE_PATH, creating fresh" err
        RL_State()
    end
    
    # Get scores for candidates
    all_scores = get_agent_scores(rl, task_type)
    candidate_scores = filter(s -> s.agent ∈ candidates, all_scores)
    
    if isempty(candidate_scores)
        return Dict(
            "status" => "error",
            "message" => "No valid candidates",
            "candidates" => candidates,
            "timestamp" => timestamp,
        )
    end
    
    # Select best candidate
    best = candidate_scores[1]
    selected_agent = best.agent
    q_score = best.q_score
    
    # Decision logic
    decision = if q_score >= SPAWN_THRESHOLD
        "spawn"
    elseif q_score >= FALLBACK_THRESHOLD || length(candidates) == 1
        "spawn"
    else
        "escalate"
    end
    
    confidence = if q_score >= 0.80
        "high"
    elseif q_score >= 0.60
        "medium"
    else
        "low"
    end
    
    # Build rationale
    ranked_str = join(
        ["$(s.agent)($(round(s.q_score, digits=2)))" for s in candidate_scores],
        ", "
    )
    rationale = "task=$task_type | ranked: $ranked_str | selected=$selected_agent"
    
    result = Dict(
        "agent" => selected_agent,
        "task" => task_type,
        "q_score" => q_score,
        "confidence" => confidence,
        "decision" => decision,
        "rationale" => rationale,
        "candidates" => candidates,
        "ranked_scores" => [Dict("agent" => s.agent, "q_score" => s.q_score) for s in candidate_scores],
        "timestamp" => timestamp,
        "description" => description,
    )
    
    # Log prediction
    open(LOG_PATH, "a") do io
        println(io, JSON.json(result))
    end
    
    return result
end

"""
    log_outcome(task, agent, success)

Update Q-value based on outcome.
Returns updated Q-score for the (agent, task) pair.
"""
function log_outcome(task::String, agent::String, success::Bool)::Float64
    reward = success ? 1.0 : 0.0
    timestamp = now()
    
    # Load current state
    rl = try
        load_state(RL_STATE_PATH)
    catch err
        @warn "Could not load RL state, creating fresh" err
        RL_State()
    end
    
    # Update Q-value
    q_new = update_q!(rl, task, agent, reward)
    
    # Save updated state
    try
        save_state(rl, RL_STATE_PATH)
    catch err
        @warn "Could not save RL state, falling back to JSON" err
    end
    
    # Log outcome
    log_entry = Dict(
        "timestamp" => timestamp,
        "task" => task,
        "agent" => agent,
        "success" => success,
        "reward" => reward,
        "q_new" => q_new,
    )
    
    open(LOG_PATH, "a") do io
        println(io, JSON.json(log_entry))
    end
    
    return q_new
end

"""
    status_report() -> Dict

Return current RL system status.
"""
function status_report()::Dict{String, Any}
    try
        rl = load_state(RL_STATE_PATH)
        
        # Summary stats
        total_updates = sum(rl.N)
        avg_q = mean(filter(!iszero, rl.Q))
        max_q = maximum(rl.Q)
        min_q = minimum(filter(!iszero, rl.Q))
        
        return Dict(
            "status" => "ok",
            "rl_state_path" => RL_STATE_PATH,
            "total_updates" => total_updates,
            "avg_q_score" => round(avg_q, digits=3),
            "max_q_score" => round(max_q, digits=3),
            "min_q_score" => round(min_q, digits=3),
            "last_update" => string(rl.last_update),
            "hyperparameters" => Dict(
                "alpha" => rl.α,
                "gamma" => rl.γ,
                "lambda" => rl.λ,
                "epsilon" => rl.ε,
            ),
            "agents_count" => length(MatrixRL.AGENTS),
            "tasks_count" => length(MatrixRL.TASKS),
        )
    catch err
        return Dict(
            "status" => "error",
            "message" => string(err),
        )
    end
end

# ─── CLI ───────────────────────────────────────────────────────────────────

function parse_args()
    parser = ArgParse.ArgumentParser()
    
    @add_arg_table! parser begin
        "--task", "-t"
            help = "Task type (code, security, research, etc.)"
            arg_type = String
        "--candidates", "-c"
            help = "Comma-separated agent names (e.g., Codex,QA,Veritas)"
            arg_type = String
        "--desc", "-d"
            help = "Task description (optional)"
            arg_type = String
            default = ""
        "--log", "-l"
            nargs = 3
            help = "Log outcome: --log task agent success (e.g., --log code Codex true)"
            arg_type = String
        "--status", "-s"
            help = "Show system status"
            action = :store_true
    end
    
    return parse_args(parser)
end

function main()
    args = parse_args()
    
    if args["status"]
        result = status_report()
        println(JSON.json(result, 2))
    elseif args["log"] !== nothing
        task, agent, success_str = args["log"]
        success = lowercase(success_str) in ("true", "1", "yes")
        q_new = log_outcome(task, agent, success)
        println(JSON.json(Dict(
            "status" => "logged",
            "task" => task,
            "agent" => agent,
            "success" => success,
            "q_new" => q_new,
        )))
    elseif args["task"] !== nothing
        candidates = split(args["candidates"], ",")
        candidates = map(strip, candidates)
        result = spawn_with_quality_prediction(
            args["task"],
            candidates;
            description = args["desc"]
        )
        println(JSON.json(result))
    else
        println("Usage:")
        println("  julia agent-spawner-fast.jl --task code --candidates Codex,QA,Veritas")
        println("  julia agent-spawner-fast.jl --log code Codex true")
        println("  julia agent-spawner-fast.jl --status")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
