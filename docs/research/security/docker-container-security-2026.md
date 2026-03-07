# Docker & Container Security Best Practices (2026)

**Domain:** Security / Infrastructure  
**Created:** 2026-03-07  
**Status:** Active  
**Refresh Cycle:** 60 days (next: 2026-05-06)  
**Confidence:** High  

---

## Executive Summary

Container security is non-negotiable in modern DevOps. Key priorities: minimal base images, vulnerability scanning in CI/CD, runtime security, and least-privilege access. Image scanning alone reduces production vulnerabilities by 70-80%.

---

## Core Security Principles

### 1. Image Security (Build-Time)

**Use Minimal Base Images:**
- Alpine Linux (~5MB) or distroless images (Google)
- Chainguard Images (zero-CVE hardened base images)
- Avoid full OS images (Ubuntu, Debian) unless necessary

**Pin Images by Digest (not tag):**
```dockerfile
# ❌ Bad: Tags are mutable
FROM node:18-alpine

# ✅ Good: Digest is immutable
FROM node:18-alpine@sha256:abc123...
```

**Scan All Images in CI/CD:**
- Tools: Trivy, Grype, Snyk, Sonatype Lifecycle, Checkmarx
- Block builds with HIGH/CRITICAL vulnerabilities
- Scan base images immediately after pulling

### 2. Runtime Security

**Run as Non-Root User:**
```dockerfile
# Create non-root user
RUN addgroup -g 1001 appuser && \
    adduser -D -u 1001 -G appuser appuser

USER appuser
```

**Read-Only Root Filesystem:**
```yaml
# Docker Compose
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

**Drop Capabilities:**
```bash
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp
```

**Resource Limits:**
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

### 3. Network Security

**Isolate Containers:**
- Use custom bridge networks (not default bridge)
- Segment microservices by trust boundary
- Deny inter-container traffic by default

**Encrypt Traffic:**
- TLS for all external communication
- mTLS for service-to-service (Istio, Linkerd)

**Firewall Rules:**
- Only expose necessary ports
- Use host firewalls (iptables, nftables)

### 4. Secrets Management

**Never Hardcode Secrets:**
```dockerfile
# ❌ Bad
ENV API_KEY=abc123

# ✅ Good
# Use Docker secrets or external vault
```

**Tools:**
- Docker Secrets (Swarm)
- Kubernetes Secrets (with encryption at rest)
- HashiCorp Vault
- AWS Secrets Manager, Azure Key Vault

### 5. Access Control

**Principle of Least Privilege:**
- IAM roles for cloud containers (ECS, EKS, Cloud Run)
- Service accounts with minimal permissions
- RBAC for Kubernetes

**Audit Logging:**
- Log all container access attempts
- Monitor for privilege escalation
- Alert on anomalous behavior

---

## Vulnerability Scanning Tools

| Tool | Type | Strengths | Cost |
|------|------|-----------|------|
| **Trivy** | Open-source | Fast, accurate, CVE + misconfig detection | Free |
| **Grype** | Open-source | Anchore-backed, SBOM support | Free |
| **Snyk** | Commercial | Developer-friendly, fix recommendations | Freemium |
| **Checkmarx** | Commercial | Enterprise-grade, compliance reports | Paid |
| **Sonatype Lifecycle** | Commercial | Supply chain security, policy engine | Paid |
| **Docker Scout** | Built-in | Native Docker integration | Freemium |

**Recommendation:** Trivy or Grype for CI/CD (free, fast), Snyk or Sonatype for enterprise compliance.

---

## CI/CD Integration

### Example: GitHub Actions with Trivy

```yaml
name: Container Security Scan

on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .
      
      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          severity: 'HIGH,CRITICAL'
          exit-code: 1  # Fail build on vulnerabilities
      
      - name: Upload results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: trivy-results.sarif
