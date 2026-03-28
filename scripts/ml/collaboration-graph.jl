#!/usr/bin/env julia
"""
COLLABORATION GRAPH - P1: Cross-Agent Learning

Analyzes task outcomes to identify high-performing agent pairs.
Builds a "collaboration matrix" showing when agents work well together.

Usage:
  julia collaboration-graph.jl --analyze
  julia collaboration-graph.jl --suggest-pairs <task_type>
  julia collaboration-graph.jl --route-complex <task_id>
"""

using JSON
using Statistics
using Dates

const AUDIT_LOGS_DIR = "data/audit-logs"
const COLLABORATION_GRAPH_FILE = "data/collaboration-graph.json"
const COMPLEX_TASK_THRESHOLD = 0.8  # Quality score >= 0.8 = complex task
const MIN_PAIR_INTERACTIONS = 3  # Need 3+ interactions to establish pattern

"""Load all audit logs into memory"""
function load_audit_logs()::Vector{Dict{String, Any}}
    all_entries = Dict{String, Any}[]
    
    audit_files = filter(f -> endswith(f, ".jsonl"), readdir(AUDIT_LOGS_DIR))
    for audit_file in sort(audit_files)
        audit_path = joinpath(AUDIT_LOGS_DIR, audit_file)
        open(audit_path, "r") do f
            for line in eachline(f)
                try
                    entry = JSON.parse(line)
                    push!(all_entries, entry)
                catch
                    continue
                end
            end
        end
    end
    
    return all_entries
end

"""Detect if a task involved multiple agents (collaboration)"""
function detect_collaboration(entries::Vector{Dict{String, Any}})::Vector{Tuple{String, String, Float64, Float64}}
    """
    Looks for task_spawn + task_outcome pairs where:
    - Same task_id
    - Multiple agents involved (direct or indirect)
    - Check for agent mentions in outcome (e.g., "delegated to Scout")
    
    Returns: [(agent1, agent2, success_rate, avg_quality), ...]
    """
    
    pairs = Dict{Tuple{String, String}, Tuple{Int, Float64}}()  # (a1, a2) => (count, total_quality)
    
    # Group by task_id to find related entries
    tasks = Dict{String, Vector{Dict}}()
    for entry in entries
        task_id = get(entry, "task_id", get(entry, "task", "unknown"))
        if task_id != "unknown"
            if !haskey(tasks, task_id)
                tasks[task_id] = []
            end
            push!(tasks[task_id], entry)
        end
    end
    
    # Analyze each task for agent interactions
    for (task_id, task_entries) in tasks
        agents_in_task = Set{String}()
        quality_scores = Float64[]
        
        for entry in task_entries
            agent = get(entry, "agent_selected", get(entry, "agent", nothing))
            if agent !== nothing
                push!(agents_in_task, agent)
                quality = get(entry, "quality_score", 0.7)
                if quality > 0
                    push!(quality_scores, quality)
                end
            end
        end
        
        # If 2+ agents in same task, record pair
        if length(agents_in_task) >= 2
            agents_list = collect(agents_in_task)
            for i in 1:length(agents_list)-1
                for j in i+1:length(agents_list)
                    a1, a2 = sort([agents_list[i], agents_list[j]])
                    pair = (a1, a2)
                    
                    avg_q = length(quality_scores) > 0 ? mean(quality_scores) : 0.5
                    
                    if haskey(pairs, pair)
                        count, total_q = pairs[pair]
                        pairs[pair] = (count + 1, total_q + avg_q)
                    else
                        pairs[pair] = (1, avg_q)
                    end
                end
            end
        end
    end
    
    # Convert to list of tuples with success metrics
    results = Tuple{String, String, Float64, Float64}[]
    for ((a1, a2), (count, total_q)) in pairs
        if count >= MIN_PAIR_INTERACTIONS
            avg_quality = total_q / count
            success_rate = count > 0 ? 1.0 : 0.0  # Presence = success
            push!(results, (a1, a2, success_rate, avg_quality))
        end
    end
    
    return sort(results, by=x -> x[4], rev=true)  # Sort by quality descending
