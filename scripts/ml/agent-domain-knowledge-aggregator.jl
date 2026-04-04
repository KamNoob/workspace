#!/usr/bin/env julia
"""
Agent Domain Knowledge Aggregator - Phase 13, Tier 2 Implementation
Consolidates extracted patterns into structured domain knowledge per agent
"""

using JSON
using Statistics
using Dates

# Configuration
const PATTERN_DIR = "data/kb/agent-patterns"
const OUTPUT_DIR = "data/kb/agent-domain-knowledge"
const DOMAIN_KNOWLEDGE_LOG = "data/phase13-domain-knowledge-log.jsonl"

# Ensure output directory exists
mkpath(OUTPUT_DIR)

"""
Load patterns from agent-specific files
"""
function load_agent_patterns(agent::String)::Dict
    safe_name = replace(lowercase(agent), " " => "_", "-" => "_")
    filename = joinpath(PATTERN_DIR, "agent-$(safe_name)-patterns.json")
    
    if !isfile(filename)
        return Dict()
    end
    
    try
        return JSON.parse(read(filename, String))
    catch e
        println("Warn: Failed to load patterns for $agent: $e")
        return Dict()
    end
end

"""
Extract domain frameworks from patterns
Groups patterns by common themes/frameworks
"""
function extract_frameworks(agent::String, patterns_data::Dict)::Dict
    patterns = get(patterns_data, "patterns", [])
    
    frameworks = Dict()
    for pattern in patterns
        task_type = pattern["task_type"]
        
        # Group by task type as framework
        if !haskey(frameworks, task_type)
            frameworks[task_type] = Dict(
                "name" => task_type,
                "frequency" => 0,
                "avg_reward" => 0.0,
                "examples" => []
            )
        end
        
        fw = frameworks[task_type]
        fw["frequency"] += 1
        push!(fw["examples"], pattern["task_type"])
        fw["avg_reward"] += pattern["reward"]
    end
    
    # Calculate averages
    for (_, fw) in frameworks
        if fw["frequency"] > 0
            fw["avg_reward"] = fw["avg_reward"] / fw["frequency"]
        end
    end
    
    return frameworks
end

"""
Extract success indicators from patterns
Identifies common characteristics of successful outcomes
"""
function extract_success_indicators(agent::String, patterns_data::Dict)::Dict
    patterns = get(patterns_data, "patterns", [])
    stats = get(patterns_data, "stats", Dict())
    
    indicators = Dict()
    
    # Calculate overall success metrics
    avg_reward = get(stats, "avg_reward", 0.0)
    total_patterns = length(patterns)
    
    # Extract task types as success indicators
    task_types = get(stats, "task_types", [])
    
    indicators["high_avg_reward"] = Dict(
        "threshold" => avg_reward,
        "description" => "Consistent high-quality outcomes (avg reward > $avg_reward)",
        "indicator" => avg_reward > 0.85
    )
    
    indicators["success_rate"] = Dict(
        "value" => 1.0,  # All extracted patterns are successes
        "description" => "Perfect success rate on high-confidence tasks",
        "indicator" => true
    )
    
    indicators["domain_coverage"] = Dict(
        "task_count" => length(task_types),
        "task_types" => task_types,
        "description" => "Broad capability across multiple task types",
        "indicator" => length(task_types) >= 3
    )
    
    # Agent-specific indicators
    if agent == "Cipher"
        indicators["security_frameworks"] = Dict(
            "value" => ["OWASP Top 10", "CVE/CWE", "CVSS v3.1"],
            "description" => "Applies industry-standard security frameworks",
            "indicator" => true
        )
    elseif agent == "Scout"
        indicators["source_diversity"] = Dict(
            "value" => "Cross-reference multiple sources",
            "description" => "Validates findings against 3+ independent sources",
            "indicator" => true
        )
    elseif agent == "Codex"
        indicators["architecture_analysis"] = Dict(
            "value" => "Design pattern evaluation",
            "description" => "Evaluates code architecture and design patterns",
            "indicator" => true
        )
    elseif agent == "Veritas"
        indicators["code_quality"] = Dict(
            "value" => "Style, maintainability, security",
            "description" => "Reviews code for quality, style, and best practices",
            "indicator" => true
        )
    elseif agent == "Chronicle"
        indicators["clarity_structure"] = Dict(
            "value" => "Clear organization and examples",
            "description" => "Documentation is well-structured with examples",
            "indicator" => true
        )
    end
    
    return indicators
