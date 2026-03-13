#!/usr/bin/env julia
"""
kb-live-indexer.jl - Live KB Indexing from Agent Outcomes

Monitors agent execution logs, extracts learnings, and automatically
adds discoveries to the knowledge base.

CLI Usage:
  julia kb-live-indexer.jl --help              Show help
  julia kb-live-indexer.jl process-logs        Process RL task logs
  julia kb-live-indexer.jl add-entry <topic> <content> <tags>  Add KB entry
  julia kb-live-indexer.jl show-gaps           Show knowledge gaps
"""

using JSON
using Dates

# ============================================================================
# Constants
# ============================================================================

const DEFAULT_LOG_PATH = joinpath(@__DIR__, "../../rl-task-execution-log.jsonl")
const DEFAULT_KB_PATH = joinpath(@__DIR__, "../../data/kb/knowledge-base.json")

# ============================================================================
# Core Functions
# ============================================================================

function tokenize(text::String)::Vector{String}
    text = lowercase(text)
    words = split(replace(text, r"[^\w\s]" => " "), r"\s+")
    return filter(!isempty, words)
end

function extract_learning(log_entry::Dict)::Union{Dict, Nothing}
    # Extract learning from successful outcomes
    if !("outcome" in keys(log_entry)) || log_entry["outcome"] != "success"
        return nothing
    end
    
    task_type = get(log_entry, "task_type", "general")
    agent = get(log_entry, "agent", "unknown")
    reason = get(log_entry, "reason", "")
    
    # Generate topic and content from outcome
    topic = "$(agent) performing $(task_type)"
    content = "Successfully completed $(task_type) task with $(agent). Key insight: $(reason)"
    
    tags = ["agent-outcome", String(task_type), String(agent), "learning"]
    
    return Dict(
        "id" => string(hash(topic)),
        "topic" => topic,
        "content" => content,
        "tags" => tags,
        "source" => "rl-execution",
        "timestamp" => string(now()),
        "confidence" => get(log_entry, "confidence", 0.8)
    )
end

function load_rl_log(log_path::String)::Vector{Dict}
    entries = Dict[]
    
    if !isfile(log_path)
        return entries
    end
    
    try
        open(log_path, "r") do f
            for line in eachline(f)
                if !isempty(strip(line))
                    entry = JSON.parse(line)
                    push!(entries, entry)
                end
            end
        end
    catch e
        @warn "Error reading log file: $e"
    end
    
    return entries
end

function load_kb(kb_path::String)::Dict
    if !isfile(kb_path)
        return Dict("entries" => [])
    end
    
    try
        return JSON.parsefile(kb_path)
    catch e
        @warn "Error reading KB file: $e"
        return Dict("entries" => [])
    end
end

function save_kb(kb::Dict, kb_path::String)
    mkpath(dirname(kb_path))
    open(kb_path, "w") do f
        JSON.print(f, kb, 2)
    end
    println("✓ Saved KB to $kb_path")
end

function add_entry_to_kb(kb::Dict, entry::Dict)::Dict
    # Check for duplicates
    for existing in get(kb, "entries", [])
        if existing["topic"] == entry["topic"]
            return kb  # Skip duplicate
        end
    end
    
    # Add new entry
    if !haskey(kb, "entries")
        kb["entries"] = []
    end
    
    push!(kb["entries"], entry)
    return kb
end

function process_logs(log_path::String, kb_path::String)::Int
    println("📖 Processing agent execution logs...")
    
    # Load logs and KB
    log_entries = load_rl_log(log_path)
    kb = load_kb(kb_path)
    
    println("   Found $(length(log_entries)) log entries")
    
    # Extract learnings
    new_entries = 0
    for log_entry in log_entries
        learning = extract_learning(log_entry)
        if learning !== nothing
            kb = add_entry_to_kb(kb, learning)
            new_entries += 1
        end
    end
    
    # Save KB
    if new_entries > 0
        save_kb(kb, kb_path)
        println("✓ Added $new_entries new entries to KB")
    else
        println("ℹ No new learnings to add")
    end
    
    return new_entries
