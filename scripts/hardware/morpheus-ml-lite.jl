#!/usr/bin/env julia
"""
  Morpheus ML-Lite Decision Server - FIXED
  
  Simplified ML integration:
  - Agent selection via rule-based routing
  - No external dependencies (stdlib only)
  - Ready for KB context injection
"""

using Sockets

# Configuration
const PORT = 8000
const BIND_IP = "127.0.0.1"
const DECISIONS_LOG = "/home/art/.openclaw/workspace/logs/morpheus-decisions.jsonl"

# Agent assignments
const AGENT_MAP = Dict(
    "temperature" => "Sentinel",
    "security" => "Cipher",
    "light" => "Scout",
    "motion" => "Codex",
    "humidity" => "Sentinel",
    "co2" => "Scout",
    "power" => "Sentinel"
)

# State
const decisions = Ref{Vector}([])
const stats = Dict(
    "requests" => 0,
    "decisions" => 0,
    "agents_assigned" => 0,
    "errors" => 0,
    "start_time" => time()
)

mkpath(dirname(DECISIONS_LOG))

"""
  Simple JSON encoder
"""
function to_json(d::Dict)
    pairs = []
    for (k, v) in d
        key_str = "\"$(k)\""
        if v isa Bool
            val_str = v ? "true" : "false"
        elseif v isa Number
            val_str = string(v)
        elseif v === nothing
            val_str = "null"
        else
            # Escape quotes
            val_str = "\"$(replace(string(v), "\"" => "\\\""))\""
        end
        push!(pairs, "$key_str:$val_str")
    end
    return "{" * join(pairs, ",") * "}"
end

"""
  Simple JSON decoder
"""
function parse_json(s::String)
    result = Dict{String, Any}()
    s = strip(s)
    
    if !startswith(s, "{") || !endswith(s, "}")
        return result
    end
    
    s = s[2:end-1]  # Remove outer braces
    
    i = 1
    while i <= length(s)
        # Skip whitespace
        while i <= length(s) && s[i] in " \t\n\r,"
            i += 1
        end
        if i > length(s)
            break
        end
        
        # Parse key
        if s[i] != '"'
            i += 1
            continue
        end
        i += 1
        key_start = i
        while i <= length(s) && s[i] != '"'
            i += 1
        end
        key = s[key_start:i-1]
        i += 1
        
        # Skip whitespace and colon
        while i <= length(s) && s[i] in " \t\n\r:"
            i += 1
        end
        
        if i > length(s)
            break
        end
        
        # Parse value
        if s[i] == '"'
            i += 1
            val_start = i
            while i <= length(s) && s[i] != '"'
                i += 1
            end
            result[key] = s[val_start:i-1]
            i += 1
        elseif s[i] in "0123456789.-"
            val_start = i
            while i <= length(s) && s[i] in "0123456789.-eE"
                i += 1
            end
            try
                result[key] = parse(Float64, s[val_start:i-1])
            catch
                result[key] = s[val_start:i-1]
            end
        elseif startswith(s[i:end], "true")
            result[key] = true
            i += 4
        elseif startswith(s[i:end], "false")
            result[key] = false
            i += 5
        else
            i += 1
        end
    end
    
    return result
end

"""
  Get agent for sensor type
"""
function get_agent(sensor_type::String)::String
    return get(AGENT_MAP, sensor_type, "Sentinel")
end

"""
  Make decision with agent assignment
"""
function make_decision(sensor_data::Dict)::Dict
    sensor_type = get(sensor_data, "sensor", "unknown")
    value = get(sensor_data, "value", 0)
    
    # Ensure value is a number
    if !isa(value, Number)
        try
            value = parse(Float64, string(value))
        catch
            value = 0
        end
    end
    
    agent = get_agent(sensor_type)
    decision = "idle"
    execute = false
    reasoning = ""
    confidence = 0.5
    
    # Temperature rules
    if sensor_type == "temperature"
        if value > 35
            decision = "relay_on"
            reasoning = "Critical: High temperature (via $agent)"
            execute = true
            confidence = 0.95
        elseif value > 30
            decision = "relay_on"
            reasoning = "High temp: cooling via $agent"
            execute = true
            confidence = 0.9
        elseif value < 5
            decision = "relay_off"
            reasoning = "Low temp: stopping cooling ($agent)"
            execute = true
            confidence = 0.85
        else
            decision = "idle"
            reasoning = "Temperature normal"
            execute = false
            confidence = 0.95
        end
    
    # Security rules
    elseif sensor_type == "security"
        if value > 0
            decision = "alert"
            reasoning = "Security event: $agent investigating"
            execute = true
            confidence = 0.95
        else
            decision = "idle"
            reasoning = "Secure"
            confidence = 0.98
        end
    
    # Light rules
    elseif sensor_type == "light"
        if value > 800
            decision = "alert"
            reasoning = "High light: $agent monitoring"
            execute = true
            confidence = 0.8
        else
            decision = "idle"
            reasoning = "Light normal"
            confidence = 0.9
        end
    
    else
        reasoning = "Unknown sensor"
        confidence = 0.3
    end
    
    return Dict(
        "decision" => decision,
        "execute" => execute,
        "reasoning" => reasoning,
        "confidence" => confidence,
        "agent" => agent
    )
