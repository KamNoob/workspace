#!/usr/bin/env julia
"""
Email Security Scanner with Cipher Integration
Manually-triggered threat analysis for Gmail inbox
"""

using JSON
using Dates

# Configuration
const GMAIL_USER = get(ENV, "GMAIL_USER", "")
const GMAIL_APP_PASSWORD = get(ENV, "GMAIL_APP_PASSWORD", "")
const THREAT_THRESHOLD = parse(Float64, get(ENV, "CIPHER_THREAT_THRESHOLD", "0.3"))
const QUARANTINE_THRESHOLD = parse(Float64, get(ENV, "CIPHER_QUARANTINE_THRESHOLD", "0.7"))

# Threat analysis patterns (Cipher's baseline heuristics)
const PHISHING_PATTERNS = [
    r"verify.*account"i,
    r"confirm.*identity"i,
    r"update.*payment"i,
    r"act.*now"i,
    r"urgent.*action"i,
    r"click.*here.*immediately"i,
    r"your account has been.*disabled"i,
    r"unusual activity"i,
]

const MALWARE_INDICATORS = [
    r"executable|\.exe|\.bat|\.cmd"i,
    r"password.*attached"i,
    r"enable.*macros"i,
    r"ransomware|trojan|worm"i,
]

const URGENCY_KEYWORDS = [
    "urgent", "immediately", "act now", "critical", "emergency",
    "verify within", "confirm by", "deadline", "limited time"
]

"""
Analyze email for threat patterns (Cipher's baseline analysis)
Returns threat score (0.0 - 1.0) and detailed breakdown
"""
function analyze_email_threat(email_data::Dict)::Dict
    subject = get(email_data, "subject", "")
    body = get(email_data, "body", "")
    from = get(email_data, "from", "")
    reply_to = get(email_data, "reply_to", "")
    
    threat_scores = Dict(
        "phishing" => 0.0,
        "malware" => 0.0,
        "urgency" => 0.0,
        "domain_spoofing" => 0.0,
        "credential_harvest" => 0.0,
    )
    
    # Phishing analysis
    phishing_matches = 0
    for pattern in PHISHING_PATTERNS
        if occursin(pattern, subject) || occursin(pattern, body)
            phishing_matches += 1
        end
    end
    threat_scores["phishing"] = min(1.0, phishing_matches * 0.15)
    
    # Malware indicators
    malware_matches = 0
    for pattern in MALWARE_INDICATORS
        if occursin(pattern, body)
            malware_matches += 1
        end
    end
    threat_scores["malware"] = min(1.0, malware_matches * 0.25)
    
    # Urgency language
    combined_text = lowercase(subject * " " * body)
    urgency_count = 0
    for keyword in URGENCY_KEYWORDS
        if occursin(keyword, combined_text)
            urgency_count += 1
        end
    end
    threat_scores["urgency"] = min(0.5, urgency_count * 0.1)
    
    # Domain spoofing detection (simple check)
    if from != reply_to && !isempty(reply_to)
        threat_scores["domain_spoofing"] = 0.4
    end
    
    # Credential harvest pattern
    if occursin(r"password|credit card|ssn|social security"i, body)
        threat_scores["credential_harvest"] = 0.6
    end
    
    # Calculate overall score (weighted average)
    weights = Dict(
        "phishing" => 0.25,
        "malware" => 0.30,
        "urgency" => 0.15,
        "domain_spoofing" => 0.20,
        "credential_harvest" => 0.10,
    )
    
    overall_score = sum(threat_scores[k] * weights[k] for k in keys(weights))
    
    return Dict(
        "overall_risk" => overall_score,
        "breakdown" => threat_scores,
        "confidence" => 0.75,  # Baseline confidence; Cipher will refine
        "timestamp" => now(),
    )
end

