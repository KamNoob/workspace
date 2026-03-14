#!/usr/bin/env julia
"""
    arduino-kb-injector.jl

Hardware Context Injection for Agent Spawner

Retrieves relevant Arduino/ESP32 context from knowledge base
and injects into agent spawn prompts.

Usage:
    julia arduino-kb-injector.jl query "compile esp32 sketch"
    julia arduino-kb-injector.jl inject "compile esp32 sketch" Codex

Output: Context blocks with confidence scoring
"""

using JSON
using Dates

# ============================================================================
# Configuration
# ============================================================================

KB_PATH = "data/knowledge-bases/arduino-reference-kb.json"
MIN_CONFIDENCE = 0.60

# ============================================================================
# Knowledge Base Loading
# ============================================================================

function load_kb()
    """Load Arduino knowledge base"""
    if !isfile(KB_PATH)
        @warn "Knowledge base not found: $KB_PATH"
        return Dict()
    end
    
    kb_data = JSON.parsefile(KB_PATH)
    return Dict(kb_data)
end

# ============================================================================
# Semantic Matching
# ============================================================================

function tokenize(text::String)::Vector{String}
    """Simple tokenization"""
    words = lowercase(text) |>
        s -> split(s, r"[^a-z0-9_]+") |>
        words -> filter(w -> length(w) > 0, words)
    return words
end

function compute_relevance(query_tokens::Vector{String}, entry_tags::Vector{String})::Float32
    """Compute relevance score between query and entry"""
    if isempty(query_tokens) || isempty(entry_tags)
        return 0.0f0
    end
    
    matches = 0
    for token in query_tokens
        for tag in entry_tags
            if token == tag || startswith(tag, token)
                matches += 1
            end
        end
    end
    
    # Normalize: 0-1 scale
    max_possible = length(query_tokens)
    score = min(1.0f0, Float32(matches) / Float32(max_possible))
    return score
end

function query_kb(query::String, kb::Dict)::Vector
    """Query knowledge base for relevant entries"""
    if isempty(kb)
        return []
    end
    
    query_tokens = tokenize(query)
    entries = get(kb, "entries", [])
    
    results = []
    
    for entry in entries
        tags = String.(get(entry, "tags", String[]))
        title = get(entry, "title", "")
        content = get(entry, "content", "")
        confidence = get(entry, "confidence", 0.5)
        
        # Relevance score from tag matching
        relevance = compute_relevance(query_tokens, tags)
        
        # Combined confidence
        combined_confidence = (relevance + Float32(confidence)) / 2.0f0
        
        if combined_confidence >= MIN_CONFIDENCE
            push!(results, Dict(
                :id => get(entry, "id", 0),
                :title => title,
                :content => content,
                :tags => tags,
                :confidence => combined_confidence,
                :source_confidence => confidence,
                :relevance_score => relevance
            ))
        end
    end
    
    # Sort by confidence descending
    sort!(results, by = x -> x[:confidence], rev = true)
    
    return results
end

# ============================================================================
# Context Formatting
# ============================================================================

function format_context_block(entry::Dict)::String
    """Format entry as context block"""
    confidence_pct = Int(round(entry[:confidence] * 100))
    
    block = """
═══════════════════════════════════════
📌 $(entry[:title]) (confidence: $(confidence_pct)%)
───────────────────────────────────────
$(entry[:content])

Tags: $(join(entry[:tags], ", "))
═══════════════════════════════════════
"""
    return block
end

function inject_context(query::String, agent::String, kb::Dict)::String
    """Generate context-injected prompt"""
    results = query_kb(query, kb)
    
    if isempty(results)
        return "No hardware context found for: $query"
    end
    
    context = "🔧 HARDWARE CONTEXT FOR $agent\n"
    context *= "Query: $query\n"
    context *= "Found $(length(results)) relevant entries\n\n"
    
    for (i, entry) in enumerate(results[1:min(3, length(results))])
        context *= format_context_block(entry)
        context *= "\n"
    end
    
    return context
end

# ============================================================================
# Statistics & Logging
# ============================================================================

function log_query(query::String, agent::String, results_count::Int)
    """Log query for tracking"""
    timestamp = now()
    log_file = "data/rl/arduino-kb-queries.jsonl"
    
    record = Dict(
        :timestamp => timestamp,
        :query => query,
        :agent => agent,
        :results_count => results_count
    )
    
    open(log_file, "a") do f
        write(f, JSON.json(record) * "\n")
    end
end

# ============================================================================
# Main: CLI Interface
# ============================================================================

function main()
    args = ARGS
    
    if isempty(args)
        println("Usage:")
        println("  julia arduino-kb-injector.jl query \"<query>\"")
        println("  julia arduino-kb-injector.jl inject \"<query>\" \"<agent>\"")
        return
    end
    
    action = args[1]
    kb = load_kb()
    
    if action == "query"
        if length(args) < 2
            println("Error: query requires <query> argument")
            return
        end
        
        query = args[2]
        results = query_kb(query, kb)
        
        println("\n🔍 Arduino KB Query Results")
        println("===========================\n")
        println("Query: $query")
        println("Found: $(length(results)) entries\n")
        
        for entry in results
            println("• $(entry[:title])")
            println("  Confidence: $(Int(round(entry[:confidence] * 100)))%")
            println("  Tags: $(join(entry[:tags], ", "))")
            println()
        end
        
        log_query(query, "query", length(results))
        
    elseif action == "inject"
        if length(args) < 3
            println("Error: inject requires <query> and <agent> arguments")
            return
        end
        
        query = args[2]
        agent = args[3]
        context = inject_context(query, agent, kb)
        
        println(context)
        
        results = query_kb(query, kb)
        log_query(query, agent, length(results))
        
    elseif action == "stats"
        println("\n📊 Arduino KB Statistics")
        println("========================\n")
        
        metadata = get(kb, "metadata", Dict())
        println("Title: $(get(metadata, "title", "N/A"))")
        println("Version: $(get(metadata, "version", "N/A"))")
        println("Total entries: $(length(get(kb, "entries", [])))")
        println("Domains: $(join(get(metadata, "domains", []), ", "))")
        println()
        
    else
        println("Unknown action: $action")
        println("Available: query, inject, stats")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
