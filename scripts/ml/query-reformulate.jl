#!/usr/bin/env julia
"""
query-reformulate.jl - Query Expansion & Reformulation

Generates query variants and expands queries from multiple angles
(technical, conceptual, practical) for better KB coverage.

CLI Usage:
  julia query-reformulate.jl --help           Show help
  julia query-reformulate.jl expand <query>   Generate query variants
  julia query-reformulate.jl rerank <results> Re-rank results for diversity
"""

using JSON

# ============================================================================
# Query Expansion Engine
# ============================================================================

const SYNONYMS = Dict(
    "agent" => ["agent", "model", "assistant", "worker", "executor"],
    "select" => ["select", "choose", "pick", "assign", "route"],
    "learn" => ["learn", "optimize", "improve", "train", "adapt"],
    "task" => ["task", "job", "work", "request", "operation"],
    "security" => ["security", "safety", "threat", "vulnerability", "attack"],
    "code" => ["code", "script", "program", "implementation", "develop"],
    "research" => ["research", "analyze", "investigate", "explore", "study"],
    "strategy" => ["strategy", "approach", "method", "technique", "plan"],
    "performance" => ["performance", "speed", "efficiency", "optimization", "throughput"],
    "confidence" => ["confidence", "certainty", "probability", "trust", "reliability"],
)

const EXPANSIONS = Dict(
    "agent selection" => [
        "how to choose agents for tasks",
        "agent routing and assignment",
        "optimal agent matching",
        "agent capability matching",
        "multi-agent task allocation"
    ],
    "learning" => [
        "reinforcement learning approaches",
        "adaptive optimization",
        "online learning systems",
        "continuous improvement"
    ],
    "security audit" => [
        "code security review",
        "vulnerability assessment",
        "threat analysis",
        "security best practices"
    ]
)

# ============================================================================
# Core Functions
# ============================================================================

function tokenize(text::String)::Vector{String}
    text = lowercase(text)
    words = split(replace(text, r"[^\w\s]" => " "), r"\s+")
    return filter(!isempty, words)
end

function expand_query(query::String)::Vector{String}
    query_lower = lowercase(query)
    variants = [query]  # Include original
    
    # Check for predefined expansions
    for (key, expansions) in EXPANSIONS
        if contains(query_lower, key)
            append!(variants, expansions)
            return unique(variants)
        end
    end
    
    # Generate synonyms-based expansions
    tokens = tokenize(query)
    for token in tokens
        if haskey(SYNONYMS, token)
            for syn in SYNONYMS[token]
                if syn != token
                    variant = replace(query_lower, token => syn)
                    push!(variants, variant)
                end
            end
        end
    end
    
    # Add angle variations
    push!(variants, "technical: " * query)
    push!(variants, "practical: " * query)
    push!(variants, "conceptual: " * query)
    push!(variants, "best practices: " * query)
    
    return unique(variants)
end

function query_diversity_score(q1::String, q2::String)::Float64
    # Higher score = more different queries
    tokens1 = Set(tokenize(q1))
    tokens2 = Set(tokenize(q2))
    
    intersection = length(intersect(tokens1, tokens2))
    union_size = length(union(tokens1, tokens2))
    
    return 1.0 - (intersection / max(union_size, 1))
end

function select_diverse_queries(queries::Vector{String}, n::Int=3)::Vector{String}
    if length(queries) <= n
        return queries
    end
    
    selected = [queries[1]]  # Start with first
    
    while length(selected) < n && length(selected) < length(queries)
        best_idx = 1
        best_diversity = 0.0
        
        for (i, q) in enumerate(queries)
            if !(q in selected)
                # Average diversity from all selected
                avg_div = mean([query_diversity_score(q, s) for s in selected])
                if avg_div > best_diversity
                    best_diversity = avg_div
                    best_idx = i
                end
            end
        end
        
        push!(selected, queries[best_idx])
    end
    
    return selected
end

function rerank_results(results::Vector{Dict}, diversity_weight::Float64=0.3)::Vector{Dict}
    if length(results) <= 1
        return results
    end
    
    # Re-rank with diversity penalty (avoid too similar results)
    ranked = copy(results)
    
    for i in 2:length(ranked)
        # Penalize if too similar to previous results
        min_diversity = minimum([
            query_diversity_score(ranked[i]["content"], ranked[j]["content"])
            for j in 1:(i-1)
        ])
        
        # Adjust relevance with diversity
        original_rel = get(ranked[i], "relevance", 0.5)
        ranked[i]["relevance"] = (1.0 - diversity_weight) * original_rel + 
                                  diversity_weight * min_diversity
    end
    
    sort!(ranked, by=r -> r["relevance"], rev=true)
    return ranked
end

function multi_angle_query(query::String)::Dict
    variants = expand_query(query)
    selected = select_diverse_queries(variants, 3)
    
    return Dict(
        "original" => query,
        "variants" => variants,
        "recommended" => selected,
        "angles" => Dict(
            "technical" => "technical aspects of $(query)",
            "practical" => "practical implementation of $(query)",
            "conceptual" => "conceptual understanding of $(query)"
        )
    )
end

# ============================================================================
# CLI Interface
# ============================================================================

function show_help()
    println("""
    query-reformulate.jl - Query Expansion & Reformulation
    
    Usage:
      julia query-reformulate.jl --help              Show this help
      julia query-reformulate.jl expand <query>      Expand query into variants
      julia query-reformulate.jl angles <query>      Get multi-angle queries
    
    Examples:
      julia query-reformulate.jl expand "agent selection"
      julia query-reformulate.jl angles "learning"
    """)
end

if isinteractive() == false
    if length(ARGS) == 0 || ARGS[1] in ["-h", "--help"]
        show_help()
    elseif ARGS[1] == "expand" && length(ARGS) >= 2
        query = join(ARGS[2:end], " ")
        variants = expand_query(query)
        
        println("\n=== Query Expansion ===")
        println("Original: \"$query\"")
        println("\nVariants:")
        for (i, v) in enumerate(variants[1:min(5, end)])
            println("  $i. $v")
        end
        
    elseif ARGS[1] == "angles" && length(ARGS) >= 2
        query = join(ARGS[2:end], " ")
        result = multi_angle_query(query)
        
        println("\n=== Multi-Angle Query ===")
        println("Original: \"$(result["original"])\"")
        println("\nRecommended Variants:")
        for (i, v) in enumerate(result["recommended"])
            println("  $i. $v")
        end
        
        println("\nAngle Suggestions:")
        for (angle, suggestion) in result["angles"]
            println("  • $(ucfirst(angle)): $suggestion")
        end
        
    else
        show_help()
    end
end
