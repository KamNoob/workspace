#!/usr/bin/env julia
"""
Phase 7B: Persistent Learning & Insights Generator
Analyzes task outcomes to extract patterns and generate recommendations

Usage:
  julia phase7b-insights-generator.jl analyze    # Run analysis
  julia phase7b-insights-generator.jl summary    # Print summary
"""

using JSON
using Statistics
using Dates

function load_outcomes()
    outcomes = []
    log_file = "data/rl/rl-task-execution-log.jsonl"
    
    if !isfile(log_file)
        return outcomes
    end
    
    try
        open(log_file, "r") do f
            for line in eachline(f)
                if isempty(line) || startswith(line, "#")
                    continue
                end
                try
                    data = JSON.parse(line)
                    push!(outcomes, data)
                catch e
                    # Skip malformed lines
                end
            end
        end
    catch e
        @warn "Error loading outcomes: $e"
    end
    
    return outcomes
end

function analyze_agents(outcomes)
    agents = Dict()
    
    for outcome in outcomes
        agent = get(outcome, "agent", "unknown")
        if !haskey(agents, agent)
            agents[agent] = Dict(
                "count" => 0,
                "success" => 0,
                "cost" => 0.0,
                "tasks" => Dict()
            )
        end
        
        agents[agent]["count"] += 1
        if get(outcome, "success", false)
            agents[agent]["success"] += 1
        end
        agents[agent]["cost"] += get(outcome, "cost", 0.0)
        
        task = get(outcome, "task_type", "unknown")
        if !haskey(agents[agent]["tasks"], task)
            agents[agent]["tasks"][task] = Dict("count" => 0, "success" => 0)
        end
        agents[agent]["tasks"][task]["count"] += 1
        if get(outcome, "success", false)
            agents[agent]["tasks"][task]["success"] += 1
        end
    end
    
    # Compute metrics
    agent_insights = Dict()
    for (agent, data) in agents
        success_rate = data["count"] > 0 ? data["success"] / data["count"] : 0.0
        avg_cost = data["count"] > 0 ? data["cost"] / data["count"] : 0.0
        
        # Find preferred tasks (>70% success)
        preferred = [t for (t, td) in data["tasks"] if (td["count"] > 0 && td["success"]/td["count"] >= 0.7)]
        
        agent_insights[agent] = Dict(
            "success_rate" => success_rate,
            "avg_cost" => avg_cost,
            "count" => data["count"],
            "preferred_tasks" => preferred
        )
    end
    
    return agent_insights
end

function analyze_tasks(outcomes)
    tasks = Dict()
    
    for outcome in outcomes
        task = get(outcome, "task_type", "unknown")
        if !haskey(tasks, task)
            tasks[task] = Dict(
                "count" => 0,
                "success" => 0,
                "cost" => 0.0,
                "agents" => Dict()
            )
        end
        
        tasks[task]["count"] += 1
        if get(outcome, "success", false)
            tasks[task]["success"] += 1
        end
        tasks[task]["cost"] += get(outcome, "cost", 0.0)
        
        agent = get(outcome, "agent", "unknown")
        if !haskey(tasks[task]["agents"], agent)
            tasks[task]["agents"][agent] = Dict("count" => 0, "success" => 0)
        end
        tasks[task]["agents"][agent]["count"] += 1
        if get(outcome, "success", false)
            tasks[task]["agents"][agent]["success"] += 1
        end
    end
    
    # Compute metrics
    task_insights = Dict()
    for (task, data) in tasks
        success_rate = data["count"] > 0 ? data["success"] / data["count"] : 0.0
        avg_cost = data["count"] > 0 ? data["cost"] / data["count"] : 0.0
        
        difficulty = success_rate >= 0.8 ? "easy" : success_rate >= 0.5 ? "medium" : "hard"
        
        # Find best agent
        best_agent = ""
        best_score = 0.0
        for (agent, ad) in data["agents"]
            if ad["count"] > 0
                score = ad["success"] / ad["count"]
                if score > best_score
                    best_score = score
                    best_agent = agent
                end
            end
        end
        
        task_insights[task] = Dict(
            "success_rate" => success_rate,
            "avg_cost" => avg_cost,
            "difficulty" => difficulty,
            "best_agent" => best_agent,
            "count" => data["count"]
        )
    end
    
    return task_insights
