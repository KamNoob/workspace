#!/usr/bin/env julia
"""
kb-rag-injector.jl - Knowledge Base RAG (Retrieval-Augmented Generation) Injector

Query knowledge base with semantic search and inject context into agent prompts.

CLI Usage:
  julia kb-rag-injector.jl --help              Show help
  julia kb-rag-injector.jl query <query>       Query KB and return top results
  julia kb-rag-injector.jl inject <query> <prompt>  Inject KB context into prompt
  julia kb-rag-injector.jl init                Initialize sample KB
  julia kb-rag-injector.jl list                List all KB entries
"""

using JSON
using Dates

# ============================================================================
# Data Structures
# ============================================================================

struct KBEntry
    id::String
    topic::String
    content::String
    tags::Vector{String}
    relevance::Float64
    timestamp::String
end

struct QueryResult
    query::String
    entries::Vector{KBEntry}
    count::Int
    avg_relevance::Float64
end

# ============================================================================
# Core Functions
# ============================================================================

function tokenize(text::String)::Vector{String}
    text = lowercase(text)
    words = split(replace(text, r"[^\w\s]" => " "), r"\s+")
    return filter(!isempty, words)
end

function compute_relevance(query::String, entry::KBEntry)::Float64
    query_tokens = tokenize(query)
    
    if isempty(query_tokens)
        return 0.0
    end
    
    # Topic match
    topic_tokens = tokenize(entry.topic)
    topic_matches = 0
    for t in query_tokens
        if t in topic_tokens
            topic_matches += 1
        end
    end
    topic_score = topic_matches / length(query_tokens)
    
    # Tag match
    tag_matches = 0
    if length(entry.tags) > 0
        for t in query_tokens
            if t in entry.tags
                tag_matches += 1
            end
        end
        tag_score = tag_matches / length(entry.tags)
    else
        tag_score = 0.0
    end
    
    # Content match
    content_tokens = tokenize(entry.content)
    if !isempty(content_tokens) && length(content_tokens) > 50
        content_tokens = content_tokens[1:50]
    end
    content_matches = 0
    for t in query_tokens
        if t in content_tokens
            content_matches += 1
        end
    end
    content_score = content_matches / length(query_tokens)
    
    # Combined score
    return 0.4 * topic_score + 0.3 * tag_score + 0.3 * content_score
end

function query_kb(kb_path::String, query::String, limit::Int=5)::QueryResult
    # Load KB
    if !isfile(kb_path)
        return QueryResult(query, KBEntry[], 0, 0.0)
    end
    
    data = JSON.parsefile(kb_path)
    entries = []
    
    # Score all entries
    for entry_data in get(data, "entries", [])
        entry = KBEntry(
            entry_data["id"],
            entry_data["topic"],
            entry_data["content"],
            entry_data["tags"],
            0.0,
            entry_data["timestamp"]
        )
        score = compute_relevance(query, entry)
        if score > 0.0
            push!(entries, KBEntry(entry.id, entry.topic, entry.content, entry.tags, score, entry.timestamp))
        end
    end
    
    # Sort and limit
    sort!(entries, by=e->e.relevance, rev=true)
    entries = entries[1:min(limit, length(entries))]
    
    avg_rel = isempty(entries) ? 0.0 : sum(e.relevance for e in entries) / length(entries)
    
    return QueryResult(query, entries, length(entries), avg_rel)
end

function format_context(result::QueryResult; format::String="markdown")::String
    if isempty(result.entries)
        return ""
    end
    
    if format == "markdown"
        lines = ["## Knowledge Base Context", ""]
        for (i, entry) in enumerate(result.entries)
            push!(lines, "### $(i). $(entry.topic)")
            push!(lines, "**Relevance:** $(round(entry.relevance, digits=2))")
            push!(lines, entry.content)
            push!(lines, "**Tags:** $(join(entry.tags, ", "))")
            push!(lines, "")
        end
        return join(lines, "\n")
    else
        lines = ["[KNOWLEDGE BASE CONTEXT]", ""]
        for (i, entry) in enumerate(result.entries)
            push!(lines, "($i) $(entry.topic) [relevance: $(round(entry.relevance, digits=2))]")
            push!(lines, entry.content)
            push!(lines, "")
        end
        return join(lines, "\n")
    end
end

function inject_context(prompt::String, context::String)::String
    return """$prompt

---
$context
"""
end

