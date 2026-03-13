#!/usr/bin/env julia
# MatrixRL.jl
# Fast matrix-based Q-learning engine for agent selection.
# Uses Julia's native Serialization module (stdlib, no dependencies).

module MatrixRL

using Dates
using Serialization

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

Fields:
- `Q::Matrix{Float64}` — 11×9 Q-values
- `N::Matrix{Int}` — Visit counts
- `α::Float64` — Learning rate
- `γ::Float64` — Discount factor
- `λ::Float64` — Eligibility trace decay
- `ε::Float64` — Exploration rate
- `last_update::DateTime` — When Q-values were last changed
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

"""
    update_q!(rl::RL_State, task::String, agent::String, reward::Float64)

Update Q-value for (agent, task) pair using standard Q-learning.
"""
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

"""
    get_agent_scores(rl::RL_State, task::String)

Return sorted scores for all agents on a given task.
"""
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

"""
    best_agent_for_task(rl::RL_State, task::String)

Return the single best agent (highest Q-value) for a task.
"""
function best_agent_for_task(rl::RL_State, task::String)
    scores = get_agent_scores(rl, task)
    return scores[1]
end

"""
    get_q_matrix(rl::RL_State) -> Matrix{Float64}

Export Q-matrix for inspection/analysis.
"""
function get_q_matrix(rl::RL_State)::Matrix{Float64}
    return copy(rl.Q)
end

# ─── Serialization ────────────────────────────────────────────────────────

"""
    save_state(rl::RL_State, path::String)

Save RL_State to binary file using Julia's Serialization module.
"""
function save_state(rl::RL_State, path::String)
    open(path, "w") do io
        serialize(io, rl)
    end
end

"""
    load_state(path::String) -> RL_State

Load RL_State from binary file.
"""
function load_state(path::String)::RL_State
    open(path, "r") do io
        deserialize(io)::RL_State
    end
end

# ─── JSON Import (for migration) ──────────────────────────────────────────

"""
    load_from_old_json(json_data::Dict)

Convert old JSON format to RL_State (used by migration).
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

export load_from_old_json

end  # module
