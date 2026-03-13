#!/usr/bin/env julia
# migrate-json-to-matrix.jl
# One-time migration: Convert rl-agent-selection.json → rl-state.jld2
#
# Usage:
#   julia migrate-json-to-matrix.jl
#   julia migrate-json-to-matrix.jl --backup
#   julia migrate-json-to-matrix.jl --restore
#
# This script:
# 1. Reads rl-agent-selection.json (old format)
# 2. Converts to MatrixRL format
# 3. Saves as rl-state.jld2 (binary)
# 4. Keeps JSON backup for safety
# 5. Verifies data integrity

using Dates
import JSON

const SCRIPT_DIR = @__DIR__
include(joinpath(SCRIPT_DIR, "MatrixRL.jl"))
using .MatrixRL

const OLD_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-agent-selection.json")
const NEW_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-state.jld2")
const BACKUP_PATH = joinpath(SCRIPT_DIR, "..", "..", "data", "rl", "rl-agent-selection.json.backup")

# ─── Migration ─────────────────────────────────────────────────────────────

"""
    migrate_json_to_matrix()

Convert JSON RL state to Julia matrix format.
"""
function migrate_json_to_matrix()
    if !isfile(OLD_PATH)
        println("❌ Error: $OLD_PATH not found")
        return false
    end
    
    println("📖 Loading old JSON format: $OLD_PATH")
    
    # Load from JSON
    try
        rl = initialize_from_json(OLD_PATH)
        println("✓ Loaded $(sum(rl.N)) total updates from JSON")
        
        # Display before state
        println("\n📊 Before migration:")
        println("   Total updates: $(sum(rl.N))")
        println("   Q-score range: [$(round(minimum(filter(!iszero, rl.Q)), digits=3)), $(round(maximum(rl.Q), digits=3))]")
        
        # Verify data
        for (t_idx, task) in enumerate(MatrixRL.TASKS)
            task_updates = sum(rl.N[:, t_idx])
            if task_updates > 0
                task_q = rl.Q[:, t_idx]
                println("   $task: $task_updates updates, avg Q=$(round(mean(task_q), digits=3))")
            end
        end
        
        # Save as binary
        println("\n💾 Saving to binary format: $NEW_PATH")
        save_state(rl, NEW_PATH)
        println("✓ Saved $(filesize(NEW_PATH)) bytes")
        
        # Backup original JSON
        if !isfile(BACKUP_PATH)
            cp(OLD_PATH, BACKUP_PATH)
            println("✓ Backup created: $BACKUP_PATH")
        end
        
        # Verify by loading back
        println("\n✔️  Verifying integrity...")
        rl2 = load_state(NEW_PATH)
        
        if rl.Q ≈ rl2.Q && rl.N == rl2.N
            println("✓ Verification passed: Data matches perfectly")
            println("\n✅ Migration successful!")
            println("\nNext steps:")
            println("  1. Update code to use new binary format")
            println("  2. Test with: julia agent-spawner-fast.jl --status")
            println("  3. Remove old JSON if desired: rm $OLD_PATH")
            return true
        else
            println("❌ Verification FAILED: Data mismatch")
            return false
        end
        
    catch err
        println("❌ Error during migration: $err")
        return false
    end
end

"""
    backup_current()

Create backup of current state (before migration).
"""
function backup_current()
    if isfile(OLD_PATH)
        timestamp = Dates.format(now(), "yyyymmdd-HHMMSS")
        backup = "$(OLD_PATH).$timestamp"
        cp(OLD_PATH, backup)
        println("✓ Backup created: $backup")
    else
        println("⚠️  No JSON file to backup")
    end
end

"""
    restore_json()

Restore from backup (if migration went wrong).
"""
function restore_json()
    if isfile(BACKUP_PATH)
        cp(BACKUP_PATH, OLD_PATH, force=true)
        println("✓ Restored: $OLD_PATH")
        rm(NEW_PATH, force=true)
        println("✓ Removed: $NEW_PATH")
    else
        println("❌ No backup found: $BACKUP_PATH")
    end
end

# ─── CLI ───────────────────────────────────────────────────────────────────

function main()
    if length(ARGS) > 0
        cmd = ARGS[1]
        if cmd == "--backup"
            backup_current()
        elseif cmd == "--restore"
            restore_json()
        elseif cmd == "--help"
            println("""
            Usage:
              julia migrate-json-to-matrix.jl       # Run migration
              julia migrate-json-to-matrix.jl --backup   # Backup before migrating
              julia migrate-json-to-matrix.jl --restore  # Undo migration (from backup)
            """)
        end
    else
        # Run migration
        success = migrate_json_to_matrix()
        exit(success ? 0 : 1)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
