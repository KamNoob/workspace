#!/usr/bin/env julia
# task-planner-mcts.jl
# Monte Carlo Tree Search for task sequence planning
# Find optimal agent strategy for likely future task paths

using Dates
using Statistics
using Serialization

# ─── MCTS Node & Tree ────────────────────────────────────────────────────

"""
    MCTSNode

Represents a state in the task sequence planning tree.
state = (current_task, depth)
"""
mutable struct MCTSNode
    task::String
    depth::Int
    visits::Int
    value::Float64  # Accumulated reward
    children::Dict{String, MCTSNode}  # next_task → child node
    parent::Union{MCTSNode, Nothing}
end

function MCTSNode(task::String, depth::Int)
    return MCTSNode(task, depth, 0, 0.0, Dict(), nothing)
end

"""
    TaskPlannerMCTS

Monte Carlo Tree Search for agent-task planning.
"""
mutable struct TaskPlannerMCTS
    root::MCTSNode
    task_transitions::Dict{String, Dict{String, Float64}}  # P(next_task | current_task)
    agent_success::Dict{Tuple{String, String}, Float64}    # P(success | task, agent)
    max_depth::Int
    num_simulations::Int
    exploration_constant::Float64  # UCB1 constant
    created::DateTime
end

function TaskPlannerMCTS(start_task::String; max_depth=5, num_sims=1000, c=1.414)
    return TaskPlannerMCTS(
        MCTSNode(start_task, 0),
        Dict(),
        Dict(),
        max_depth,
        num_sims,
        c,
        now()
    )
end

# ─── MCTS Algorithm ────────────────────────────────────────────────────────

"""
    ucb1(node::MCTSNode, c::Float64) -> Float64

Upper Confidence Bound for exploration vs exploitation.
"""
function ucb1(node::MCTSNode, parent_visits::Int, c::Float64)::Float64
    if node.visits == 0
        return Inf  # Unvisited nodes have infinite UCB
    end
    
    exploitation = node.value / node.visits
    exploration = c * sqrt(log(parent_visits) / node.visits)
    
    return exploitation + exploration
end

"""
    select_child(node::MCTSNode, c::Float64) -> MCTSNode

Select best child using UCB1.
"""
function select_child(node::MCTSNode, c::Float64)::MCTSNode
    if isempty(node.children)
        return node
    end
    
    best_child = nothing
    best_ucb = -Inf
    
    for (_, child) in node.children
        u = ucb1(child, node.visits, c)
        if u > best_ucb
            best_ucb = u
            best_child = child
        end
    end
    
    return best_child
end

"""
    expand(node::MCTSNode, transitions::Dict)

Create child nodes for unexplored next tasks.
"""
function expand(node::MCTSNode, transitions::Dict)
    if haskey(transitions, node.task)
        next_tasks = transitions[node.task]
        
        for (next_task, prob) in next_tasks
            if !haskey(node.children, next_task)
                child = MCTSNode(next_task, node.depth + 1)
                child.parent = node
                node.children[next_task] = child
            end
        end
    end
    
    return node
end

"""
    simulate(task::String, agent_success::Dict, depth::Int, max_depth::Int) -> Float64

Random rollout from this state to estimate reward.
"""
function simulate(task::String, agent_success::Dict, depth::Int, max_depth::Int)::Float64
    if depth >= max_depth
        return 0.0  # Terminal state
    end
    
    # Pick a random agent for this task (weighted by historical success)
    agents = ["Codex", "Scout", "Cipher", "Veritas", "QA", "Sentinel", "Chronicle", "Lens", "Echo", "Prism", "Navigator"]
    
    best_agent_prob = 0.5
    for agent in agents
        key = (task, agent)
        if haskey(agent_success, key)
            prob = agent_success[key]
            best_agent_prob = max(best_agent_prob, prob)
        end
    end
    
    # Reward: success probability
    return best_agent_prob
end

