#!/usr/bin/env julia
"""
FEEDBACK VALIDATOR - P0: Close the feedback loop
Bridges task outcomes with explicit user validation.
Feeds validated outcomes back into Q-learning system.

Usage:
  julia feedback-validator.jl --task-id <uuid> --approved true --quality 4 --notes "optional"
  julia feedback-validator.jl --batch --process-pending
  julia feedback-validator.jl --sync-to-qlearning
"""

using JSON
using Dates
using Statistics

const FEEDBACK_LOG = "data/feedback-logs/feedback-validation.jsonl"
const AUDIT_LOGS_DIR = "data/audit-logs"
const Q_MATRIX_FILE = "data/rl/rl-agent-selection.json"
const LEARNING_RATE = 0.1  # α for Q-learning update
const GAMMA = 0.95  # Discount factor

# Ensure feedback log directory exists
mkpath(dirname(FEEDBACK_LOG))

"""Parse command-line arguments"""
function parse_args()
    args = Dict(
        "task_id" => nothing,
        "approved" => nothing,
        "quality" => nothing,
        "notes" => "",
        "batch" => false,
        "process_pending" => false,
        "sync_to_qlearning" => false
    )
    
    i = 1
    while i <= length(ARGS)
        arg = ARGS[i]
        if arg == "--task-id" && i < length(ARGS)
            args["task_id"] = ARGS[i+1]
            i += 2
        elseif arg == "--approved" && i < length(ARGS)
            args["approved"] = lowercase(ARGS[i+1]) == "true"
            i += 2
        elseif arg == "--quality" && i < length(ARGS)
            args["quality"] = parse(Int, ARGS[i+1])
            i += 2
        elseif arg == "--notes" && i < length(ARGS)
            args["notes"] = ARGS[i+1]
            i += 2
        elseif arg == "--batch"
            args["batch"] = true
            i += 1
        elseif arg == "--process-pending"
            args["process_pending"] = true
            i += 1
        elseif arg == "--sync-to-qlearning"
            args["sync_to_qlearning"] = true
            i += 1
        else
            i += 1
        end
    end
    return args
end

"""Record user feedback for a task"""
function record_feedback(task_id::String, approved::Bool, quality::Int, notes::String="")
    if quality < 1 || quality > 5
        error("Quality must be 1-5, got $quality")
    end
    
    feedback = Dict(
        "task_id" => task_id,
        "approved" => approved,
        "quality_score" => quality,
        "notes" => notes,
        "timestamp" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ"),
        "event_type" => "user_feedback",
        "validation_signal" => approved ? quality : 1,  # Disapproved = signal 1
        "reviewed_by" => "user"
    )
    
    open(FEEDBACK_LOG, "a") do f
        println(f, JSON.json(feedback))
    end
    
    println("✓ Feedback recorded: task=$task_id approved=$approved quality=$quality")
    return feedback
end

"""Find audit entry for a task and enrich it with feedback"""
function enrich_audit_with_feedback(task_id::String, feedback::Dict)
    # Search audit logs for matching task
    audit_files = filter(f -> endswith(f, ".jsonl"), readdir(AUDIT_LOGS_DIR))
    
    found = false
    for audit_file in audit_files
        audit_path = joinpath(AUDIT_LOGS_DIR, audit_file)
        lines = readlines(audit_path)
        
        # Look for task_id in audit logs
        for (idx, line) in enumerate(lines)
            try
                entry = JSON.parse(line)
                if get(entry, "task_id", nothing) == task_id
                    # Found it - add feedback enrichment
                    entry["user_feedback"] = feedback
                    entry["feedback_enriched_at"] = Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")
                    
                    # Rewrite line with enriched data
                    lines[idx] = JSON.json(entry)
                    found = true
                    break
                end
            catch
                continue
            end
        end
        
        if found
            # Write back enriched audit log
            open(audit_path, "w") do f
                for line in lines
                    println(f, line)
                end
            end
            break
        end
    end
    
    return found
end

"""Load current Q-matrix"""
function load_qmatrix()
    if !isfile(Q_MATRIX_FILE)
        error("Q-matrix not found at $Q_MATRIX_FILE")
    end
    return JSON.parsefile(Q_MATRIX_FILE)
end

