# Zero Trust Security Model & Implementation (2026)

**Domain:** Security / Architecture  
**Created:** 2026-03-07  
**Status:** Active  
**Refresh Cycle:** 90 days (next: 2026-06-05)  
**Confidence:** High  

---

## Executive Summary

Zero Trust = "Never trust, always verify." Assumes breach, verifies every access request. Core principles: continuous verification, least privilege, assume breach, microsegmentation. NIST framework defines 7 pillars: Identity, Devices, Network, Applications, Data, Infrastructure, Visibility/Analytics.

---

## Core Principles

### 1. Never Trust, Always Verify
- No implicit trust based on network location
- Verify every user, device, and request
- Continuous authentication and authorization

### 2. Assume Breach
- Design as if attackers are already inside
- Limit lateral movement
- Microsegmentation of resources

### 3. Least Privilege Access
- Grant minimum permissions needed
- Time-bound access (JIT - Just-In-Time)
- Revoke immediately when no longer needed

### 4. Continuous Monitoring & Verification
- Real-time threat detection
- Behavioral analytics
- Anomaly detection

---

## NIST Zero Trust Architecture (7 Pillars)

### Pillar 1: Identity
**Goal:** Authenticate and authorize all entities (users, services, devices)

**Implementation:**
- **MFA (Multi-Factor Authentication):** Hardware tokens (YubiKey), biometrics, TOTP
- **SSO (Single Sign-On):** Okta, Azure AD, Google Workspace
- **Adaptive Authentication:** Risk-based MFA (location, device, behavior)
- **Passwordless:** FIDO2, passkeys, biometrics

**Tools:**
- Okta, Azure AD, Ping Identity, Duo Security
- FIDO2 authenticators (YubiKey, WebAuthn)

**Example: Azure AD Conditional Access**
```json
{
  "conditions": {
    "users": ["all"],
    "applications": ["office365"],
    "locations": ["untrusted"],
    "devices": ["unmanaged"]
  },
  "controls": {
    "require_mfa": true,
    "require_device_compliance": true
  }
}
```

### Pillar 2: Devices
**Goal:** Ensure all devices meet security baselines

**Implementation:**
- **Device Inventory:** Track all endpoints (BYOD, corporate)
- **Endpoint Security:** EDR (Endpoint Detection & Response)
- **Compliance Checks:** OS version, patching, encryption
- **Device Posture:** Assess before granting access

**Tools:**
- Microsoft Intune, Jamf, VMware Workspace ONE
- CrowdStrike, SentinelOne, Microsoft Defender for Endpoint

**Example: Device Compliance Policy**
```yaml
compliance_requirements:
  - os_version: >= "Windows 11 22H2"
  - bitlocker_enabled: true
  - firewall_enabled: true
  - antivirus_updated: last_24h
  - patch_level: critical_patches_installed
```

### Pillar 3: Network
**Goal:** Segment network, control traffic, verify connections

**Implementation:**
- **Microsegmentation:** Isolate workloads (east-west traffic control)
- **Software-Defined Perimeter (SDP):** VPN replacement
- **Zero Trust Network Access (ZTNA):** Verify before connect
- **Network Policies:** Kubernetes NetworkPolicies, AWS Security Groups

**Tools:**
- Zscaler, Cloudflare Access, Palo Alto Prisma Access
- AWS PrivateLink, Azure Private Link, Google Private Service Connect

**Example: Kubernetes Network Policy (Default Deny)**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Pillar 4: Applications
**Goal:** Secure application access, enforce policies

**Implementation:**
- **App-Level Authentication:** OAuth 2.0, OIDC, SAML
- **API Security:** API gateways, rate limiting, input validation
- **Web Application Firewalls (WAF):** Block OWASP Top 10 attacks
- **Service Mesh:** mTLS between microservices (Istio, Linkerd)

**Tools:**
- Kong, Apigee, AWS API Gateway, Azure API Management
- Cloudflare WAF, AWS WAF, Akamai
- Istio, Linkerd, Consul