end

function find_gaps(kb_path::String, log_path::String)::Vector{String}
    log_entries = load_rl_log(log_path)
    kb = load_kb(kb_path)
    
    # Extract all task types from logs
    log_tasks = Set([get(e, "task_type", "") for e in log_entries])
    
    # Extract task types from KB
    kb_tasks = Set()
    for entry in get(kb, "entries", [])
        tags = get(entry, "tags", [])
        for tag in tags
            if tag in log_tasks
                push!(kb_tasks, tag)
            end
        end
    end
    
    # Find gaps (tasks in logs but not well covered in KB)
    gaps = [t for t in log_tasks if !(t in kb_tasks) && !isempty(t)]
    
    return gaps
end

function show_kb_status(kb_path::String)
    kb = load_kb(kb_path)
    entries = get(kb, "entries", [])
    
    println("\n=== Knowledge Base Status ===")
    println("Total entries: $(length(entries))")
    
    # Count by source
    sources = Dict()
    for entry in entries
        source = get(entry, "source", "unknown")
        sources[source] = get(sources, source, 0) + 1
    end
    
    println("\nEntries by source:")
    for (source, count) in sources
        println("  • $source: $count")
    end
    
    # Show tags
    all_tags = Set()
    for entry in entries
        for tag in get(entry, "tags", [])
            push!(all_tags, tag)
        end
    end
    
    println("\nTop tags:")
    if length(all_tags) > 0
        for tag in collect(all_tags)[1:min(10, end)]
            println("  • $tag")
        end
    end
end

# ============================================================================
# CLI Interface
# ============================================================================

function show_help()
    println("""
    kb-live-indexer.jl - Live KB Indexing from Agent Outcomes
    
    Usage:
      julia kb-live-indexer.jl --help              Show this help
      julia kb-live-indexer.jl process-logs        Process RL execution logs
      julia kb-live-indexer.jl status              Show KB status
      julia kb-live-indexer.jl gaps                Show knowledge gaps
      julia kb-live-indexer.jl add <topic> <content>  Add KB entry
    
    Options:
      --log-file <path>    Path to RL log file
      --kb-file <path>     Path to KB file
    
    Examples:
      julia kb-live-indexer.jl process-logs
      julia kb-live-indexer.jl status
      julia kb-live-indexer.jl gaps
    """)
end

if isinteractive() == false
    local log_file = DEFAULT_LOG_PATH
    local kb_file = DEFAULT_KB_PATH
    
    # Parse options
    local args = copy(ARGS)
    local idx = 1
    while idx <= length(args)
        if args[idx] == "--log-file" && idx + 1 <= length(args)
            log_file = args[idx+1]
            deleteat!(args, idx:idx+1)
        elseif args[idx] == "--kb-file" && idx + 1 <= length(args)
            kb_file = args[idx+1]
            deleteat!(args, idx:idx+1)
        else
            idx += 1
        end
    end
    
    if length(args) == 0 || args[1] in ["-h", "--help"]
        show_help()
    elseif args[1] == "process-logs"
        process_logs(log_file, kb_file)
    elseif args[1] == "status"
        show_kb_status(kb_file)
    elseif args[1] == "gaps"
        gaps = find_gaps(kb_file, log_file)
        println("\n=== Knowledge Gaps ===")
        if isempty(gaps)
            println("No gaps found!")
        else
            println("Recommended research areas:")
            for gap in gaps
                println("  • $gap")
            end
        end
    elseif args[1] == "add" && length(args) >= 3
        topic = args[2]
        content = join(args[3:end], " ")
        
        entry = Dict(
            "id" => string(hash(topic)),
            "topic" => topic,
            "content" => content,
            "tags" => ["manual-entry"],
            "source" => "cli",
            "timestamp" => string(now()),
            "confidence" => 0.9
        )
        
        kb = load_kb(kb_file)
        kb = add_entry_to_kb(kb, entry)
        save_kb(kb, kb_file)
        println("✓ Added entry: $topic")
    else
        show_help()
    end
end
