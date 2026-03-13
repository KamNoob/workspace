"""
KB Integration Module - Live RAG Context Injection
Integrates knowledge base retrieval into agent spawning.
"""

module KBIntegration

using JSON
using Dates

export get_kb_context, augment_prompt, kb_enabled

const KB_PATH = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
const KB_CONFIDENCE_THRESHOLD = 0.6
const MAX_CONTEXT_ENTRIES = 3

"""
    get_kb_context(query::String; threshold=0.6)::Dict

Retrieve KB context for a query with confidence filtering.
"""
function get_kb_context(query::String; threshold::Float64=KB_CONFIDENCE_THRESHOLD)::Dict
    result = Dict(
        "found" => false,
        "entries" => [],
        "confidences" => [],
        "count" => 0,
        "reason" => ""
    )
    
    if !isfile(KB_PATH)
        result["reason"] = "KB file not found"
        return result
    end
    
    try
        kb_data = JSON.parsefile(KB_PATH)
        entries = get(kb_data, "entries", [])
        
        if isempty(entries)
            result["reason"] = "KB is empty"
            return result
        end
        
        # Score entries
        scored = []
        for entry in entries
            # Convert JSON object to regular Dict
            entry_dict = Dict(entry)
            score = score_entry(entry_dict, query)
            if score >= threshold
                push!(scored, (entry_dict, score))
            end
        end
        
        if isempty(scored)
            result["reason"] = "No entries above threshold"
            return result
        end
        
        # Sort by score
        sort!(scored, by=x->x[2], rev=true)
        
        # Take top entries
        top_n = min(MAX_CONTEXT_ENTRIES, length(scored))
        
        for i in 1:top_n
            entry, score = scored[i]
            push!(result["entries"], entry["content"])
            push!(result["confidences"], score)
        end
        
        result["found"] = true
        result["count"] = length(result["entries"])
        result["reason"] = "Retrieved $(result["count"]) entries"
        
    catch e
        result["reason"] = "Error: $(string(e))"
    end
    
    return result
end

"""
    score_entry(entry::Dict, query::String)::Float64

Score relevance of KB entry to query (0-1).
"""
function score_entry(entry::Dict, query::String)::Float64
    topic = lowercase(get(entry, "topic", ""))
    content = lowercase(get(entry, "content", ""))
    tags_raw = get(entry, "tags", [])
    tags = String[]
    for tag in tags_raw
        push!(tags, lowercase(string(tag)))
    end
    query_lower = lowercase(query)
    
    query_words = split(query_lower, r"[^\w]+")
    
    # Topic matching (highest weight)
    topic_matches = 0
    for word in query_words
        if occursin(word, topic)
            topic_matches += 1
        end
    end
    topic_matches = topic_matches / max(length(query_words), 1)
    
    # Tag matching
    tag_matches = 0
    if !isempty(tags)
        for word in query_words
            if word in tags
                tag_matches += 1
            end
        end
        tag_matches = tag_matches / length(tags)
    else
        tag_matches = 0.0
    end
    
    # Content matching
    content_matches = 0
    for word in query_words
        if occursin(word, content)
            content_matches += 1
        end
    end
    content_matches = content_matches / max(length(query_words), 1)
    
    score = 0.5 * topic_matches + 0.2 * tag_matches + 0.3 * content_matches
    
    return min(1.0, score)
end

"""
    augment_prompt(base_prompt::String, kb_context::Dict)::String

Augment prompt with KB context if available.
"""
function augment_prompt(base_prompt::String, kb_context::Dict)::String
    if !kb_context["found"] || kb_context["count"] == 0
        return base_prompt
    end
    
    kb_block = "\n\n" * "="^70 * "\n"
    kb_block *= "KNOWLEDGE BASE CONTEXT (Confidence-based RAG)\n"
    kb_block *= "="^70 * "\n\n"
    
    for (i, entry) in enumerate(kb_context["entries"])
        conf = round(Int, kb_context["confidences"][i] * 100)
        kb_block *= "[$conf% confidence] $entry\n\n"
    end
    
    kb_block *= "Use this context to inform your decisions.\n"
    kb_block *= "="^70 * "\n"
    
    return base_prompt * kb_block
end

"""
    kb_enabled()::Bool

Check if KB is available for integration.
"""
function kb_enabled()::Bool
    return isfile(KB_PATH)
end

end # module
