#!/usr/bin/env julia
"""
sla-calculator.jl

Calculate SLA metrics for agents and tasks.
Tracks: latency, success rate, cost vs. targets
Generates alerts if SLA breached
"""

using Dates
using JSON
using Statistics

module SLACalculator

export calculate_sla, check_alerts, get_sla_dashboard

# SLA Targets (configurable)
const SLA_TARGETS = Dict(
    "latency_p50_ms" => 2000,
    "latency_p95_ms" => 3000,
    "latency_p99_ms" => 4000,
    "success_rate" => 0.80,
    "cost_per_task_usd" => 0.025,
    "quality_score" => 0.85
)

function calculate_sla_for_agent(agent::String, date::Date=Dates.today())
    """
    Calculate SLA metrics for a specific agent on a given day.
    
    Args:
        agent: Agent name
        date: Date to analyze (default: today)
    
    Returns:
        Dict with SLA metrics and compliance status
    """
    try
        audit_dir = joinpath(@__DIR__, "..", "..", "data", "audit-logs")
        date_str = Dates.format(date, "yyyy-mm-dd")
        log_path = joinpath(audit_dir, "$(date_str).jsonl")
        
        isfile(log_path) || return nothing
        
        outcomes = []
        
        open(log_path, "r") do io
            for line in eachline(io)
                isempty(line) && continue
                try
                    event = JSON.parse(line)
                    if event["event_type"] == "task_outcome" && 
                       get(event, "agent", "") == agent
                        push!(outcomes, event)
                    end
                catch
                    # Skip malformed
                end
            end
        end
        
        isempty(outcomes) && return nothing
        
        # Calculate metrics
        latencies = [get(o, "duration_ms", 0) for o in outcomes]
        successes = count(get(o, "success", false) for o in outcomes)
        costs = [get(o, "cost_usd", 0.0) for o in outcomes]
        qualities = [get(o, "quality_score", 0.0) for o in outcomes]
        
        success_rate = successes / length(outcomes)
        avg_quality = mean(qualities)
        avg_cost = mean(costs)
        
        # Percentiles
        sort!(latencies)
        p50_idx = max(1, div(length(latencies), 2))
        p95_idx = max(1, div(length(latencies) * 95, 100))
        p99_idx = max(1, div(length(latencies) * 99, 100))
        
        metrics = Dict(
            "agent" => agent,
            "date" => date_str,
            "metrics" => Dict(
                "tasks_count" => length(outcomes),
                "success_rate" => round(success_rate, digits=3),
                "latency_p50_ms" => latencies[p50_idx],
                "latency_p95_ms" => latencies[p95_idx],
                "latency_p99_ms" => latencies[p99_idx],
                "cost_per_task" => round(avg_cost, digits=4),
                "quality_score_avg" => round(avg_quality, digits=3)
            ),
            "sla_targets" => SLA_TARGETS,
            "alerts" => []
        )
        
        # Check SLA compliance
        alerts = []
        
        if metrics["metrics"]["success_rate"] < SLA_TARGETS["success_rate"]
            push!(alerts, "Success rate below target")
        end
        if metrics["metrics"]["latency_p95_ms"] > SLA_TARGETS["latency_p95_ms"]
            push!(alerts, "P95 latency above target")
        end
        if metrics["metrics"]["cost_per_task"] > SLA_TARGETS["cost_per_task_usd"]
            push!(alerts, "Cost per task above target")
        end
        if metrics["metrics"]["quality_score_avg"] < SLA_TARGETS["quality_score"]
            push!(alerts, "Quality score below target")
        end
        
        metrics["alerts"] = alerts
        metrics["sla_met"] = isempty(alerts)
        
        return metrics
    catch err
        @error "SLA calculation error for $agent: $err"
        return nothing
    end
end

function get_sla_dashboard(date::Date=Dates.today())
    """
    Generate SLA dashboard for all agents.
    
    Returns:
        Dict with overall SLA status
    """
    agents = [
        "Codex", "Cipher", "Scout", "Chronicle", "Sentinel",
        "Lens", "Echo", "Veritas", "QA", "Prism", "Navigator"
    ]
    
    dashboard = Dict(
        "date" => Dates.format(date, "yyyy-mm-dd"),
        "generated_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SS.sssZ"),
        "agents" => [],
        "summary" => Dict()
    )
    
    all_met = true
    total_cost = 0.0
    total_tasks = 0
    
    for agent in agents
        sla = calculate_sla_for_agent(agent, date)
        if !isnothing(sla)
            push!(dashboard["agents"], sla)
            
            all_met = all_met && sla["sla_met"]
            total_cost += get(sla["metrics"], "cost_per_task", 0.0) * 
                         get(sla["metrics"], "tasks_count", 0)
            total_tasks += get(sla["metrics"], "tasks_count", 0)
        end
    end
    
    dashboard["summary"] = Dict(
        "all_slas_met" => all_met,
        "agents_monitored" => length(dashboard["agents"]),
        "total_tasks" => total_tasks,
        "total_cost" => round(total_cost, digits=2),
        "status" => all_met ? "✅ HEALTHY" : "⚠️ ALERT"
    )
    
    return dashboard
end

function check_alerts(date::Date=Dates.today())
    """Check for SLA breaches and return alerts"""
    dashboard = get_sla_dashboard(date)
    
    alerts = []
    for agent_sla in dashboard["agents"]
        if !agent_sla["sla_met"]
            for alert in agent_sla["alerts"]
                push!(alerts, "$(agent_sla["agent"]): $alert")
            end
        end
    end
    
    return alerts
end

end  # module