end

"""Build collaboration graph"""
function build_collaboration_graph(entries::Vector{Dict{String, Any}})::Dict{String, Any}
    pairs = detect_collaboration(entries)
    
    graph = Dict(
        "generated_at" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ"),
        "total_pairs" => length(pairs),
        "pairs" => []
    )
    
    # Add top 20 pairs to graph
    for (a1, a2, success_rate, quality) in pairs[1:min(20, length(pairs))]
        push!(graph["pairs"], Dict(
            "agent_1" => a1,
            "agent_2" => a2,
            "success_rate" => round(success_rate, digits=3),
            "avg_quality" => round(quality, digits=3),
            "recommendation" => quality >= 0.85 ? "HIGHLY_RECOMMENDED" : "recommended"
        ))
    end
    
    return graph
end

"""Suggest best agent pairs for a task type"""
function suggest_pairs_for_task(task_type::String, graph::Dict{String, Any})::Vector{Tuple{String, String, Float64}}
    """
    For complex tasks, suggests agent pairs that perform well together.
    """
    suggestions = Tuple{String, String, Float64}[]
    
    for pair_data in graph["pairs"]
        a1 = pair_data["agent_1"]
        a2 = pair_data["agent_2"]
        quality = pair_data["avg_quality"]
        
        if quality >= 0.8  # Only high-quality pairs
            push!(suggestions, (a1, a2, quality))
        end
    end
    
    return suggestions
end

"""Route complex task to high-performing agent pair"""
function route_complex_task(task_id::String, task_type::String, complexity::Float64, graph::Dict{String, Any})
    suggestions = suggest_pairs_for_task(task_type, graph)
    
    if length(suggestions) > 0
        best_a1, best_a2, quality = suggestions[1]
        
        routing_decision = Dict(
            "task_id" => task_id,
            "task_type" => task_type,
            "complexity" => complexity,
            "routing_decision" => "pair_execution",
            "primary_agent" => best_a1,
            "secondary_agent" => best_a2,
            "pair_quality_score" => quality,
            "rationale" => "High-performing pair detected in collaboration graph",
            "timestamp" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")
        )
        
        return routing_decision
    else
        return Dict(
            "task_id" => task_id,
            "routing_decision" => "single_agent",
            "reason" => "No high-quality pair found, route via standard Q-learning"
        )
    end
end

"""Analyze collaboration patterns and save graph"""
function analyze_and_save()
    println("Loading audit logs...")
    entries = load_audit_logs()
    println("Loaded $(length(entries)) audit entries")
    
    println("\nDetecting collaborations...")
    graph = build_collaboration_graph(entries)
    
    # Save graph
    open(COLLABORATION_GRAPH_FILE, "w") do f
        JSON.print(f, graph, 2)
    end
    
    println("✓ Collaboration graph saved to $COLLABORATION_GRAPH_FILE")
    println("\nTop 5 Agent Pairs:")
    for (i, pair) in enumerate(graph["pairs"][1:min(5, length(graph["pairs"]))])
        println("  $i. $(pair["agent_1"]) + $(pair["agent_2"]): quality=$(pair["avg_quality"])")
    end
    
    return graph
end

# Main execution
function main()
    if length(ARGS) > 0
        if ARGS[1] == "--analyze"
            analyze_and_save()
        elseif ARGS[1] == "--suggest-pairs" && length(ARGS) > 1
            graph = JSON.parsefile(COLLABORATION_GRAPH_FILE)
            task_type = ARGS[2]
            suggestions = suggest_pairs_for_task(task_type, graph)
            println("\nBest pairs for '$task_type':")
            for (a1, a2, quality) in suggestions[1:min(3, length(suggestions))]
                println("  - $a1 + $a2 (quality=$quality)")
            end
        else
            println("Unknown command")
        end
    else
        analyze_and_save()
    end
end

main()
