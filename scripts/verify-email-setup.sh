#!/bin/bash
###############################################################################
# Email Setup Verification Checklist
# Helps diagnose Gmail account and configuration issues
###############################################################################

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  📧 GMAIL ACCOUNT VERIFICATION CHECKLIST                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Source env
source ~/.openclaw/.env

# Check 1: Account exists
echo "✓ Gmail Account Created: morpheus.phanwises@gmail.com"
echo ""

# Check 2: Verify email
echo "ACTION REQUIRED:"
echo ""
echo "1️⃣  VERIFY EMAIL ADDRESS"
echo "   • Go to: myaccount.google.com"
echo "   • Check your recovery email inbox"
echo "   • Click the verification link from Google"
echo "   • This may take a few minutes to arrive"
echo ""

echo "2️⃣  ENABLE 2-STEP VERIFICATION"
echo "   • Go to: myaccount.google.com/security"
echo "   • Scroll to 'How you sign in to Google'"
echo "   • Click '2-Step Verification'"
echo "   • Select your phone number"
echo "   • Confirm the code Google sends"
echo ""

echo "3️⃣  ENABLE IMAP ACCESS"
echo "   • Go to: myaccount.google.com/apppasswords"
echo "   • (Requires 2FA to be enabled first)"
echo "   • Select: Mail + Linux"
echo "   • Copy the 16-character password"
echo "   • Update in ~/.openclaw/.env:"
echo "     GMAIL_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx"
echo ""

echo "4️⃣  ENABLE IMAP IN GMAIL SETTINGS"
echo "   • Go to: Gmail Settings → Forwarding and POP/IMAP"
echo "   • Under 'IMAP access': Select 'Enable IMAP'"
echo "   • Save changes"
echo ""

echo "5️⃣  VERIFY CURRENT CONFIGURATION"
echo ""
echo "Current Settings:"
echo "  Email: $GMAIL_USER"
echo "  App Password: $(echo $GMAIL_APP_PASSWORD | head -c 5)****$(echo $GMAIL_APP_PASSWORD | tail -c 5)"
echo ""

# Check credentials in env
if grep -q "GMAIL_USER=" ~/.openclaw/.env; then
    echo "✓ GMAIL_USER configured"
else
    echo "✗ GMAIL_USER not in .env"
fi

if grep -q "GMAIL_APP_PASSWORD=" ~/.openclaw/.env; then
    echo "✓ GMAIL_APP_PASSWORD configured"
else
    echo "✗ GMAIL_APP_PASSWORD not in .env"
fi

echo ""
echo "6️⃣  TEST CONNECTION (AFTER COMPLETING ABOVE)"
echo ""
echo "Once all steps above are complete, test with:"
echo "  bash ~/scripts/test-gmail-connection.sh"
echo ""
echo "Or run the scanner:"
echo "  bash ~/scripts/scan-email-manual.sh --demo"
echo ""

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  📋 COMMON ISSUES                                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

echo "Q: Connection times out?"
echo "A: Account may not be fully verified. Check email for verification link."
echo ""

echo "Q: 'Invalid credentials' error?"
echo "A: Make sure you're using the App Password, not your Gmail password."
echo ""

echo "Q: Can't find app password option?"
echo "A: 2-Step Verification must be enabled first."
echo ""

echo "Q: 'IMAP is disabled' error?"
echo "A: Enable IMAP in Gmail Settings → Forwarding and POP/IMAP"
echo ""

echo "Once everything is configured, reply 'test connection' again."
echo ""
