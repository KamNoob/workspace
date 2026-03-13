#!/usr/bin/env julia
# migrate-to-matrix.jl
# One-time migration: JSON → Matrix format
# Simple version without external dependencies.

using Dates

const SCRIPT_DIR = @__DIR__
include(joinpath(SCRIPT_DIR, "MatrixRL.jl"))
using .MatrixRL

const OLD_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-agent-selection.json")
const NEW_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-state.jld2")
const BACKUP_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-agent-selection.json.backup")

"""
    parse_json_manually(filepath::String) -> Dict

Parse JSON file manually (no JSON library required).
"""
function parse_json_manually(filepath::String)::Dict
    content = read(filepath, String)
    
    # Very basic JSON parsing for our specific use case
    # Real implementation would use JSON.jl, but this is fallback
    
    # For now, use built-in eval (careful with untrusted input)
    # In production, use JSON.jl
    
    try
        # Replace common JSON patterns
        json_str = content
        result = eval(Meta.parse("Dict($json_str)"))
        return result
    catch err
        @warn "Manual JSON parsing failed, falling back to empty state"
        return Dict()
    end
end

"""
    migrate()

Run the migration.
"""
function migrate()
    if !isfile(OLD_PATH)
        println("📖 Old JSON file not found: $OLD_PATH")
        println("   Creating fresh RL state...")
        rl = MatrixRL.RL_State()
    else
        println("📖 Loading old JSON: $OLD_PATH")
        
        # Try loading JSON
        rl = try
            # Load JSON at top-level
            content = read(OLD_PATH, String)
            # Try parsing with JSON library if available
            try
                import JSON
                data = JSON.parse(content)
                MatrixRL.load_from_old_json(data)
            catch
                @warn "JSON library not available, creating fresh state"
                MatrixRL.RL_State()
            end
        catch err
            @warn "Failed to load JSON: $err, creating fresh state"
            MatrixRL.RL_State()
        end
    end
    
    println("\n📊 RL State Summary:")
    println("   Total updates: $(sum(rl.N))")
    if maximum(rl.Q) > 0
        nonzero_q = filter(!iszero, vec(rl.Q))
        println("   Q-score range: [$(round(minimum(nonzero_q), digits=3)), $(round(maximum(nonzero_q), digits=3))]")
    end
    
    println("\n💾 Saving to binary format: $NEW_PATH")
    try
        MatrixRL.save_state(rl, NEW_PATH)
        file_size = filesize(NEW_PATH)
        println("✓ Saved ($file_size bytes)")
    catch err
        println("❌ Save failed: $err")
        return false
    end
    
    # Backup original
    if isfile(OLD_PATH) && !isfile(BACKUP_PATH)
        cp(OLD_PATH, BACKUP_PATH)
        println("✓ Backup created: $BACKUP_PATH")
    end
    
    # Verify
    println("\n✔️  Verifying...")
    try
        rl2 = MatrixRL.load_state(NEW_PATH)
        if rl.Q ≈ rl2.Q && rl.N == rl2.N
            println("✓ Verification passed!")
            println("\n✅ Migration complete!")
            println("\nNext: julia scripts/ml/agent-spawner-fast.jl --status")
            return true
        else
            println("❌ Data mismatch after load")
            return false
        end
    catch err
        println("❌ Verification failed: $err")
        return false
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    success = migrate()
    exit(success ? 0 : 1)
end