"""
Format threat analysis for logging and display
"""
function format_threat_report(email_id::String, email_data::Dict, analysis::Dict)::String
    threat = analysis["overall_risk"]
    breakdown = analysis["breakdown"]
    
    status = if threat > QUARANTINE_THRESHOLD
        "🚨 QUARANTINE"
    elseif threat >= THREAT_THRESHOLD
        "⚠️  SUSPICIOUS"
    else
        "✅ SAFE"
    end
    
    report = """
    ┌─ Email Threat Analysis ─────────────────────────
    │ ID: $email_id
    │ From: $(get(email_data, "from", "unknown"))
    │ Subject: $(get(email_data, "subject", "(no subject)"))
    │ 
    │ Status: $status
    │ Risk Score: $(round(threat; digits=2)) / 1.0
    │ Confidence: $(round(analysis["confidence"]; digits=2))
    │
    │ Breakdown:
    │   • Phishing: $(round(breakdown["phishing"]; digits=2))
    │   • Malware: $(round(breakdown["malware"]; digits=2))
    │   • Urgency: $(round(breakdown["urgency"]; digits=2))
    │   • Domain Spoofing: $(round(breakdown["domain_spoofing"]; digits=2))
    │   • Credential Harvest: $(round(breakdown["credential_harvest"]; digits=2))
    │
    └─────────────────────────────────────────────────
    """
    
    return report
end

"""
Log analysis result to audit file
"""
function log_threat_analysis(email_id::String, analysis::Dict, action::String)
    log_dir = expanduser("~/logs/email-security")
    mkpath(log_dir)
    
    log_file = joinpath(log_dir, "threat-analysis.jsonl")
    
    entry = Dict(
        "timestamp" => now(UTC),
        "email_id" => email_id,
        "risk_score" => analysis["overall_risk"],
        "action" => action,
        "analysis" => analysis,
    )
    
    open(log_file, "a") do io
        println(io, JSON.json(entry))
    end
    
    return log_file
end

"""
Main scanning function
"""
function scan_email(email_id::String, email_data::Dict)::Dict
    # Run threat analysis
    analysis = analyze_email_threat(email_data)
    threat = analysis["overall_risk"]
    
    # Determine action
    action = if threat > QUARANTINE_THRESHOLD
        "QUARANTINE"
    elseif threat >= THREAT_THRESHOLD
        "FLAG_FOR_REVIEW"
    else
        "SAFE"
    end
    
    # Log result
    log_file = log_threat_analysis(email_id, analysis, action)
    
    # Print report
    report = format_threat_report(email_id, email_data, analysis)
    println(report)
    
    return Dict(
        "email_id" => email_id,
        "threat_score" => threat,
        "action" => action,
        "confidence" => analysis["confidence"],
        "log_file" => log_file,
    )
end

"""
Demo mode: Test with sample emails
"""
function demo_scan()
    samples = [
        Dict(
            "id" => "email_1",
            "from" => "support@paypal-verify.com",
            "subject" => "URGENT: Verify Your Account Immediately",
            "body" => "Your account has been disabled. Click here immediately to confirm your identity.",
            "reply_to" => "noreply@phishing-domain.com",
        ),
        Dict(
            "id" => "email_2",
            "from" => "john@example.com",
            "subject" => "Project update",
            "body" => "Here's the latest status on the Q1 project. Let me know if you have questions.",
            "reply_to" => "john@example.com",
        ),
        Dict(
            "id" => "email_3",
            "from" => "noreply@amazon-alerts.net",
            "subject" => "Unusual Activity Detected",
            "body" => "Your password and credit card need verification. Download the attachment and enable macros.",
            "reply_to" => "fake@amazon.com",
        ),
    ]
    
    println("\n📧 EMAIL SECURITY SCANNER - DEMO MODE\n")
    
    for sample in samples
        result = scan_email(sample["id"], sample)
        println()
    end
end

# Main entry point
if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) == 0 || ARGS[1] == "demo"
        demo_scan()
    elseif ARGS[1] == "test"
        println("Testing threat analysis...")
        test_email = Dict(
            "from" => "attacker@spam.com",
            "subject" => "Act Now: Verify Your Account",
            "body" => "Click here immediately. Your account has been disabled.",
            "reply_to" => "phishing@attacker.com",
        )
        analysis = analyze_email_threat(test_email)
        println("Test Score: $(analysis["overall_risk"])")
    else
        println("Usage: julia email-security-scanner.jl [demo|test]")
        println("  demo - Run with sample emails")
        println("  test - Test threat analysis algorithm")
    end
end
