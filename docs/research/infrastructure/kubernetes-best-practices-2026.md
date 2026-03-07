# Kubernetes Production Best Practices (2026)

**Domain:** Infrastructure / DevOps  
**Created:** 2026-03-07  
**Status:** Active  
**Refresh Cycle:** 60 days (next: 2026-05-06)  
**Confidence:** High  

---

## Executive Summary

Production Kubernetes requires: RBAC with least privilege, Pod Security Standards, network policies, encrypted etcd, audit logging, and OIDC authentication. Key principle: assume breach, defense in depth.

---

## Core Security Controls

### 1. RBAC (Role-Based Access Control)

**Principle: Least Privilege**
- Grant minimum permissions needed
- Use Roles (namespace-scoped) over ClusterRoles when possible
- Avoid `cluster-admin` for workloads

**Example: Read-Only Role**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

**Example: Service Account Binding**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Best Practices:**
- Use service accounts for pods (not default)
- Avoid wildcard permissions (`*`)
- Audit RBAC regularly (`kubectl auth can-i`)
- Integrate with OIDC for human users (not static tokens)

### 2. Pod Security Standards (PSS)

**Three Levels:**
1. **Privileged** — Unrestricted (admin workloads only)
2. **Baseline** — Minimally restrictive (block known privilege escalations)
3. **Restricted** — Hardened (non-root, no host access, read-only FS)

**Enforcement Modes:**
- **enforce** — Reject violating pods
- **audit** — Log violations
- **warn** — Warn on violations

**Example: Namespace-Level Enforcement**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**Restricted Profile Requirements:**
- Must run as non-root (`runAsNonRoot: true`)
- Drop all capabilities
- No host network/IPC/PID
- Read-only root filesystem
- SeccompProfile: RuntimeDefault or Localhost

### 3. Network Policies

**Default Deny All Traffic:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Allow Specific Traffic:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

**Best Practices:**
- Start with default-deny-all
- Whitelist only required connections
- Use namespace selectors for multi-tenant clusters
- Test with `kubectl exec` before enforcing

### 4. Secrets Management

**Never Store Secrets in ConfigMaps or Code**

**Kubernetes Secrets (Baseline):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  username: admin
  password: changeme  # Base64-encoded at rest
```

**Encrypt Secrets at Rest (etcd):**
```yaml
# /etc/kubernetes/enc/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: <base64-encoded-32-byte-key>
    - identity: {}
```

**External Secrets Operators (Recommended):**
- **HashiCorp Vault** + Vault Secrets Operator
- **AWS Secrets Manager** + External Secrets Operator (ESO)
- **Azure Key Vault** + Secrets Store CSI Driver
- **Google Secret Manager** + Workload Identity

**Example: External Secrets Operator**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  secretStoreRef:
    name: aws-secretsmanager
  target:
    name: db-credentials
  data:
  - secretKey: password
    remoteRef:
      key: prod/db/password
```

### 5. Authentication & Authorization

**OIDC Integration (Recommended for Humans):**
```yaml
# API server flags
--oidc-issuer-url=https://accounts.google.com
--oidc-client-id=kubernetes
--oidc-username-claim=email
--oidc-groups-claim=groups
```

**Benefits:**
- Short-lived tokens (no static kubeconfig)
- Centralized user management
- MFA enforcement
- Audit trail

**Tools:**
- Dex (OIDC provider)
- Keycloak (identity management)
- Pinniped (OIDC for kubectl)

### 6. API Server Security

**Production Checklist:**
- [ ] Restrict API server access to trusted networks (private VPC)
- [ ] Enable audit logging
- [ ] Disable anonymous auth (`--anonymous-auth=false`)
- [ ] Enable NodeRestriction admission plugin
- [ ] Set admission control policies (PodSecurity, ResourceQuota, LimitRanger)

**Audit Policy Example:**
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]
- level: Metadata
  omitStages:
  - RequestReceived
```

### 7. etcd Security

**Critical: etcd = Cluster Brain**

**Encryption at Rest:**
```bash
# Generate encryption key
head -c 32 /dev/urandom | base64

# Apply encryption config (see Section 4)
```

**Network Isolation:**
- Only API server should access etcd
- Use TLS for etcd client-server communication
- Use mTLS for etcd peer communication

**Backup Strategy:**
```bash
# Automated daily backups
ETCDCTL_API=3 etcdctl snapshot save backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

---

## Production Deployment Best Practices

### 1. Resource Management

**Always Set Requests & Limits:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:v1
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
```

**Why:**
- Prevents resource starvation
- Enables proper scheduling
- Triggers horizontal pod autoscaling (HPA)

### 2. Health Checks

**Liveness & Readiness Probes:**
```yaml
spec:
  containers:
  - name: app
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

