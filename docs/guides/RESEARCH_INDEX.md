# Research Index — Searchable Catalog

**Purpose:** Master inventory of all research documents. Check this FIRST before spawning research tasks.

**Last Updated:** 2026-03-07 19:57 GMT

---

## Active Research

### Technology / AI/ML

#### Dynamic Neural Architectures (2026)
- **File:** `docs/research/technology/dynamic-neural-architectures-2026.md`
- **Status:** Pending Verification
- **Created:** 2026-03-06
- **Tags:** neural-networks, transformers, mamba, mixture-of-experts, state-space-models, hybrid-architectures
- **Summary:** Comprehensive analysis of most dynamic neural architectures for general use (Hybrid Transformer-Mamba, MoE, pure Mamba). Includes decision matrix and practical recommendations.
- **Refresh:** 30 days (next: 2026-04-05)
- **Confidence:** High
- **Sources:** ArXiv (2024-2026), NVIDIA, Industry Publications

#### AI Persistent Memory Systems (2026)
- **File:** `docs/research/technology/ai-persistent-memory-systems-2026.md`
- **Status:** Active
- **Created:** 2026-03-06
- **Tags:** ai-memory, persistent-memory, semantic-memory, episodic-memory, procedural-memory, mem0, zep, synapse, vector-database, embeddings
- **Summary:** Comprehensive analysis of persistent memory methods for AI assistants. Covers three-layer architecture (semantic/episodic/procedural), leading systems (Mem0, SYNAPSE, Zep, MemSync, Redis), implementation patterns, and recommendation for Morpheus (hybrid Markdown + local embeddings + SQLite episodic indexing).
- **Refresh:** 30 days (next: 2026-04-05)
- **Confidence:** High
- **Sources:** IBM, Mem0, ArXiv, Redis, DEV Community, Medium (2024-2026)

---

### Security

#### Docker & Container Security (2026)
- **File:** `docs/research/security/docker-container-security-2026.md`
- **Status:** Active
- **Created:** 2026-03-07
- **Tags:** docker, containers, security, vulnerability-scanning, trivy, grype, alpine, distroless, least-privilege, runtime-security, image-security, ci-cd-security
- **Summary:** Container security best practices (2026): minimal base images (Alpine, distroless), vulnerability scanning (Trivy, Grype) in CI/CD, runtime security (non-root, read-only FS, capability dropping), network isolation, secrets management. Includes CVE-2026-28400 (Docker Model Runner) mitigation and CIS Docker Benchmark compliance.
- **Refresh:** 60 days (next: 2026-05-06)
- **Confidence:** High
- **Sources:** Xcitium, Checkmarx, Sonatype, ZeonEdge, Docker Docs (2025-2026)

#### Zero Trust Security Model (2026)
- **File:** `docs/research/security/zero-trust-security-model-2026.md`
- **Status:** Active
- **Created:** 2026-03-07
- **Tags:** zero-trust, security-architecture, NIST, identity, MFA, SSO, ZTNA, microsegmentation, least-privilege, continuous-verification, EDR, SIEM, UEBA
- **Summary:** Zero Trust framework ("never trust, always verify"): NIST 7 pillars (Identity, Devices, Network, Applications, Data, Infrastructure, Visibility/Analytics), implementation roadmap (12-18 months), vendor comparison (Zscaler, Cloudflare, Palo Alto, Okta), maturity model (Level 0-3), compliance mapping (NIST SP 800-207, ISO 27001, PCI-DSS). Cost analysis by company size.
- **Refresh:** 90 days (next: 2026-06-05)
- **Confidence:** High
- **Sources:** U.S. DoD, Trevonix, NIST NCCoE, Gray Group Intl, Cyberhaven (2025-2026)

---

### Infrastructure / DevOps

#### Kubernetes Production Best Practices (2026)
- **File:** `docs/research/infrastructure/kubernetes-best-practices-2026.md`
- **Status:** Active
- **Created:** 2026-03-07
- **Tags:** kubernetes, k8s, production, security, RBAC, pod-security-standards, network-policies, etcd-encryption, secrets-management, high-availability, monitoring
- **Summary:** Production Kubernetes security and operations: RBAC with least privilege, Pod Security Standards (Restricted profile), network policies (default-deny), etcd encryption, OIDC authentication, external secrets operators (Vault, AWS, Azure), resource management (requests/limits), health probes, high availability (PDB, anti-affinity), monitoring (Prometheus, Grafana). Includes compliance (CIS Kubernetes Benchmark, NSA/CISA Hardening Guide).
- **Refresh:** 60 days (next: 2026-05-06)
- **Confidence:** High
- **Sources:** Portainer, Kubernetes.io, Reddit r/kubernetes, SentinelOne, OWASP (2026)

