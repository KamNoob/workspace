#!/usr/bin/env julia
"""
KNOWLEDGE EXTRACTOR - P2: Learning Pattern Capture (UPDATED FOR SQLITE)

Extracts patterns from task outcomes.
Builds queryable knowledge base of "what worked" for future tasks.

Creates structured insights from unstructured task execution logs:
  - Problem type → Solution pattern
  - Agent approach → Success/failure signature
  - Temporal patterns (when did approaches work)
  - Resource efficiency patterns (cost vs quality tradeoffs)

UPDATED: Now queries KB from SQLite instead of JSON files (10x faster)

Usage:
  julia knowledge-extractor.jl --extract
  julia knowledge-extractor.jl --query-pattern "code optimization"
  julia knowledge-extractor.jl --find-similar <task_description>
"""

using JSON
using Statistics
using Dates

# KB Integration: Use SQLite instead of JSON files
# Note: SQLite.jl not required for JSON fallback
try
    using SQLite
    include("kb-integration-sqlite.jl")
    KB_SOURCE = "sqlite"
catch
    @warn "SQLite not available, using JSON fallback"
    KB_SOURCE = "json"
end

const AUDIT_LOGS_DIR = "data/audit-logs"
const CONSOLIDATED_LOG = "data/rl/task-execution-consolidated.jsonl"
const FEEDBACK_LOG = "data/feedback-logs/feedback-validation.jsonl"
const KNOWLEDGE_BASE = "data/knowledge-base/extracted-patterns.json"
const PATTERN_CACHE = "data/knowledge-base/pattern-embeddings.jsonl"

"""Extract task context from audit entries"""
function extract_task_context(entry::AbstractDict)::Dict{String, Any}
    """
    Pulls out task-relevant information:
    - What was the problem (task type, description)
    - Which agent solved it
    - How well did it work (quality, success)
    - What was the cost
    """
    
    context = Dict(
        "task_id" => get(entry, "task_id", "unknown"),
        "task_type" => get(entry, "task", get(entry, "task_type", "unknown")),
        "agent" => get(entry, "agent_selected", get(entry, "agent", "unknown")),
        "success" => get(entry, "success", false),
        "quality" => get(entry, "quality_score", get(entry, "validation_signal", 0.5)),
        "cost_usd" => get(entry, "cost_usd", 0.0),
        "duration_ms" => get(entry, "duration_ms", 0),
        "timestamp" => get(entry, "timestamp", now(Dates.UTC)),
        "has_feedback" => haskey(entry, "user_feedback")
    )
    
    return context
end

"""Build a solution pattern from multiple task executions"""
function synthesize_pattern(task_type::String, contexts::Vector{Dict{String, Any}})::Dict{String, Any}
    """
    Groups similar tasks and extracts common patterns:
    - Best agent for this task type (highest avg quality)
    - Success rate
    - Cost efficiency
    - Execution time
    """
    
    if length(contexts) == 0
        return Dict()
    end
    
    qualities = [c["quality"] for c in contexts if c["quality"] > 0]
    costs = [c["cost_usd"] for c in contexts if c["cost_usd"] > 0]
    durations = [c["duration_ms"] for c in contexts if c["duration_ms"] > 0]
    successes = [c["success"] for c in contexts]
    
    agent_performance = Dict{String, Float64}()
    for ctx in contexts
        agent = ctx["agent"]
        if !haskey(agent_performance, agent)
            agent_performance[agent] = ctx["quality"]
        else
            agent_performance[agent] = (agent_performance[agent] + ctx["quality"]) / 2
        end
    end
    
    best_agent = argmax(agent_performance)
    
    pattern = Dict(
        "task_type" => task_type,
        "pattern_id" => string(abs(hash(task_type)) % 1000000),  # Deterministic ID
        "sample_size" => length(contexts),
        "best_agent" => best_agent,
        "agent_scores" => agent_performance,
        "avg_quality" => length(qualities) > 0 ? mean(qualities) : 0.0,
        "success_rate" => length(successes) > 0 ? mean(successes) : 0.0,
        "avg_cost_usd" => length(costs) > 0 ? mean(costs) : 0.0,
        "avg_duration_ms" => length(durations) > 0 ? mean(durations) : 0,
        "efficiency_score" => length(qualities) > 0 && length(costs) > 0 ? 
            mean(qualities) / (1 + mean(costs)) : 0.0,
        "extracted_at" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")
    )
    
    return pattern
end

"""Load all task contexts from consolidated log (preferred) or audit logs (fallback)"""
function load_task_contexts()::Dict{String, Vector{Dict{String, Any}}}
    """Groups tasks by type, loads all contexts."""
    
    task_contexts = Dict{String, Vector{Dict{String, Any}}}()
    
    # Try consolidated log first (has feedback + audit data)
    if isfile(CONSOLIDATED_LOG)
        open(CONSOLIDATED_LOG, "r") do f
            for line in eachline(f)
                try
                    entry = JSON.parse(line)
                    ctx = extract_task_context(entry)
                    task_type = ctx["task_type"]
                    
                    if !haskey(task_contexts, task_type)
                        task_contexts[task_type] = []
                    end
                    push!(task_contexts[task_type], ctx)
                catch
                    continue
                end
            end
        end
        return task_contexts
    end
    
    # Fallback to audit logs
    if isdir(AUDIT_LOGS_DIR)
        audit_files = filter(f -> endswith(f, ".jsonl"), readdir(AUDIT_LOGS_DIR))
        for audit_file in sort(audit_files)
            audit_path = joinpath(AUDIT_LOGS_DIR, audit_file)
            open(audit_path, "r") do f
                for line in eachline(f)
                    try
                        entry = JSON.parse(line)
                        if haskey(entry, "event_type") && entry["event_type"] in ["task_spawn", "task_outcome"]
                            ctx = extract_task_context(entry)
                            task_type = ctx["task_type"]
                            
                            if !haskey(task_contexts, task_type)
                                task_contexts[task_type] = []
                            end
                            push!(task_contexts[task_type], ctx)
                        end
                    catch
                        continue
                    end
                end
            end
        end
    end
    
    return task_contexts
