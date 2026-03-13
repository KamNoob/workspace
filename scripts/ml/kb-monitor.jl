#!/usr/bin/env julia
"""
kb-monitor.jl - KB System Monitoring & Reporting Dashboard

CLI Usage:
  julia kb-monitor.jl status              Show live status dashboard
  julia kb-monitor.jl metrics             Show metrics summary
  julia kb-monitor.jl growth              Show KB growth over time
  julia kb-monitor.jl --json              Export metrics as JSON
"""

using JSON
using Dates
using Statistics

const WORKSPACE = "/home/art/.openclaw/workspace"
const METRICS_FILE = joinpath(WORKSPACE, "data/metrics/kb-system-metrics.json")
const RL_LOG = joinpath(WORKSPACE, "data/rl/rl-task-execution-log.jsonl")

function load_metrics()::Dict
    if !isfile(METRICS_FILE)
        return Dict("error" => "Metrics file not found")
    end
    return JSON.parsefile(METRICS_FILE)
end

function get_rl_stats()::Dict
    stats = Dict(
        "total_entries" => 0,
        "success_count" => 0,
        "failure_count" => 0,
        "success_rate" => 0.0
    )
    
    if !isfile(RL_LOG)
        return stats
    end
    
    try
        count = 0
        success = 0
        for line in readlines(RL_LOG)
            entry = JSON.parse(line)
            count += 1
            if get(entry, "success", false) == true
                success += 1
            end
        end
        
        stats["total_entries"] = count
        stats["success_count"] = success
        stats["failure_count"] = count - success
        stats["success_rate"] = count > 0 ? round(success / count, digits=3) : 0.0
    catch e
        # Silent fail
    end
    
    return stats
end

function print_status()
    metrics = load_metrics()
    rl_stats = get_rl_stats()
    
    println("\n" * "═"^80)
    println("  KNOWLEDGE BASE SYSTEM - LIVE STATUS")
    println("═"^80 * "\n")
    
    # System Overview
    println("SYSTEM OVERVIEW")
    println("─"^80)
    if haskey(metrics, "system_start")
        println("  System Start:           $(metrics["system_start"])")
    end
    if haskey(metrics, "last_updated")
        println("  Last Updated:           $(metrics["last_updated"])")
    end
    println("  Current Time:           $(Dates.format(now(Dates.UTC), "yyyy-mm-dd HH:MM:SS UTC"))\n")
    
    # RL Execution Stats
    println("RL EXECUTION METRICS")
    println("─"^80)
    println("  Total Entries:          $(rl_stats["total_entries"])")
    println("  Successful:             $(rl_stats["success_count"])")
    println("  Failed:                 $(rl_stats["failure_count"])")
    println("  Success Rate:           $(round(rl_stats["success_rate"]*100, digits=1))%\n")
    
    # KB Growth
    if haskey(metrics, "kb_growth_history") && !isempty(metrics["kb_growth_history"])
        println("KB GROWTH (Last 7 Days)")
        println("─"^80)
        growth = metrics["kb_growth_history"]
        for entry in last(growth, min(7, length(growth)))
            ts = entry["timestamp"]
            entries = entry["new_entries_added"]
            sr = entry["success_rate"]
            println("  $ts  │  +$entries entries  │  Success: $(round(sr*100, digits=1))%")
        end
        println()
    end
    
    # Spawn Metrics
    if haskey(metrics, "spawn_metrics")
        println("SPAWN CONTEXT USAGE")
        println("─"^80)
        spawn = metrics["spawn_metrics"]
        println("  Total Spawns:           $(get(spawn, "total_spawns", 0))")
        println("  Success Rate:           $(round(get(spawn, "success_rate", 0.0)*100, digits=1))%")
        if haskey(spawn, "kb_context_usage")
            usage = spawn["kb_context_usage"]
            println("  KB Queries Used:        $(get(usage, "queries_using_kb", 0))")
        end
        println()
    end
    
    # Learning Metrics
    if haskey(metrics, "learning_metrics")
        println("LEARNING METRICS")
        println("─"^80)
        learning = metrics["learning_metrics"]
        
        # Agent improvements
        if haskey(learning, "agent_improvement")
            println("  Agent Improvements:")
            for (agent, data) in learning["agent_improvement"]
                sessions = get(data, "sessions", 0)
                improvement = get(data, "improvement", 0.0)
                println("    • $agent: +$(round(improvement*100, digits=1))% ($(sessions) sessions)")
            end
        end
        
        # Q-values by task
        if haskey(learning, "q_values_by_task")
            println("\n  Top Agent Selections by Task:")
            for (task, agents_dict) in learning["q_values_by_task"]
                if !isempty(agents_dict)
                    best_agent = nothing
                    best_q = -Inf
                    for (agent_name, q_val) in agents_dict
                        if q_val > best_q
                            best_q = q_val
                            best_agent = agent_name
                        end
                    end
                    if best_agent !== nothing
                        println("    • $task: $best_agent (Q=$(round(best_q, digits=2)))")
                    end
                end
            end
        end
        println()
    end
    
    println("═"^80 * "\n")
end

function print_metrics()
    metrics = load_metrics()
    rl_stats = get_rl_stats()
    
    summary = Dict(
        "timestamp" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SSZ"),
        "rl_execution" => rl_stats,
        "kb_system" => metrics
    )
    
    println(JSON.json(summary, 2))
end

function print_growth()
    metrics = load_metrics()
    
    if !haskey(metrics, "kb_growth_history")
        println("No growth history available")
        return
    end
    
    println("\nKB GROWTH HISTORY")
    println("─"^60)
    println("Date            │ Entries Added │ Success Rate")
    println("─"^60)
    
    for entry in metrics["kb_growth_history"]
        ts = entry["timestamp"][1:10]  # Just date
        added = entry["new_entries_added"]
        sr = round(entry["success_rate"]*100, digits=1)
        println("$ts  │      $added          │    $sr%")
    end
    println()
end

function show_help()
    println("""
    kb-monitor.jl - KB System Monitoring & Reporting
    
    Usage:
      julia kb-monitor.jl status                Show live status dashboard
      julia kb-monitor.jl metrics               Show metrics summary
      julia kb-monitor.jl growth                Show growth history
      julia kb-monitor.jl --json                Export metrics as JSON
      julia kb-monitor.jl --help                Show this help
    
    Examples:
      julia kb-monitor.jl status
      julia kb-monitor.jl metrics | jq '.rl_execution'
    """)
end

if isinteractive() == false
    if length(ARGS) == 0 || ARGS[1] in ["--help", "-h"]
        show_help()
    elseif ARGS[1] == "status"
        print_status()
    elseif ARGS[1] == "metrics" || ARGS[1] == "--json"
        print_metrics()
    elseif ARGS[1] == "growth"
        print_growth()
    else
        show_help()
    end
end
