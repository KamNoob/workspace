"""
FEEDBACK HOOK - Integrates with spawner-matrix
Captures task outcomes and prompts for user validation.
Feeds validated outcomes back into Q-learning.

Called AFTER task completion, BEFORE Q-value update.
"""

module FeedbackHook

using JSON
using Dates
using UUIDs

const FEEDBACK_LOG = "data/feedback-logs/feedback-validation.jsonl"

export record_task_outcome, prompt_user_feedback, enrich_outcome_with_feedback

"""
Record task completion outcome.
Called by spawner after agent completes task.
"""
function record_task_outcome(
    task_id::String,
    agent::String,
    task_type::String,
    success::Bool,
    duration_ms::Int,
    cost_usd::Float64,
    quality_estimate::Float64
)::Dict{String, Any}
    
    outcome = Dict(
        "task_id" => task_id,
        "agent" => agent,
        "task_type" => task_type,
        "success" => success,
        "duration_ms" => duration_ms,
        "cost_usd" => cost_usd,
        "quality_estimate" => quality_estimate,  # Automated estimate (0-1)
        "timestamp" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ"),
        "event_type" => "task_completion",
        "awaiting_feedback" => true
    )
    
    return outcome
end

"""
Prompt user for feedback on task outcome.
Returns: Dict with approved (bool), quality_score (1-5), notes (string)
"""
function prompt_user_feedback(outcome::Dict{String, Any})::Dict{String, Any}
    """
    In production, this would:
    1. Show task summary to user (what agent did, output preview)
    2. Ask: "Did this meet expectations? Y/N"
    3. Ask: "Quality (1-5)?" if approved
    4. Optional: "Any notes?"
    
    For now, returns structure for external integration.
    """
    return Dict(
        "task_id" => outcome["task_id"],
        "approved" => nothing,  # Awaiting user input
        "quality_score" => nothing,
        "notes" => "",
        "feedback_requested_at" => Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")
    )
end

"""
Enrich outcome with explicit user feedback.
Called after user provides validation signal.
"""
function enrich_outcome_with_feedback(
    outcome::Dict{String, Any},
    feedback::Dict{String, Any}
)::Dict{String, Any}
    
    outcome["user_feedback"] = feedback
    outcome["awaiting_feedback"] = false
    outcome["feedback_enriched_at"] = Dates.format(now(Dates.UTC), "yyyy-mm-ddTHH:MM:SS.sssZ")
    
    # Compute validation signal for Q-learning
    if feedback["approved"] === nothing
        outcome["validation_signal"] = outcome["quality_estimate"]  # Use automated estimate
    else
        # User-provided signal: quality_score (1-5) if approved, 1 if rejected
        if feedback["approved"]
            outcome["validation_signal"] = feedback["quality_score"] / 5.0  # Normalize to 0-1
        else
            outcome["validation_signal"] = 0.2  # Strong negative signal for rejection
        end
    end
    
    return outcome
end

"""
Log enriched outcome to audit trail.
"""
function log_enriched_outcome(outcome::Dict{String, Any})
    audit_dir = dirname(FEEDBACK_LOG)
    mkpath(audit_dir)
    
    open(FEEDBACK_LOG, "a") do f
        println(f, JSON.json(outcome))
    end
end

end  # module FeedbackHook
