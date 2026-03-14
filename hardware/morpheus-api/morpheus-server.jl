#!/usr/bin/env julia
"""
    morpheus-server.jl

Morpheus Decision Server - Hardware Phase 2

HTTP server that receives sensor data from ESP32 devices,
queries the agent spawner for decisions, and returns actions.

Architecture:
    ESP32 (WiFi sketch)
        ↓ POST /api/decide (sensor data JSON)
    Morpheus Server (Julia)
        ↓ Parse sensor data
        ↓ Query spawner-matrix
        ↓ Log decision
    Return Action JSON
        ↓
    ESP32 executes (blink LED, move servo, etc.)

Usage:
    julia morpheus-server.jl
    # Listens on http://127.0.0.1:8000

API Endpoints:
    GET  /api/health              Server status
    POST /api/decide              Get decision for sensor data
    GET  /api/decisions/<count>   Get recent decisions
"""

# Note: No external HTTP library available
# Using raw sockets + TCP parsing instead

using JSON
using Sockets
using Dates

# ============================================================================
# Configuration
# ============================================================================

const HOST = "127.0.0.1"
const PORT = 8000
const MAX_REQUEST_SIZE = 8192
const DECISIONS_LOG = "data/rl/morpheus-decisions.jsonl"

# ============================================================================
# HTTP Parsing (Minimal Implementation)
# ============================================================================

struct HTTPRequest
    method::String
    path::String
    headers::Dict{String, String}
    body::String
end

function parse_http_request(raw::String)::Union{HTTPRequest, Nothing}
    """Parse HTTP request from raw bytes"""
    lines = split(raw, "\r\n")
    
    if isempty(lines)
        return nothing
    end
    
    # Parse request line
    req_line = split(lines[1], " ")
    if length(req_line) < 3
        return nothing
    end
    
    method = req_line[1]
    path = req_line[2]
    
    # Parse headers
    headers = Dict{String, String}()
    body_start = 0
    
    for (i, line) in enumerate(lines[2:end])
        if isempty(line)
            body_start = i + 1
            break
        end
        
        if contains(line, ":")
            parts = split(line, ":", limit=2)
            key = strip(parts[1])
            value = strip(parts[2])
            headers[key] = value
        end
    end
    
    # Get body
    body = ""
    if body_start > 0 && body_start < length(lines)
        body = join(lines[body_start+1:end], "\r\n")
    end
    
    return HTTPRequest(method, path, headers, body)
end

function build_http_response(status::Int, content_type::String, body::String)::String
    """Build HTTP response"""
    status_text = status == 200 ? "OK" : 
                  status == 404 ? "Not Found" :
                  status == 400 ? "Bad Request" : "Error"
    
    response = "HTTP/1.1 $status $status_text\r\n"
    response *= "Content-Type: $content_type\r\n"
    response *= "Content-Length: $(length(body))\r\n"
    response *= "Connection: close\r\n"
    response *= "\r\n"
    response *= body
    
    return response
end

# ============================================================================
# Business Logic
# ============================================================================

function parse_sensor_data(json_str::String)::Union{Dict, Nothing}
    """Parse JSON sensor data"""
    try
        return JSON.parse(json_str)
    catch e
        return nothing
    end
end

function generate_decision(sensor_data::Dict)::Dict
    """
    Generate decision based on sensor data.
    
    In production, this would:
    1. Query spawner-matrix.jl for agent selection
    2. Run that agent with sensor context
    3. Parse agent output
    4. Return action JSON
    
    For now, demo behavior:
    """
    
    # Demo: simple rule-based decision
    # In production: spawn Morpheus/Sentinel + run decision logic
    
    decision = Dict(
        :timestamp => now(),
        :request_id => rand(1:999999),
        :sensor_data => sensor_data,
        :decision => "process",
        :action => Dict(
            :type => "log",
            :message => "Decision received and logged"
        ),
        :confidence => 0.8
    )
    
    # In production, add real decision logic here
    if haskey(sensor_data, "sensor_type")
        sensor = sensor_data["sensor_type"]
        
        if sensor == "temperature"
            value = get(sensor_data, "value", 20)
            if value > 25
                decision[:action] = Dict(:type => "alert", :message => "Temperature high")
                decision[:decision] = "alert"
            end
        elseif sensor == "motion"
            decision[:action] = Dict(:type => "execute", :command => "log_event")
            decision[:decision] = "motion_detected"
        elseif sensor == "light"
            value = get(sensor_data, "value", 500)
            if value < 100
                decision[:action] = Dict(:type => "control", :command => "blink_led")
                decision[:decision] = "low_light"
            end
        end
    end
    
    return decision
