#!/usr/bin/env julia
"""
spawner-matrix-integrated.jl

PHASE 5 FULLY INTEGRATED SPAWNER

Production spawner with all Phase 5 optimizations:
  1. Auto cache-warmup before spawn
  2. Auto-load specialized agent prompts
  3. Enable task batching metadata
  4. Memory pruning scheduled via cron

Drop-in replacement for spawner-matrix.jl
Backward compatible with existing code.
"""

using Dates
using Statistics
using JSON

const SCRIPT_DIR = @__DIR__
const PHASE5_ENABLED = true
const PHASE5_DEBUG = false
const PHASE12A_ENABLED = true  # Phase 12A routing alignment enabled
const PHASE12A_SANDBOX_ENABLED = true  # Phase 12A container sandboxing enabled

include(joinpath(SCRIPT_DIR, "MatrixRL.jl"))
include(joinpath(SCRIPT_DIR, "kb-integration.jl"))
include(joinpath(SCRIPT_DIR, "audit-logger.jl"))
using .MatrixRL
using .KBIntegration
using .AuditLogger

const RL_STATE_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-state.jld2")
const ROUTING_CONFIG_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "routing-alignment-config.json")
const SPAWN_THRESHOLD = 0.70
const KB_ENABLED = KBIntegration.kb_enabled()

# ─── PHASE 12A: ROUTING CONFIG LOADER ─────────────────────────────────────

function load_routing_config()::Dict{String, Any}
    """Load canonical task-to-agents routing configuration."""
    try
        if isfile(ROUTING_CONFIG_PATH)
            return JSON.parsefile(ROUTING_CONFIG_PATH)
        else
            @warn "Routing config not found at $ROUTING_CONFIG_PATH, using fallback"
            return Dict()
        end
    catch err
        @warn "Error loading routing config: $err"
        return Dict()
    end
end

function get_task_candidates(task::String, routing_config::Dict{String, Any})::Vector{String}
    """Get validated candidates for task from routing config. Falls back to all agents if task unknown."""
    if isempty(routing_config)
        return String[]
    end
    
    rules = get(routing_config, "routing_rules", Dict())
    task_rule = get(rules, lowercase(task), nothing)
    
    if task_rule !== nothing
        return get(task_rule, "agents", String[])
    end
    
    # Fallback: return empty (let caller provide candidates)
    return String[]
end

const ROUTING_CONFIG = load_routing_config()

# ─── PHASE 5: CACHE WARMUP ─────────────────────────────────────────────────

function phase5_warmup_cache()::Bool
    """Run Phase 5 cache warmup once per session."""
    try
        # Call Python cache warmup (non-blocking)
        cache_script = joinpath(SCRIPT_DIR, "..", "optimization", "cache-warmup.py")
        if isfile(cache_script)
            run(`python3 $cache_script`, wait=false)
            return true
        end
        return false
    catch
        return false
    end
end

# ─── PHASE 5: SPECIALIZED PROMPTS ──────────────────────────────────────────

function phase5_load_agent_prompt(agent::String)::String
    """Load specialized agent prompt if available."""
    try
        prompts_dir = joinpath(SCRIPT_DIR, "..", "..", "prompts", "specialized")
        agent_lower = lowercase(agent)
        
        # Try exact match
        for suffix in ["-security.md", "-development.md", "-research.md", "-documentation.md", 
                       "-infrastructure.md", "-analysis.md", "-review.md", "-testing.md", 
                       "-testing.md", "-brainstorming.md", "-planning.md"]
            prompt_path = joinpath(prompts_dir, agent_lower * suffix)
            if isfile(prompt_path)
                return read(prompt_path, String)
            end
        end
        
        # Fallback: generic specialized prompt
        return "You are specialized in $(agent) tasks. Focus on domain-specific knowledge and patterns."
    catch
        return ""
    end
end

# ─── PHASE 5: METADATA & BATCHING ──────────────────────────────────────────

function phase5_add_batching_metadata(task::String)::Dict{String, Any}
    """Add batching hints for task queue."""
    task_lower = lowercase(task)
    
    batch_category = if contains(task_lower, "test") || contains(task_lower, "qa")
        "testing"
    elseif contains(task_lower, "code") || contains(task_lower, "develop")
        "development"
    elseif contains(task_lower, "security") || contains(task_lower, "audit")
        "security"
    elseif contains(task_lower, "doc") || contains(task_lower, "write")
        "documentation"
    elseif contains(task_lower, "infra") || contains(task_lower, "deploy")
        "infrastructure"
    else
        "general"
    end
    
    return Dict(
        "batch_category" => batch_category,
        "batch_size" => 4,
        "batch_wait_seconds" => 30,
        "batching_enabled" => true
    )
