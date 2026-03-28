#!/usr/bin/env julia
"""
KNOWLEDGE EXTRACTOR - P2: Learning Pattern Capture

Extracts patterns from task outcomes.
Builds queryable knowledge base of "what worked" for future tasks.

Creates structured insights from unstructured task execution logs:
  - Problem type → Solution pattern
  - Agent approach → Success/failure signature
  - Temporal patterns (when did approaches work)
  - Resource efficiency patterns (cost vs quality tradeoffs)

Usage:
  julia knowledge-extractor.jl --extract
  julia knowledge-extractor.jl --query-pattern "code optimization"
  julia knowledge-extractor.jl --find-similar <task_description>
"""

using JSON
using Statistics
using Dates

const AUDIT_LOGS_DIR = "data/audit-logs"
const FEEDBACK_LOG = "data/feedback-logs/feedback-validation.jsonl"
const KNOWLEDGE_BASE = "data/knowledge-base/extracted-patterns.json"
const PATTERN_CACHE = "data/knowledge-base/pattern-embeddings.jsonl"

"""Extract task context from audit entries"""
function extract_task_context(entry::Dict{String, Any})::Dict{String, Any}
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
        "pattern_id" => string(hash(task_type)) % 1000000,  # Deterministic ID
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

"""Load all task contexts from audit logs"""
function load_task_contexts()::Dict{String, Vector{Dict{String, Any}}}
    """Groups tasks by type, loads all contexts."""
    
    task_contexts = Dict{String, Vector{Dict{String, Any}}}()
    
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
        "patterns" => Dict{String, Dict}()
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
    
    # Save knowledge base
    open(KNOWLEDGE_BASE, "w") do f
        JSON.print(f, knowledge_base, 2)
    end
    
    println("\n✓ Knowledge base saved to $KNOWLEDGE_BASE")
    return knowledge_base
end

"""Query knowledge base for task pattern"""
function query_pattern(task_type::String)
    if !isfile(KNOWLEDGE_BASE)
        println("Knowledge base not found. Run --extract first.")
        return
    end
    
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
    else
        println("Pattern not found for task type: $task_type")
        println("Available patterns: $(join(keys(kb["patterns"]), ", "))")
    end
end

"""Find similar task patterns (for warm-start on new tasks)"""
function find_similar_patterns(keywords::String)
    if !isfile(KNOWLEDGE_BASE)
        println("Knowledge base not found. Run --extract first.")
        return
    end
    
    kb = JSON.parsefile(KNOWLEDGE_BASE)
    keyword_list = split(lowercase(keywords), " ")
    
    matches = []
    for (task_type, pattern) in kb["patterns"]
        score = 0
        for kw in keyword_list
            if contains(lowercase(task_type), kw)
                score += 1
            end
        end
        if score > 0
            push!(matches, (task_type, pattern, score))
        end
    end
    
    sort!(matches, by=x -> x[3], rev=true)
    
    if length(matches) > 0
        println("\n🔍 Similar patterns found:")
        for (task_type, pattern, score) in matches[1:min(3, length(matches))]
            println("  • $task_type (match_score: $score)")
            println("    Best agent: $(pattern["best_agent"]), quality: $(round(pattern["avg_quality"], digits=3))")
        end
    else
        println("No similar patterns found.")
    end
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
        else
            println("Unknown command: $(ARGS[1])")
        end
    else
        extract_and_save()
    end
end

main()