end

function log_decision(decision::Dict)
    """Log decision to JSONL"""
    open(DECISIONS_LOG, "a") do f
        write(f, JSON.json(decision) * "\n")
    end
end

# ============================================================================
# API Handlers
# ============================================================================

function handle_health()::String
    """GET /api/health"""
    response = Dict(
        :status => "ok",
        :service => "Morpheus Decision Server",
        :version => "Phase 2",
        :timestamp => now(),
        :uptime => "running"
    )
    
    return JSON.json(response)
end

function handle_decide(body::String)::Tuple{Int, String}
    """POST /api/decide"""
    
    sensor_data = parse_sensor_data(body)
    
    if sensor_data === nothing
        error_response = Dict(:error => "Invalid JSON")
        return 400, JSON.json(error_response)
    end
    
    # Generate decision
    decision = generate_decision(sensor_data)
    
    # Log it
    log_decision(decision)
    
    # Return decision
    return 200, JSON.json(decision)
end

function handle_decisions(count_str::String)::Tuple{Int, String}
    """GET /api/decisions/<count>"""
    
    count = try
        parse(Int, count_str)
    catch
        10
    end
    
    # Read last N decisions
    if !isfile(DECISIONS_LOG)
        response = Dict(:decisions => [], :count => 0)
        return 200, JSON.json(response)
    end
    
    lines = readlines(DECISIONS_LOG)
    recent = lines[max(1, length(lines)-count+1):end]
    
    decisions = []
    for line in recent
        try
            push!(decisions, JSON.parse(line))
        catch
        end
    end
    
    response = Dict(
        :decisions => decisions,
        :count => length(decisions),
        :timestamp => now()
    )
    
    return 200, JSON.json(response)
end

function route_request(req::HTTPRequest)::String
    """Route HTTP request to handler"""
    
    status = 404
    content_type = "application/json"
    body = "{\"error\": \"Not found\"}"
    
    if req.path == "/api/health" && req.method == "GET"
        status = 200
        body = handle_health()
        
    elseif startswith(req.path, "/api/decide")
        if req.method == "POST"
            status, body = handle_decide(req.body)
        else
            status = 405
            body = "{\"error\": \"Method not allowed\"}"
        end
        
    elseif startswith(req.path, "/api/decisions/")
        count_str = split(req.path, "/")[4]
        status, body = handle_decisions(count_str)
        
    else
        status = 404
        body = "{\"error\": \"Not found\"}"
    end
    
    return build_http_response(status, content_type, body)
end

# ============================================================================
# Server
# ============================================================================

function run_server()
    """Start HTTP server"""
    
    server = listen(IPv4(HOST), PORT)
    
    println("\n🌐 Morpheus Decision Server")
    println("=" ^ 50)
    println("Listening on http://$HOST:$PORT")
    println("\nEndpoints:")
    println("  GET  /api/health")
    println("  POST /api/decide       (JSON sensor data)")
    println("  GET  /api/decisions/10 (last 10 decisions)")
    println("\nExample request:")
    println("""
    curl -X POST http://127.0.0.1:8000/api/decide \\
      -H 'Content-Type: application/json' \\
      -d '{
        "device_id": "esp32-01",
        "sensor_type": "temperature",
        "value": 28.5
      }'
    """)
    println("\n" * "=" ^ 50)
    println("Press Ctrl+C to stop")
    println("=" ^ 50 * "\n")
    
    # Ensure log directory exists
    mkpath(dirname(DECISIONS_LOG))
    
    while true
        try
            client = accept(server)
            
            # Read request
            request_str = ""
            try
                while true
                    data = String(read(client, 1024))
                    if isempty(data)
                        break
                    end
                    request_str *= data
                    if length(request_str) > MAX_REQUEST_SIZE
                        break
                    end
                end
            catch
            end
            
            # Parse and route
            req = parse_http_request(request_str)
            
            if req !== nothing
                response = route_request(req)
                write(client, response)
            else
                write(client, build_http_response(400, "text/plain", "Bad request"))
            end
            
            close(client)
            
        catch e
            if !isa(e, Base.IOError)
                @warn "Error: $e"
            end
        end
    end
end

# ============================================================================
# Main
# ============================================================================

if abspath(PROGRAM_FILE) == @__FILE__
    run_server()
end