**Example: Istio mTLS (Service-to-Service)**
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT  # Require mTLS for all traffic
```

### Pillar 5: Data
**Goal:** Protect data at rest, in transit, and in use

**Implementation:**
- **Encryption:** TLS 1.3, AES-256, at-rest encryption
- **Data Loss Prevention (DLP):** Block sensitive data exfiltration
- **Data Classification:** Public, internal, confidential, restricted
- **Tokenization:** Replace sensitive data with tokens

**Tools:**
- Microsoft Purview, Google DLP, Symantec DLP
- AWS KMS, Azure Key Vault, Google Cloud KMS
- HashiCorp Vault (secrets management)

**Example: DLP Policy (Block SSN Exfiltration)**
```yaml
dlp_rule:
  name: "Block SSN Export"
  pattern: "\\d{3}-\\d{2}-\\d{4}"  # SSN regex
  action: block
  channels: [email, cloud_storage, usb]
  alert: true
```

### Pillar 6: Infrastructure
**Goal:** Secure cloud, on-prem, and hybrid infrastructure

**Implementation:**
- **Infrastructure as Code (IaC):** Terraform, CloudFormation
- **Policy as Code:** OPA (Open Policy Agent), Sentinel
- **Immutable Infrastructure:** Rebuild, don't patch
- **Least-Privilege IAM:** Roles with minimal permissions

**Tools:**
- Terraform, Pulumi, CloudFormation, Ansible
- OPA Gatekeeper, HashiCorp Sentinel
- AWS IAM, Azure RBAC, Google Cloud IAM

**Example: AWS IAM Policy (Least Privilege)**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "s3:GetObject",
      "s3:ListBucket"
    ],
    "Resource": [
      "arn:aws:s3:::my-bucket",
      "arn:aws:s3:::my-bucket/*"
    ],
    "Condition": {
      "IpAddress": {
        "aws:SourceIp": "203.0.113.0/24"
      }
    }
  }]
}
```

### Pillar 7: Visibility & Analytics
**Goal:** Monitor all activity, detect anomalies, respond to threats

**Implementation:**
- **SIEM (Security Information & Event Management):** Centralized logging
- **UEBA (User & Entity Behavior Analytics):** Detect insider threats
- **Threat Intelligence:** Feed from external sources
- **Incident Response:** Automated playbooks (SOAR)

**Tools:**
- Splunk, Elastic Security, Microsoft Sentinel, Sumo Logic
- Exabeam, Varonis (UEBA)
- Palo Alto Cortex XSOAR, Splunk Phantom (SOAR)

**Example: SIEM Alert (Anomalous Login)**
```yaml
alert_rule:
  name: "Impossible Travel"
  trigger:
    - login from IP_A at time T1
    - login from IP_B at time T2
    - distance(IP_A, IP_B) > 500 miles
    - (T2 - T1) < 1 hour
  action: block_session, alert_soc
```

---

## Implementation Roadmap

### Phase 1: Foundation (Months 1-3)
- [ ] Deploy MFA for all users (hardware tokens preferred)
- [ ] Implement SSO (Okta, Azure AD, Google Workspace)
- [ ] Enable logging (SIEM setup: Splunk, Elastic, Sentinel)
- [ ] Inventory all assets (users, devices, applications, data)
- [ ] Define security policies (identity, device, network)

### Phase 2: Network & Device Security (Months 4-6)
- [ ] Deploy EDR on all endpoints (CrowdStrike, SentinelOne)
- [ ] Enforce device compliance (OS version, patching, encryption)
- [ ] Segment network (microsegmentation, VLANs, firewalls)
- [ ] Deploy ZTNA (Zscaler, Cloudflare Access)
- [ ] Replace VPN with SDP (Software-Defined Perimeter)

### Phase 3: Application & Data Protection (Months 7-9)
- [ ] Implement API security (API gateway, rate limiting)
- [ ] Deploy WAF (Cloudflare, AWS WAF)
- [ ] Encrypt all data at rest (KMS, Key Vault)
- [ ] Deploy DLP (Microsoft Purview, Google DLP)
- [ ] Service mesh for microservices (Istio, Linkerd)

### Phase 4: Advanced Analytics & Automation (Months 10-12)
- [ ] Deploy UEBA (Exabeam, Varonis)
- [ ] Integrate threat intelligence feeds
- [ ] Automate incident response (SOAR: Cortex XSOAR, Phantom)
- [ ] Red team exercises (test Zero Trust controls)
- [ ] Continuous improvement (quarterly reviews)

---

## Cost Analysis (by Company Size)

### Small (50-200 employees)
- **Annual Cost:** $50K-150K
- **Tools:** Okta (SSO), Duo (MFA), Cloudflare Access (ZTNA), Microsoft Defender (EDR)
- **Implementation:** 6-9 months