```

---

## Runtime Protection

### AppArmor / SELinux Profiles

**AppArmor (Ubuntu/Debian):**
```bash
docker run --security-opt apparmor=docker-default myapp
```

**SELinux (RHEL/CentOS):**
```bash
docker run --security-opt label=level:s0:c100,c200 myapp
```

### Seccomp Profiles

**Default Seccomp (recommended):**
```bash
docker run --security-opt seccomp=/path/to/profile.json myapp
```

**Custom Profile (restrict syscalls):**
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {"names": ["read", "write", "exit"], "action": "SCMP_ACT_ALLOW"}
  ]
}
```

---

## Common Vulnerabilities (2026)

### CVE-2026-28400: Docker Model Runner Flag Injection
- **Impact:** Arbitrary command execution in Docker Desktop 4.61.x
- **Fixed:** Docker Desktop 4.62.0 (Feb 2026)
- **Mitigation:** Upgrade immediately

### Supply Chain Attacks
- **Vector:** Malicious base images from public registries
- **Mitigation:** Use verified/official images only, scan with Trivy/Grype

### Container Escape
- **Vector:** Kernel vulnerabilities (e.g., dirty pipe, dirty cow)
- **Mitigation:** Keep host kernel updated, use user namespaces

---

## Security Checklist (Priority Order)

### Critical (Do First)
- [ ] Use minimal base images (Alpine, distroless, Chainguard)
- [ ] Scan all images in CI/CD (Trivy/Grype)
- [ ] Run containers as non-root
- [ ] Pin images by digest (not tag)
- [ ] Never hardcode secrets (use vault)

### High Priority
- [ ] Read-only root filesystem
- [ ] Drop all capabilities, add only needed ones
- [ ] Resource limits (CPU, memory)
- [ ] Network isolation (custom bridge networks)
- [ ] Enable audit logging

### Medium Priority
- [ ] AppArmor/SELinux profiles
- [ ] Seccomp profiles (custom)
- [ ] mTLS for service-to-service
- [ ] Regular image updates (automated)
- [ ] SBOM generation for compliance

---

## Compliance Standards

**CIS Docker Benchmark:**
- 100+ security controls for Docker deployments
- Covers host, daemon, images, containers, runtime

**NIST SP 800-190:**
- Application Container Security Guide
- Lifecycle security (build → deploy → runtime)

**PCI-DSS, HIPAA, SOC 2:**
- Require container scanning, access control, encryption

---

## Monitoring & Detection

**Runtime Security Tools:**
- **Falco** — Kubernetes threat detection (CNCF)
- **Sysdig Secure** — Commercial runtime protection
- **Aqua Security** — Enterprise container security platform

**Metrics to Monitor:**
- Container start/stop events
- Privilege escalation attempts
- Unusual network connections
- High CPU/memory usage (crypto-mining)

---

## Best Practices Summary

1. **Shift Left:** Scan early in CI/CD, not just production
2. **Minimal Attack Surface:** Use distroless or Alpine images
3. **Least Privilege:** Non-root, dropped capabilities, read-only FS
4. **Zero Trust:** Assume compromise, isolate everything
5. **Automate:** Scanning, updates, compliance checks

---

## Tools & Resources

**Scanners:**
- Trivy: https://github.com/aquasecurity/trivy
- Grype: https://github.com/anchore/grype
- Docker Scout: https://docs.docker.com/scout/

**Base Images:**
- Alpine: https://hub.docker.com/_/alpine
- Distroless: https://github.com/GoogleContainerTools/distroless
- Chainguard: https://www.chainguard.dev/

**Benchmarks:**
- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker
- NIST SP 800-190: https://csrc.nist.gov/publications/detail/sp/800-190/final

---

## Tags

docker, containers, security, vulnerability-scanning, trivy, grype, alpine, distroless, least-privilege, runtime-security, image-security, ci-cd-security, seccomp, apparmor, selinux

---

**Sources:** Xcitium, Checkmarx, Sonatype, ZeonEdge, Docker Docs (2025-2026)  
**Verified:** 2026-03-07  
**Next Refresh:** 2026-05-06 (60 days)
