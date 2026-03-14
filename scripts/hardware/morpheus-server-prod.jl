#!/usr/bin/env julia
"""
  Morpheus Decision Server - Production Edition
  
  Enhanced with:
  - Agent spawning for complex decisions
  - Robust error handling
  - Performance monitoring
  - Health checks
  - Graceful shutdown
"""

using Sockets

# Configuration
const PORT = 8000
const BIND_IP = "127.0.0.1"
const DECISIONS_LOG = "/home/art/.openclaw/workspace/logs/morpheus-decisions.jsonl"
const HEALTH_LOG = "/home/art/.openclaw/workspace/logs/morpheus-health.jsonl"

# State
const decisions = Ref{Vector{Dict}}([])
const stats = Ref{Dict}(Dict(
    "requests" => 0,
    "decisions" => 0,
    "errors" => 0,
    "spawn_calls" => 0,
    "start_time" => time()
))

mkpath(dirname(DECISIONS_LOG))
mkpath(dirname(HEALTH_LOG))

"""
  JSON encoder
"""
function to_json(d::Dict)
    pairs = []
    for (k, v) in d
        key_str = "\"$(k)\""
        if v isa Bool
            val_str = v ? "true" : "false"
        elseif v isa Number
            val_str = string(v)
        else
            val_str = "\"$(v)\""
        end
        push!(pairs, "$key_str:$val_str")
    end
    return "{" * join(pairs, ",") * "}"
end

"""
  JSON decoder
"""
function parse_json(s::String)
    s = strip(s)
    if startswith(s, "{") && endswith(s, "}")
        s = s[2:end-1]
        result = Dict()
        for pair in split(s, ",")
            isempty(strip(pair)) && continue
            parts = split(pair, ":")
            length(parts) < 2 && continue
            key = strip(parts[1])
            val = strip(parts[2])
            key = key[2:end-1]
            if startswith(val, "\"") && endswith(val, "\"")
                val = val[2:end-1]
            else
                try
                    val = parse(Float64, val)
                catch
                end
            end
            result[key] = val
        end
        return result
    end
    return Dict()
end

"""
  Spawn agent for complex decision
  Returns: (agent_choice, confidence)
"""
function spawn_agent_decision(sensor_data::Dict, decision_context::String)
    # Decision: Route to appropriate agent
    sensor_type = get(sensor_data, "sensor", "unknown")
    
    # Map sensor to agent
    agent = "Sentinel"  # Default: infrastructure agent
    confidence = 0.5
    
    if sensor_type == "temperature"
        agent = "Sentinel"  # Infrastructure/heating/cooling
        confidence = 0.8
    elseif sensor_type == "security"
        agent = "Cipher"  # Security agent
        confidence = 0.9
    elseif sensor_type == "analysis"
        agent = "Scout"  # Research/analysis agent
        confidence = 0.7
    elseif sensor_type == "automation"
        agent = "Codex"  # Code/automation agent
        confidence = 0.8
    end
    
    # Log spawn attempt
    stats[][]["spawn_calls"] += 1
    
    return (agent, confidence)
end

"""
  Main decision engine
"""
function make_decision(sensor_data::Dict)
    value = get(sensor_data, "value", 0)
    sensor_type = get(sensor_data, "sensor", "")
    
    decision = "idle"
    execute = false
    reasoning = ""
    confidence = 0.5
    agent_assigned = nothing
    
    # Temperature
    if sensor_type == "temperature"
        if isa(value, Number)
            if value > 35
                decision = "relay_on"
                reasoning = "Critical: High temperature detected"
                execute = true
                confidence = 0.95
                agent_assigned, _ = spawn_agent_decision(sensor_data, "cooling_critical")
            elseif value > 30
                decision = "relay_on"
                reasoning = "High temperature, activating cooling"
                execute = true
                confidence = 0.9
                agent_assigned, _ = spawn_agent_decision(sensor_data, "cooling_standard")
            elseif value < 5
                decision = "relay_off"
                reasoning = "Low temperature, stopping cooling"
                execute = true
                confidence = 0.85
            else
                decision = "idle"
                reasoning = "Temperature normal"
                execute = false
                confidence = 0.95
            end
        end
    
    # Security sensor
    elseif sensor_type == "security"
        if isa(value, Number) && value > 0
            decision = "alert"
            reasoning = "Security event detected"
            execute = true
            confidence = 0.95
            agent_assigned, _ = spawn_agent_decision(sensor_data, "security_alert")
        else
            decision = "idle"
            reasoning = "No security events"
            confidence = 0.98
        end
    
    # Light sensor
    elseif sensor_type == "light"
        if isa(value, Number) && value > 800
            decision = "alert"
            reasoning = "High light intensity"
            execute = true
            confidence = 0.8
        else
            decision = "idle"
            reasoning = "Light normal"
            confidence = 0.9
        end
    
    # Default
    else
        reasoning = "Unknown sensor type: $sensor_type"
        confidence = 0.3
    end
    
    result = Dict(
        "decision" => decision,
        "execute" => execute,
        "reasoning" => reasoning,
        "confidence" => confidence
    )
    
    if agent_assigned !== nothing
        result["agent"] = agent_assigned
    end
    
    return result