**Startup Probes (for slow-starting apps):**
```yaml
spec:
  containers:
  - name: app
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
```

### 3. High Availability

**Pod Disruption Budgets (PDB):**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

**Multiple Replicas:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```

**Anti-Affinity (spread across nodes):**
```yaml
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - myapp
        topologyKey: kubernetes.io/hostname
```

### 4. Image Management

**Use Specific Tags (not `latest`):**
```yaml
# ❌ Bad
image: myapp:latest

# ✅ Good
image: myapp:v1.2.3
```

**Image Pull Policies:**
```yaml
spec:
  containers:
  - name: app
    image: myapp:v1.2.3
    imagePullPolicy: IfNotPresent  # or Always for :latest
```

**Private Registries:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: regcred
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
---
spec:
  imagePullSecrets:
  - name: regcred
```

### 5. Monitoring & Observability

**Tools:**
- **Prometheus** — Metrics collection
- **Grafana** — Visualization
- **Jaeger/Tempo** — Distributed tracing
- **Loki** — Log aggregation

**Key Metrics:**
- Pod CPU/memory usage
- Request latency (p50, p95, p99)
- Error rates (4xx, 5xx)
- Pod restart count

**Alerts:**
- High memory usage (>80%)
- High CPU usage (>80%)
- CrashLoopBackOff pods
- Pending pods (cannot schedule)

---

## Security Checklist (Production)

### Critical (Must Have)
- [ ] RBAC enabled, least-privilege policies
- [ ] Pod Security Standards enforced (baseline or restricted)
- [ ] Network policies (default-deny)
- [ ] Secrets encrypted at rest (etcd encryption)
- [ ] API server access restricted (private network)
- [ ] Audit logging enabled
- [ ] Resource requests/limits on all pods

### High Priority
- [ ] OIDC authentication for human users
- [ ] Service accounts with minimal RBAC
- [ ] External secrets operator (Vault, AWS, Azure, GCP)
- [ ] etcd backups automated (daily)
- [ ] Node security (CIS benchmarks, kernel hardening)
- [ ] Image scanning in CI/CD (Trivy, Grype)

### Medium Priority
- [ ] Pod Disruption Budgets (PDB)
- [ ] Anti-affinity rules (HA)
- [ ] Horizontal Pod Autoscaler (HPA)
- [ ] Vertical Pod Autoscaler (VPA)
- [ ] Service mesh (Istio, Linkerd) for mTLS
- [ ] Runtime security (Falco, Tetragon)

---

## Common Pitfalls

### 1. Running as Root
**Problem:** Default pod user = root  
**Fix:** Set `securityContext.runAsNonRoot: true`

### 2. No Resource Limits
**Problem:** Pod can consume all node resources  
**Fix:** Set requests/limits, use LimitRanges

### 3. Overly Permissive RBAC
**Problem:** `cluster-admin` for all service accounts  
**Fix:** Audit with `kubectl auth can-i --list`, reduce permissions

### 4. Secrets in ConfigMaps
**Problem:** Plain-text secrets visible in etcd  
**Fix:** Use Secrets with encryption, or external vaults

### 5. No Network Policies
**Problem:** Any pod can talk to any pod  
**Fix:** Default-deny-all + explicit allow rules

---

## Tools & Resources

**Security Scanners:**
- **Kubescape** — Kubernetes security posture (CNCF)
- **Kube-bench** — CIS Kubernetes Benchmark
- **Popeye** — Cluster sanitizer

**Secrets Management:**
- External Secrets Operator: https://external-secrets.io/
- Vault Secrets Operator: https://developer.hashicorp.com/vault/docs/platform/k8s
- Sealed Secrets: https://sealed-secrets.netlify.app/

**Policy Enforcement:**
- OPA Gatekeeper: https://open-policy-agent.github.io/gatekeeper/
- Kyverno: https://kyverno.io/

**Monitoring:**
- Prometheus Operator: https://prometheus-operator.dev/
- Grafana: https://grafana.com/
- Loki: https://grafana.com/oss/loki/

---

## Compliance Standards

**CIS Kubernetes Benchmark:**
- 100+ controls for control plane, nodes, policies

**NSA/CISA Kubernetes Hardening Guide:**
- Pod security, network policies, audit logging, supply chain security

**NIST SP 800-190:**
- Container security (applies to K8s)

---

## Tags

kubernetes, k8s, production, security, RBAC, pod-security-standards, network-policies, etcd-encryption, secrets-management, high-availability, monitoring, devops, infrastructure

---

**Sources:** Portainer, Kubernetes.io, Reddit r/kubernetes, SentinelOne, OWASP (2026)  
**Verified:** 2026-03-07  
**Next Refresh:** 2026-05-06 (60 days)
