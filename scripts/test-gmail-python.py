#!/usr/bin/env python3
"""Test Gmail IMAP Connection"""

import imaplib
import sys
import os

# Load credentials
gmail_user = os.getenv('GMAIL_USER')
gmail_pass = os.getenv('GMAIL_APP_PASSWORD')

print("=" * 60)
print("📧 GMAIL IMAP CONNECTION TEST (Python)")
print("=" * 60)
print()

if not gmail_user or not gmail_pass:
    print("❌ ERROR: Credentials not found in environment")
    print("   Set GMAIL_USER and GMAIL_APP_PASSWORD in ~/.openclaw/.env")
    sys.exit(1)

print(f"Email: {gmail_user}")
print(f"Password: {'*' * len(gmail_pass)}")
print()

print("Attempting connection to imap.gmail.com:993...")
print()

try:
    # Connect to Gmail IMAP
    mail = imaplib.IMAP4_SSL('imap.gmail.com', 993)
    print("✓ SSL connection established")
    
    # Login
    mail.login(gmail_user, gmail_pass)
    print("✓ Login successful")
    
    # List mailboxes
    status, mailboxes = mail.list()
    print(f"✓ Mailbox list retrieved ({len(mailboxes)} folders)")
    
    # Select inbox
    status, count = mail.select('INBOX')
    print(f"✓ INBOX selected")
    print(f"  Messages in inbox: {count[0]}")
    
    # Logout
    mail.logout()
    print()
    print("=" * 60)
    print("✅ CONNECTION SUCCESSFUL")
    print("=" * 60)
    print()
    print("Gmail account is fully accessible!")
    print()
    print("Next: Test the scanner")
    print("  bash ~/scripts/scan-email-manual.sh --demo")
    
except imaplib.IMAP4.error as e:
    print(f"❌ IMAP Error: {e}")
    print()
    print("Possible causes:")
    print("  1. Account not verified (check recovery email)")
    print("  2. 2FA not enabled")
    print("  3. IMAP not enabled in Gmail settings")
    print("  4. App password incorrect")
    print("  5. Account not fully set up yet")
    print()
    print("See: bash ~/scripts/verify-email-setup.sh")
    sys.exit(1)
    
except Exception as e:
    print(f"❌ Connection Error: {e}")
    sys.exit(1)
