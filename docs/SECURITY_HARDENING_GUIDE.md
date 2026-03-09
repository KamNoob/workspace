# Security Hardening Guide — Manual Steps Required

**Date:** 2026-03-07  
**Status:** Partially Complete  
**Manual Intervention Required:** UFW installation (sudo password needed)  

---

## Current Security Status

### ✅ Already Secure (No Action Needed)

**Database Port Restrictions:**
- ✅ MySQL bound to 127.0.0.1:3306 (localhost only)
- ✅ PostgreSQL bound to 127.0.0.1:5432 (localhost only)
- ✅ No external database access possible

**Docker Security:**
- ✅ No privileged containers running
- ✅ No containers running as root
- ✅ Docker socket permissions secure (root:docker)

**SSH Security:**
- ✅ Root login disabled (PermitRootLogin no)
- ✅ SSH on standard port 22

---

## ⚠️ Action Required: UFW Firewall Installation

**Status:** Not installed  
**Priority:** 🔴 HIGH  
**Requires:** sudo password  

### Installation Steps (Manual)

```bash
# 1. Install UFW
sudo apt-get update
sudo apt-get install -y ufw

# 2. Configure default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3. Allow SSH (critical - don't lock yourself out!)
sudo ufw allow 22/tcp comment 'SSH'

# 4. Allow OpenClaw Gateway (localhost only)
sudo ufw allow from 127.0.0.1 to any port 18789 comment 'OpenClaw Gateway'

# 5. Allow loopback
sudo ufw allow in on lo

# 6. Review rules before enabling
sudo ufw show added

# 7. Enable UFW (WARNING: Confirm SSH rule is present!)
sudo ufw enable

# 8. Verify status
sudo ufw status verbose
```

### Expected Output

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                   # SSH
18789                      ALLOW IN    127.0.0.1                  # OpenClaw Gateway
Anywhere on lo             ALLOW IN    Anywhere
```

---

## Recommended Additional Steps

### 1. SSH Key Authentication (Optional)

**Current:** Password authentication may be enabled  
**Recommendation:** Set up SSH keys, disable password auth  

```bash
# Generate SSH key (if not already present)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key to authorized_keys
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Edit SSH config to disable password auth
sudo nano /etc/ssh/sshd_config

# Set:
# PasswordAuthentication no
# PubkeyAuthentication yes

# Restart SSH
sudo systemctl restart sshd
```

### 2. Move SSH to Non-Standard Port (Optional)

**Current:** Port 22 (standard, frequently scanned)  
**Recommendation:** Move to port 2222 or similar  

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Change:
# Port 2222

# Update UFW
sudo ufw delete allow 22/tcp
sudo ufw allow 2222/tcp comment 'SSH (non-standard port)'

# Restart SSH
sudo systemctl restart sshd
```

### 3. Docker Image Scanning

**Current:** 6 images, not scanned  
**Recommendation:** Scan with Trivy  

```bash
# Install Trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Scan all images
docker images --format "{{.Repository}}:{{.Tag}}" | xargs -I {} trivy image --severity HIGH,CRITICAL {}
```

### 4. Fail2Ban (Brute Force Protection)

**Recommendation:** Install Fail2Ban for SSH protection  

```bash
# Install
sudo apt-get install fail2ban

# Configure
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

# Enable SSH jail (usually enabled by default)
# [sshd]
# enabled = true
# maxretry = 5
# bantime = 3600

# Start service
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo fail2ban-client status sshd
```

---

## Security Checklist

### Critical (Do Now)
- [ ] **Install UFW firewall** (requires sudo)
- [ ] Enable UFW with SSH rule
- [ ] Verify UFW status (should show active)

### High Priority (This Week)
- [ ] Set up SSH key authentication
- [ ] Disable SSH password authentication
- [ ] Scan Docker images with Trivy
- [ ] Install Fail2Ban

### Medium Priority (This Month)
- [ ] Move SSH to non-standard port
- [ ] Set up automated security updates
- [ ] Configure log monitoring (Logwatch)
- [ ] Review open ports monthly

### Ongoing
- [ ] Keep Docker images updated
- [ ] Review UFW logs weekly
- [ ] Monitor Fail2Ban bans
- [ ] Update OS packages regularly

---

## Verification Commands

```bash
# UFW status
sudo ufw status verbose

# Open ports
ss -tuln | grep LISTEN

# Database bindings
ss -tlnp | grep -E ':(3306|5432)'

# Docker security
docker ps --format "{{.ID}}: User={{.Config.User}}, Privileged={{.HostConfig.Privileged}}"

# SSH config
grep -E "^(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)" /etc/ssh/sshd_config

# Fail2Ban status (if installed)
sudo fail2ban-client status sshd
```

---

## Current Risk Assessment

**Overall Risk Level:** 🟡 MODERATE

**Risks:**
- 🔴 **HIGH:** No firewall (UFW not installed)
- 🟢 **LOW:** Databases already restricted to localhost
- 🟢 **LOW:** SSH root login disabled
- 🟡 **MEDIUM:** Password authentication may be enabled
- 🟡 **MEDIUM:** SSH on standard port (frequent scans)

**Priority:** Install UFW immediately to reduce attack surface.

---

## Tags

security-hardening, ufw, firewall, ssh, database-security, docker-security, fail2ban

---

**Created:** 2026-03-07  
**Status:** UFW installation pending (requires sudo)  
**Next Review:** After UFW installation complete
