#!/bin/bash
###############################################################################
# Test Gmail IMAP Connection
# Validates email credentials and IMAP connectivity
###############################################################################

set -euo pipefail

# Source environment
source ~/.openclaw/.env

# Configuration
GMAIL_USER="${GMAIL_USER:-}"
GMAIL_APP_PASSWORD="${GMAIL_APP_PASSWORD:-}"
IMAP_SERVER="imap.gmail.com"
IMAP_PORT="993"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  📧 GMAIL IMAP CONNECTION TEST                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Validate credentials
echo -e "${YELLOW}1. Checking credentials...${NC}"
if [[ -z "$GMAIL_USER" ]]; then
    echo -e "${RED}❌ ERROR: GMAIL_USER not set in ~/.openclaw/.env${NC}"
    exit 1
fi

if [[ -z "$GMAIL_APP_PASSWORD" ]]; then
    echo -e "${RED}❌ ERROR: GMAIL_APP_PASSWORD not set in ~/.openclaw/.env${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Credentials found${NC}"
echo "  Email: $GMAIL_USER"
echo "  Password: $(echo $GMAIL_APP_PASSWORD | sed 's/./*/g')"
echo ""

# Check for required tools
echo -e "${YELLOW}2. Checking for IMAP tools...${NC}"

if command -v openssl &> /dev/null; then
    echo -e "${GREEN}✓ openssl found${NC}"
    USE_OPENSSL=true
else
    echo -e "${RED}✗ openssl not found${NC}"
    USE_OPENSSL=false
fi

if command -v fetchmail &> /dev/null; then
    echo -e "${GREEN}✓ fetchmail found${NC}"
    USE_FETCHMAIL=true
else
    echo -e "${YELLOW}⚠ fetchmail not found (optional)${NC}"
    USE_FETCHMAIL=false
fi

echo ""

# Test IMAP connection
echo -e "${YELLOW}3. Testing IMAP connection...${NC}"
echo "  Server: $IMAP_SERVER:$IMAP_PORT"
echo ""

if [[ "$USE_OPENSSL" == "true" ]]; then
    # Test with openssl
    echo -e "${BLUE}Attempting OpenSSL connection...${NC}"
    
    IMAP_TEST=$(timeout 5 openssl s_client -connect $IMAP_SERVER:$IMAP_PORT -quiet 2>&1 <<EOF
LOGIN $GMAIL_USER $GMAIL_APP_PASSWORD
LOGOUT
EOF
)
    
    if echo "$IMAP_TEST" | grep -q "OK"; then
        echo -e "${GREEN}✓ IMAP connection successful${NC}"
        echo ""
        echo -e "${YELLOW}4. Testing email retrieval...${NC}"
        
        # Try to get mailbox status with fetchmail if available
        if [[ "$USE_FETCHMAIL" == "true" ]]; then
            echo -e "${BLUE}Checking inbox with fetchmail...${NC}"
            
            FETCH_RESULT=$(timeout 10 fetchmail -s $IMAP_SERVER -u $GMAIL_USER \
                --password "$GMAIL_APP_PASSWORD" \
                --ssl -k -t 10 -e 0 -c 2>&1 | head -20)
            
            if echo "$FETCH_RESULT" | grep -q "mail"; then
                echo -e "${GREEN}✓ Fetchmail can access inbox${NC}"
                echo "$FETCH_RESULT" | head -5
            else
                echo -e "${YELLOW}⚠ Fetchmail response:${NC}"
                echo "$FETCH_RESULT" | head -5
            fi
        fi
        
    else
        echo -e "${RED}✗ IMAP login failed${NC}"
        echo "Response: $IMAP_TEST"
        exit 1
    fi
else
    echo -e "${RED}✗ Cannot test: openssl not found${NC}"
    echo ""
    echo -e "${YELLOW}Install with:${NC}"
    echo "  sudo apt-get install openssl"
    exit 1
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✅ CONNECTION TEST COMPLETE                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Status: Gmail account is accessible${NC}"
echo ""
echo "Next steps:"
echo "  1. Run threat scanner: bash ~/scripts/scan-email-manual.sh --demo"
echo "  2. Read docs: cat docs/EMAIL-SECURITY-SETUP.md"
echo "  3. Set up fetchmail for automated scanning (optional)"
echo ""
