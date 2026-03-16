"""
kb-vector-search.jl - Vector database search interface for knowledge base

Modes: semantic, keyword, hybrid (85%+15%)
Fallback: JSON when Milvus unavailable
"""

module KBVectorSearch

using HTTP, JSON

export search, is_milvus_available

const MILVUS_HOST = "localhost"
const MILVUS_PORT = 19530
const DEFAULT_K = 5
const FALLBACK_DB = homedir() * "/.openclaw/workspace/data/kb-fallback.json"

function is_milvus_available()::Bool
    try
        response = HTTP.get(
            "http://$MILVUS_HOST:$MILVUS_PORT/healthz",
            timeout=2.0,
            status_exception=false
        )
        return response.status == 200
    catch
        return false
    end
end

function search(query::String; k::Int=DEFAULT_K, mode::String="hybrid")
    if isempty(query)
        return []
    end
    
    results = if is_milvus_available()
        if mode == "semantic"
            semantic_search(query, k)
        elseif mode == "keyword"
            keyword_search(query, k)
        else
            hybrid_search(query, k)
        end
    else
        fallback_search(query, k)
    end
    
    return format_results(results)
end

function semantic_search(query::String, k::Int)
    # Placeholder for semantic search via Milvus
    # In production, calls actual Milvus API
    try
        payload = JSON.json(Dict(
            "collection_name" => "knowledge_base",
            "vector" => query_to_vector(query),
            "limit" => k
        ))
        
        response = HTTP.post(
            "http://$MILVUS_HOST:$MILVUS_PORT/v1/search",
            ["Content-Type" => "application/json"],
            payload,
            timeout=5.0,
            status_exception=false
        )
        
        if response.status == 200
            return JSON.parse(String(response.body))
        end
    catch e
        @warn "Semantic search failed: $e"
    end
    
    return []
end

function keyword_search(query::String, k::Int)
    # Placeholder for keyword search
    try
        response = HTTP.post(
            "http://$MILVUS_HOST:$MILVUS_PORT/v1/query",
            ["Content-Type" => "application/json"],
            JSON.json(Dict("filter" => "text like \"%$query%\"", "limit" => k)),
            timeout=5.0,
            status_exception=false
        )
        
        if response.status == 200
            return JSON.parse(String(response.body))
        end
    catch e
        @warn "Keyword search failed: $e"
    end
    
    return []
end

function hybrid_search(query::String, k::Int)
    semantic = semantic_search(query, k)
    keyword = keyword_search(query, k)
    
    merged = Dict()
    
    for result in semantic
        id = string(get(result, "id", "unknown"))
        score = get(result, "score", 0.0) * 0.85
        merged[id] = merge(result, Dict("score" => score, "source_type" => "semantic"))
    end
    
    for result in keyword
        id = string(get(result, "id", "unknown"))
        score = get(result, "score", 0.0) * 0.15
        if haskey(merged, id)
            merged[id]["score"] += score
            merged[id]["source_type"] = "hybrid"
        else
            merged[id] = merge(result, Dict("score" => score, "source_type" => "keyword"))
        end
    end
    
    sorted = sort(collect(values(merged)), by=x -> get(x, "score", 0.0), rev=true)
    return sorted[1:min(k, length(sorted))]
end

function query_to_vector(query::String)
    # Placeholder: hash-based for testing
    Random.seed!(hash(query) % Int32)
    return Float32.(randn(384))
end

function fallback_search(query::String, k::Int)
    if !isfile(FALLBACK_DB)
        return []
    end
    
    try
        data = JSON.parsefile(FALLBACK_DB)
        docs = get(data, "documents", [])
        
        query_lower = lowercase(query)
        results = []
        
        for doc in docs
            text = lowercase(get(doc, "text", ""))
            if occursin(query_lower, text)
                push!(results, merge(doc, Dict(
                    "score" => 0.5,
                    "source_type" => "fallback"
                )))
            end
        end
        
        sorted = sort(results, by=x -> get(x, "score", 0.0), rev=true)
        return sorted[1:min(k, length(sorted))]
    catch e
        @warn "Fallback search failed: $e"
        return []
    end
end

function format_results(results::Vector)
    formatted = []
    for result in results
        push!(formatted, Dict(
            "id" => string(get(result, "id", "unknown")),
            "text" => get(result, "text", ""),
            "score" => Float64(get(result, "score", 0.0)),
            "metadata" => get(result, "metadata", Dict()),
            "source" => get(result, "source", "unknown")
        ))
    end
    return formatted
end

end  # module
