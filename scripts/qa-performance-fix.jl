#!/usr/bin/env julia
"""
QA Performance Fix: Route QA to testing tasks only, not coding implementation
Issue: QA was scoring 100% on 7 early tasks, then started failing on hard coding tasks
Solution: Create dedicated 'testing' task type, remove QA from 'code' type
"""

using JSON

config_path = "data/rl/rl-agent-selection.json"
config = JSON.parsefile(config_path)

# Backup
cp(config_path, config_path * ".backup-qa-fix-$(now())", force=true)

println("=== QA Performance Fix ===\n")

# Strategy 1: Remove QA from code task type (not suited for implementation)
if haskey(config["task_types"], "code") && haskey(config["task_types"]["code"]["agents"], "QA")
    println("📍 Before: QA in 'code' task routing")
    
    qa_code = config["task_types"]["code"]["agents"]["QA"]
    println("   Q-score: $(qa_code["q_score"])")
    println("   Success: $(qa_code["success_count"])/$(qa_code["total_uses"]) (early bias)")
    println("   Issue: Assigned complex coding tasks beyond testing scope\n")
    
    # Remove QA from code
    delete!(config["task_types"]["code"]["agents"], "QA")
    println("✅ Action 1: Removed QA from 'code' task routing")
    println("   Reason: QA specializes in testing/validation, not implementation\n")
end

# Strategy 2: Create or update 'testing' task type for QA
if !haskey(config["task_types"], "testing")
    config["task_types"]["testing"] = Dict(
        "agents" => Dict(
            "QA" => Dict(
                "q_score" => 0.7,
                "success_count" => 0,
                "failure_count" => 0,
                "total_uses" => 0,
                "success_rate" => 0.5,
                "last_updated" => now()
            )
        )
    )
    println("✅ Action 2: Created 'testing' task type")
    println("   Dedicated routing for: unit tests, integration tests, edge case discovery\n")
else
    if !haskey(config["task_types"]["testing"]["agents"], "QA")
        config["task_types"]["testing"]["agents"]["QA"] = Dict(
            "q_score" => 0.7,
            "success_count" => 0,
            "failure_count" => 0,
            "total_uses" => 0,
            "success_rate" => 0.5,
            "last_updated" => now()
        )
        println("✅ Action 2: Added QA to existing 'testing' task type\n")
    end
end

# Strategy 3: Add Veritas (code review) to code tasks
if haskey(config["task_types"], "code") && !haskey(config["task_types"]["code"]["agents"], "Veritas")
    config["task_types"]["code"]["agents"]["Veritas"] = Dict(
        "q_score" => 0.65,
        "success_count" => 0,
        "failure_count" => 0,
        "total_uses" => 0,
        "success_rate" => 0.5,
        "last_updated" => now()
    )
    println("✅ Action 3: Added Veritas (code review) to 'code' task routing\n")
end

# Strategy 4: Reinforce Codex on code tasks
config["task_types"]["code"]["agents"]["Codex"]["q_score"] = 0.75  # Boost
println("✅ Action 4: Reinforced Codex Q-score on 'code' to 0.75\n")

# Summary
println("=== Result ===")
println("Before: QA routed to all 'code' tasks (implementation + testing)")
println("After:  QA routed to dedicated 'testing' tasks only\n")

println("New routing:")
for (task_type, task_data) in sort(config["task_types"])
    if haskey(task_data["agents"], "QA")
        qa = task_data["agents"]["QA"]
        println("  • $task_type → QA (Q=$(qa["q_score"]))")
    end
end

# Save
open(config_path, "w") do f
    JSON.print(f, config, 2)
end

println("\n✅ Config saved to $config_path")
println("📝 Backup: $config_path.backup-qa-fix-*")