"""
    tree_search(planner::TaskPlannerMCTS) -> Vector{String}

Run MCTS: return sequence of recommended tasks.
"""
function tree_search(planner::TaskPlannerMCTS)::Vector{String}
    println("🌳 Running Monte Carlo Tree Search...")
    println("   Simulations: $(planner.num_simulations)")
    println("   Max depth: $(planner.max_depth)")
    
    # Run simulations
    for sim in 1:planner.num_simulations
        node = planner.root
        
        # Selection & Expansion
        while node.depth < planner.max_depth && !isempty(node.children)
            node = select_child(node, planner.exploration_constant)
        end
        
        # Expand if possible
        if node.depth < planner.max_depth
            expand(node, planner.task_transitions)
            
            if !isempty(node.children)
                # Pick random child
                node = collect(values(node.children))[rand(1:length(node.children))]
            end
        end
        
        # Simulation (rollout)
        reward = simulate(node.task, planner.agent_success, node.depth, planner.max_depth)
        
        # Backpropagation
        while node !== nothing
            node.visits += 1
            node.value += reward
            node = node.parent
        end
        
        if sim % max(1, div(planner.num_simulations, 10)) == 0
            println("   Progress: $sim / $(planner.num_simulations)")
        end
    end
    
    # Extract best path
    path = [planner.root.task]
    node = planner.root
    
    while node.depth < planner.max_depth && !isempty(node.children)
        # Pick best child by visits (most visits = most promising)
        best_child = nothing
        max_visits = -1
        for child in values(node.children)
            if child.visits > max_visits
                max_visits = child.visits
                best_child = child
            end
        end
        
        if best_child !== nothing
            push!(path, best_child.task)
            node = best_child
        else
            break
        end
    end
    
    return path
end

# ─── File I/O ──────────────────────────────────────────────────────────────

function save_planner(planner::TaskPlannerMCTS, path::String)
    open(path, "w") do io
        serialize(io, planner)
    end
end

function load_planner(path::String)::TaskPlannerMCTS
    open(path, "r") do io
        return deserialize(io)::TaskPlannerMCTS
    end
end

# ─── Main ──────────────────────────────────────────────────────────────────

function load_task_transitions()
    model_path = joinpath(@__DIR__, "..", "..", "data", "rl", "task-transitions.jld2")
    
    if !isfile(model_path)
        @warn "Task transitions not found"
        return Dict()
    end
    
    try
        open(model_path, "r") do io
            model = deserialize(io)
            return model.transitions
        end
    catch err
        @warn "Failed to load transitions: $err"
        return Dict()
    end
end

function load_agent_success()
    model_path = joinpath(@__DIR__, "..", "..", "data", "rl", "outcome-confidence.jld2")
    
    if !isfile(model_path)
        @warn "Outcome model not found, using defaults"
        return Dict()
    end
    
    try
        open(model_path, "r") do io
            model = deserialize(io)
            return model.point_estimate
        end
    catch err
        @warn "Failed to load outcome model: $err"
        return Dict()
    end
end

function main()
    println("╔════════════════════════════════════════════════════════╗")
    println("║ Task Planner: Monte Carlo Tree Search                  ║")
    println("╚════════════════════════════════════════════════════════╝\n")
    
    if length(ARGS) < 1
        println("Usage:")
        println("  julia task-planner-mcts.jl plan code       # Plan from 'code' task")
        println("  julia task-planner-mcts.jl plan research 5 # Plan, max 5 steps")
        return
    end
    
    cmd = ARGS[1]
    
    if cmd == "plan" && length(ARGS) >= 2
        start_task = ARGS[2]
        max_depth = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 5
        
        println("📖 Loading task transitions...")
        transitions = load_task_transitions()
        
        println("📖 Loading agent success rates...")
        agent_success = load_agent_success()
        
        if isempty(transitions)
            println("⚠️  No transitions available, using sample data")
            transitions = Dict(
                "code" => Dict("research" => 0.5, "security" => 0.3, "test" => 0.2),
                "research" => Dict("code" => 0.6, "security" => 0.4),
                "security" => Dict("code" => 0.5, "test" => 0.5)
            )
        end
        
        # Run MCTS
        planner = TaskPlannerMCTS(start_task, max_depth=max_depth, num_sims=1000)
        planner.task_transitions = transitions
        planner.agent_success = agent_success
        
        path = tree_search(planner)
        
        println("\n✅ Recommended task sequence:\n")
        for (i, task) in enumerate(path)
            if i == 1
                println("   ▶ $task (start)")
            else
                println("   → $task")
            end
        end
        
        println("\n💡 Interpretation:")
        println("   This sequence has highest expected success")
        println("   based on $(planner.num_simulations) Monte Carlo simulations")
        
    else
        println("Unknown command: $cmd")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