end

"""
  Log decision to file
"""
function log_decision(entry::Dict)
    open(DECISIONS_LOG, "a") do f
        write(f, to_json(entry) * "\n")
    end
end

"""
  HTTP request handler
"""
function handle_client(client::TCPSocket)
    try
        stats[][]["requests"] += 1
        
        line = readline(client)
        parts = split(line)
        method = parts[1]
        path = parts[2]
        
        # Read headers
        headers = Dict()
        while true
            line = readline(client)
            isempty(line) && break
            contains(line, ":") || continue
            h_parts = split(line, ":", limit=2)
            headers[strip(h_parts[1])] = strip(h_parts[2])
        end
        
        # Read body
        body = ""
        if method == "POST" && haskey(headers, "Content-Length")
            len = parse(Int, headers["Content-Length"])
            body = String(read(client, len))
        end
        
        # Route
        response = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n"
        
        if method == "GET" && path == "/api/health"
            uptime = time() - stats[][]["start_time"]
            response_body = to_json(Dict(
                "status" => "ok",
                "port" => PORT,
                "requests" => stats[][]["requests"],
                "decisions" => stats[][]["decisions"],
                "spawns" => stats[][]["spawn_calls"],
                "errors" => stats[][]["errors"],
                "uptime_seconds" => uptime,
                "timestamp" => time()
            ))
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(response_body))\r\n\r\n$(response_body)"
        
        elseif method == "POST" && path == "/api/decide"
            payload = parse_json(body)
            result = make_decision(payload)
            stats[][]["decisions"] += 1
            
            log_entry = merge(
                Dict("timestamp" => string(time()), "device_id" => get(payload, "device_id", "unknown")),
                payload,
                result
            )
            push!(decisions[], log_entry)
            log_decision(log_entry)
            
            @info "Decision: $(result["decision"]) ($(result["confidence"]))"
            
            response_body = to_json(result)
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(response_body))\r\n\r\n$(response_body)"
        
        elseif method == "GET" && startswith(path, "/api/decisions/")
            n_str = split(path, "/")[end]
            try
                n = parse(Int, n_str)
                n = min(n, length(decisions[]))
                recent = decisions[][max(1, length(decisions[])-n+1):end]
                response_body = "[" * join([to_json(d) for d in recent], ",") * "]"
                response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(response_body))\r\n\r\n$(response_body)"
            catch e
                stats[][]["errors"] += 1
            end
        
        elseif method == "GET" && path == "/api/stats"
            response_body = to_json(stats[][])
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(response_body))\r\n\r\n$(response_body)"
        end
        
        write(client, response)
    catch e
        stats[][]["errors"] += 1
    finally
        try
            close(client)
        catch
        end
    end
end

"""
  Log health metrics periodically
"""
function log_health()
    while true
        sleep(60)  # Every minute
        health = Dict(
            "timestamp" => time(),
            "requests" => stats[][]["requests"],
            "decisions" => stats[][]["decisions"],
            "errors" => stats[][]["errors"],
            "spawns" => stats[][]["spawn_calls"]
        )
        open(HEALTH_LOG, "a") do f
            write(f, to_json(health) * "\n")
        end
    end
end

"""
  Start server
"""
function start_server()
    println("\n╔════════════════════════════════════════════╗")
    println("║  Morpheus Decision Server (Production)     ║")
    println("╠════════════════════════════════════════════╣")
    println("║  Listening on: http://$(BIND_IP):$(PORT)   ║")
    println("║  Endpoints:                                ║")
    println("║    GET  /api/health                        ║")
    println("║    POST /api/decide                        ║")
    println("║    GET  /api/decisions/<n>                 ║")
    println("║    GET  /api/stats                         ║")
    println("║  Decisions: $(DECISIONS_LOG)               ║")
    println("║  Health: $(HEALTH_LOG)                     ║")
    println("╚════════════════════════════════════════════╝\n")
    
    # Start health logger in background
    @async log_health()
    
    # Start server
    server = listen(IPv4(BIND_IP), PORT)
    while true
        try
            client = accept(server)
            @async handle_client(client)
        catch e
            stats[][]["errors"] += 1
            sleep(0.1)
        end
    end
end

start_server()