"""Update Q-learning values based on feedback"""
function update_qvalues_from_feedback()
    if !isfile(FEEDBACK_LOG)
        println("No feedback log found. Skipping Q-value update.")
        return
    end
    
    qdata = load_qmatrix()
    feedback_count = 0
    
    open(FEEDBACK_LOG, "r") do f
        for line in eachline(f)
            try
                fb = JSON.parse(line)
                if fb["event_type"] != "user_feedback"
                    continue
                end
                
                # Extract task and quality signal
                task_id = fb["task_id"]
                validation_signal = fb["validation_signal"]  # 1-5 or 1 (disapproved)
                
                # Find corresponding audit entry to get agent + task type
                audit_files = filter(f -> endswith(f, ".jsonl"), readdir(AUDIT_LOGS_DIR))
                for audit_file in audit_files
                    audit_path = joinpath(AUDIT_LOGS_DIR, audit_file)
                    audit_lines = readlines(audit_path)
                    
                    for audit_line in audit_lines
                        try
                            entry = JSON.parse(audit_line)
                            if get(entry, "task_id", nothing) == task_id
                                agent = get(entry, "agent_selected", get(entry, "agent", nothing))
                                task_type = get(entry, "task", get(entry, "task_type", nothing))
                                
                                if agent !== nothing && task_type !== nothing
                                    # Update Q-value: Q(s,a) = Q(s,a) + α * [r - Q(s,a)]
                                    # where r = validation_signal (1-5)
                                    reward = validation_signal / 5.0  # Normalize to 0-1
                                    
                                    if haskey(qdata["task_types"], task_type)
                                        agents_list = qdata["task_types"][task_type]["agents"]
                                        if haskey(agents_list, agent)
                                            old_q = agents_list[agent]["q_value"]
                                            new_q = old_q + LEARNING_RATE * (reward - old_q)
                                            agents_list[agent]["q_value"] = new_q
                                            agents_list[agent]["last_feedback"] = fb["timestamp"]
                                            feedback_count += 1
                                        end
                                    end
                                end
                            end
                        catch
                            continue
                        end
                    end
                end
            catch
                continue
            end
        end
    end
    
    # Write updated Q-matrix
    open(Q_MATRIX_FILE, "w") do f
        JSON.print(f, qdata, 2)
    end
    
    println("✓ Q-learning updated from $feedback_count feedback entries")
    return feedback_count
end

"""Generate feedback summary report"""
function generate_feedback_report()
    if !isfile(FEEDBACK_LOG)
        println("No feedback log found.")
        return
    end
    
    approvals = 0
    rejections = 0
    total_quality = 0
    quality_count = 0
    
    open(FEEDBACK_LOG, "r") do f
        for line in eachline(f)
            try
                fb = JSON.parse(line)
                if fb["event_type"] == "user_feedback"
                    if fb["approved"]
                        approvals += 1
                    else
                        rejections += 1
                    end
                    total_quality += fb["quality_score"]
                    quality_count += 1
                end
            catch
                continue
            end
        end
    end
    
    if quality_count > 0
        approval_rate = approvals / (approvals + rejections) * 100
        avg_quality = total_quality / quality_count
        
        report = """
        FEEDBACK SUMMARY REPORT
        =======================
        Total Feedback: $(approvals + rejections)
        Approval Rate: $(round(approval_rate, digits=1))%
        Average Quality: $(round(avg_quality, digits=2))/5.0
        
        Approvals: $approvals
        Rejections: $rejections
        """
        println(report)
        return report
    end
end

# Main execution
function main()
    args = parse_args()
    
    if args["task_id"] !== nothing && args["approved"] !== nothing && args["quality"] !== nothing
        # Record single feedback
        feedback = record_feedback(args["task_id"], args["approved"], args["quality"], args["notes"])
        enrich_audit_with_feedback(args["task_id"], feedback)
        update_qvalues_from_feedback()
        
    elseif args["process_pending"]
        # Process all pending feedback → Q-learning
        count = update_qvalues_from_feedback()
        println("Processed $count feedback entries into Q-learning")
        
    elseif args["sync_to_qlearning"]
        # Sync all feedback to Q-matrix
        update_qvalues_from_feedback()
        
    else
        # Show report
        generate_feedback_report()
    end
end

main()
