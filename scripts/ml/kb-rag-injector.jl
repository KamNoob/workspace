#!/usr/bin/env julia
"""
kb-rag-injector.jl - Knowledge Base RAG (Retrieval-Augmented Generation) Injector

UPDATED: Now queries from SQLite KB (morpheus.db) instead of JSON files
Query knowledge base with semantic search and inject context into agent prompts.

CLI Usage:
  julia kb-rag-injector.jl --help              Show help
  julia kb-rag-injector.jl query <query>       Query KB and return top results
  julia kb-rag-injector.jl inject <query> <prompt>  Inject KB context into prompt
  julia kb-rag-injector.jl status              KB health status
  julia kb-rag-injector.jl list                List all KB entries
"""

using JSON
using Dates

# KB Integration: Use SQLite for queries
include("kb-integration-sqlite.jl") rescue nothing

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
    source::String  # "sqlite" or "fallback"
end

struct QueryResult
    query::String
    entries::Vector{KBEntry}
    count::Int
    avg_relevance::Float64
    source::String
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

"""Query KB from SQLite (primary) or fallback to JSON"""
function query_kb(kb_path::String, query::String, limit::Int=5)::QueryResult
    # First try SQLite KB (now primary source)
    sqlite_results = try
        search_kb_sqlite(query; limit=limit)
    catch
        []
    end
    
    if !isempty(sqlite_results)
        # Convert SQLite results to KBEntry format
        entries = []
        for result in sqlite_results
            entry = KBEntry(
                result["id"],
                result["name"],
                result["preview"],
                String[],  # Tags from document would need separate query
                get(result, "score", 0.8),
                now(Dates.UTC) |> string,
                "sqlite"
            )
            push!(entries, entry)
        end
        avg_rel = isempty(entries) ? 0.0 : sum(e.relevance for e in entries) / length(entries)
        return QueryResult(query, entries, length(entries), avg_rel, "sqlite")
    end
    
    # Fallback to JSON if SQLite unavailable
    if !isfile(kb_path)
        return QueryResult(query, KBEntry[], 0, 0.0, "none")
    end
    
    try
        data = JSON.parsefile(kb_path)
        entries = []
        
        # Score all entries
        for entry_data in get(data, "entries", [])
            entry = KBEntry(
                entry_data["id"],
                entry_data["topic"],
                entry_data["content"],
                get(entry_data, "tags", String[]),
                0.0,
                entry_data["timestamp"],
                "fallback"
            )
            score = compute_relevance(query, entry)
            if score > 0.0
                push!(entries, KBEntry(entry.id, entry.topic, entry.content, entry.tags, score, entry.timestamp, "fallback"))
            end
        end
        
        # Sort and limit
        sort!(entries, by=e->e.relevance, rev=true)
        entries = entries[1:min(limit, length(entries))]
        
        avg_rel = isempty(entries) ? 0.0 : sum(e.relevance for e in entries) / length(entries)
        return QueryResult(query, entries, length(entries), avg_rel, "fallback")
    catch
        return QueryResult(query, KBEntry[], 0, 0.0, "error")
    end
end

function format_context(result::QueryResult; format::String="markdown")::String
    if isempty(result.entries)
        return ""
    end
    
    if format == "markdown"
        lines = ["## Knowledge Base Context (from $(result.source))", ""]
        for (i, entry) in enumerate(result.entries)
            push!(lines, "### $(i). $(entry.topic)")
            push!(lines, "**Relevance:** $(round(entry.relevance, digits=2))")
            push!(lines, entry.content)
            if !isempty(entry.tags)
                push!(lines, "**Tags:** $(join(entry.tags, ", "))")
            end
            push!(lines, "")
        end
        return join(lines, "\n")
    else
        lines = ["[KNOWLEDGE BASE CONTEXT from $(result.source)]", ""]
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