### Medium (200-1000 employees)
- **Annual Cost:** $200K-500K
- **Tools:** Azure AD Premium, CrowdStrike (EDR), Zscaler (ZTNA), Palo Alto Prisma (CASB)
- **Implementation:** 9-12 months

### Large (1000+ employees)
- **Annual Cost:** $1M-5M+
- **Tools:** Full stack (Okta, CrowdStrike, Zscaler, Palo Alto, Splunk)
- **Implementation:** 12-18 months

---

## Zero Trust Maturity Model (NIST)

### Level 0: Traditional (Perimeter-Based)
- Castle-and-moat security
- Implicit trust inside network
- VPN for remote access

### Level 1: Initial (Ad Hoc)
- MFA deployed for some users
- Basic logging and monitoring
- Limited segmentation

### Level 2: Advanced (Coordinated)
- MFA for all users
- Device compliance checks
- Network microsegmentation
- API security implemented

### Level 3: Optimal (Comprehensive)
- Continuous verification
- Automated threat response
- Full microsegmentation
- UEBA and behavioral analytics
- Red team tested

**Goal:** Most organizations aim for Level 2-3 by end of 2026.

---

## Vendor Comparison (2026)

| Vendor | Strength | Weakness | Best For |
|--------|----------|----------|----------|
| **Zscaler** | ZTNA, CASB, DLP | Expensive for small orgs | Large enterprises |
| **Cloudflare Access** | Global network, fast | Limited UEBA | Mid-market |
| **Palo Alto Prisma** | Comprehensive, enterprise | Complex config | Enterprises with in-house team |
| **Okta** | Identity leader, easy SSO | Limited device management | Identity-first orgs |
| **Microsoft** | E5 suite, native Azure | Vendor lock-in | Microsoft-heavy environments |
| **Google BeyondCorp** | Born-in-cloud design | Less mature than Okta/MS | Google Workspace orgs |

---

## Common Pitfalls

### 1. "Rip and Replace" Approach
**Problem:** Trying to deploy everything at once  
**Solution:** Phased rollout (12-18 months for large orgs)

### 2. Forgetting Legacy Systems
**Problem:** Zero Trust assumes modern APIs, OAuth, etc.  
**Solution:** Use identity broker or gateway for legacy apps

### 3. No User Training
**Problem:** MFA/SSO frustrates users → shadow IT  
**Solution:** Training, UX focus, gradual rollout

### 4. Over-Segmentation
**Problem:** Too many firewall rules → operational burden  
**Solution:** Start with coarse segmentation, refine over time

### 5. Ignoring Third-Party Access
**Problem:** Vendors/contractors bypass Zero Trust  
**Solution:** Extend Zero Trust to all external access

---

## Compliance Mapping

### NIST SP 800-207 (Zero Trust Architecture)
- Official U.S. government standard
- 7 pillars framework (detailed above)

### NIST CSF (Cybersecurity Framework)
- Identify → Asset inventory, risk assessment
- Protect → Access control, data security
- Detect → Continuous monitoring, anomaly detection
- Respond → Incident response, forensics
- Recover → Backup, disaster recovery

### ISO 27001
- A.9: Access Control → Zero Trust IAM
- A.13: Communications Security → Encryption, network segmentation
- A.14: System Acquisition → Secure SDLC

### PCI-DSS 4.0
- Requirement 7: Restrict access to cardholder data → Least privilege
- Requirement 8: Identify and authenticate access → MFA, SSO

---

## Success Metrics

### Technical Metrics
- **MFA Adoption:** Target 100%
- **Unmanaged Devices:** Target 0%
- **Lateral Movement (East-West Traffic):** Blocked by microsegmentation
- **Mean Time to Detect (MTTD):** <15 minutes
- **Mean Time to Respond (MTTR):** <1 hour

### Business Metrics
- **Security Incidents:** -50% YoY (after full implementation)
- **Compliance Audit Findings:** -70% YoY
- **Ransomware Resilience:** No successful attacks

---

## Tags

zero-trust, security-architecture, NIST, identity, MFA, SSO, ZTNA, microsegmentation, least-privilege, continuous-verification, assume-breach, EDR, SIEM, UEBA, Okta, Zscaler, Cloudflare, Palo-Alto

---

**Sources:** U.S. DoD, Trevonix, NIST NCCoE, Gray Group Intl, Cyberhaven (2025-2026)  
**Verified:** 2026-03-07  
**Next Refresh:** 2026-06-05 (90 days)
