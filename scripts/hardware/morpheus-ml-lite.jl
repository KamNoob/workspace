#!/usr/bin/env julia
"""
  Morpheus ML-Lite Decision Server
  
  Simplified ML integration:
  - No JLD2 dependencies (uses JSON directly)
  - Agent selection via rule-based routing
  - Ready for KB context injection
  - Compatible with existing spawner-matrix.jl
"""

using Sockets

# Configuration
const PORT = 8000
const BIND_IP = "127.0.0.1"
const DECISIONS_LOG = "/home/art/.openclaw/workspace/logs/morpheus-decisions.jsonl"

# Agent assignments (rule-based for now)
const AGENT_MAP = Dict(
    "temperature" => "Sentinel",      # Infrastructure/heating
    "security" => "Cipher",           # Security threats
    "light" => "Scout",               # Monitoring/analysis
    "motion" => "Codex",              # Automation logic
    "humidity" => "Sentinel",         # Environmental control
    "co2" => "Scout",                 # Air quality monitoring
    "power" => "Sentinel"             # Power management
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
        else
            val_str = "\"$(v)\""
        end
        push!(pairs, "$key_str:$val_str")
    end
    return "{" * join(pairs, ",") * "}"
end

"""
  Simple JSON decoder
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
  Get agent for sensor type
"""
function get_agent(sensor_type::String)::String
    return get(AGENT_MAP, sensor_type, "Sentinel")
end

"""
  ML-enhanced decision making
"""
function make_decision_ml(sensor_data::Dict)::Dict
    value = get(sensor_data, "value", 0)
    sensor_type = get(sensor_data, "sensor", "")
    
    decision = "idle"
    execute = false
    reasoning = ""
    confidence = 0.5
    agent = "Sentinel"  # Default
    
    # Get assigned agent for sensor type
    agent = get_agent(sensor_type)
    stats["agents_assigned"] += 1
    
    # Temperature
    if sensor_type == "temperature" && isa(value, Number)
        if value > 35
            decision = "relay_on"
            reasoning = "Critical: High temperature ($(agent) assigned)"
            execute = true
            confidence = 0.95
        elseif value > 30
            decision = "relay_on"
            reasoning = "High temp: cooling via $(agent)"
            execute = true
            confidence = 0.9
        elseif value < 5
            decision = "relay_off"
            reasoning = "Low temp: stopping cooling ($(agent))"
            execute = true
            confidence = 0.85
        else
            decision = "idle"
            reasoning = "Normal temperature"
            execute = false
            confidence = 0.95
        end
    
    # Security
    elseif sensor_type == "security"
        if isa(value, Number) && value > 0
            decision = "alert"
            reasoning = "Security event: $(agent) investigating"
            execute = true
            confidence = 0.95
        else
            decision = "idle"
            reasoning = "Secure"
            confidence = 0.98
        end
    
    # Light
    elseif sensor_type == "light"
        if isa(value, Number) && value > 800
            decision = "alert"
            reasoning = "High light: $(agent) monitoring"
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
        "agent" => agent,
        "agent_type" => "assigned"
    )
end

"""
  Log decision
"""
function log_decision(entry::Dict)
    open(DECISIONS_LOG, "a") do f
        write(f, to_json(entry) * "\n")
    end
end

"""
  HTTP handler
"""
function handle_client(client::TCPSocket)
    try
        stats["requests"] += 1
        
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
            uptime = time() - stats["start_time"]
            response_body = to_json(Dict(
                "status" => "ok",
                "port" => PORT,
                "mode" => "ml_lite",
                "requests" => stats["requests"],
                "decisions" => stats["decisions"],
                "agents_assigned" => stats["agents_assigned"],
                "uptime_seconds" => round(uptime),
                "timestamp" => time()
            ))
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(response_body))\r\n\r\n$(response_body)"
        
        elseif method == "POST" && path == "/api/decide"
            payload = parse_json(body)
            result = make_decision_ml(payload)
            stats["decisions"] += 1
            
            log_entry = merge(
                Dict("timestamp" => string(time()), "device_id" => get(payload, "device_id", "unknown")),
                payload,
                result
            )
            push!(decisions[], log_entry)
            log_decision(log_entry)
            
            print("[Decision] $(result["decision"]) → $(result["agent"])\n")
            
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
                stats["errors"] += 1
            end
        
        elseif method == "GET" && path == "/api/stats"
            response_body = to_json(stats)
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(response_body))\r\n\r\n$(response_body)"
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
    println("║  Morpheus ML-Lite Decision Server          ║")
    println("╠════════════════════════════════════════════╣")
    println("║  Listening on: http://$(BIND_IP):$(PORT)   ║")
    println("║  Mode: Agent Assignment (Lite ML)          ║")
    println("║  Agents:                                   ║")
    println("║    Temperature → Sentinel (infrastructure) ║")
    println("║    Security    → Cipher (security)         ║")
    println("║    Light       → Scout (monitoring)        ║")
    println("║    Motion      → Codex (automation)        ║")
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
            sleep(0.1)
        end
    end
end

start_server()
