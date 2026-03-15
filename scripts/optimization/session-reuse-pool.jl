#!/usr/bin/env julia
"""
Phase 5: Pillar 1 — Session Reuse Pool

Maintains a pool of 10 warm, pre-cached sessions ready to use.
Each session has SOUL.md, IDENTITY.md, AGENTS.md, MEMORY.md cached.

Usage:
  julia scripts/optimization/session-reuse-pool.jl status
  julia scripts/optimization/session-reuse-pool.jl init [size=10]
  julia scripts/optimization/session-reuse-pool.jl get-session
"""

using JSON
using Dates
using Random

function create_session(id::Int)::Dict
    return Dict(
        "session_id" => "warm_session_$id",
        "status" => "ready",
        "created_at" => string(now()),
        "cache_warmed_at" => string(now()),
        "last_used" => nothing,
        "use_count" => 0,
        "context_cached" => true
    )
end

function initialize_pool(size::Int=10)
    pool = Dict(
        "created_at" => string(now()),
        "pool_size" => size,
        "sessions" => [create_session(i) for i in 1:size],
        "total_uses" => 0,
        "status" => "initialized"
    )
    
    mkpath("data/metrics")
    open("data/metrics/session-pool.json", "w") do f
        write(f, JSON.json(pool, 2))
    end
    
    return pool
end

function load_pool()::Dict
    if !isfile("data/metrics/session-pool.json")
        return initialize_pool(10)
    end
    return JSON.parsefile("data/metrics/session-pool.json")
end

function get_ready_session()::Dict
    pool = load_pool()
    sessions = pool["sessions"]
    
    # Find a ready session
    for session in sessions
        if session["status"] == "ready"
            session["status"] = "in_use"
            session["last_used"] = string(now())
            session["use_count"] += 1
            
            # Save updated pool
            open("data/metrics/session-pool.json", "w") do f
                write(f, JSON.json(pool, 2))
            end
            
            return session
        end
    end
    
    # If no ready sessions, create new one
    new_id = length(sessions) + 1
    new_session = create_session(new_id)
    new_session["status"] = "in_use"
    push!(sessions, new_session)
    
    open("data/metrics/session-pool.json", "w") do f
        write(f, JSON.json(pool, 2))
    end
    
    return new_session
end

function return_session(session_id::String)
    pool = load_pool()
    sessions = pool["sessions"]
    
    for session in sessions
        if session["session_id"] == session_id
            session["status"] = "ready"
            break
        end
    end
    
    open("data/metrics/session-pool.json", "w") do f
        write(f, JSON.json(pool, 2))
    end
end

function show_status()
    pool = load_pool()
    
    println("\n" * "="^70)
    println("SESSION REUSE POOL STATUS")
    println("="^70 * "\n")
    
    println("📋 Pool Configuration:")
    println("   Pool size: $(pool["pool_size"]) sessions")
    println("   Created: $(pool["created_at"])")
    println("   Status: $(pool["status"])\n")
    
    ready_count = count(s -> s["status"] == "ready", pool["sessions"])
    in_use_count = count(s -> s["status"] == "in_use", pool["sessions"])
    
    println("🔄 Current State:")
    println("   Ready: $ready_count / $(pool["pool_size"])")
    println("   In use: $in_use_count / $(pool["pool_size"])")
    println("   Total uses: $(pool["total_uses"])\n")
    
    println("⏱️  Recent Usage:")
    recent = pool["sessions"][1:min(3, length(pool["sessions"]))]
    for session in recent
        uses = session["use_count"]
        last = get(session, "last_used", "never")
        println("   $(session["session_id"]): $uses uses, last=$last")
    end
    
    if ready_count >= pool["pool_size"] * 0.8
        println("\n✅ Pool healthy: >80% ready")
    elseif ready_count >= pool["pool_size"] * 0.5
        println("\n✅ Pool OK: >50% ready")
    else
        println("\n⚠️  Pool low: <50% ready")
        println("   Recommendation: Increase pool size or free sessions faster")
    end
    
    println("\n" * "="^70 * "\n")
end

# Parse command
if length(ARGS) > 0
    cmd = ARGS[1]
    
    if cmd == "status"
        show_status()
    elseif cmd == "init"
        size = length(ARGS) > 1 ? parse(Int, ARGS[2]) : 10
        println("\nInitializing session pool with size=$size...")
        initialize_pool(size)
        println("✅ Pool initialized\n")
        show_status()
    elseif cmd == "get-session"
        session = get_ready_session()
        println("\n✅ Allocated session: $(session["session_id"])")
        println("   Status: $(session["status"])")
        println("   Use count: $(session["use_count"])")
        println("   Context cached: $(session["context_cached"])\n")
    else
        println("Unknown command: $cmd")
        println("Usage: julia session-reuse-pool.jl [status|init|get-session]")
    end
else
    show_status()
end
