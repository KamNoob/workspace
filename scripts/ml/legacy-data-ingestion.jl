#!/usr/bin/env julia
"""
LEGACY DATA INGESTION - Accelerate learning with historical data

Processes historical task execution logs and integrates them into:
  1. Consolidated task execution records
  2. Q-learning state (warm-start with historical success rates)
  3. Knowledge base patterns (patterns from proven outcomes)

Usage:
  julia legacy-data-ingestion.jl --ingest-all
  julia legacy-data-ingestion.jl --enhance-qlearning
  julia legacy-data-ingestion.jl --enrich-kb
  julia legacy-data-ingestion.jl --report
"""

using JSON
using Dates
using Statistics

const LEGACY_EXECUTION_LOG = "data/rl/rl-task-execution-log.jsonl"
const PHASE7B_LEARNINGS = "data/metrics/phase7b-learnings.json"
const CONSOLIDATED_LOG = "data/rl/task-execution-consolidated.jsonl"
const Q_MATRIX = "data/rl/rl-agent-selection.json"
const KB = "data/knowledge-base/extracted-patterns.json"

"""Load historical task execution log"""
function load_legacy_executions()::Vector{Dict{String,Any}}
    records = Dict{String,Any}[]
    
    if !isfile(LEGACY_EXECUTION_LOG)
        @warn "Legacy execution log not found: $LEGACY_EXECUTION_LOG"
        return records
    end
    
    for line in readlines(LEGACY_EXECUTION_LOG)
        try
            record = JSON.parse(line)
            push!(records, record)
        catch
            continue
        end
    end
    
    return records
end

"""Load Phase 7B learnings (agent insights)"""
function load_phase7b_learnings()::Dict{String,Any}
    if !isfile(PHASE7B_LEARNINGS)
        return Dict()
    end
    
    try
        return JSON.parsefile(PHASE7B_LEARNINGS)
    catch
        return Dict()
    end
end

