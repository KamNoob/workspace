#!/usr/bin/env julia
"""
  Morpheus Decision Server - HTTP API (stdlib only, zero dependencies)
  
  Listens on http://localhost:8000
  
  Endpoints:
    GET  /api/health             → {status: "ok"}
    POST /api/decide             → {decision, execute, reasoning}
    GET  /api/decisions/<n>      → [decision, ...]
"""

using Sockets

# Server configuration
const PORT = 8000
const BIND_IP = "127.0.0.1"
const DECISIONS_LOG = joinpath(@__DIR__, "../../logs/morpheus-decisions.jsonl")

# Create logs directory
mkpath(dirname(DECISIONS_LOG))

# Decision history
const decisions = Ref{Vector{Dict}}([])

"""
  Simple JSON encoder (stdlib only)
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
  Simple JSON decoder (stdlib only)
"""
function parse_json(s::String)
    s = strip(s)
    if startswith(s, "{") && endswith(s, "}")
        s = s[2:end-1]
        result = Dict()
        for pair in split(s, ",")
            if isempty(strip(pair))
                continue
            end
            parts = split(pair, ":")
            if length(parts) == 2
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
        end
        return result
    end
    return Dict()
end

"""
  Decision Rules Engine
"""
function make_decision(sensor_data::Dict)
    value = get(sensor_data, "value", 0)
    unit = get(sensor_data, "unit", "")
    sensor_type = get(sensor_data, "sensor", "")
    
    decision = "idle"
    execute = false
    reasoning = ""
    confidence = 0.5
    
    # Temperature-based decisions
    if sensor_type == "temperature"
        if isa(value, Number) && value > 30
            decision = "relay_on"
            reasoning = "High temperature, activating cooling"
            execute = true
            confidence = 0.9
        elseif isa(value, Number) && value < 5
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
    
    elseif sensor_type == "light"
        if isa(value, Number) && value > 800
            decision = "alert"
            reasoning = "High light intensity"
            execute = true
            confidence = 0.8
        else
            decision = "idle"
            reasoning = "Light normal"
            execute = false
            confidence = 0.9
        end
    
    else
        reasoning = "Unknown sensor type"
        confidence = 0.3
    end
    
    return Dict(
        "decision" => decision,
        "execute" => execute,
        "reasoning" => reasoning,
        "confidence" => confidence
    )
end

"""
  HTTP Request Handler
"""
function handle_client(client::TCPSocket)
    try
        # Read HTTP request
        line = readline(client)
        parts = split(line)
        method = parts[1]
        path = parts[2]
        
        # Read headers and body
        headers = Dict()
        while true
            line = readline(client)
            if isempty(line)
                break
            end
            if contains(line, ":")
                h_parts = split(line, ":", limit=2)
                headers[strip(h_parts[1])] = strip(h_parts[2])
            end
        end
        
        # Read body if POST
        body = ""
        if method == "POST" && haskey(headers, "Content-Length")
            len = parse(Int, headers["Content-Length"])
            body = String(read(client, len))
        end
        
        # Route request
        response = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n"
        
        if method == "GET" && path == "/api/health"
            response_body = to_json(Dict(
                "status" => "ok",
                "port" => PORT,
                "timestamp" => time()
            ))
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: $(length(response_body))\r\n\r\n$(response_body)"
        
        elseif method == "POST" && path == "/api/decide"
            payload = parse_json(body)
            result = make_decision(payload)
            
            # Log
            log_entry = merge(
                Dict("timestamp" => string(time()), "device_id" => get(payload, "device_id", "unknown")),
                payload,
                result
            )
            push!(decisions[], log_entry)
            
            open(DECISIONS_LOG, "a") do f
                write(f, to_json(log_entry) * "\n")
            end
            
            print("[Decision] $(result["decision"]) ($(result["confidence"]))\n")
            
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
            catch
            end
        end
        
        write(client, response)
    catch e
        # Silent fail
    finally
        close(client)
    end
end

"""
  Start Server
"""
function start_server()
    println("\n╔════════════════════════════════════════════╗")
    println("║  Morpheus Decision Server                  ║")
    println("╠════════════════════════════════════════════╣")
    println("║  Listening on: http://$(BIND_IP):$(PORT)   ║")
    println("║  Endpoints:                                ║")
    println("║    GET  /api/health                        ║")
    println("║    POST /api/decide                        ║")
    println("║    GET  /api/decisions/<n>                 ║")
    println("║  Logs: $(DECISIONS_LOG)                    ║")
    println("╚════════════════════════════════════════════╝\n")
    
    server = listen(IPv4(BIND_IP), PORT)
    
    while true
        client = accept(server)
        handle_client(client)
    end
end

# Run server
start_server()