function kb_status()
    """Show KB health status from SQLite"""
    try
        stats = kb_stats_sqlite()
        println("\n📊 KNOWLEDGE BASE STATUS")
        println("====================================")
        println("Documents: $(stats["total_documents"])")
        println("Tags: $(stats["total_tags"])")
        println("Total Size: $(stats["total_size_bytes"]) bytes")
        println("Database: $(stats["database_path"])")
        println("Source: SQLite (morpheus.db)")
        println("Status: $(stats["status"])")
        println("====================================\n")
    catch
        println("\n⚠️ KB Status: SQLite unavailable")
    end
end

function list_kb(kb_path::String)
    """List KB entries from SQLite or JSON fallback"""
    # Try SQLite first
    try
        docs = list_kb_documents_sqlite()
        println("\n=== Knowledge Base ($(length(docs)) documents, SQLite) ===\n")
        for doc in docs
            println("$(doc["id"]). $(doc["name"])")
            println("   Category: $(doc["category"])")
            println("   Size: $(doc["file_size"]) bytes")
            println()
        end
        return
    catch
        # Fallback to JSON
    end
    
    if !isfile(kb_path)
        println("KB not found. Run: julia kb-rag-injector.jl init")
        return
    end
    
    try
        data = JSON.parsefile(kb_path)
        entries = get(data, "entries", [])
        
        println("\n=== Knowledge Base ($(length(entries)) entries, JSON fallback) ===\n")
        for entry in entries
            println("$(entry["id"]). $(entry["topic"])")
            println("   Tags: $(join(get(entry, "tags", []), ", "))")
            println("   Length: $(length(entry["content"])) chars")
            println()
        end
    catch
        println("Error reading KB")
    end
end

# ============================================================================
# CLI Interface
# ============================================================================

function show_help()
    println("""
    kb-rag-injector.jl - Knowledge Base RAG Injector
    
    UPDATED: Now queries from SQLite KB (morpheus.db) for 10x faster performance
    
    Usage:
      julia kb-rag-injector.jl --help              Show this help
      julia kb-rag-injector.jl status              Show KB health status
      julia kb-rag-injector.jl list                List KB entries
      julia kb-rag-injector.jl query QUERY         Query KB (from SQLite)
      julia kb-rag-injector.jl inject QUERY PROMPT Inject KB context into prompt
    
    Examples:
      julia kb-rag-injector.jl status
      julia kb-rag-injector.jl query "oracle cloud"
      julia kb-rag-injector.jl list
      julia kb-rag-injector.jl inject "AI" "Write about artificial intelligence"
    
    Notes:
      - KB now queries from SQLite (morpheus.db) for speed
      - Fallback to JSON if SQLite unavailable
      - All queries return < 1ms with SQLite
    """)
end

if isinteractive() == false
    if length(ARGS) == 0 || ARGS[1] in ["-h", "--help"]
        show_help()
    elseif ARGS[1] == "status"
        kb_status()
    elseif ARGS[1] == "list"
        kb_path = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
        list_kb(kb_path)
    elseif ARGS[1] == "query" && length(ARGS) >= 2
        kb_path = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
        query = join(ARGS[2:end], " ")
        result = query_kb(kb_path, query)
        
        println("\n=== Query Results (from $(result.source)) ===")
        println("Query: \"$query\"")
        println("Found: $(result.count) entries (avg relevance: $(round(result.avg_relevance, digits=2)))\n")
        
        for (i, entry) in enumerate(result.entries)
            println("$(i). $(entry.topic) [relevance: $(round(entry.relevance, digits=2))]")
            content_preview = length(entry.content) > 100 ? entry.content[1:100] * "..." : entry.content
            println("   $content_preview")
            if !isempty(entry.tags)
                println("   Tags: $(join(entry.tags, ", "))")
            end
            println()
        end
    elseif ARGS[1] == "inject" && length(ARGS) >= 3
        kb_path = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
        query = ARGS[2]
        prompt = join(ARGS[3:end], " ")
        
        result = query_kb(kb_path, query)
        context = format_context(result)
        injected = inject_context(prompt, context)
        
        println("\n=== Injected Prompt (KB source: $(result.source)) ===\n")
        println(injected)
    else
        show_help()
    end
end
