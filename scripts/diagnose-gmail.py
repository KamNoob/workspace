#!/usr/bin/env python3
"""
Deep diagnosis of Gmail IMAP issues
"""

import imaplib
import os
import socket
import ssl

gmail_user = os.getenv('GMAIL_USER')
gmail_pass = os.getenv('GMAIL_APP_PASSWORD')

print("=" * 70)
print("🔍 GMAIL IMAP DIAGNOSTIC REPORT")
print("=" * 70)
print()

print("1️⃣  CONFIGURATION CHECK")
print("-" * 70)
print(f"Email: {gmail_user}")
print(f"Password length: {len(gmail_pass) if gmail_pass else 'N/A'}")
print(f"Password format: {gmail_pass if gmail_pass else 'N/A'}")
print()

print("2️⃣  NETWORK CONNECTIVITY")
print("-" * 70)
try:
    # Test DNS resolution
    ip = socket.gethostbyname('imap.gmail.com')
    print(f"✓ DNS resolved: imap.gmail.com → {ip}")
    
    # Test port connectivity
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    result = sock.connect_ex(('imap.gmail.com', 993))
    if result == 0:
        print(f"✓ Port 993 (SSL/TLS) is open")
    else:
        print(f"✗ Port 993 unreachable")
    sock.close()
except Exception as e:
    print(f"✗ Network error: {e}")

print()

print("3️⃣  SSL/TLS CONNECTION")
print("-" * 70)
try:
    context = ssl.create_default_context()
    with socket.create_connection(('imap.gmail.com', 993)) as sock:
        with context.wrap_socket(sock, server_hostname='imap.gmail.com') as ssock:
            cert = ssock.getpeercert()
            print(f"✓ SSL handshake successful")
            print(f"  Cert Subject: {dict(x[0] for x in cert['subject'])}")
except Exception as e:
    print(f"✗ SSL error: {e}")

print()

print("4️⃣  IMAP CAPABILITY CHECK")
print("-" * 70)
try:
    mail = imaplib.IMAP4_SSL('imap.gmail.com', 993)
    status, capabilities = mail.capability()
    print(f"✓ Connected (pre-auth)")
    print(f"  Capabilities: {capabilities[0].decode() if capabilities else 'N/A'}")
    mail.close()
except Exception as e:
    print(f"✗ Pre-auth error: {e}")

print()

print("5️⃣  AUTHENTICATION ATTEMPT")
print("-" * 70)
try:
    mail = imaplib.IMAP4_SSL('imap.gmail.com', 993)
    
    # Try login
    print(f"Attempting login...")
    print(f"  User: {gmail_user}")
    print(f"  Pass: {gmail_pass}")
    
    mail.login(gmail_user, gmail_pass)
    print(f"✓ LOGIN SUCCESSFUL")
    
    # Get mailbox info
    status, count = mail.select('INBOX')
    print(f"✓ INBOX: {count[0]} messages")
    
    mail.logout()
    
except imaplib.IMAP4.error as e:
    print(f"✗ IMAP Error: {e}")
    print()
    print("ANALYSIS:")
    error_str = str(e)
    
    if "Application-specific password required" in error_str:
        print("  The error says 'Application-specific password required'")
        print()
        print("  This typically means:")
        print("  1. App password wasn't created/generated properly")
        print("  2. 2FA wasn't actually enabled when app password was created")
        print("  3. The account needs more time to propagate (~24 hours)")
        print("  4. The app password has expired or been revoked")
        print()
        print("  NEXT STEPS:")
        print("  A) Go to: https://myaccount.google.com/apppasswords")
        print("  B) Verify 2FA is shown as 'ON' (check security settings first)")
        print("  C) Delete the current app password")
        print("  D) Create a BRAND NEW app password")
        print("  E) Copy it exactly (spaces or dashes as shown)")
        print("  F) Try again")
        
    elif "Invalid credentials" in error_str:
        print("  Password/username are incorrect")
        print("  Double-check the app password format")
        
    elif "AUTHENTICATIONFAILED" in error_str:
        print("  Authentication failed - check credentials")

except Exception as e:
    print(f"✗ Connection error: {e}")

print()
print("=" * 70)
