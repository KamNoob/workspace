#!/usr/bin/env julia
"""
audit-logger.jl

Immutable audit logging for all agent spawns and outcomes.
Records: timestamp, task, agent, decision, result, cost

Format: JSON-L (one event per line, append-only)
Retention: 90 days hot, archive older
"""

using Dates
using JSON

module AuditLogger

using Dates
using JSON

export log_spawn, log_outcome, log_event, get_today_log_path

const AUDIT_DIR = joinpath(@__DIR__, "..", "..", "data", "audit-logs")

function get_today_log_path()
    """Get today's audit log file path"""
    today = Dates.today()
    date_str = Dates.format(today, "yyyy-mm-dd")
    return joinpath(AUDIT_DIR, "$(date_str).jsonl")
end

function ensure_audit_dir()
    """Ensure audit-logs directory exists"""
    isdir(AUDIT_DIR) || mkpath(AUDIT_DIR)
end

function log_event(event::Dict)
    """
    Log a single event (append-only, immutable).
    
    Args:
        event: Dict with event data
    
    Returns:
        true if logged successfully, false otherwise
    """
    try
        ensure_audit_dir()
        
        # Add timestamp if missing
        if !haskey(event, "timestamp")
            event["timestamp"] = Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")
        end
        
        log_path = get_today_log_path()
        
        # Append to log (atomic write)
        open(log_path, "a") do io
            JSON.print(io, event)
            println(io)  # Newline for next entry
        end
        
        return true
    catch err
        @error "Audit log error: $err"
        return false
    end
end

function log_spawn(task::String, agent::String, q_score::Float64, confidence::String, session_id::String="")
    """
    Log a task spawn event.
    
    Args:
        task: Task description or type
        agent: Selected agent name
        q_score: Q-learning score for decision
        confidence: Confidence level (high/medium/low)
        session_id: Optional session identifier
    """
    event = Dict(
        "event_type" => "task_spawn",
        "task" => task,
        "agent_selected" => agent,
        "q_score" => round(q_score, digits=4),
        "confidence" => confidence,
        "session_id" => session_id,
        "spawner_version" => "phase5-integrated"
    )
    
    log_event(event)
end

function log_outcome(task::String, agent::String, success::Bool, quality::Float64, duration_ms::Int, cost::Float64)
    """
    Log a task outcome event.
    
    Args:
        task: Task description or type
        agent: Agent that executed
        success: Whether task succeeded
        quality: Quality score (0-1)
        duration_ms: Execution time in milliseconds
        cost: Cost in USD
    """
    event = Dict(
        "event_type" => "task_outcome",
        "task" => task,
        "agent" => agent,
        "success" => success,
        "quality_score" => round(quality, digits=4),
        "duration_ms" => duration_ms,
        "cost_usd" => round(cost, digits=4)
    )
    
    log_event(event)
end

function list_events(filter_type::String=""; limit::Int=100)
    """
    List recent audit events.
    
    Args:
        filter_type: Filter by event_type (empty = all)
        limit: Maximum events to return
    
    Returns:
        Vector of event dictionaries
    """
    try
        ensure_audit_dir()
        
        log_path = get_today_log_path()
        isfile(log_path) || return []
        
        events = []
        open(log_path, "r") do io
            for line in eachline(io)
                isempty(line) && continue
                
                try
                    event = JSON.parse(line)
                    if isempty(filter_type) || get(event, "event_type", "") == filter_type
                        push!(events, event)
                    end
                catch
                    # Skip malformed lines
                end
            end
        end
        
        # Return last `limit` events
        return events[max(1, length(events)-limit+1):end]
    catch err
        @error "Error reading audit log: $err"
        return []
    end
end

function get_stats(date::Date=Dates.today())
    """Get daily statistics from audit log"""
    try
        date_str = Dates.format(date, "yyyy-mm-dd")
        log_path = joinpath(AUDIT_DIR, "$(date_str).jsonl")
        
        isfile(log_path) || return Dict()
        
        spawns = 0
        outcomes = 0
        successes = 0
        total_cost = 0.0
        total_quality = 0.0
        agent_usage = Dict()
        
        open(log_path, "r") do io
            for line in eachline(io)
                isempty(line) && continue
                
                try
                    event = JSON.parse(line)
                    
                    if event["event_type"] == "task_spawn"
                        spawns += 1
                        agent = get(event, "agent_selected", "unknown")
                        agent_usage[agent] = get(agent_usage, agent, 0) + 1
                    elseif event["event_type"] == "task_outcome"
                        outcomes += 1
                        successes += get(event, "success", false) ? 1 : 0
                        total_cost += get(event, "cost_usd", 0.0)
                        total_quality += get(event, "quality_score", 0.0)
                    end
                catch
                    # Skip malformed
                end
            end
        end
        
        return Dict(
            "date" => date_str,
            "spawns" => spawns,
            "outcomes" => outcomes,
            "success_rate" => outcomes > 0 ? round(successes / outcomes, digits=2) : 0.0,
            "total_cost" => round(total_cost, digits=2),
            "avg_quality" => outcomes > 0 ? round(total_quality / outcomes, digits=2) : 0.0,
            "agent_usage" => agent_usage
        )
    catch err
        @error "Error calculating stats: $err"
        return Dict()
    end
end

end  # module