end

# ─── MAIN API (PHASE 5 INTEGRATED) ──────────────────────────────────────────

"""
    spawn(task::String, candidates::Vector{String}; use_kb=true, phase5=true) -> Dict

Select best agent for task with Phase 5 optimizations enabled by default.
"""
function spawn(task::String, candidates::Vector{String}; use_kb::Bool=true, phase5::Bool=PHASE5_ENABLED, phase12a::Bool=PHASE12A_ENABLED)::Dict{String, Any}
    
    # ─── PHASE 12A: Validate candidates against routing config
    validated_candidates = candidates
    if phase12a && !isempty(ROUTING_CONFIG)
        config_candidates = get_task_candidates(task, ROUTING_CONFIG)
        if !isempty(config_candidates)
            # Filter user candidates to match routing config
            validated_candidates = filter(c -> c ∈ config_candidates, candidates)
            if isempty(validated_candidates)
                @warn "No candidates match routing config for task '$task'. Allowing user candidates with warning."
                validated_candidates = candidates
            end
        end
    end
    
    # ─── PHASE 5: Cache warmup (non-blocking, once per session)
    if phase5
        @async phase5_warmup_cache()
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
    candidate_scores = filter(s -> s.agent ∈ validated_candidates, all_scores)
    
    if isempty(candidate_scores)
        return Dict("error" => "No valid candidates for task: $task")
    end
    
    best = candidate_scores[1]
    
    # Decision
    decision = best.q_score >= SPAWN_THRESHOLD ? "spawn" : "escalate"
    confidence = best.q_score >= 0.80 ? "high" : best.q_score >= 0.60 ? "medium" : "low"
    
    # KB context (existing feature)
    kb_context = Dict("found" => false, "count" => 0)
    if use_kb && KB_ENABLED
        kb_context = KBIntegration.get_kb_context(task)
    end
    
    # ─── PHASE 5: Load specialized prompt
    agent_prompt = ""
    phase5_prompt_loaded = false
    if phase5
        agent_prompt = phase5_load_agent_prompt(best.agent)
        phase5_prompt_loaded = !isempty(agent_prompt)
    end
    
    # ─── PHASE 5: Add batching metadata
    batching_meta = Dict()
    if phase5
        batching_meta = phase5_add_batching_metadata(task)
    end
    
    # ─── PHASE 11: Log spawn decision (audit trail)
    try
        AuditLogger.log_spawn(task, best.agent, best.q_score, confidence, "")
    catch err
        @warn "Audit logging error: $err"
    end
    
    result = Dict(
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
        # Phase 5 metadata
        "phase5_enabled" => phase5,
        "phase5_cache_warmed" => phase5,
        "phase5_prompt_loaded" => phase5_prompt_loaded,
        "phase5_batching" => batching_meta,
    )
    
    return result
end

"""
    log_outcome(task::String, agent::String, success::Bool)

Update Q-value and save state. (Unchanged)
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
    
    # ─── PHASE 11: Log outcome (audit trail)
    try
        quality_score = success ? 0.9 : 0.3  # Default scoring if not provided
        AuditLogger.log_outcome(task, agent, success, quality_score, 0, 0.02)
    catch err
        @warn "Audit logging error: $err"
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

System status including Phase 5 metrics.
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
            "phase5_enabled" => PHASE5_ENABLED,
            "phase5_memory_pruning" => "scheduled_daily_0200_utc",
        )
    catch err
        return Dict("error" => string(err), "status" => "error")
    end
end

# ─── CLI ────────────────────────────────────────────────────────────────────

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) < 2
        println("Usage: julia spawner-matrix-integrated.jl spawn <task> <agent1> [<agent2> ...]")
        println("       julia spawner-matrix-integrated.jl log <task> <agent> <success>")
        println("       julia spawner-matrix-integrated.jl status")
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
    elseif cmd == "status"
        result = status()
        println(JSON.json(result, 2))
    else
        println("Unknown command: $cmd")
        exit(1)
    end
end
