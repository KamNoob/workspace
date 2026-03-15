#!/usr/bin/env julia
using JSON
using Dates

println("\n" * "="^70)
println("PHASE 3: Q-Learning Model Retraining")
println("="^70 * "\n")

# Load outcomes
outcomes = Dict[]
open("data/rl/rl-task-execution-log.jsonl") do f
    for line in eachline(f)
        isempty(strip(line)) && continue
        try
            push!(outcomes, JSON.parse(line))
        catch
        end
    end
end

println("✓ Loaded $(length(outcomes)) Phase 2b outcomes\n")

# Calculate success rates
agent_stats = Dict()
for outcome in outcomes
    agent = get(outcome, "agent", "Codex")
    success = get(outcome, "success", false)
    
    if !haskey(agent_stats, agent)
        agent_stats[agent] = (0, 0)  # (success, total)
    end
    s, t = agent_stats[agent]
    agent_stats[agent] = (s + (success ? 1 : 0), t + 1)
end

println("Agent Performance:\n")
for (agent, (succ, total)) in sort(collect(agent_stats), by=x->x[2][1]/x[2][2], rev=true)
    println("$agent: $succ/$total = $(round(100*succ/total, digits=1))%")
end

# Load and convert JSON to pure Dict
raw_json = JSON.parsefile("data/rl/rl-agent-selection.json")

# Deep convert to Dict
function to_dict(x)
    if isa(x, Dict)
        return Dict(k => to_dict(v) for (k, v) in x)
    elseif isa(x, Vector)
        return [to_dict(item) for item in x]
    else
        return x
    end
end

state = to_dict(raw_json)

# Update Q-values
α = 0.1f0
println("\n" * "="^70)
println("Updating Q-values with α = 0.1")
println("="^70 * "\n")

for (task_name, task_data) in state["task_types"]
    agents = task_data["agents"]
    
    for agent_dict in agents
        agent_name = agent_dict["name"]
        q_old = Float32(agent_dict["q_score"])
        
        if haskey(agent_stats, agent_name)
            s, t = agent_stats[agent_name]
            success_rate = Float32(s / t)
        else
            success_rate = 0.5f0
        end
        
        q_new = (1 - α) * q_old + α * success_rate
        agent_dict["q_score"] = q_new
    end
    
    sort!(agents, by=x->x["q_score"], rev=true)
    top = agents[1]
    println("$(task_name): $(top["name"]) (Q=$(round(top["q_score"], digits=4)))")
end

# Update metadata and save
state["metadata"]["last_refresh"] = string(now())
state["metadata"]["refresh_reason"] = "phase_3_retraining"

open("data/rl/rl-agent-selection.json", "w") do f
    write(f, JSON.json(state, 2))
end

println("\n" * "="^70)
println("✅ PHASE 3 RETRAINING COMPLETE")
println("="^70)
println("\nUpdated from 67 outcomes. Model saved.\n")
