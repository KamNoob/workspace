# CI/CD Pipeline Best Practices (2026)

**Domain:** Infrastructure / DevOps  
**Created:** 2026-03-07  
**Status:** Active  
**Refresh Cycle:** 60 days (next: 2026-05-06)  
**Confidence:** High  

---

## Executive Summary

Modern CI/CD in 2026: everything-as-code, security scanning at every stage, OIDC for secrets (no static keys), automated testing with quality gates, canary deployments. GitHub Actions dominates, Jenkins still used in enterprises.

---

## Core Principles

### 1. Everything as Code
- **Pipelines:** YAML/Groovy (not UI clicks)
- **Infrastructure:** Terraform, Pulumi, CloudFormation
- **Configuration:** Ansible, Chef, Puppet
- **Benefits:** Version control, reproducibility, code review

### 2. Shift-Left Security
- **Scan early:** Commit stage, not production
- **Tools:** SAST, dependency audit, container scanning, IaC scanning
- **Fail fast:** Block builds with HIGH/CRITICAL vulnerabilities

### 3. Automated Testing
- **Unit tests:** 80%+ coverage
- **Integration tests:** API contracts, database interactions
- **E2E tests:** Critical user flows only (slow, flaky)
- **Performance tests:** Load testing in staging

### 4. Zero Trust Secrets
- **OIDC:** Short-lived tokens, no static keys
- **Vaults:** HashiCorp Vault, AWS Secrets Manager, Azure Key Vault
- **Rotation:** Automate secret rotation
- **Audit:** Log all secret access

### 5. Progressive Delivery
- **Canary:** 5% → 25% → 100% traffic
- **Blue-Green:** Instant rollback capability
- **Feature Flags:** Decouple deployment from release
- **Rollback:** Automated revert on failure

---

## Modern CI/CD Pipeline Architecture

### Ideal Flow (GitHub Actions Example)

```yaml
name: Production Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Stage 1: Lint & Code Quality
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run linters
        run: |
          npm run lint
          npm run prettier-check
      
      - name: SonarQube scan
        uses: sonarsource/sonarcloud-github-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  
  # Stage 2: Security Scans
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # Dependency scanning
      - name: Audit dependencies
        run: npm audit --audit-level=high
      
      # SAST (Static Application Security Testing)
      - name: CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          languages: javascript,typescript
          queries: security-extended
      
      # Secret scanning
      - name: Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  
  # Stage 3: Unit & Integration Tests
  test:
    runs-on: ubuntu-latest
    needs: [lint, security]
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: npm run test:unit -- --coverage
      
      - name: Run integration tests
        run: npm run test:integration
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          fail_ci_if_error: true
  
  # Stage 4: Build & Container Scan
  build:
    runs-on: ubuntu-latest
    needs: test
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Trivy vulnerability scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          severity: 'CRITICAL,HIGH'
          exit-code: 1  # Fail if vulnerabilities found
  
  # Stage 5: Deploy to Staging
  deploy-staging:
    runs-on: ubuntu-latest
    needs: build
    environment: staging
    steps:
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
          aws-region: us-east-1
      
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster staging-cluster \
            --service myapp \
            --force-new-deployment
      
      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster staging-cluster \
            --services myapp
  
  # Stage 6: E2E Tests (Staging)
  e2e-tests:
    runs-on: ubuntu-latest
    needs: deploy-staging
    steps:
      - uses: actions/checkout@v4
      
      - name: Run E2E tests
        run: npm run test:e2e
        env:
          TEST_URL: https://staging.example.com
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: e2e-results
          path: test-results/
  
  # Stage 7: Deploy to Production (Canary)
  deploy-production:
    runs-on: ubuntu-latest
    needs: e2e-tests
    environment: production
    steps:
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActions-Prod
          aws-region: us-east-1
      
      - name: Canary deployment (5%)
        run: |
          # Deploy with traffic split: 5% new, 95% old
          aws ecs update-service \
            --cluster prod-cluster \
            --service myapp-canary \
            --force-new-deployment
          
          # Monitor for 10 minutes
          sleep 600
          
          # Check error rate
          ERROR_RATE=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/ApplicationELB \
            --metric-name HTTPCode_Target_5XX_Count \
            --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
            --period 600 \
            --statistics Sum \
            | jq '.Datapoints[0].Sum')
          
          if [ "$ERROR_RATE" -gt 10 ]; then
            echo "Error rate too high, rolling back"
            exit 1
          fi
      
      - name: Full production rollout
        run: |
          # Promote canary to 100%
          aws ecs update-service \
            --cluster prod-cluster \
            --service myapp \
            --force-new-deployment
```

---

## Security Best Practices

### 1. OIDC Authentication (No Static Keys)

**GitHub Actions → AWS:**
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
    aws-region: us-east-1
    # No access keys needed!
```

**AWS IAM Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
        "token.actions.githubusercontent.com:sub": "repo:myorg/myrepo:ref:refs/heads/main"
      }
    }
  }]
}
```

**Benefits:**
- ✅ No static credentials in secrets
- ✅ Short-lived tokens (1 hour max)
- ✅ Automatic rotation
- ✅ Audit trail via CloudTrail

### 2. Secrets Management

**HashiCorp Vault Integration:**
```yaml
- name: Fetch secrets from Vault
  uses: hashicorp/vault-action@v2
  with:
    url: https://vault.example.com
    role: github-actions
    method: jwt
    secrets: |
      secret/data/db password | DB_PASSWORD ;
      secret/data/api key | API_KEY
```

**Vault Policy:**
```hcl
path "secret/data/db" {
  capabilities = ["read"]
}
```

### 3. Supply Chain Security

**SLSA (Supply-chain Levels for Software Artifacts):**
```yaml
- name: Generate SLSA provenance
  uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v1.9.0
  with:
    artifacts: dist/
```