end

"""
Extract pitfalls (anti-patterns) from failure cases if available
"""
function extract_pitfalls(agent::String, patterns_data::Dict)::Dict
    pitfalls = Dict()
    
    # Agent-specific known pitfalls
    if agent == "Cipher"
        pitfalls["missed_edge_cases"] = Dict(
            "severity" => "medium",
            "description" => "Incomplete authentication edge case coverage",
            "mitigation" => "Systematically check token refresh, expiry, and invalid token scenarios"
        )
        pitfalls["weak_privilege_checks"] = Dict(
            "severity" => "high",
            "description" => "Insufficient privilege escalation testing",
            "mitigation" => "Test role transitions, permission boundaries, and lateral movement"
        )
    elseif agent == "Scout"
        pitfalls["single_source_reliance"] = Dict(
            "severity" => "medium",
            "description" => "Over-relying on single source",
            "mitigation" => "Always cross-reference with 3+ independent sources"
        )
        pitfalls["outdated_information"] = Dict(
            "severity" => "high",
            "description" => "Using outdated information",
            "mitigation" => "Verify publication date, check for newer versions"
        )
    elseif agent == "Codex"
        pitfalls["shallow_analysis"] = Dict(
            "severity" => "medium",
            "description" => "Insufficient depth in architecture evaluation",
            "mitigation" => "Dig deeper into performance implications and scalability"
        )
        pitfalls["missing_edge_cases"] = Dict(
            "severity" => "medium",
            "description" => "Overlooked error handling",
            "mitigation" => "Systematically check error paths and edge conditions"
        )
    end
    
    return pitfalls
end

"""
Generate domain knowledge summary per agent
"""
function generate_domain_knowledge(agent::String, patterns_data::Dict)::Dict
    frameworks = extract_frameworks(agent, patterns_data)
    indicators = extract_success_indicators(agent, patterns_data)
    pitfalls = extract_pitfalls(agent, patterns_data)
    
    stats = get(patterns_data, "stats", Dict())
    
    domain_knowledge = Dict(
        "agent" => agent,
        "metadata" => Dict(
            "generated_at" => Dates.now(UTC),
            "phase" => "13",
            "tier" => "2-domain-knowledge",
            "source" => "$(length(get(patterns_data, "patterns", []))) extracted patterns"
        ),
        "domain_summary" => Dict(
            "agent_role" => get_agent_role(agent),
            "specialization" => get_agent_specialization(agent),
            "proven_approaches" => length(frameworks),
            "success_rate" => 1.0,
            "avg_reward" => float(get(stats, "avg_reward", 0.0))
        ),
        "frameworks" => frameworks,
        "success_indicators" => indicators,
        "pitfalls" => pitfalls,
        "recommendations" => Dict(
            "when_to_use" => "$(agent) is optimal for " * get_optimal_use_case(agent),
            "confidence" => get_confidence_level(agent, get(patterns_data, "stats", Dict())),
            "avoid_when" => get_avoid_scenario(agent)
        )
    )
    
    return domain_knowledge
end

"""
Helper functions for agent-specific information
"""
function get_agent_role(agent::String)::String
    roles = Dict(
        "Cipher" => "Security & Threat Assessment Specialist",
        "Scout" => "Research & Information Gathering Specialist",
        "Codex" => "Code Development & Architecture Specialist",
        "Veritas" => "Code Review & Quality Assurance Specialist",
        "Chronicle" => "Documentation & Technical Writing Specialist",
        "QA" => "Testing & Quality Assurance Specialist",
        "Sentinel" => "Infrastructure & DevOps Specialist"
    )
    return get(roles, agent, "Specialist")
end

function get_agent_specialization(agent::String)::String
    specs = Dict(
        "Cipher" => "Security audits, penetration testing, threat modeling, vulnerability assessment",
        "Scout" => "Research, information gathering, analysis, documentation, system architecture",
        "Codex" => "Code development, user guides, API documentation, architecture analysis",
        "Veritas" => "Code review, pull request validation, architecture evaluation",
        "Chronicle" => "Onboarding guides, documentation, API docs, technical specifications",
        "QA" => "Test strategy design, integration testing",
        "Sentinel" => "API security, system architecture, distributed systems"
    )
    return get(specs, agent, "General specialization")
end

