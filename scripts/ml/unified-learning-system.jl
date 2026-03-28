#!/usr/bin/env julia
"""
UNIFIED LEARNING SYSTEM - P0+P1+P2 Integration

Orchestrates feedback validation, collaboration detection, and knowledge extraction.
Single entry point for all learning operations.

Usage:
  julia unified-learning-system.jl --full-cycle        # Run all three stages
  julia unified-learning-system.jl --feedback-only     # Just feedback processing
  julia unified-learning-system.jl --collaboration      # Just collaboration analysis
  julia unified-learning-system.jl --knowledge          # Just knowledge extraction
  julia unified-learning-system.jl --report             # Generate learning report
"""

using JSON
using Dates
using Statistics

const SCRIPT_DIR = @__DIR__

"""Execute full learning cycle: feedback → collaboration → knowledge"""
function run_full_cycle()
    println("═" ^ 60)
    println("UNIFIED LEARNING SYSTEM - FULL CYCLE")
    println("═" ^ 60)
    println("[$(now())] Starting learning pipeline...\n")
    
    # Stage 1: Feedback Processing
    println("STAGE 1: FEEDBACK PROCESSING & Q-LEARNING UPDATE")
    println("-" ^ 60)
    run(`/snap/julia/165/bin/julia $(joinpath(SCRIPT_DIR, "feedback-validator.jl")) --sync-to-qlearning`)
    
    # Stage 2: Collaboration Analysis
    println("\nSTAGE 2: COLLABORATION GRAPH ANALYSIS")
    println("-" ^ 60)
    run(`/snap/julia/165/bin/julia $(joinpath(SCRIPT_DIR, "collaboration-graph.jl")) --analyze`)
    
    # Stage 3: Knowledge Extraction
    println("\nSTAGE 3: KNOWLEDGE EXTRACTION & PATTERN SYNTHESIS")
    println("-" ^ 60)
    run(`/snap/julia/165/bin/julia $(joinpath(SCRIPT_DIR, "knowledge-extractor.jl")) --extract`)
    
    println("\n" * "═" ^ 60)
    println("✅ LEARNING CYCLE COMPLETE")
    println("═" ^ 60)
    println("[$(now())] All systems updated: Q-learning, collaboration graph, knowledge base\n")
end

"""Run feedback processing only"""
function run_feedback_only()
    println("Feedback Processing...")
    run(`/snap/julia/165/bin/julia $(joinpath(SCRIPT_DIR, "feedback-validator.jl")) --sync-to-qlearning`)
end

"""Run collaboration analysis only"""
function run_collaboration_only()
    println("Collaboration Analysis...")
    run(`/snap/julia/165/bin/julia $(joinpath(SCRIPT_DIR, "collaboration-graph.jl")) --analyze`)
end

"""Run knowledge extraction only"""
function run_knowledge_only()
    println("Knowledge Extraction...")
    run(`/snap/julia/165/bin/julia $(joinpath(SCRIPT_DIR, "knowledge-extractor.jl")) --extract`)
end

"""Generate comprehensive learning report"""
function generate_report()
    println("\n" * "═" ^ 60)
    println("LEARNING SYSTEM REPORT")
    println("═" ^ 60)
    
    # Check files exist
    feedback_log = "data/feedback-logs/feedback-validation.jsonl"
    collab_graph = "data/collaboration-graph.json"
    kb_file = "data/knowledge-base/extracted-patterns.json"
    
    println("\n📊 SYSTEM STATUS:\n")
    
    if isfile(feedback_log)
        feedback_count = parse(Int, readlines(`wc -l $feedback_log`)[1])
        println("✅ Feedback System: ACTIVE ($feedback_count feedback entries)")
    else
        println("⏳ Feedback System: Awaiting first feedback")
    end
    
    if isfile(collab_graph)
        graph = JSON.parsefile(collab_graph)
        println("✅ Collaboration Graph: $(graph["total_pairs"]) agent pairs analyzed")
    else
        println("⏳ Collaboration Graph: Awaiting audit data")
    end
    
    if isfile(kb_file)
        kb = JSON.parsefile(kb_file)
        println("✅ Knowledge Base: $(kb["total_patterns"]) patterns extracted")
    else
        println("⏳ Knowledge Base: Awaiting task outcomes")
    end
    
    println("\n" * "═" ^ 60)
    println("\n💡 NEXT STEPS:")
    println("  1. Record task outcome: feedback-validator.jl --task-id <uuid> --approved true --quality 4")
    println("  2. Run feedback → Q-learning: unified-learning-system.jl --feedback-only")
    println("  3. Analyze collaboration: unified-learning-system.jl --collaboration")
    println("  4. Extract knowledge: unified-learning-system.jl --knowledge")
    println("  5. Full cycle (all above): unified-learning-system.jl --full-cycle")
    println("\n" * "═" ^ 60 * "\n")
end

# Main execution
function main()
    if length(ARGS) > 0
        cmd = ARGS[1]
        
        if cmd == "--full-cycle"
            run_full_cycle()
        elseif cmd == "--feedback-only"
            run_feedback_only()
        elseif cmd == "--collaboration"
            run_collaboration_only()
        elseif cmd == "--knowledge"
            run_knowledge_only()
        elseif cmd == "--report"
            generate_report()
        else
            println("Unknown command: $cmd")
            println("\nUsage:")
            println("  julia unified-learning-system.jl --full-cycle")
            println("  julia unified-learning-system.jl --feedback-only")
            println("  julia unified-learning-system.jl --collaboration")
            println("  julia unified-learning-system.jl --knowledge")
            println("  julia unified-learning-system.jl --report")
        end
    else
        generate_report()
    end
end

main()
