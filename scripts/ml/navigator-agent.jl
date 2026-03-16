"""
navigator-agent.jl
Core Navigator agent for task assignment, sprint management, blocker detection,
resource allocation, and outcome logging (Phase 7B).
"""

module NavigatorAgent

using JSON, Dates

export NavigatorState, TaskAssignment, load_config, initialize_navigator,
       assign_task, get_agent_capacity, log_outcome, escalate_blocker

struct AgentProfile
    name::String
    task_type::String
    q_value::Float64
    capacity_limit::Int
    current_utilization::Int
end

struct TaskAssignment
    task_id::String
    assigned_agent::String
    assigned_at::DateTime
    expected_duration_minutes::Int
    priority::String
    dependencies::Vector{String}
    status::String
end

struct NavigatorState
    agents::Dict{String, AgentProfile}
    active_tasks::Dict{String, TaskAssignment}
    sprint_config::Dict{String, Any}
    execution_log_path::String
end

function load_config(config_path::String)
    if !isfile(config_path)
        return default_config()
    end
    try
        JSON.parsefile(config_path)
    catch e
        @warn "Failed to load config: $e"
        default_config()
    end
end

function default_config()
    Dict(
        "sprint" => Dict(
            "length_hours" => 4,
            "capacity_limit_tasks" => 5,
            "rebalance_threshold" => 0.80,
        ),
        "blockers" => Dict(
            "timeout_minutes" => 30,
            "escalation_enabled" => true,
        ),
    )
end

function initialize_navigator(
    q_scores_path::String,
    execution_log_path::String,
    config_path::String=""
)
    agents = load_agent_profiles(q_scores_path)
    sprint_config = load_config(config_path)
    
    NavigatorState(
        agents,
        Dict{String, TaskAssignment}(),
        sprint_config,
        execution_log_path
    )
end

function load_agent_profiles(q_scores_path::String)
    if !isfile(q_scores_path)
        return default_agents()
    end
    
    try
        data = JSON.parsefile(q_scores_path)
        agents = Dict{String, AgentProfile}()
        
        if haskey(data, "agent_metadata")
            for (agent_name, metadata) in data["agent_metadata"]
                q_value = 0.5
                if haskey(data, "task_types") && haskey(data["task_types"], agent_name)
                    q_value = data["task_types"][agent_name]
                end
                
                agents[agent_name] = AgentProfile(
                    agent_name,
                    get(metadata, "domain", "general"),
                    Float64(q_value),
                    get(metadata, "capacity_per_sprint", 5),
                    get(metadata, "current_tasks", 0)
                )
            end
        end
        
        return isempty(agents) ? default_agents() : agents
    catch
        default_agents()
    end
end

function default_agents()
    Dict(
        "Codex" => AgentProfile("Codex", "code", 0.85, 5, 0),
        "Cipher" => AgentProfile("Cipher", "security", 0.90, 3, 0),
        "Scout" => AgentProfile("Scout", "research", 0.78, 4, 0),
    )
end

function assign_task(
    nav_state::NavigatorState,
    task_id::String,
    task_type::String,
    priority::String="medium"
)
    candidates = filter_agents_by_type(nav_state, task_type)
    
    if isempty(candidates)
        @warn "No agents available for task type: $task_type"
        return nothing
    end
    
    sorted = sort(collect(candidates), by=x -> x[2].q_value, rev=true)
    
    assigned_agent = nothing
    for (agent_name, profile) in sorted
        if profile.current_utilization < profile.capacity_limit
            assigned_agent = agent_name
            break
        end
    end
    
    if isnothing(assigned_agent)
        @warn "No agents with available capacity"
        return nothing
    end
    
    assignment = TaskAssignment(
        task_id,
        assigned_agent,
        now(),
        60,
        priority,
        String[],
        "pending"
    )
    
    nav_state.agents[assigned_agent].current_utilization += 1
    nav_state.active_tasks[task_id] = assignment
    
    return assignment
end

function filter_agents_by_type(nav_state::NavigatorState, task_type::String)
    candidates = Dict{String, AgentProfile}()
    
    for (agent_name, profile) in nav_state.agents
        if task_type == "general" || profile.task_type == task_type
            candidates[agent_name] = profile
        end
    end
    
    return isempty(candidates) ? nav_state.agents : candidates
end

function get_agent_capacity(nav_state::NavigatorState, agent_name::String)
    if !haskey(nav_state.agents, agent_name)
        return nothing
    end
    
    profile = nav_state.agents[agent_name]
    utilization = (profile.current_utilization / profile.capacity_limit) * 100
    available = max(0, profile.capacity_limit - profile.current_utilization)
    
    Dict(
        "agent" => agent_name,
        "capacity_limit" => profile.capacity_limit,
        "utilization" => profile.current_utilization,
        "utilization_percent" => round(utilization; digits=1),
        "available_slots" => available,
    )
end

function log_outcome(nav_state::NavigatorState, task_id::String, agent::String, status::String, duration_ms::Int)
    outcome = Dict(
        "timestamp" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ"),
        "task_id" => task_id,
        "agent" => agent,
        "status" => status,
        "duration_ms" => duration_ms,
        "quality_score" => status == "success" ? 0.85 : 0.3
    )
    
    try
        open(nav_state.execution_log_path, "a") do f
            println(f, JSON.json(outcome))
        end
        return true
    catch e
        @warn "Failed to log outcome: $e"
        return false
    end
end

function escalate_blocker(nav_state::NavigatorState, task_id::String, reason::String)
    @info "ESCALATION: Task $task_id blocked - $reason"
    # In production, this would notify Morpheus
    return true
end

end  # module
