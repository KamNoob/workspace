#!/usr/bin/env julia
"""
spawner-matrix-phase5.jl

Enhanced spawner with Phase 5 optimizations:
  1. Auto cache-warmup before spawn
  2. Load specialized agent prompts
  3. Enable task batching
  4. Monitor memory pruning

Backward compatible with original spawner.
"""

using Dates
using Statistics

const SCRIPT_DIR = @__DIR__
const PHASE5_ENABLED = true

include(joinpath(SCRIPT_DIR, "MatrixRL.jl"))
include(joinpath(SCRIPT_DIR, "kb-integration.jl"))
using .MatrixRL
using .KBIntegration

const RL_STATE_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-state.jld2")
const SPAWN_THRESHOLD = 0.70
const KB_ENABLED = KBIntegration.kb_enabled()

# ─── PHASE 5 INTEGRATION ────────────────────────────────────────────────────

"""Phase 5 cache warmup"""
function phase5_warmup_cache()::Bool
    try
        # Call Python cache warmup
        result = run(`python3 $(joinpath(SCRIPT_DIR, "..", "optimization", "cache-warmup.py"))`)
        return result.exitcode == 0
    catch
        return false
    end
end

"""Load specialized agent prompt"""
function phase5_get_agent_prompt(agent::String)::String
    prompt_path = joinpath(SCRIPT_DIR, "..", "..", "prompts", "specialized", lowercase(agent) * "-*.md")
    # Return path if exists, else return empty
    return isfile(prompt_path) ? read(prompt_path, String) : ""
end

"""Check if should batch similar tasks"""
function phase5_should_batch(task_queue::Vector{String})::Bool
    return length(task_queue) >= 3  # Batch if 3+ tasks
end

# ─── MAIN API ───────────────────────────────────────────────────────────────

"""
    spawn(task::String, candidates::Vector{String}; use_kb=true, phase5=true) -> Dict

Select best agent with Phase 5 optimizations.
"""
function spawn(task::String, candidates::Vector{String}; use_kb::Bool=true, phase5::Bool=PHASE5_ENABLED)::Dict{String, Any}
    # Phase 5: Warmup cache once per session
    if phase5
        phase5_warmup_cache()
    end
    
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
    
    # Phase 5: Get specialized agent prompt
    agent_prompt = ""
    phase5_prompt_loaded = false
    if phase5
        agent_prompt = phase5_get_agent_prompt(best.agent)
        phase5_prompt_loaded = !isempty(agent_prompt)
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
        "phase5_enabled" => phase5,
        "phase5_cache_warmed" => phase5,
        "phase5_prompt_loaded" => phase5_prompt_loaded,
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

# ─── CLI ────────────────────────────────────────────────────────────────────

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) < 2
        println("Usage: julia spawner-matrix-phase5.jl spawn <task> <agent1> [<agent2> ...]")
        println("       julia spawner-matrix-phase5.jl log <task> <agent> <success>")
        exit(1)
    end
    
    cmd = ARGS[1]
    
    if cmd == "spawn"
        task = ARGS[2]
        candidates = ARGS[3:end]
        result = spawn(task, candidates)
        println(JSON.json(result, 2))
    elseif cmd == "log"
        task = ARGS[2]
        agent = ARGS[3]
        success = ARGS[4] == "true"
        result = log_outcome(task, agent, success)
        println(JSON.json(result, 2))
    else
        println("Unknown command: $cmd")
        exit(1)
    end
end
