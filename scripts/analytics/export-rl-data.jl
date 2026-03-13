#!/usr/bin/env julia
# export-rl-data.jl
# Export RL outcome logs and Q-values to CSV for R analytics

using Dates
using Serialization

const SCRIPT_DIR = @__DIR__
include(joinpath(SCRIPT_DIR, "..", "ml", "MatrixRL.jl"))
using .MatrixRL

function export_rl_state_to_csv()
    rl_path = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-state.jld2")
    csv_path = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-q-values.csv")
    
    println("📖 Loading RL state from: $rl_path")
    
    try
        rl = MatrixRL.load_state(rl_path)
        
        # Write CSV header
        open(csv_path, "w") do io
            println(io, "task,agent,q_score,visits")
            
            # Write data
            for (t_idx, task) in enumerate(MatrixRL.TASKS)
                for (a_idx, agent) in enumerate(MatrixRL.AGENTS)
                    q_score = rl.Q[a_idx, t_idx]
                    visits = rl.N[a_idx, t_idx]
                    println(io, "$task,$agent,$(round(q_score, digits=4)),$visits")
                end
            end
        end
        
        println("✓ Exported Q-values to: $csv_path")
        return true
    catch err
        @error "Failed to export RL state: $err"
        return false
    end
end

function export_outcomes_to_csv()
    jsonl_path = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-task-execution-log.jsonl")
    csv_path = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-outcomes.csv")
    
    if !isfile(jsonl_path)
        @warn "Outcomes JSONL not found: $jsonl_path"
        return false
    end
    
    println("📖 Loading outcomes from: $jsonl_path")
    
    try
        lines = readlines(jsonl_path)
        open(csv_path, "w") do io
            println(io, "timestamp,task,agent,success,reward")
            
            for line in lines
                if isempty(strip(line))
                    continue
                end
                try
                    # Parse JSON manually (simple case)
                    # Extract fields using regex/string parsing
                    if contains(line, "\"task\"") && contains(line, "\"agent\"")
                        # Simple extraction (not full JSON parsing)
                        ts = match(r"\"timestamp\":\"([^\"]+)\"", line)
                        task_m = match(r"\"task\":\"([^\"]+)\"", line)
                        agent_m = match(r"\"agent\":\"([^\"]+)\"", line)
                        success_m = match(r"\"success\":(true|false)", line)
                        reward_m = match(r"\"reward\":([0-9.]+)", line)
                        
                        if !isnothing(ts) && !isnothing(task_m) && !isnothing(agent_m) && !isnothing(success_m)
                            ts_val = ts.captures[1]
                            task_val = task_m.captures[1]
                            agent_val = agent_m.captures[1]
                            success_val = success_m.captures[1] == "true" ? 1 : 0
                            reward_val = isnothing(reward_m) ? (success_val == 1 ? 1.0 : 0.0) : parse(Float64, reward_m.captures[1])
                            
                            println(io, "$ts_val,$task_val,$agent_val,$success_val,$reward_val")
                        end
                    end
                catch err
                    # Skip malformed lines
                    continue
                end
            end
        end
        
        println("✓ Exported outcomes to: $csv_path")
        return true
    catch err
        @error "Failed to export outcomes: $err"
        return false
    end
end

function main()
    println("╔═════════════════════════════════════════╗")
    println("║ RL Data Export (CSV for R Analytics)     ║")
    println("╚═════════════════════════════════════════╝\n")
    
    success1 = export_rl_state_to_csv()
    success2 = export_outcomes_to_csv()
    
    if success1 && success2
        println("\n✅ Export complete!")
        println("📂 CSV files ready for R:\n")
        println("   - data/rl/rl-q-values.csv")
        println("   - data/rl/rl-outcomes.csv")
        println("\nRun: Rscript scripts/analytics/rl-analytics.R")
    else
        println("\n⚠️  Partial export (see errors above)")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
