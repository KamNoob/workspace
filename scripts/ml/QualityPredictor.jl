# QualityPredictor.jl
# Lightweight agent quality prediction module for Morpheus task routing.
# No external dependencies — pure stdlib + base Julia.

module QualityPredictor

export top_agent_for_task, AgentScore

# ─── Agent capability profile ──────────────────────────────────────────────
# Each agent has a base skill score per task_type (0.0 – 1.0).
# Trained from AGENTS_CONFIG.md; update as outcomes accumulate.

const AGENT_PROFILES = Dict{String, Dict{String, Float64}}(
    "Codex"      => Dict("code"=>0.93, "review"=>0.85, "test"=>0.80, "security"=>0.60, "docs"=>0.65, "research"=>0.45, "data"=>0.55, "default"=>0.70),
    "Cipher"     => Dict("security"=>0.95, "review"=>0.75, "code"=>0.55, "docs"=>0.50, "default"=>0.55),
    "Scout"      => Dict("research"=>0.92, "docs"=>0.80, "review"=>0.70, "data"=>0.65, "default"=>0.60),
    "Chronicle"  => Dict("docs"=>0.95, "research"=>0.80, "review"=>0.70, "default"=>0.55),
    "Sentinel"   => Dict("infra"=>0.93, "security"=>0.75, "code"=>0.60, "default"=>0.60),
    "Lens"       => Dict("data"=>0.94, "research"=>0.78, "review"=>0.65, "default"=>0.58),
    "Echo"       => Dict("design"=>0.90, "research"=>0.72, "docs"=>0.68, "default"=>0.55),
    "Veritas"    => Dict("review"=>0.94, "research"=>0.80, "docs"=>0.72, "default"=>0.60),
    "QA"         => Dict("test"=>0.95, "review"=>0.82, "code"=>0.65, "default"=>0.62),
    "Prism"      => Dict("test"=>0.90, "design"=>0.75, "review"=>0.70, "default"=>0.58),
    "Navigator"  => Dict("planning"=>0.92, "docs"=>0.75, "research"=>0.65, "default"=>0.60),
)

# Task type aliases: normalise user-supplied strings
const TASK_ALIASES = Dict(
    "coding"      => "code",
    "development" => "code",
    "dev"         => "code",
    "bug"         => "code",
    "fix"         => "code",
    "testing"     => "test",
    "qa"          => "test",
    "audit"       => "security",
    "vuln"        => "security",
    "sec"         => "security",
    "documentation" => "docs",
    "write"       => "docs",
    "analysis"    => "data",
    "metrics"     => "data",
    "validate"    => "review",
    "check"       => "review",
    "infra"       => "infra",
    "infrastructure" => "infra",
    "design"      => "design",
    "ux"          => "design",
    "plan"        => "planning",
    "schedule"    => "planning",
)

struct AgentScore
    agent::String
    prob::Float64        # 0.0–1.0 success probability
    confidence::Symbol   # :high | :medium | :low
    rationale::String
end

"""
    normalise_task(task_type) -> String
Map user-supplied task label to canonical type.
"""
function normalise_task(task_type::AbstractString)::String
    t = lowercase(strip(task_type))
    return get(TASK_ALIASES, t, t)
end

"""
    agent_prob(agent, task_type) -> Float64
Return the base skill probability for an agent on a given task type.
Falls back to agent's "default" score if task not found.
"""
function agent_prob(agent::AbstractString, task_type::AbstractString)::Float64
    profile = get(AGENT_PROFILES, agent, nothing)
    isnothing(profile) && return 0.40   # unknown agent — conservative
    return get(profile, task_type, get(profile, "default", 0.50))
end

"""
    confidence_band(prob) -> Symbol
Map probability to confidence tier.
  :high   >= 0.80
  :medium >= 0.60
  :low    <  0.60
"""
function confidence_band(prob::Float64)::Symbol
    prob >= 0.80 && return :high
    prob >= 0.60 && return :medium
    return :low
end

"""
    top_agent_for_task(task_type, candidates) -> AgentScore
Score each candidate and return the best match.

  task_type  - e.g. "code", "security", "research"
  candidates - Vector of agent name strings

Returns an AgentScore with selected agent, probability, confidence, and rationale.
"""
function top_agent_for_task(task_type::AbstractString, candidates::Vector{String})::AgentScore
    isempty(candidates) && error("candidates must be non-empty")

    norm_task = normalise_task(task_type)

    scores = map(candidates) do agent
        p = agent_prob(agent, norm_task)
        (agent=agent, prob=p)
    end

    best = reduce((a, b) -> a.prob >= b.prob ? a : b, scores)
    conf = confidence_band(best.prob)

    # Build rationale string
    ranked = sort(scores, by=x->x.prob, rev=true)
    rank_str = join(["$(r.agent)($(round(r.prob, digits=2)))" for r in ranked], ", ")
    rationale = "task=$(norm_task) | ranked: $(rank_str) | selected=$(best.agent) conf=$(conf)"

    return AgentScore(best.agent, best.prob, conf, rationale)
end

end # module QualityPredictor