function get_optimal_use_case(agent::String)::String
    cases = Dict(
        "Cipher" => "security-critical systems and audits",
        "Scout" => "research-intensive tasks and complex analysis",
        "Codex" => "code development and architectural decisions",
        "Veritas" => "code quality and architecture review",
        "Chronicle" => "technical documentation and guides",
        "QA" => "test planning and quality assurance",
        "Sentinel" => "infrastructure and deployment tasks"
    )
    return get(cases, agent, "its domain tasks")
end

function get_confidence_level(agent::String, stats)::String
    avg_reward = float(get(stats, "avg_reward", 0.0))
    if avg_reward >= 0.95
        return "Very High (95%+)"
    elseif avg_reward >= 0.85
        return "High (85-95%)"
    elseif avg_reward >= 0.75
        return "Good (75-85%)"
    else
        return "Baseline (50-75%)"
    end
end

function get_avoid_scenario(agent::String)::String
    scenarios = Dict(
        "Cipher" => "Tasks not requiring security analysis or threat assessment",
        "Scout" => "Tasks requiring immediate action (research takes time)",
        "Codex" => "Non-coding tasks or pure documentation",
        "Veritas" => "Tasks not requiring quality assurance or code review",
        "Chronicle" => "Tasks not involving documentation or communication",
        "QA" => "Tasks not involving testing or quality validation",
        "Sentinel" => "Tasks not involving infrastructure or deployment"
    )
    return get(scenarios, agent, "tasks outside its domain")
end

"""
Save domain knowledge to JSON file
"""
function save_domain_knowledge(agent::String, domain_knowledge::Dict)::Bool
    safe_name = replace(lowercase(agent), " " => "_", "-" => "_")
    filename = joinpath(OUTPUT_DIR, "agent-$(safe_name)-domain-knowledge.json")
    
    try
        open(filename, "w") do f
            JSON.print(f, domain_knowledge, 4)
        end
        return true
    catch e
        println("Error saving domain knowledge for $agent: $e")
        return false
    end
end

"""
Main execution
"""
function main()
    println("=" ^ 80)
    println("AGENT DOMAIN KNOWLEDGE AGGREGATOR - Phase 13, Tier 2")
    println("=" ^ 80)
    println()
    
    # Get list of pattern files
    pattern_files = filter(f -> endswith(f, "-patterns.json"), readdir(PATTERN_DIR))
    agents = [replace(split(f, "-patterns.json")[1], "agent-" => "") for f in pattern_files]
    agents = [replace(a, "_" => " ") for a in agents]
    
    if isempty(agents)
        println("[!] No pattern files found in $PATTERN_DIR")
        return
    end
    
    println("[*] Found patterns for $(length(agents)) agents:")
    for agent in agents
        println("    • $agent")
    end
    println()
    
    # Process each agent
    println("[*] Aggregating domain knowledge...")
    saved_count = 0
    all_knowledge = Dict()
    
    for agent in sort(agents)
        patterns = load_agent_patterns(agent)
        
        if isempty(patterns)
            println("[!] No patterns found for $agent")
            continue
        end
        
        # Generate domain knowledge
        domain_knowledge = generate_domain_knowledge(agent, patterns)
        
        # Save to file
        if save_domain_knowledge(agent, domain_knowledge)
            saved_count += 1
            println("[✓] Generated domain knowledge for $agent")
            all_knowledge[agent] = domain_knowledge["domain_summary"]
        else
            println("[✗] Failed to save domain knowledge for $agent")
        end
    end
    
    println()
    println("[*] Saving aggregation summary...")
    
    # Save summary log
    summary = Dict(
        "timestamp" => Dates.now(UTC),
        "phase" => "13",
        "tier" => "2-domain-knowledge-aggregation",
        "agents_processed" => length(agents),
        "knowledge_files_saved" => saved_count,
        "agent_summaries" => all_knowledge
    )
    
    try
        open(DOMAIN_KNOWLEDGE_LOG, "a") do f
            JSON.print(f, summary)
            write(f, "\n")
        end
        println("[✓] Summary logged")
    catch e
        println("[!] Failed to write summary log: $e")
    end
    
    println()
    println("=" ^ 80)
    println("SUMMARY")
    println("=" ^ 80)
    println("Agents processed: $(length(agents))")
    println("Knowledge files saved: $saved_count")
    println("Output directory: $OUTPUT_DIR")
    println()
    println("Next steps:")
    println("1. Review generated domain knowledge files")
    println("2. Update agent system prompts with learned knowledge")
    println("3. Test with Scout, then scale to other agents")
    println("4. Monitor Phase 7B for +75ms overhead")
    println()
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
