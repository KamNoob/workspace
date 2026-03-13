#!/usr/bin/env julia
"""
kb-confidence-scorer.jl - KB Retrieval Confidence Scoring

Scores the confidence level of KB retrieval results and flags
low-confidence matches that need research or verification.

CLI Usage:
  julia kb-confidence-scorer.jl --help            Show help
  julia kb-confidence-scorer.jl score <query>     Score KB retrieval
  julia kb-confidence-scorer.jl evaluate <results> Evaluate result quality
  julia kb-confidence-scorer.jl flag-gaps         Identify gaps needing research
"""

using JSON
using Statistics

# ============================================================================
# Constants & Configuration
# ============================================================================

const DEFAULT_KB_PATH = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")
const CONFIDENCE_THRESHOLD = 0.6  # Below this = flag for review
const MIN_RETRIEVAL_COUNT = 3     # Need at least N results for confidence

# ============================================================================
# Data Structures
# ============================================================================

struct ScoredResult
    query::String
    entries::Vector{Dict}
    confidence::Float64
    flags::Vector{String}
    recommendation::String
end

# ============================================================================
# Scoring Functions
# ============================================================================

function tokenize(text::String)::Vector{String}
    text = lowercase(text)
    words = split(replace(text, r"[^\w\s]" => " "), r"\s+")
    return filter(!isempty, words)
end

function compute_match_diversity(entries::Vector{Dict})::Float64
    if length(entries) <= 1
        return 0.0
    end
    
    # Measure how diverse the results are (avoid redundancy)
    total_diversity = 0.0
    count = 0
    
    for i in 1:(length(entries)-1)
        tokens_i = Set(tokenize(entries[i]["topic"]))
        for j in (i+1):length(entries)
            tokens_j = Set(tokenize(entries[j]["topic"]))
            intersection = length(intersect(tokens_i, tokens_j))
            union_size = length(union(tokens_i, tokens_j))
            diversity = 1.0 - (intersection / max(union_size, 1))
            total_diversity += diversity
            count += 1
        end
    end
    
    return count > 0 ? total_diversity / count : 0.0
end

function compute_relevance_consistency(entries::Vector{Dict})::Float64
    if length(entries) == 0
        return 0.0
    end
    
    # Check consistency: are all results similarly relevant?
    relevances = [get(e, "relevance", 0.5) for e in entries]
    
    if length(relevances) <= 1
        return 1.0
    end
    
    # Standard deviation of relevances (lower = more consistent)
    std_dev = std(relevances)
    consistency = 1.0 - std_dev
    
    return max(0.0, consistency)
end

function compute_coverage_score(query::String, entries::Vector{Dict})::Float64
    # How well do the results cover the query?
    if isempty(entries)
        return 0.0
    end
    
    query_tokens = Set(tokenize(query))
    covered_tokens = Set()
    
    for entry in entries
        topic_tokens = Set(tokenize(entry["topic"]))
        union!(covered_tokens, topic_tokens)
    end
    
    intersection = length(intersect(query_tokens, covered_tokens))
    coverage = intersection / max(length(query_tokens), 1)
    
    return min(coverage, 1.0)
end

function compute_confidence_score(query::String, entries::Vector{Dict})::Tuple{Float64, Vector{String}}
    flags = String[]
    
    # Check 1: Have enough results?
    if length(entries) < MIN_RETRIEVAL_COUNT
        push!(flags, "low_result_count: only $(length(entries)) results found")
    end
    
    # Check 2: Are all results relevant?
    if !isempty(entries)
        min_relevance = minimum([get(e, "relevance", 0.5) for e in entries])
        if min_relevance < 0.4
            push!(flags, "low_minimum_relevance: $(round(min_relevance, digits=2))")
        end
    end
    
    # Check 3: Results too similar (low diversity)?
    diversity = compute_match_diversity(entries)
    if diversity < 0.3
        push!(flags, "low_diversity: results are too similar")
    end
    
    # Check 4: Relevance consistency
    consistency = compute_relevance_consistency(entries)
    if consistency < 0.5
        push!(flags, "inconsistent_relevance: results vary widely")
    end
    
    # Check 5: Coverage of query
    coverage = compute_coverage_score(query, entries)
    if coverage < 0.4
        push!(flags, "low_query_coverage: $(round(Int, coverage*100))% of query covered")
    end
    
    # Compute composite confidence
    score_components = []
    
    push!(score_components, min(length(entries) / MIN_RETRIEVAL_COUNT, 1.0))
    if !isempty(entries)
        push!(score_components, mean([get(e, "relevance", 0.5) for e in entries]))
    end
    push!(score_components, diversity)
    push!(score_components, consistency)
    push!(score_components, coverage)
    
    composite_score = mean(score_components)
    
    return composite_score, flags
