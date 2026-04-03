#!/usr/bin/env julia
# spawner-sandboxed.jl - Sandboxed agent spawner for Phase 12A
# Executes agents in isolated Docker containers with resource limits

using JSON
using Dates
using TOML

# SandboxConfig struct
mutable struct SandboxConfig
    image::String
    runtime::String
    remove_after_exit::Bool
    mounts::Dict{String, Dict}
    resources::Dict{String, Any}
    network::Dict{String, Any}
    timeout::Dict{String, Int}
    logging::Dict{String, Any}
    security::Dict{String, Any}
    tmpfs::Dict{String, Any}
end

# Load config from TOML file
function load_config(config_path::String)::SandboxConfig
    config = TOML.parsefile(config_path)
    
    SandboxConfig(
        config["container"]["image"],
        config["container"]["runtime"],
        config["container"]["remove_after_exit"],
        config["mounts"],
        config["resources"],
        config["network"],
        config["timeout"],
        config["logging"],
        config["security"],
        config["tmpfs"]
    )
end

# Build Docker run command from config
function build_docker_command(config::SandboxConfig, agent::String, task::String, container_id::String)::String
    cmd_parts = ["docker", "run"]
    
    # Container lifecycle
    push!(cmd_parts, "--name", container_id)
    if config.remove_after_exit
        push!(cmd_parts, "--rm")
    end
    
    # Resource limits
    push!(cmd_parts, "--memory", config.resources["memory_limit"])
    push!(cmd_parts, "--cpus", string(config.resources["cpus"]))
    push!(cmd_parts, "--pids-limit", string(config.resources["pids_limit"]))
    
    # Network isolation
    push!(cmd_parts, "--network", config.network["network_mode"])
    
    # Timeout (via timeout command wrapper)
    timeout_seconds = config.timeout["max_duration_seconds"]
    
    # Mount volumes
    for (name, mount_config) in config.mounts
        source = mount_config["source"]
        target = mount_config["target"]
        mode = mount_config["mode"]
        push!(cmd_parts, "-v", "$(source):$(target):$(mode)")
    end
    
    # Security options
    if !config.security["privileged"]
        push!(cmd_parts, "--security-opt=no-new-privileges:true")
    end
    
    # Drop capabilities
    for cap in config.security["drop_capabilities"]
        push!(cmd_parts, "--cap-drop", cap)
    end
    
    # Logging
    push!(cmd_parts, "--log-driver", config.logging["log_driver"])
    
    # Environment variables
    push!(cmd_parts, "-e", "AGENT=$(agent)")
    push!(cmd_parts, "-e", "TASK=$(task)")
    push!(cmd_parts, "-e", "CONTAINER_ID=$(container_id)")
    
    # Image
    push!(cmd_parts, config.image)
    
    # Command: run agent task in Julia
    cmd_script = """
    julia -e \"
    include('/scripts/ml/agent-spawner-qp.jl')
    task = (
        agent='$(agent)',
        task='$(task)',
        container_id='$(container_id)',
        timestamp=now()
    )
    try
        spawn_agent(task)
        exit(0)
    catch e
        println(stderr, \"Error: \$(e)\")
        exit(1)
    end
    \"
    """
    
    push!(cmd_parts, "sh", "-c", cmd_script)
    
    # Wrap with timeout
    return "timeout $(timeout_seconds) " * join(cmd_parts, " ")
end

# Spawn agent in container
function spawn_sandboxed(
    agent::String,
    task::String,
    config_path::String = "/home/art/.openclaw/workspace/configs/sandbox-default.toml"
)::Dict{String, Any}
    
    # Load configuration
    config = load_config(config_path)
    
    # Generate container ID
    container_id = "agent-$(agent)-$(replace(string(now()), r"[:\.]" => "-"))"
    
    # Build Docker command
    cmd = build_docker_command(config, agent, task, container_id)
    
    # Log execution
    log_entry = Dict(
        "timestamp" => now(UTC),
        "agent" => agent,
        "task" => task,
        "container_id" => container_id,
        "command" => cmd,
        "status" => "spawned"
    )
    
    println(stderr, "🐳 [SANDBOX] Spawning $(agent) in container $(container_id)")
    println(stderr, "   Task: $(task)")
    println(stderr, "   Timeout: $(config.timeout["max_duration_seconds"])s")
    println(stderr, "   Memory: $(config.resources["memory_limit"])")
    
    # Execute command
    start_time = time()
    result = run(Cmd(split(cmd)), wait=true)
    elapsed = time() - start_time
    
    # Capture outcome
    status = if result.exitcode == 0
        "success"
    elseif result.exitcode == 124
        "timeout"
    else
        "failed"
    end
    
    log_entry["status"] = status
    log_entry["exit_code"] = result.exitcode
    log_entry["elapsed_seconds"] = elapsed
    
    # Log to file
    log_file = "/home/art/.openclaw/workspace/data/sandbox-execution.jsonl"
    open(log_file, "a") do f
        println(f, JSON.json(log_entry))
    end
    
    println(stderr, "   Status: $(status)")
    println(stderr, "   Elapsed: $(round(elapsed, digits=2))s")
    
    return log_entry
end

# CLI interface
function main()
    if length(ARGS) < 2
        println(stderr, "Usage: spawner-sandboxed.jl --agent AGENT --task TASK [--config CONFIG]")
        println(stderr, "Example: spawner-sandboxed.jl --agent scout --task 'research python' --config configs/sandbox-default.toml")
        exit(1)
    end
    
    agent = ""
    task = ""
    config = "/home/art/.openclaw/workspace/configs/sandbox-default.toml"
    
    i = 1
    while i <= length(ARGS)
        if ARGS[i] == "--agent" && i < length(ARGS)
            agent = ARGS[i+1]
            i += 2
        elseif ARGS[i] == "--task" && i < length(ARGS)
            task = ARGS[i+1]
            i += 2
        elseif ARGS[i] == "--config" && i < length(ARGS)
            config = ARGS[i+1]
            i += 2
        else
            i += 1
        end
    end
    
    if isempty(agent) || isempty(task)
        println(stderr, "Error: --agent and --task are required")
        exit(1)
    end
    
    # Spawn sandboxed agent
    result = spawn_sandboxed(agent, task, config)
    
    # Exit with agent's exit code
    exit(result["exit_code"])
end

# Run if called as script
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

# Export for use as module
export SandboxConfig, load_config, build_docker_command, spawn_sandboxed