end

function generate_insights(outcomes)
    if isempty(outcomes)
        return Dict(
            "timestamp" => string(now()),
            "status" => "no_data",
            "message" => "Insufficient outcomes for analysis"
        )
    end
    
    agent_insights = analyze_agents(outcomes)
    task_insights = analyze_tasks(outcomes)
    
    # Overall metrics
    successes = sum(1 for o in outcomes if get(o, "success", false))
    success_rate = successes / length(outcomes)
    avg_cost = mean(get(o, "cost", 0.0) for o in outcomes)
    
    # Recommendations
    recommendations = []
    
    # High-performing agents
    for (agent, insight) in agent_insights
        if insight["success_rate"] >= 0.8 && !isempty(insight["preferred_tasks"])
            push!(recommendations, "✅ $(agent) excels at $(join(insight["preferred_tasks"], ", ")). Consider routing more tasks there.")
        end
    end
    
    # Low-performing tasks
    for (task, insight) in task_insights
        if insight["difficulty"] == "hard"
            push!(recommendations, "🔴 Task '$task' has $(round((1-insight["success_rate"])*100, digits=0))% failure rate. Review or specialize.")
        end
    end
    
    # Cost optimization
    expensive_agents = [a for (a, i) in agent_insights if i["avg_cost"] > avg_cost * 1.5]
    if !isempty(expensive_agents)
        push!(recommendations, "💰 Review expensive agents: $(join(expensive_agents, ", "))")
    end
    
    insights = Dict(
        "timestamp" => string(now()),
        "total_outcomes" => length(outcomes),
        "overall_success_rate" => success_rate,
        "avg_cost" => avg_cost,
        "agent_insights" => agent_insights,
        "task_insights" => task_insights,
        "recommendations" => recommendations,
        "status" => "success"
    )
    
    return insights
end

function save_insights(insights)
    filename = "data/metrics/phase7b-learnings.json"
    open(filename, "w") do f
        JSON.print(f, insights, 2)
    end
    return filename
end

function print_summary(insights)
    if get(insights, "status", "") == "no_data"
        println("ℹ️  No outcomes to analyze yet")
        return
    end
    
    println("\n" * "="^80)
    println("PHASE 7B: PERSISTENT LEARNING INSIGHTS")
    println("="^80)
    println("\n📊 System Status ($(insights["timestamp"]))")
    println("  Total Outcomes: $(insights["total_outcomes"])")
    println("  Success Rate: $(round(insights["overall_success_rate"] * 100, digits=1))%")
    println("  Average Cost: \$$(round(insights["avg_cost"], digits=4))")
    
    if haskey(insights, "agent_insights") && !isempty(insights["agent_insights"])
        println("\n🤖 Top Agent Performance:")
        agents = collect(insights["agent_insights"])
        sort!(agents, by=x -> x[2]["success_rate"], rev=true)
        for (i, (agent, data)) in enumerate(agents[1:min(5, length(agents))])
            println("  $i. $(agent): $(round(data["success_rate"]*100, digits=1))% success, \$$(round(data["avg_cost"], digits=4)) cost")
        end
    end
    
    if haskey(insights, "recommendations") && !isempty(insights["recommendations"])
        println("\n💡 Recommendations:")
        for (i, rec) in enumerate(insights["recommendations"][1:min(5, length(insights["recommendations"]))])
            println("  $i. $rec")
        end
    end
    
    println("\n" * "="^80)
end

# Main
function main(args)
    outcomes = load_outcomes()
    insights = generate_insights(outcomes)
    
    command = length(args) > 0 ? args[1] : "analyze"
    
    if command == "analyze"
        filename = save_insights(insights)
        println("✅ Insights saved to: $filename")
        print_summary(insights)
    elseif command == "summary"
        print_summary(insights)
    else
        println("Unknown command: $command")
    end
end

main(ARGS)
