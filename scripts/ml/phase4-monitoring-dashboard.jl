#!/usr/bin/env julia
"""
Phase 4: Monitoring Dashboard & Auto-Retraining

Real-time agent performance tracking with:
- Agent utilization metrics
- Success rate trends
- Auto-retraining triggers (every 50 outcomes)
- Performance alerts
- Historical dashboards
"""

using JSON
using Statistics
using Dates

function load_outcomes()::Vector{Dict}
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
    return outcomes
end

function calculate_metrics(outcomes::Vector{Dict})::Dict
    metrics = Dict(
        "total_outcomes" => length(outcomes),
        "agents" => Dict(),
        "tasks" => Dict(),
        "timestamp" => string(now())
    )
    
    agent_stats = Dict()
    task_stats = Dict()
    
    for outcome in outcomes
        agent = get(outcome, "agent", "Unknown")
        task = get(outcome, "task", "unknown")
        success = get(outcome, "success", false)
        
        # Agent stats
        if !haskey(agent_stats, agent)
            agent_stats[agent] = Dict("success" => 0, "total" => 0, "last_used" => "")
        end
        agent_stats[agent]["total"] += 1
        agent_stats[agent]["last_used"] = get(outcome, "timestamp", "")
        if success
            agent_stats[agent]["success"] += 1
        end
        
        # Task stats
        if !haskey(task_stats, task)
            task_stats[task] = Dict("success" => 0, "total" => 0, "agents" => Dict())
        end
        task_stats[task]["total"] += 1
        if success
            task_stats[task]["success"] += 1
        end
        
        if !haskey(task_stats[task]["agents"], agent)
            task_stats[task]["agents"][agent] = Dict("success" => 0, "total" => 0)
        end
        task_stats[task]["agents"][agent]["total"] += 1
        if success
            task_stats[task]["agents"][agent]["success"] += 1
        end
    end
    
    # Format agent metrics
    for (agent, stats) in agent_stats
        success_rate = stats["total"] > 0 ? stats["success"] / stats["total"] : 0.0
        metrics["agents"][agent] = Dict(
            "total_uses" => stats["total"],
            "success_count" => stats["success"],
            "success_rate" => round(success_rate, digits=3),
            "last_used" => stats["last_used"]
        )
    end
    
    # Format task metrics
    for (task, stats) in task_stats
        success_rate = stats["total"] > 0 ? stats["success"] / stats["total"] : 0.0
        metrics["tasks"][task] = Dict(
            "total_outcomes" => stats["total"],
            "success_count" => stats["success"],
            "success_rate" => round(success_rate, digits=3),
            "agents_used" => length(stats["agents"])
        )
    end
    
    return metrics
end

function check_retraining_needed(metrics::Dict)::Bool
    total = metrics["total_outcomes"]
    
    # Load previous count
    prev_count = 0
    if isfile("data/metrics/phase4-prev-retrain-count.txt")
        prev_count = parse(Int, read("data/metrics/phase4-prev-retrain-count.txt", String))
    end
    
    # Retrain if 50+ new outcomes
    should_retrain = total - prev_count >= 50
    
    if should_retrain
        write("data/metrics/phase4-prev-retrain-count.txt", string(total))
    end
    
    return should_retrain
end

function check_alerts(metrics::Dict)::Vector{String}
    alerts = String[]
    
    # Check for low success rates
    for (agent, agent_metrics) in metrics["agents"]
        success_rate = agent_metrics["success_rate"]
        if agent_metrics["total_uses"] >= 5 && success_rate < 0.5  # At least 5 uses before alerting
            push!(alerts, "⚠️  $agent: Success rate $(round(success_rate*100, digits=1))% (below 50%)")
        end
    end
    
    # Check for neglected agents
    for (agent, agent_metrics) in metrics["agents"]
        if agent_metrics["total_uses"] == 0
            push!(alerts, "📊 $agent: No uses yet (possible routing issue)")
        end
    end
    
    return alerts
end

function print_dashboard(metrics::Dict, alerts::Vector{String}, retrain_needed::Bool)
    println("\n" * "="^80)
    println("PHASE 4: MONITORING DASHBOARD")
    println("="^80 * "\n")
    
    println("Overall Metrics:")
    println("  Total Outcomes: $(metrics["total_outcomes"])")
    println("  Timestamp: $(metrics["timestamp"])")
    println("  Auto-Retrain Needed: $(retrain_needed ? "YES ✓" : "no")\n")
    
    println("Agent Performance (Sorted by Success Rate):\n")
    agent_list = sort(collect(metrics["agents"]), by=x->x[2]["success_rate"], rev=true)
    for (agent, stats) in agent_list
        rate_pct = round(stats["success_rate"] * 100, digits=1)
        println("  $agent")
        println("    Uses: $(stats["total_uses"]) | Success: $(stats["success_count"])/$(stats["total_uses"]) ($(rate_pct)%)")
        println("    Last Used: $(stats["last_used"])\n")
    end
    
    println("Task Performance:\n")
    task_list = sort(collect(metrics["tasks"]), by=x->x[2]["success_rate"], rev=true)
    for (task, stats) in task_list
        rate_pct = round(stats["success_rate"] * 100, digits=1)
        println("  $task")
        println("    Outcomes: $(stats["total_outcomes"]) | Success: $(stats["success_count"])/$(stats["total_outcomes"]) ($(rate_pct)%)")
        println("    Agents: $(stats["agents_used"])\n")
    end
    
    if !isempty(alerts)
        println("⚠️  ALERTS:\n")
        for alert in alerts
            println("  $alert\n")
        end
    else
        println("✅ No alerts\n")
    end
    
    if retrain_needed
        println("🔄 RETRAINING TRIGGERED: Run retrain-q-learning.jl to update model\n")
    end
    
    println("="^80 * "\n")
end

# Main
mkpath("data/metrics")

outcomes = load_outcomes()
metrics = calculate_metrics(outcomes)
alerts = check_alerts(metrics)
retrain_needed = check_retraining_needed(metrics)

# Save metrics
open("data/metrics/phase4-dashboard.json", "w") do f
    write(f, JSON.json(metrics, 2))
end

print_dashboard(metrics, alerts, retrain_needed)

if retrain_needed
    println("Run this to retrain:")
    println("  julia scripts/ml/retrain-q-learning.jl\n")
end