function init_kb(kb_path::String)
    entries = [
        Dict(
            "id" => "1",
            "topic" => "Agent Selection Strategies",
            "content" => "When selecting agents for tasks, consider the task type, required expertise, and agent capabilities. Codex excels at code tasks, Scout at research, Cipher at security audits.",
            "tags" => ["agent", "selection", "strategy"],
            "timestamp" => string(now())
        ),
        Dict(
            "id" => "2",
            "topic" => "Q-Learning for Agent Optimization",
            "content" => "Use Q-learning to optimize agent assignment over time. Track success rates, update Q-values based on outcomes, and gradually converge on optimal pairings.",
            "tags" => ["q-learning", "rl", "optimization"],
            "timestamp" => string(now())
        ),
        Dict(
            "id" => "3",
            "topic" => "Knowledge Base Management",
            "content" => "Maintain an organized KB with clear topics, relevant content, and consistent tagging. Regular updates from agent outcomes improve system learning.",
            "tags" => ["kb", "knowledge", "management"],
            "timestamp" => string(now())
        ),
        Dict(
            "id" => "4",
            "topic" => "RAG Implementation Best Practices",
            "content" => "For RAG systems: retrieve relevant context first, rank by relevance, inject into prompts with clear markers, monitor retrieval quality metrics.",
            "tags" => ["rag", "retrieval", "generation"],
            "timestamp" => string(now())
        ),
        Dict(
            "id" => "5",
            "topic" => "Confidence Scoring in RL",
            "content" => "Score confidence of agent selections using bootstrap methods or uncertainty quantification. Flag low-confidence decisions for manual review or escalation.",
            "tags" => ["confidence", "uncertainty", "scoring"],
            "timestamp" => string(now())
        ),
    ]
    
    mkpath(dirname(kb_path))
    open(kb_path, "w") do f
        JSON.print(f, Dict("entries" => entries), 2)
    end
    println("✓ Initialized KB at $kb_path")
end

function list_kb(kb_path::String)
    if !isfile(kb_path)
        println("KB not found. Run: julia kb-rag-injector.jl init")
        return
    end
    
    data = JSON.parsefile(kb_path)
    entries = get(data, "entries", [])
    
    println("\n=== Knowledge Base ($(length(entries)) entries) ===\n")
    for entry in entries
        println("$(entry["id"]). $(entry["topic"])")
        println("   Tags: $(join(entry["tags"], ", "))")
        println("   Length: $(length(entry["content"])) chars")
        println()
    end
end

# ============================================================================
# CLI Interface
# ============================================================================

function show_help()
    println("""
    kb-rag-injector.jl - Knowledge Base RAG Injector
    
    Usage:
      julia kb-rag-injector.jl --help              Show this help
      julia kb-rag-injector.jl init                Initialize sample KB
      julia kb-rag-injector.jl list                List KB entries
      julia kb-rag-injector.jl query QUERY         Query KB
      julia kb-rag-injector.jl inject QUERY PROMPT Inject KB context into prompt
    
    Examples:
      julia kb-rag-injector.jl init
      julia kb-rag-injector.jl query "agent selection"
      julia kb-rag-injector.jl list
    """)
end

if isinteractive() == false
    if length(ARGS) == 0 || ARGS[1] in ["-h", "--help"]
        show_help()
    elseif ARGS[1] == "init"
        kb_path = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
        init_kb(kb_path)
    elseif ARGS[1] == "list"
        kb_path = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
        list_kb(kb_path)
    elseif ARGS[1] == "query" && length(ARGS) >= 2
        kb_path = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
        query = join(ARGS[2:end], " ")
        result = query_kb(kb_path, query)
        
        println("\n=== Query Results ===")
        println("Query: \"$query\"")
        println("Found: $(result.count) entries (avg relevance: $(round(result.avg_relevance, digits=2)))\n")
        
        for (i, entry) in enumerate(result.entries)
            println("$(i). $(entry.topic) [relevance: $(round(entry.relevance, digits=2))]")
            println("   $(entry.content[1:min(100, end)]...)") 
            println("   Tags: $(join(entry.tags, ", "))")
            println()
        end
    elseif ARGS[1] == "inject" && length(ARGS) >= 3
        kb_path = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
        query = ARGS[2]
        prompt = join(ARGS[3:end], " ")
        
        result = query_kb(kb_path, query)
        context = format_context(result)
        injected = inject_context(prompt, context)
        
        println("\n=== Injected Prompt ===\n")
        println(injected)
    else
        show_help()
    end
end