**SBOM Generation:**
```yaml
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    format: cyclonedx-json
    output-file: sbom.json
```

**Sign Artifacts:**
```yaml
- name: Sign with Cosign
  uses: sigstore/cosign-installer@v3
  
- name: Sign container image
  run: |
    cosign sign --yes ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

### 4. Branch Protection & Code Review

**GitHub Branch Protection Rules:**
- ✅ Require pull request reviews (2+ approvers)
- ✅ Require status checks (all CI jobs pass)
- ✅ Require up-to-date branches
- ✅ Require signed commits
- ✅ Restrict force pushes
- ✅ Require linear history

---

## Testing Strategy

### Test Pyramid (2026)

```
           ╱ E2E Tests ╲            10%  (slow, brittle)
          ╱─────────────╲
         ╱ Integration  ╲           20%  (medium)
        ╱───────────────╲
       ╱   Unit Tests    ╲          70%  (fast, reliable)
      ╱─────────────────╲
```

### Quality Gates

**SonarQube Quality Gate:**
```yaml
- name: SonarQube Quality Gate
  run: |
    STATUS=$(curl -s -u ${{ secrets.SONAR_TOKEN }}: \
      "https://sonarcloud.io/api/qualitygates/project_status?projectKey=myapp" \
      | jq -r '.projectStatus.status')
    
    if [ "$STATUS" != "OK" ]; then
      echo "Quality gate failed"
      exit 1
    fi
```

**Code Coverage Threshold:**
```yaml
- name: Check coverage
  run: |
    COVERAGE=$(jq '.total.lines.pct' coverage/coverage-summary.json)
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "Coverage below 80%: $COVERAGE%"
      exit 1
    fi
```

---

## Deployment Strategies

### 1. Canary Deployment

**Gradual Rollout:**
```
Phase 1: Deploy to 5% of traffic (10 min)
Phase 2: Monitor error rate, latency, CPU
Phase 3: If healthy → 25% traffic (10 min)
Phase 4: If healthy → 50% traffic (10 min)
Phase 5: If healthy → 100% traffic
If unhealthy at any stage → Rollback
```

**Automated Rollback:**
```yaml
- name: Canary health check
  run: |
    ERROR_RATE=$(check_error_rate)
    LATENCY_P95=$(check_latency_p95)
    
    if [ "$ERROR_RATE" -gt 5 ] || [ "$LATENCY_P95" -gt 1000 ]; then
      echo "Canary unhealthy, rolling back"
      rollback_deployment
      exit 1
    fi
```

### 2. Blue-Green Deployment

**Zero-Downtime Switch:**
```yaml
- name: Deploy to green environment
  run: deploy_to_green
  
- name: Run smoke tests
  run: test_green_environment
  
- name: Switch traffic (ALB target group)
  run: |
    aws elbv2 modify-listener \
      --listener-arn $LISTENER_ARN \
      --default-actions \
        Type=forward,TargetGroupArn=$GREEN_TG_ARN
  
- name: Monitor for 5 minutes
  run: sleep 300 && check_metrics
  
- name: Rollback if needed
  if: failure()
  run: |
    aws elbv2 modify-listener \
      --listener-arn $LISTENER_ARN \
      --default-actions \
        Type=forward,TargetGroupArn=$BLUE_TG_ARN
```

### 3. Feature Flags

**LaunchDarkly / Unleash:**
```javascript
// App code
const showNewUI = await featureFlags.isEnabled('new-ui', user);

if (showNewUI) {
  return <NewUI />;
} else {
  return <OldUI />;
}
```

**Benefits:**
- Deploy code without activating features
- Test in production with limited users
- Instant rollback (flag toggle, no redeploy)

---

## Tools Comparison (2026)

| Tool | Pros | Cons | Best For |
|------|------|------|----------|
| **GitHub Actions** | Native GitHub integration, free for public repos, huge marketplace | Limited self-hosted runner features | Open-source, GitHub-hosted projects |
| **GitLab CI** | Built-in, excellent Kubernetes integration, Auto DevOps | Complex configuration for advanced workflows | GitLab-hosted projects |
| **Jenkins** | Mature, highly customizable, thousands of plugins | Legacy UI, high maintenance, resource-heavy | Enterprises with existing Jenkins |
| **CircleCI** | Fast, great Docker support, easy config | Expensive for large teams | Docker-heavy workflows |
| **Argo CD** | GitOps-native, Kubernetes-first, declarative | Kubernetes-only | Cloud-native apps on K8s |

**2026 Trend:** GitHub Actions + Argo CD hybrid (CI on GitHub, CD on Argo)

---

## Monitoring & Observability

### Metrics to Track

**Build Metrics:**
- Build success rate (target: >95%)
- Build duration (target: <10 min)
- Test flakiness rate (target: <2%)
- Deployment frequency (DORA metric)

**Deployment Metrics:**
- Lead time for changes (DORA metric)
- Change failure rate (DORA metric)
- Time to restore service (DORA metric)
- Deployment success rate (target: >99%)

**DORA Metrics (Elite Performers, 2026):**
- Deployment frequency: Multiple times per day
- Lead time: <1 hour
- Change failure rate: <5%
- Time to restore: <1 hour

---

## Tags

CI/CD, DevOps, GitHub-Actions, Jenkins, security, OIDC, secrets-management, automated-testing, canary-deployment, blue-green, feature-flags, SLSA, SBOM, Trivy, CodeQL

---

**Sources:** Calmops, Cybersecurity For Me, Refonte Learning, Medium (Krishna Fattepurkar), Master Software Testing (2026)  
**Verified:** 2026-03-07  
**Next Refresh:** 2026-05-06 (60 days)