#### CI/CD Pipeline Best Practices (2026)
- **File:** `docs/research/infrastructure/cicd-pipeline-best-practices-2026.md`
- **Status:** Active
- **Created:** 2026-03-07
- **Tags:** CI/CD, DevOps, GitHub-Actions, Jenkins, security, OIDC, secrets-management, automated-testing, canary-deployment, blue-green, feature-flags, SLSA, SBOM, Trivy, CodeQL
- **Summary:** Modern CI/CD (2026): everything-as-code, shift-left security (SAST, dependency audit, container scanning), OIDC for secrets (no static keys), automated testing with quality gates, progressive delivery (canary, blue-green, feature flags), DORA metrics (Elite: multiple deploys/day, <1h lead time). GitHub Actions dominates, includes full production pipeline YAML example.
- **Refresh:** 60 days (next: 2026-05-06)
- **Confidence:** High
- **Sources:** Calmops, Cybersecurity For Me, Refonte Learning, Medium (Krishna Fattepurkar), Master Software Testing (2026)

---

### Data

#### Database Performance Optimization (2026)
- **File:** `docs/research/data/database-performance-optimization-2026.md`
- **Status:** Active
- **Created:** 2026-03-07
- **Tags:** database, performance, optimization, PostgreSQL, MySQL, indexing, query-optimization, EXPLAIN, connection-pooling, pgbouncer, proxysql, vacuum, pg_stat_statements
- **Summary:** Database optimization best practices: indexing strategy (B-tree, GIN, BRIN, covering indexes), query analysis (EXPLAIN ANALYZE, EXPLAIN FORMAT=TREE), query rewriting (avoid SELECT *, use EXISTS not IN, keyset pagination), connection pooling (PgBouncer, ProxySQL), VACUUM (PostgreSQL), configuration tuning (shared_buffers, innodb_buffer_pool_size). PostgreSQL 17: 88x faster bulk loads. Includes pg_stat_statements and Performance Schema (MySQL) for monitoring.
- **Refresh:** 90 days (next: 2026-06-05)
- **Confidence:** High
- **Sources:** Rapydo, OneUpTime, Medium (DevBoost Lab), MOGE (2025-2026)

---

## Research Domains

Current coverage:
- **Technology/AI/ML:** 2 entries
- **Security:** 2 entries
- **Infrastructure/DevOps:** 2 entries
- **Data:** 1 entry
- **Business:** 0 entries
- **Total:** 7 entries

---

## Quick Search Tags

**Neural Networks:** dynamic-neural-architectures-2026  
**Transformers:** dynamic-neural-architectures-2026  
**Mamba/SSM:** dynamic-neural-architectures-2026  
**MoE:** dynamic-neural-architectures-2026  
**Hybrid Architectures:** dynamic-neural-architectures-2026  
**AI Memory:** ai-persistent-memory-systems-2026  
**Persistent Memory:** ai-persistent-memory-systems-2026  
**Semantic Memory:** ai-persistent-memory-systems-2026  
**Episodic Memory:** ai-persistent-memory-systems-2026  
**Procedural Memory:** ai-persistent-memory-systems-2026  
**Mem0:** ai-persistent-memory-systems-2026  
**Vector Database:** ai-persistent-memory-systems-2026  
**Embeddings:** ai-persistent-memory-systems-2026  

**Docker:** docker-container-security-2026  
**Container Security:** docker-container-security-2026  
**Trivy:** docker-container-security-2026  
**Zero Trust:** zero-trust-security-model-2026  
**NIST Zero Trust:** zero-trust-security-model-2026  
**ZTNA:** zero-trust-security-model-2026  
**Kubernetes:** kubernetes-best-practices-2026  
**K8s:** kubernetes-best-practices-2026  
**RBAC:** kubernetes-best-practices-2026  
**CI/CD:** cicd-pipeline-best-practices-2026  
**GitHub Actions:** cicd-pipeline-best-practices-2026  
**Canary Deployment:** cicd-pipeline-best-practices-2026  
**Database Performance:** database-performance-optimization-2026  
**PostgreSQL:** database-performance-optimization-2026  
**MySQL:** database-performance-optimization-2026  
**Indexing:** database-performance-optimization-2026  

---

## Retrieval Protocol

1. **Check this index FIRST** before spawning Scout
2. If topic exists → Read existing research
3. If outdated (past refresh cycle) → Update via Scout
4. If missing → Create new research entry

**Storage:** All research files → `docs/research/{domain}/{topic}-{year}.md`
