#!/usr/bin/env julia
# init-matrix-rl.jl
# Initialize fresh MatrixRL state and save to binary format.
# Simple initialization without JSON dependency.

using Dates
using Serialization

const SCRIPT_DIR = @__DIR__
include(joinpath(SCRIPT_DIR, "MatrixRL.jl"))
using .MatrixRL

const RL_STATE_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-state.jld2")

function main()
    println("🚀 Initializing MatrixRL binary state...")
    
    # Create fresh RL state
    rl = MatrixRL.RL_State()
    
    println("✓ Created fresh RL_State")
    println("  - Agents: $(length(MatrixRL.AGENTS))")
    println("  - Tasks: $(length(MatrixRL.TASKS))")
    println("  - Matrix size: $(size(rl.Q))")
    println("  - Learning rate (α): $(rl.α)")
    println("  - Discount (γ): $(rl.γ)")
    println("  - Trace decay (λ): $(rl.λ)")
    
    # Save to binary
    println("\n💾 Saving to: $RL_STATE_PATH")
    try
        MatrixRL.save_state(rl, RL_STATE_PATH)
        file_size = filesize(RL_STATE_PATH)
        println("✓ Saved ($file_size bytes)")
        
        # Verify
        println("\n✔️  Verifying...")
        rl2 = MatrixRL.load_state(RL_STATE_PATH)
        if rl.Q ≈ rl2.Q && rl.N == rl2.N
            println("✓ Verification passed!")
            println("\n✅ Ready! Binary RL state initialized.")
            println("\nNext: Test spawner with: julia agent-spawner-fast.jl --status")
            return true
        else
            println("❌ Verification failed")
            return false
        end
    catch err
        println("❌ Error: $err")
        return false
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    success = main()
    exit(success ? 0 : 1)
end
