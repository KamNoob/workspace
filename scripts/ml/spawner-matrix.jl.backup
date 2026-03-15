#!/usr/bin/env julia
# spawner-matrix.jl
# Fast agent spawner using MatrixRL binary state.

using Dates
using Statistics

const SCRIPT_DIR = @__DIR__
include(joinpath(SCRIPT_DIR, "MatrixRL.jl"))
include(joinpath(SCRIPT_DIR, "kb-integration.jl"))
using .MatrixRL
using .KBIntegration

const RL_STATE_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-state.jld2")
const SPAWN_THRESHOLD = 0.70
const KB_ENABLED = KBIntegration.kb_enabled()

# ─── API ───────────────────────────────────────────────────────────────────

"""
    spawn(task::String, candidates::Vector{String}; use_kb=true) -> Dict

Select best agent for task with optional KB context injection.
"""
function spawn(task::String, candidates::Vector{String}; use_kb::Bool=true)::Dict{String, Any}
    # Load RL state
    rl = try
        MatrixRL.load_state(RL_STATE_PATH)
    catch err
        @error "Cannot load RL state: $err"
        return Dict("error" => "RL state not found")
    end
    
    # Get scores
    all_scores = MatrixRL.get_agent_scores(rl, task)
    candidate_scores = filter(s -> s.agent ∈ candidates, all_scores)
    
    if isempty(candidate_scores)
        return Dict("error" => "No valid candidates for task: $task")
    end
    
    best = candidate_scores[1]
    
    # Decision
    decision = best.q_score >= SPAWN_THRESHOLD ? "spawn" : "escalate"
    confidence = best.q_score >= 0.80 ? "high" : best.q_score >= 0.60 ? "medium" : "low"
    
    # Retrieve KB context if enabled
    kb_context = Dict("found" => false, "count" => 0)
    if use_kb && KB_ENABLED
        kb_context = KBIntegration.get_kb_context(task)
    end
    
    return Dict(
        "agent" => best.agent,
        "task" => task,
        "q_score" => round(best.q_score, digits=4),
        "confidence" => confidence,
        "decision" => decision,
        "candidates" => candidates,
        "kb_context_found" => kb_context["found"],
        "kb_context_entries" => kb_context["count"],
        "kb_context_reason" => kb_context["reason"],
        "timestamp" => string(now()),
    )
end

"""
    log_outcome(task::String, agent::String, success::Bool)

Update Q-value and save state.
"""
function log_outcome(task::String, agent::String, success::Bool)::Dict{String, Any}
    rl = try
        MatrixRL.load_state(RL_STATE_PATH)
    catch err
        @error "Cannot load RL state: $err"
        return Dict("error" => string(err))
    end
    
    reward = success ? 1.0 : 0.0
    q_new = MatrixRL.update_q!(rl, task, agent, reward)
    
    try
        MatrixRL.save_state(rl, RL_STATE_PATH)
    catch err
        @error "Cannot save RL state: $err"
        return Dict("error" => string(err))
    end
    
    return Dict(
        "task" => task,
        "agent" => agent,
        "success" => success,
        "q_new" => round(q_new, digits=4),
        "timestamp" => string(now()),
    )
end

"""
    status() -> Dict

System status.
"""
function status()::Dict{String, Any}
    try
        rl = MatrixRL.load_state(RL_STATE_PATH)
        total_updates = sum(rl.N)
        q_matrix = MatrixRL.get_q_matrix(rl)
        nonzero_q = filter(!iszero, vec(q_matrix))
        if isempty(nonzero_q)
            nonzero_q = [0.0]
        end
        
        agent_best = Dict()
        for agent in MatrixRL.AGENTS
            agent_scores = Float64[]
            for task in MatrixRL.TASKS
                scores = MatrixRL.get_agent_scores(rl, task)
                for s in scores
                    if s.agent == agent
                        push!(agent_scores, s.q_score)
                        break
                    end
                end
            end
            if !isempty(agent_scores)
                agent_best[agent] = round(sum(agent_scores) / length(agent_scores), digits=3)
            else
                agent_best[agent] = 0.5
            end
        end
        
        return Dict(
            "status" => "ok",
            "total_updates" => total_updates,
            "agents" => length(MatrixRL.AGENTS),
            "tasks" => length(MatrixRL.TASKS),
            "q_score_range" => [
                round(minimum(nonzero_q), digits=3),
                round(maximum(q_matrix), digits=3)
            ],
            "agent_avg_q" => agent_best,
            "last_update" => string(rl.last_update),
        )
    catch err
        return Dict("error" => string(err), "status" => "error")
    end
end

# ─── Main ──────────────────────────────────────────────────────────────────

function main()
    if length(ARGS) < 1
        println("Usage: julia spawner-matrix.jl [spawn|log|status] [args...]")
        println("Examples:")
        println("  julia spawner-matrix.jl spawn code Codex,QA,Veritas")
        println("  julia spawner-matrix.jl log code Codex true")
        println("  julia spawner-matrix.jl status")
        return
    end
    
    cmd = ARGS[1]
    
    if cmd == "spawn" && length(ARGS) >= 3
        task = ARGS[2]
        candidates = String.(map(strip, split(ARGS[3], ",")))
        result = spawn(task, candidates)
        for (k, v) in result
            println("$k: $v")
        end
    elseif cmd == "log" && length(ARGS) >= 4
        task = ARGS[2]
        agent = ARGS[3]
        success = lowercase(ARGS[4]) in ("true", "1", "yes")
        result = log_outcome(task, agent, success)
        for (k, v) in result
            println("$k: $v")
        end
    elseif cmd == "status"
        result = status()
        for (k, v) in result
            println("$k: $v")
        end
    else
        println("Unknown command: $cmd")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