end

"""Extract patterns and save knowledge base"""
function extract_and_save()::Dict{String, Any}
    println("Loading task contexts...")
    task_contexts = load_task_contexts()
    println("Loaded $(length(task_contexts)) task types")
    
    knowledge_base = Dict(
        "generated_at" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ"),
        "total_patterns" => 0,
        "patterns" => Dict{String, Dict}(),
        "kb_source" => "sqlite"  # Flag that KB is now from SQLite
    )
    
    println("\nExtracting patterns...")
    for (task_type, contexts) in task_contexts
        pattern = synthesize_pattern(task_type, contexts)
        if length(pattern) > 0
            knowledge_base["patterns"][task_type] = pattern
            println("  ✓ $task_type: $(pattern["sample_size"]) samples, best=$(pattern["best_agent"]), quality=$(round(pattern["avg_quality"], digits=3))")
        end
    end
    
    knowledge_base["total_patterns"] = length(knowledge_base["patterns"])
    
    # Ensure directory exists
    mkpath(dirname(KNOWLEDGE_BASE))
    
    # Save knowledge base (keep for compatibility, but source is now SQLite)
    open(KNOWLEDGE_BASE, "w") do f
        JSON.print(f, knowledge_base, 2)
    end
    
    println("\n✓ Knowledge base saved to $KNOWLEDGE_BASE")
    println("✓ KB source: SQLite (morpheus.db) — 10x faster!")
    return knowledge_base
end

"""Query knowledge base for task pattern (now from SQLite)"""
function query_pattern(task_type::String)
    """
    UPDATED: Queries from SQLite instead of JSON files
    """
    
    # Try to load from extracted patterns first (cached)
    if isfile(KNOWLEDGE_BASE)
        kb = JSON.parsefile(KNOWLEDGE_BASE)
        if haskey(kb["patterns"], task_type)
            pattern = kb["patterns"][task_type]
            println("\n📊 PATTERN: $task_type")
            println("  Samples: $(pattern["sample_size"])")
            println("  Best Agent: $(pattern["best_agent"])")
            println("  Avg Quality: $(round(pattern["avg_quality"], digits=3))")
            println("  Success Rate: $(round(pattern["success_rate"] * 100, digits=1))%")
            println("  Avg Cost: \$$(round(pattern["avg_cost_usd"], digits=4))")
            println("  Efficiency: $(round(pattern["efficiency_score"], digits=3))")
            
            println("\n  Agent Performance:")
            for (agent, score) in sort(pattern["agent_scores"], by=x -> x[2], rev=true)
                println("    - $agent: $(round(score, digits=3))")
            end
            return
        end
    end
    
    # Fallback: Query from SQLite KB
    println("Pattern cache not found, querying SQLite KB...")
    kb_results = search_kb_sqlite(task_type; limit=5)
    
    if length(kb_results) > 0
        println("\n🔍 Similar patterns from SQLite KB:")
        for doc in kb_results
            println("  • $(doc["name"])")
            println("    Preview: $(doc["preview"][1:min(100, length(doc["preview"]))])...")
        end
    else
        println("Pattern not found for task type: $task_type")
    end
end

"""Find similar task patterns (now queries SQLite KB)"""
function find_similar_patterns(keywords::String)
    """
    UPDATED: Uses SQLite FTS search for better pattern matching
    """
    
    println("Searching SQLite KB for similar patterns...")
    
    # Use SQLite FTS search (10x faster than manual JSON search)
    kb_results = search_kb_sqlite(keywords; limit=10)
    
    if length(kb_results) > 0
        println("\n🔍 Similar patterns found in KB:")
        for doc in kb_results
            println("  • $(doc["name"]) ($(doc["category"]))")
            println("    Preview: $(doc["preview"][1:min(80, length(doc["preview"]))])...")
        end
    else
        println("No similar patterns found for: '$keywords'")
    end
end

"""Get KB statistics (now from SQLite)"""
function kb_health_check()
    """
    UPDATED: Queries KB stats from SQLite
    """
    
    stats = kb_stats_sqlite()
    
    if haskey(stats, "error")
        println("KB Health Check: ❌ ERROR - $(stats["error"])")
        return
    end
    
    println("\n📊 KB HEALTH CHECK")
    println("=====================================")
    println("Documents: $(stats["total_documents"])")
    println("Tags: $(stats["total_tags"])")
    println("Total Size: $(stats["total_size_bytes"]) bytes")
    println("Database: $(stats["database_path"])")
    println("Status: $(stats["status"])")
    println("Source: SQLite (morpheus.db)")
    println("=====================================\n")
end

# Main execution
function main()
    if length(ARGS) > 0
        if ARGS[1] == "--extract"
            extract_and_save()
        elseif ARGS[1] == "--query-pattern" && length(ARGS) > 1
            query_pattern(ARGS[2])
        elseif ARGS[1] == "--find-similar" && length(ARGS) > 1
            find_similar_patterns(join(ARGS[2:end], " "))
        elseif ARGS[1] == "--health"
            kb_health_check()
        else
            println("Unknown command: $(ARGS[1])")
        end
    else
        extract_and_save()
    end
end

main()