"""Enrich consolidated log with legacy data"""
function enrich_consolidated_with_legacy()
    println("Loading legacy execution data...")
    legacy = load_legacy_executions()
    println("  Loaded $(length(legacy)) historical records")
    
    # Read existing consolidated log
    consolidated = Dict{String,Any}[]
    if isfile(CONSOLIDATED_LOG)
        for line in readlines(CONSOLIDATED_LOG)
            try
                push!(consolidated, JSON.parse(line))
            catch
                continue
            end
        end
    end
    
    println("Converting legacy records to consolidated format...")
    for rec in legacy
        task = get(rec, "task", "unknown")
        agent = get(rec, "agent", "unknown")
        success = get(rec, "success", false)
        reward = get(rec, "reward", success ? 1.0 : 0.0)
        timestamp = get(rec, "timestamp", Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ"))
        
        # Convert legacy record to consolidated schema
        quality_score = reward * 5.0  # Scale reward (0-1) to quality (0-5)
        
        consolidated_rec = Dict{String,Any}(
            "task_id" => "legacy-$(task)-$(agent)-$(hash(timestamp)%100000)",
            "task_type" => task,
            "agent" => agent,
            "timestamp" => timestamp,
            "q_score_initial" => 0.5,  # Unknown at legacy time
            "confidence" => "medium",
            "success" => success,
            "approved" => success,
            "quality_score" => round(quality_score, digits=2),
            "validation_signal" => round(quality_score / 5.0, digits=2),
            "duration_ms" => get(rec, "duration_ms", 5000),
            "cost_usd" => get(rec, "cost_usd", 0.02),
            "efficiency_score" => round((quality_score / 5.0) * 100, digits=2),
            "source" => "legacy-execution-log"
        )
        
        push!(consolidated, consolidated_rec)
    end
    
    # Write enriched consolidated log
    mkpath(dirname(CONSOLIDATED_LOG))
    open(CONSOLIDATED_LOG, "w") do f
        for rec in consolidated
            println(f, JSON.json(rec))
        end
    end
    
    println("✓ Consolidated log enriched: $(length(consolidated)) total records")
    println("  $(length(legacy)) legacy + $(length(consolidated) - length(legacy)) current")
    
    return consolidated
end

"""Enhance Q-learning with legacy success rates"""
function enhance_qlearning_with_legacy()
    println("\nEnhancing Q-learning with legacy insights...")
    
    legacy = load_legacy_executions()
    phase7b = load_phase7b_learnings()
    
    if !isfile(Q_MATRIX)
        @warn "Q-matrix not found, skipping Q-learning enhancement"
        return
    end
    
    # Load current Q-matrix
    qmatrix = JSON.parsefile(Q_MATRIX)
    
    # Calculate legacy success rates by (task, agent)
    legacy_stats = Dict{Tuple{String,String},NamedTuple}()
    
    for rec in legacy
        task = get(rec, "task", "unknown")
        agent = get(rec, "agent", "unknown")
        success = get(rec, "success", false)
        
        key = (lowercase(task), lowercase(agent))
        if !haskey(legacy_stats, key)
            legacy_stats[key] = (successes=0, total=0, success_rate=0.0)
        end
        
        old = legacy_stats[key]
        legacy_stats[key] = (
            successes = old.successes + (success ? 1 : 0),
            total = old.total + 1,
            success_rate = (old.successes + (success ? 1 : 0)) / (old.total + 1)
        )
    end
    
    # Apply legacy success rates as warmup to Q-values
    updates = 0
    for (key, stats) in legacy_stats
        task, agent = key
        
        # Find matching task type in Q-matrix
        for (task_key, task_data) in qmatrix["task_types"]
            if lowercase(task_key) == task
                if haskey(task_data["agents"], agent)
                    old_q = task_data["agents"][agent]["q_score"]
                    # Blend legacy success rate with current Q-value
                    legacy_contribution = stats.success_rate * 0.8  # Weight legacy heavily
                    new_q = 0.2 * old_q + 0.8 * stats.success_rate
                    
                    if new_q != old_q
                        println("  $task → $agent: Q $(round(old_q, digits=3)) → $(round(new_q, digits=3)) (legacy: $(round(stats.success_rate, digits=2)))")
                        
                        # Update Q-value
                        qmatrix["task_types"][task_key]["agents"][agent]["q_score"] = new_q
                        qmatrix["task_types"][task_key]["agents"][agent]["legacy_warmed"] = true
                        qmatrix["task_types"][task_key]["agents"][agent]["legacy_success_rate"] = stats.success_rate
                        qmatrix["task_types"][task_key]["agents"][agent]["legacy_samples"] = stats.total
                        
                        updates += 1
                    end
                end
                break
            end
        end
    end
    
    # Update metadata
    qmatrix["metadata"]["legacy_enhancement"] = true
    qmatrix["metadata"]["legacy_enhancement_timestamp"] = Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")
    qmatrix["metadata"]["legacy_updates"] = updates
    
    # Write enhanced Q-matrix
    open(Q_MATRIX, "w") do f
        JSON.print(f, qmatrix, 2)
    end
    
    println("✓ Q-learning enhanced: $updates agent-task pairs warmed with legacy data")
end

"""Enrich knowledge base with legacy patterns"""
function enrich_kb_with_legacy()
    println("\nEnriching knowledge base with legacy patterns...")
    
    consolidated = enrich_consolidated_with_legacy()
    
    # Group by task type
    by_task = Dict{String,Vector}()
    for rec in consolidated
        task = get(rec, "task_type", "unknown")
        if !haskey(by_task, task)
            by_task[task] = Dict[]
        end
        push!(by_task[task], rec)
    end
    
    # Generate patterns
    kb = Dict(
        "generated_at" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ"),
        "total_patterns" => 0,
        "patterns" => Dict{String,Dict}(),
        "legacy_enriched" => true
    )
    
    for (task, recs) in by_task
        successes = [get(r, "success", false) for r in recs]
        qualities = [get(r, "quality_score", 3) for r in recs if get(r, "quality_score", 0) > 0]
        costs = [get(r, "cost_usd", 0.02) for r in recs if get(r, "cost_usd", 0) > 0]
        
        # Best agent by avg quality
        agents_quality = Dict{String,Vector{Float64}}()
        for rec in recs
            agent = get(rec, "agent", "unknown")
            quality = get(rec, "quality_score", 3)
            if !haskey(agents_quality, agent)
                agents_quality[agent] = Float64[]
            end
            push!(agents_quality[agent], Float64(quality))
        end
        
        agent_avgs = Dict{String,Float64}()
        for (agent, qs) in agents_quality
            if !isempty(qs)
                agent_avgs[agent] = mean(qs)
            end
        end
        
        best_agent = isempty(agent_avgs) ? "unknown" : argmax(agent_avgs)
        
        pattern = Dict{String,Any}(
            "task_type" => task,
            "sample_size" => length(recs),
            "best_agent" => best_agent,
            "agent_scores" => agent_avgs,
            "success_rate" => length(successes) > 0 ? mean(successes) : 0.0,
            "avg_quality" => length(qualities) > 0 ? mean(qualities) : 0.0,
            "avg_cost_usd" => length(costs) > 0 ? mean(costs) : 0.0,
            "legacy_samples" => count(r -> get(r, "source", "") == "legacy-execution-log", recs),
            "extracted_at" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")
        )
        
        kb["patterns"][task] = pattern
    end
    
    kb["total_patterns"] = length(kb["patterns"])
    
    # Write enhanced KB
    mkpath(dirname(KB))
    open(KB, "w") do f
        JSON.print(f, kb, 2)
    end
    
    println("✓ Knowledge base enriched: $(kb["total_patterns"]) patterns (legacy data integrated)")
end

"""Generate ingestion report"""
function generate_report()
    legacy = load_legacy_executions()
    phase7b = load_phase7b_learnings()
    
    println("\n" * "═"^60)
    println("LEGACY DATA INGESTION REPORT")
    println("═"^60)
    
    if isempty(legacy)
        println("\n⏳ No legacy data found. System ready for real workload only.")
        return
    end
    
    println("\n📊 LEGACY DATA SUMMARY:\n")
    
    # Group by task
    by_task = Dict{String,Vector}()
    by_agent = Dict{String,Vector}()
    
    for rec in legacy
        task = get(rec, "task", "unknown")
        agent = get(rec, "agent", "unknown")
        
        if !haskey(by_task, task)
            by_task[task] = Dict[]
        end
        push!(by_task[task], rec)
        
        if !haskey(by_agent, agent)
            by_agent[agent] = Dict[]
        end
        push!(by_agent[agent], rec)
    end
    
    println("By Task Type:")
    for task in sort(collect(keys(by_task)))
        recs = by_task[task]
        success_rate = mean([get(r, "success", false) for r in recs])
        println("  $task: $(length(recs)) samples, success=$(round(success_rate*100, digits=1))%")
    end
    
    println("\nBy Agent:")
    for agent in sort(collect(keys(by_agent)))
        recs = by_agent[agent]
        success_rate = mean([get(r, "success", false) for r in recs])
        println("  $agent: $(length(recs)) samples, success=$(round(success_rate*100, digits=1))%")
    end
    
    println("\n✅ Ready to accelerate learning with $(length(legacy)) historical records")
    println("═"^60 * "\n")
end

function main()
    if length(ARGS) > 0
        cmd = ARGS[1]
        
        if cmd == "--ingest-all"
            enrich_consolidated_with_legacy()
            enhance_qlearning_with_legacy()
            enrich_kb_with_legacy()
            generate_report()
        elseif cmd == "--enhance-qlearning"
            enhance_qlearning_with_legacy()
        elseif cmd == "--enrich-kb"
            enrich_kb_with_legacy()
        elseif cmd == "--report"
            generate_report()
        else
            println("Unknown command: $cmd")
        end
    else
        generate_report()
    end
end

main()