end

function score_retrieval(kb_path::String, query::String)::ScoredResult
    # Load KB
    if !isfile(kb_path)
        return ScoredResult(query, [], 0.0, ["no_kb_found"], "Initialize KB first")
    end
    
    kb = JSON.parsefile(kb_path)
    entries = get(kb, "entries", [])
    
    # Score each entry against query
    scored = Dict[]
    for entry in entries
        query_tokens = tokenize(query)
        entry_tokens = tokenize(entry["topic"])
        
        matches = 0
        for t in query_tokens
            if t in entry_tokens
                matches += 1
            end
        end
        relevance = matches / max(length(query_tokens), 1)
        
        if relevance > 0.0
            scored_entry = copy(entry)
            scored_entry["relevance"] = relevance
            push!(scored, scored_entry)
        end
    end
    
    # Sort by relevance
    sort!(scored, by=e->e["relevance"], rev=true)
    
    # Compute confidence score
    confidence, flags = compute_confidence_score(query, scored)
    
    # Generate recommendation
    recommendation = if confidence >= 0.8
        "✓ High confidence. Results are suitable for use."
    elseif confidence >= CONFIDENCE_THRESHOLD
        "⚠ Medium confidence. Consider Scout research for verification."
    else
        "❌ Low confidence. Recommend Scout investigation before using."
    end
    
    return ScoredResult(query, scored, confidence, flags, recommendation)
end

function evaluate_results(results::Vector{Dict})::Dict
    # Detailed evaluation of result quality
    diversity = compute_match_diversity(results)
    consistency = compute_relevance_consistency(results)
    
    return Dict(
        "count" => length(results),
        "diversity" => round(diversity, digits=2),
        "consistency" => round(consistency, digits=2),
        "avg_relevance" => isempty(results) ? 0.0 : round(mean([get(r, "relevance", 0.5) for r in results]), digits=2),
        "min_relevance" => isempty(results) ? 0.0 : round(minimum([get(r, "relevance", 0.5) for r in results]), digits=2),
        "max_relevance" => isempty(results) ? 0.0 : round(maximum([get(r, "relevance", 0.5) for r in results]), digits=2),
    )
end

# ============================================================================
# CLI Interface
# ============================================================================

function show_help()
    println("""
    kb-confidence-scorer.jl - KB Retrieval Confidence Scoring
    
    Usage:
      julia kb-confidence-scorer.jl --help           Show this help
      julia kb-confidence-scorer.jl score <query>    Score retrieval quality
      julia kb-confidence-scorer.jl eval <results>   Evaluate result metrics
    
    Options:
      --kb-file <path>     Path to KB file
      --threshold <f>      Confidence threshold (0-1)
    
    Examples:
      julia kb-confidence-scorer.jl score "agent selection"
      julia kb-confidence-scorer.jl eval "[{...}, {...}]"
    
    Confidence Levels:
      >= 0.80   : High confidence ✓ (use directly)
      0.60-0.79 : Medium confidence ⚠ (verify with Scout)
      < 0.60    : Low confidence ❌ (escalate for research)
    """)
end

if isinteractive() == false
    local kb_file = DEFAULT_KB_PATH
    
    # Parse options
    local args = copy(ARGS)
    local idx = 1
    while idx <= length(args)
        if args[idx] == "--kb-file" && idx + 1 <= length(args)
            kb_file = args[idx+1]
            deleteat!(args, idx:idx+1)
        else
            idx += 1
        end
    end
    
    if length(args) == 0 || args[1] in ["-h", "--help"]
        show_help()
    elseif args[1] == "score" && length(args) >= 2
        query = join(args[2:end], " ")
        result = score_retrieval(kb_file, query)
        
        println("\n=== KB Retrieval Confidence Score ===")
        println("Query: \"$query\"")
        println("Confidence: $(round(result.confidence, digits=2)) ($(Int(round(result.confidence*100)))%)")
        println("$(result.recommendation)\n")
        
        println("Results Found: $(length(result.entries))")
        if !isempty(result.entries)
            for (i, entry) in enumerate(result.entries[1:min(3, end)])
                println("  $(i). $(entry["topic"]) (relevance: $(round(entry["relevance"], digits=2)))")
            end
        end
        
        if !isempty(result.flags)
            println("\nFlags:")
            for flag in result.flags
                println("  ⚠ $flag")
            end
        end
        
    elseif args[1] == "eval" && length(args) >= 2
        # Parse JSON results
        try
            json_str = join(args[2:end], " ")
            results = JSON.parse(json_str)
            
            metrics = evaluate_results(results)
            
            println("\n=== Result Evaluation ===")
            for (k, v) in metrics
                println("$k: $v")
            end
        catch e
            println("Error parsing results: $e")
        end
    else
        show_help()
    end
end
