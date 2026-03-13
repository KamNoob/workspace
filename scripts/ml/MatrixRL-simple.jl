#!/usr/bin/env julia
# MatrixRL-simple.jl
# Fast matrix-based Q-learning without external dependencies.
# Uses only JLD2 (standard library since Julia 1.6).

module MatrixRL

using Dates

export RL_State, update_q!, save_state, load_state,
       get_agent_scores, best_agent_for_task, get_q_matrix

# ─── Constants ─────────────────────────────────────────────────────────────
const AGENTS = [
    "Codex", "Cipher", "Scout", "Chronicle", "Sentinel", 
    "Lens", "Echo", "Veritas", "QA", "Prism", "Navigator"
]

const TASKS = [
    "code", "security", "research", "docs", "test", 
    "data", "review", "infra", "planning"
]

const N_AGENTS = length(AGENTS)
const N_TASKS = length(TASKS)

# ─── RL State ──────────────────────────────────────────────────────────────

"""
    RL_State

Mutable struct holding the complete RL system state.
"""
mutable struct RL_State
    Q::Matrix{Float64}
    N::Matrix{Int}
    α::Float64
    γ::Float64
    λ::Float64
    ε::Float64
    last_update::DateTime
end

"""
    RL_State(; α=0.02, γ=0.99, λ=0.9, ε=0.15)

Initialize fresh RL_State with zero Q-values.
"""
function RL_State(; α=0.02, γ=0.99, λ=0.9, ε=0.15)
    Q = zeros(N_AGENTS, N_TASKS)
    N = zeros(Int, N_AGENTS, N_TASKS)
    return RL_State(Q, N, α, γ, λ, ε, now())
end

# ─── Core Functions ───────────────────────────────────────────────────────

function agent_index(agent_name::String)::Int
    idx = findfirst(==(agent_name), AGENTS)
    isnothing(idx) && error("Unknown agent: $agent_name")
    return idx
end

function task_index(task_name::String)::Int
    idx = findfirst(==(task_name), TASKS)
    isnothing(idx) && error("Unknown task: $task_name")
    return idx
end

function update_q!(rl::RL_State, task::String, agent::String, reward::Float64)
    a_idx = agent_index(agent)
    t_idx = task_index(task)
    
    q_old = rl.Q[a_idx, t_idx]
    max_q_next = maximum(rl.Q[:, t_idx])
    q_new = q_old + rl.α * (reward + rl.γ * max_q_next - q_old)
    
    rl.Q[a_idx, t_idx] = q_new
    rl.N[a_idx, t_idx] += 1
    rl.last_update = now()
    
    return q_new
end

function get_agent_scores(rl::RL_State, task::String)
    t_idx = task_index(task)
    
    scores = [
        (
            agent = AGENTS[a_idx],
            q_score = rl.Q[a_idx, t_idx],
            visits = rl.N[a_idx, t_idx]
        )
        for a_idx in 1:N_AGENTS
    ]
    
    return sort(scores, by=x -> x.q_score, rev=true)
end

function best_agent_for_task(rl::RL_State, task::String)
    scores = get_agent_scores(rl, task)
    return scores[1]
end

function get_q_matrix(rl::RL_State)::Matrix{Float64}
    return copy(rl.Q)
end

# ─── Serialization ────────────────────────────────────────────────────────

function save_state(rl::RL_State, path::String)
    try
        using JLD2
        @save path rl
    catch err
        @error "Failed to save RL state: $err"
        rethrow(err)
    end
end

function load_state(path::String)::RL_State
    try
        using JLD2
        @load path rl
        return rl
    catch err
        @error "Failed to load RL state: $err"
        rethrow(err)
    end
end

# ─── JSON Import/Export (helper for migration) ─────────────────────────────

"""
    load_from_old_json(json_data::Dict)

Convert old JSON format to RL_State.
Used by migration script.
"""
function load_from_old_json(json_data::Dict)::RL_State
    rl = RL_State()
    task_types = get(json_data, "task_types", Dict())
    
    for (t_idx, task) in enumerate(TASKS)
        if haskey(task_types, task)
            agents_dict = get(task_types[task], "agents", Dict())
            
            for (a_idx, agent) in enumerate(AGENTS)
                if haskey(agents_dict, agent)
                    agent_data = agents_dict[agent]
                    rl.Q[a_idx, t_idx] = get(agent_data, "q_score", 0.0)
                    rl.N[a_idx, t_idx] = get(agent_data, "total_uses", 0)
                end
            end
        end
    end
    
    return rl
end

end  # module
