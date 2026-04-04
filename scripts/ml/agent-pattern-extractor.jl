#!/usr/bin/env julia
"""
Agent Pattern Extractor - Phase 13, Tier 1 Implementation
Extracts successful task patterns from outcomes and stores them per agent
"""

using JSON
using Statistics
using Dates

# Configuration
const MIN_REWARD = 0.7  # High-confidence threshold
const PATTERN_DIR = "data/kb/agent-patterns"
const OUTCOME_FILE = "data/rl/rl-task-execution-log.jsonl"
const OUTPUT_SUMMARY = "data/phase13-extraction-log.jsonl"

# Ensure pattern directory exists
mkpath(PATTERN_DIR)

"""
Load outcomes from JSONL file
"""
function load_outcomes()::Vector{Dict}
    outcomes = []
    if isfile(OUTCOME_FILE)
        open(OUTCOME_FILE, "r") do f
            for line in eachline(f)
                if !isempty(strip(line))
                    try
                        push!(outcomes, JSON.parse(line))
                    catch e
                        println("Warn: Failed to parse outcome: $line")
                    end
                end
            end
        end
    end
    return outcomes
end

"""
Extract task patterns from outcomes
Focuses on high-confidence outcomes (reward > MIN_REWARD)
"""
function extract_patterns(outcomes::Vector{Dict})::Dict
    agent_patterns = Dict()
    
    for outcome in outcomes
        # Skip low-confidence outcomes
        reward = get(outcome, "reward", 0.0)
        if reward < MIN_REWARD
            continue
        end
        
        # Only process successful outcomes
        if !get(outcome, "success", false)
            continue
        end
        
        agent = get(outcome, "agent", "unknown")
        task_type = get(outcome, "task_type", get(outcome, "task", "unknown"))
        
        if agent == "unknown" || task_type == "unknown"
            continue
        end
        
        # Initialize agent entry
        if !haskey(agent_patterns, agent)
            agent_patterns[agent] = Dict(
                "agent" => agent,
                "patterns" => [],
                "stats" => Dict(
                    "total_high_confidence" => 0,
                    "avg_reward" => 0.0,
                    "task_types" => Set()
                )
            )
        end
        
        # Extract pattern from outcome
        pattern = Dict(
            "task_type" => task_type,
            "timestamp" => get(outcome, "timestamp", Dates.now(UTC)),
            "success" => true,
            "reward" => reward,
            "confidence" => get(outcome, "confidence", reward),
            "metadata" => Dict(
                "task_id" => get(outcome, "task_id", ""),
                "subtask" => get(outcome, "subtask", ""),
                "complexity" => get(outcome, "complexity", "standard")
            )
        )
        
        # Add any extra context from outcome
        if haskey(outcome, "context")
            pattern["context"] = outcome["context"]
        end
        
        push!(agent_patterns[agent]["patterns"], pattern)
        agent_patterns[agent]["stats"]["total_high_confidence"] += 1
        push!(agent_patterns[agent]["stats"]["task_types"], task_type)
    end
    
    return agent_patterns
end

"""
Calculate aggregate statistics for each agent
"""
function calculate_statistics(agent_patterns::Dict)::Dict
    for (agent, data) in agent_patterns
        patterns = data["patterns"]
        if !isempty(patterns)
            rewards = [p["reward"] for p in patterns]
            data["stats"]["avg_reward"] = mean(rewards)
            data["stats"]["task_types"] = collect(data["stats"]["task_types"])
            data["stats"]["pattern_count"] = length(patterns)
            
            # Group by task type
            task_groups = Dict()
            for pattern in patterns
                task = pattern["task_type"]
                if !haskey(task_groups, task)
                    task_groups[task] = []
                end
                push!(task_groups[task], pattern)
            end
            
            data["stats"]["patterns_by_task"] = Dict(
                task => length(patterns_list) for (task, patterns_list) in task_groups
            )
        end
    end
    
    return agent_patterns
end