end

"""
  Log decision to JSONL
"""
function log_decision(entry::Dict)
    try
        open(DECISIONS_LOG, "a") do f
            write(f, to_json(entry) * "\n")
        end
    catch e
        # Silent fail on log
    end
end

"""
  HTTP request handler
"""
function handle_client(client::TCPSocket)
    try
        stats["requests"] += 1
        
        # Read request line
        line = readline(client)
        parts = split(line)
        method = parts[1]
        path = parts[2]
        
        # Read headers
        headers = Dict()
        while true
            hline = readline(client)
            isempty(hline) && break
            if contains(hline, ":")
                h_parts = split(hline, ":", limit=2)
                headers[strip(h_parts[1])] = strip(h_parts[2])
            end
        end
        
        # Read body
        body = ""
        if method == "POST" && haskey(headers, "Content-Length")
            len = parse(Int, headers["Content-Length"])
            body = String(read(client, len))
        end
        
        # Route request
        response = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: 18\r\n\r\n{\"error\":\"not found\"}"
        
        if method == "GET" && path == "/api/health"
            uptime = round(time() - stats["start_time"])
            h_body = to_json(Dict(
                "status" => "ok",
                "port" => PORT,
                "mode" => "ml_lite",
                "requests" => stats["requests"],
                "decisions" => stats["decisions"],
                "agents_assigned" => stats["agents_assigned"],
                "uptime_seconds" => uptime,
                "timestamp" => time()
            ))
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(h_body))\r\n\r\n$h_body"
        
        elseif method == "POST" && path == "/api/decide"
            payload = parse_json(body)
            result = make_decision(payload)
            stats["decisions"] += 1
            stats["agents_assigned"] += 1
            
            # Create log entry
            log_entry = Dict(
                "timestamp" => string(time()),
                "device_id" => get(payload, "device_id", "unknown"),
                "sensor" => get(payload, "sensor", ""),
                "value" => get(payload, "value", 0),
                "unit" => get(payload, "unit", ""),
                "decision" => result["decision"],
                "execute" => result["execute"],
                "reasoning" => result["reasoning"],
                "confidence" => result["confidence"],
                "agent" => result["agent"]
            )
            
            push!(decisions[], log_entry)
            log_decision(log_entry)
            
            print("[Decision] $(result["decision"]) → $(result["agent"])\n")
            
            d_body = to_json(result)
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(d_body))\r\n\r\n$d_body"
        
        elseif method == "GET" && startswith(path, "/api/decisions/")
            try
                n_str = split(path, "/")[end]
                n = parse(Int, n_str)
                n = min(n, length(decisions[]))
                recent = decisions[][max(1, length(decisions[])-n+1):end]
                l_body = "[" * join([to_json(d) for d in recent], ",") * "]"
                response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(l_body))\r\n\r\n$l_body"
            catch e
                stats["errors"] += 1
            end
        
        elseif method == "GET" && path == "/api/stats"
            s_body = to_json(stats)
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(s_body))\r\n\r\n$s_body"
        end
        
        write(client, response)
    catch e
        stats["errors"] += 1
    finally
        try
            close(client)
        catch
        end
    end
end

"""
  Start server
"""
function start_server()
    println("\n╔════════════════════════════════════════════╗")
    println("║  Morpheus ML-Lite Decision Server (FIXED)  ║")
    println("╠════════════════════════════════════════════╣")
    println("║  Listening on: http://$(BIND_IP):$(PORT)   ║")
    println("║  Mode: Agent Assignment + Rules            ║")
    println("║  Agents:                                   ║")
    println("║    Temperature → Sentinel                  ║")
    println("║    Security    → Cipher                    ║")
    println("║    Light       → Scout                     ║")
    println("║    Motion      → Codex                     ║")
    println("║  Endpoints:                                ║")
    println("║    GET  /api/health                        ║")
    println("║    POST /api/decide                        ║")
    println("║    GET  /api/decisions/<n>                 ║")
    println("║    GET  /api/stats                         ║")
    println("║  Logs: $(DECISIONS_LOG)                    ║")
    println("╚════════════════════════════════════════════╝\n")
    
    server = listen(IPv4(BIND_IP), PORT)
    while true
        try
            client = accept(server)
            handle_client(client)
        catch e
            stats["errors"] += 1
            sleep(0.01)
        end
    end
end

start_server()
