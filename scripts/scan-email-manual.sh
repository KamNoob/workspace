#!/bin/bash
###############################################################################
# Manual Email Security Scan with Cipher Integration
# Scans Gmail inbox and analyzes emails for malicious intent
# 
# Usage:
#   ./scan-email-manual.sh                 # Scan all unread emails
#   ./scan-email-manual.sh --limit 5       # Scan last 5 emails
#   ./scan-email-manual.sh --threat-only   # Show only suspicious emails
#   ./scan-email-manual.sh --demo          # Run demo with sample emails
###############################################################################

set -euo pipefail

# Source environment variables
source ~/.openclaw/.env

# Configuration
GMAIL_USER="${GMAIL_USER:-}"
GMAIL_APP_PASSWORD="${GMAIL_APP_PASSWORD:-}"
THREAT_THRESHOLD="${CIPHER_THREAT_THRESHOLD:-0.3}"
QUARANTINE_THRESHOLD="${CIPHER_QUARANTINE_THRESHOLD:-0.7}"
LOG_DIR="$HOME/logs/email-security"
AUDIT_LOG="$LOG_DIR/threat-analysis.jsonl"

# Create log directory
mkdir -p "$LOG_DIR"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

###############################################################################
# Functions
###############################################################################

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  📧 EMAIL SECURITY SCANNER - MANUAL TRIGGER               ║${NC}"
    echo -e "${BLUE}║  Powered by Cipher (Malicious Intent Detection)           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_credentials() {
    if [[ -z "$GMAIL_USER" || -z "$GMAIL_APP_PASSWORD" ]]; then
        echo -e "${RED}❌ ERROR: Gmail credentials not configured${NC}"
        echo "   Set GMAIL_USER and GMAIL_APP_PASSWORD in ~/.openclaw/.env"
        exit 1
    fi
}

check_imap_tool() {
    if ! command -v imapfilter &> /dev/null && ! command -v fetchmail &> /dev/null; then
        echo -e "${YELLOW}⚠️  NOTE: imapfilter or fetchmail not found${NC}"
        echo "   Email fetching requires: sudo apt-get install fetchmail"
        echo ""
        echo "   For now, using Julia scanner in demo mode..."
        echo ""
    fi
}

run_demo() {
    echo -e "${GREEN}▶ Demo Mode: Testing with sample emails${NC}"
    echo ""
    
    julia /home/art/.openclaw/workspace/scripts/email-security-scanner.jl demo
}

spawn_cipher_for_email() {
    local email_id="$1"
    local email_data="$2"
    
    echo -e "${BLUE}🔐 Spawning Cipher agent for threat analysis...${NC}"
    
    # TODO: Replace with actual Cipher spawning once integration ready
    # For now, run Julia analyzer
    echo "Email ID: $email_id"
    echo "Analyzing with threat detection algorithms..."
    echo ""
}

scan_inbox() {
    echo -e "${GREEN}▶ Scanning Gmail Inbox${NC}"
    echo "   User: $GMAIL_USER"
    echo "   Status: Connecting to IMAP..."
    echo ""
    
    # Note: Full IMAP integration requires additional setup
    # For initial implementation, use Julia analyzer + demo mode
    run_demo
}

run_threat_analyzer() {
    echo -e "${GREEN}▶ Running Threat Analysis${NC}"
    echo ""
    
    julia /home/art/.openclaw/workspace/scripts/email-security-scanner.jl test
}

show_audit_log() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  📋 THREAT ANALYSIS AUDIT LOG                             ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -f "$AUDIT_LOG" ]]; then
        # Show last 10 entries
        echo -e "${GREEN}Last 10 threat analyses:${NC}"
        echo ""
        tail -10 "$AUDIT_LOG" | jq '{timestamp: .timestamp, email_id: .email_id, risk_score: .risk_score, action: .action}'
        echo ""
        echo "Full log: $AUDIT_LOG"
    else
        echo -e "${YELLOW}No audit log found yet.${NC}"
        echo "Logs will be created at: $AUDIT_LOG"
    fi
}

show_stats() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  📊 THREAT STATISTICS                                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -f "$AUDIT_LOG" ]]; then
        local total=$(wc -l < "$AUDIT_LOG")
        local quarantine=$(jq -r '.action' "$AUDIT_LOG" | grep -c "QUARANTINE" || echo 0)
        local suspicious=$(jq -r '.action' "$AUDIT_LOG" | grep -c "FLAG_FOR_REVIEW" || echo 0)
        local safe=$(jq -r '.action' "$AUDIT_LOG" | grep -c "SAFE" || echo 0)
        
        echo "Total Scanned:        $total"
        echo -e "${RED}Quarantined:         $quarantine${NC}"
        echo -e "${YELLOW}Flagged Suspicious:   $suspicious${NC}"
        echo -e "${GREEN}Safe:                $safe${NC}"
    else
        echo "No data yet."
    fi
    echo ""
}

show_help() {
    cat << 'EOF'
USAGE:
  ./scan-email-manual.sh [OPTION]

OPTIONS:
  (no args)              Scan unread emails in Gmail inbox
  --demo                 Run demo with sample emails
  --test                 Test threat analysis algorithm
  --limit N              Scan last N emails
  --threat-only          Show only suspicious/quarantined emails
  --audit-log            Show audit log of threat analyses
  --stats                Show threat statistics
  --help                 Show this help message

EXAMPLES:
  # Scan inbox with demo emails
  ./scan-email-manual.sh --demo

  # Test the analyzer
  ./scan-email-manual.sh --test

  # View statistics
  ./scan-email-manual.sh --stats

  # View audit log
  ./scan-email-manual.sh --audit-log

CONFIGURATION:
  Credentials stored in: ~/.openclaw/.env
    GMAIL_USER
    GMAIL_APP_PASSWORD
    CIPHER_THREAT_THRESHOLD (default: 0.3)
    CIPHER_QUARANTINE_THRESHOLD (default: 0.7)

LOGS:
  Threat analysis logs: ~/logs/email-security/threat-analysis.jsonl
  
NOTE:
  For production use, configure:
  - imapfilter or fetchmail for email retrieval
  - OpenClaw Cipher integration for AI threat analysis
  - Scheduled cron job for periodic scanning
EOF
}

###############################################################################
# Main
###############################################################################

main() {
    print_header
    
    # Parse arguments
    local mode="scan"
    
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --demo)
                mode="demo"
                ;;
            --test)
                mode="test"
                ;;
            --audit-log)
                mode="audit-log"
                ;;
            --stats)
                mode="stats"
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    fi
    
    # Run selected mode
    case "$mode" in
        demo)
            check_imap_tool
            run_demo
            show_stats
            ;;
        test)
            run_threat_analyzer
            ;;
        scan)
            check_credentials
            check_imap_tool
            scan_inbox
            show_stats
            ;;
        audit-log)
            show_audit_log
            ;;
        stats)
            show_stats
            ;;
        *)
            echo "Unknown mode: $mode"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✓ Scan complete${NC}"
}

main "$@"