"""
Save patterns to agent-specific JSON files
"""
function save_agent_patterns(agent_patterns::Dict)::Int
    saved_count = 0
    
    for (agent, data) in agent_patterns
        # Sanitize agent name for filename
        safe_name = replace(lowercase(agent), " " => "_", "-" => "_")
        filename = joinpath(PATTERN_DIR, "agent-$(safe_name)-patterns.json")
        
        # Prepare output
        output = Dict(
            "agent" => agent,
            "metadata" => Dict(
                "extracted_at" => Dates.now(UTC),
                "phase" => "13",
                "tier" => "1-pattern-extraction",
                "min_reward_threshold" => MIN_REWARD
            ),
            "stats" => data["stats"],
            "patterns" => data["patterns"]
        )
        
        # Write to file
        try
            open(filename, "w") do f
                JSON.print(f, output, 4)
            end
            saved_count += 1
            println("[✓] Saved: $agent ($(length(data["patterns"])) patterns)")
        catch e
            println("[✗] Failed to save $agent: $e")
        end
    end
    
    return saved_count
end

"""
Generate extraction summary report
"""
function generate_summary(agent_patterns::Dict, total_outcomes::Int, high_confidence::Int)
    summary = Dict(
        "timestamp" => Dates.now(UTC),
        "phase" => "13",
        "tier" => "1-pattern-extraction",
        "metrics" => Dict(
            "total_outcomes_processed" => total_outcomes,
            "high_confidence_outcomes" => high_confidence,
            "confidence_threshold" => MIN_REWARD,
            "agents_with_patterns" => length(agent_patterns)
        ),
        "agents" => Dict()
    )
    
    for (agent, data) in agent_patterns
        summary["agents"][agent] = Dict(
            "patterns_extracted" => data["stats"]["total_high_confidence"],
            "avg_reward" => round(data["stats"]["avg_reward"], digits=4),
            "task_types_covered" => data["stats"]["task_types"],
            "patterns_by_task" => data["stats"]["patterns_by_task"]
        )
    end
    
    # Append to log
    try
        open(OUTPUT_SUMMARY, "a") do f
            JSON.print(f, summary)
            write(f, "\n")
        end
        println("[✓] Summary logged to $OUTPUT_SUMMARY")
    catch e
        println("[✗] Failed to write summary: $e")
    end
    
    return summary
end

"""
Main execution
"""
function main()
    println("=" ^ 80)
    println("AGENT PATTERN EXTRACTOR - Phase 13, Tier 1")
    println("=" ^ 80)
    println()
    
    # Load outcomes
    println("[*] Loading outcomes from $OUTCOME_FILE...")
    outcomes = load_outcomes()
    println("[✓] Loaded $(length(outcomes)) outcomes")
    
    # Count high-confidence
    high_confidence = length([o for o in outcomes if get(o, "reward", 0.0) > MIN_REWARD && get(o, "success", false)])
    println("[✓] High-confidence outcomes (reward > $MIN_REWARD): $high_confidence")
    println()
    
    # Extract patterns
    println("[*] Extracting patterns...")
    agent_patterns = extract_patterns(outcomes)
    println("[✓] Extracted patterns from $(length(agent_patterns)) agents")
    println()
    
    # Calculate statistics
    println("[*] Calculating statistics...")
    agent_patterns = calculate_statistics(agent_patterns)
    
    # Display per-agent summary
    sorted_agents = sort(collect(agent_patterns), by=x -> get(x[2]["stats"], "avg_reward", 0.0), rev=true)
    for (agent, data) in sorted_agents
        stats = data["stats"]
        println("[✓] $(agent):")
        println("    Patterns: $(stats["pattern_count"])")
        println("    Avg Reward: $(round(stats["avg_reward"], digits=4))")
        println("    Task Types: $(join(stats["task_types"], ", "))")
    end
    println()
    
    # Save patterns
    println("[*] Saving agent-specific pattern files...")
    saved = save_agent_patterns(agent_patterns)
    println("[✓] Saved $saved agent pattern files")
    println()
    
    # Generate summary
    println("[*] Generating extraction summary...")
    summary = generate_summary(agent_patterns, length(outcomes), high_confidence)
    println("[✓] Extraction complete!")
    println()
    
    println("=" ^ 80)
    println("SUMMARY")
    println("=" ^ 80)
    println("Agents with patterns: $(length(agent_patterns))")
    println("Total patterns extracted: $(sum(get(d["stats"], "pattern_count", 0) for (_, d) in agent_patterns))")
    println("Pattern files saved: $saved")
    println("Average reward threshold: $MIN_REWARD")
    println()
    println("Next steps:")
    println("1. Review extracted patterns in: $PATTERN_DIR")
    println("2. Integrate with Phase 7B hourly cycle")
    println("3. Update agent system prompts with learned patterns")
    println("4. Monitor Phase 7B performance (+75ms overhead)")
    println()
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
