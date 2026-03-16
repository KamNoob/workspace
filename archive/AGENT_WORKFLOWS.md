# Agent → Workflow Mapping

**Last Updated:** 2026-03-13 16:59 GMT  
**Phase:** 2b (Full team utilization)

---

## Overview

All 11 agents now have task routing paths. This document maps agents to workflows and shows utilization status.

---

## Agent Assignment by Workflow

### 🔧 **code-review-qp.sh** ✅ UPDATED
Routes: Codex, QA, Prism (+ Veritas on high complexity)

| Complexity | Agents Routed | Q-Score | Status |
|---|---|---|---|
| low | Codex | 0.68 | ✅ Established |
| medium | Codex, QA, Prism | 0.69, 0.69, 0.50 | ✅ QA active, Prism NEW |
| high | Codex, QA, Prism, Veritas | 0.68, 0.69, 0.50, 0.50 | ✅ Multi-agent review |

**Impact:** Prism now has task routing (was 0 uses → active path)

---

### 📊 **analysis-qp.sh** ✅ NEW WORKFLOW
Routes: Lens (primary) + Scout + Veritas/Chronicle

| Scope | Agents Routed | Q-Score | Status |
|---|---|---|---|
| quick | Lens | 0.50 | 🆕 NEW workflow |
| standard | Lens, Scout, Veritas | 0.50, 0.80, 0.50 | 🆕 Lens activation |
| deep | Lens, Scout, Chronicle, Veritas | 0.50, 0.80, 0.69, 0.50 | 🆕 Full analysis team |

**Impact:** Lens gets exclusive primary role (was 0 uses → domain expert)

---

### 💡 **brainstorm-qp.sh** ✅ NEW WORKFLOW
Routes: Echo (primary) + Scout + Codex/Chronicle

| Depth | Agents Routed | Q-Score | Status |
|---|---|---|---|
| quick | Echo | 0.50 | 🆕 NEW workflow |
| standard | Echo, Scout, Codex | 0.50, 0.80, 0.68 | 🆕 Echo activation |
| deep | Echo, Scout, Codex, Chronicle | 0.50, 0.80, 0.68, 0.69 | 🆕 Full creative team |

**Impact:** Echo debuts as brainstorming specialist (was 0 uses → creative lead)

---

### 📚 **code-learning-qp.sh** ✅ UPDATED
Routes: Codex, Echo, Lens (+ Chronicle on deep)

| Depth | Agents Routed | Q-Score | Status |
|---|---|---|---|
| light | Codex | 0.68 | ✅ Unchanged |
| standard | Codex, Echo, Lens | 0.68, 0.50, 0.50 | ✅ Lens added |
| deep | Codex, Echo, Lens, Chronicle | 0.68, 0.50, 0.50, 0.69 | ✅ Expanded team |

**Impact:** Lens now included for performance analysis during learning

---

### 🔍 **research-qp.sh**
Routes: Scout (primary) + Veritas + Chronicle

| Depth | Agents Routed | Q-Score | Status |
|---|---|---|---|
| quick | Scout | 0.80 | ✅ Active |
| standard | Scout, Veritas | 0.80, 0.80 | ✅ Established |
| deep | Scout, Chronicle, Veritas | 0.80, 0.69, 0.80 | ✅ Full team |

**No change** (already optimized)

---

### 🛡️ **security-audit-qp.sh**
Routes: Cipher (primary) + Veritas + Sentinel (full scope)

| Scope | Agents Routed | Q-Score | Status |
|---|---|---|---|
| quick | Cipher | 0.55 | ✅ Active |
| standard | Cipher, Veritas | 0.55, 0.50 | ✅ Established |
| full | Cipher, Sentinel, Veritas | 0.55, 0.55, 0.50 | ✅ Infrastructure included |

**No change** (already includes Sentinel)

---

### ⚙️ **infrastructure-planning-qp.sh**
Routes: Sentinel (primary)

| Complexity | Agents Routed | Q-Score | Status |
|---|---|---|---|
| quick | Sentinel | 0.55 | ✅ Active |
| standard | Sentinel, Cipher | 0.55, 0.50 | ✅ Security advisory |
| complex | Sentinel, Cipher, Scout | 0.55, 0.50, 0.80 | ✅ Full planning |

**No change** (already established)

---

### 📋 **planning-qp.sh**
Routes: Navigator (primary)

| Scope | Agents Routed | Q-Score | Status |
|---|---|---|---|
| All | Navigator | 0.92 | ✅ Active |

**No change** (Navigator firmly established)

---

## Agent Utilization Before/After

### Before (2026-03-13 16:57 GMT)

| Agent | Task Type | Q-Score | Uses | Status |
|---|---|---|---|---|
| Morpheus | — | — | — | 🎯 Orchestrator (no direct tasks) |
| Navigator | planning | 0.92 | ~8 | ✅ Active |
| Codex | code | 0.68 | 7 | ✅ Active |
| QA | code | 0.69 | 7 | ✅ Active |
| **Prism** | — | 0.50 | **0** | ❌ **NO ROUTING** |
| Scout | research | 0.80 | 12 | ✅ Active |
| Veritas | research, review | 0.80 | 12+ | ✅ Active |
| Chronicle | research, docs | 0.69 | 7 | ✅ Active |
| Cipher | security | 0.55 | 2 | ✅ Active |
| Sentinel | infrastructure | 0.55 | 2 | ✅ Active |
| **Echo** | — | 0.50 | **0** | ❌ **NO ROUTING** |
| **Lens** | — | 0.50 | **0** | ❌ **NO ROUTING** |

### After (2026-03-13 16:59 GMT)

| Agent | Task Type | Q-Score | Uses | Status |
|---|---|---|---|---|
| Morpheus | — | — | — | 🎯 Orchestrator |
| Navigator | planning | 0.92 | ~8 | ✅ Active |
| Codex | code, learning | 0.68 | 7 | ✅ Active |
| QA | code | 0.69 | 7 | ✅ **Now routed** |
| **Prism** | code (mobile/responsive) | 0.50 | 0 → routed | ✅ **ACTIVATED** |
| Scout | research, brainstorm, analysis | 0.80 | 12+ | ✅ Active |
| Veritas | research, review, security, analysis | 0.80 | 12+ | ✅ Active |
| Chronicle | research, docs, learning, brainstorm | 0.69 | 7+ | ✅ Active |
| Cipher | security | 0.55 | 2 | ✅ Active |
| Sentinel | infrastructure, security | 0.55 | 2 | ✅ Active |
| **Echo** | learning, brainstorming | 0.50 | 0 → routed | ✅ **ACTIVATED** |
| **Lens** | code-learning, analysis | 0.50 | 0 → routed | ✅ **ACTIVATED** |

---

## What Changed

### ✅ Prism (Mobile/Responsive Testing)
- **Was:** No workflows, Q-score 0.50 (default), 0 uses
- **Now:** Routed in code-review-qp.sh (medium/high complexity)
- **First test:** Run `./scripts/workflows/code-review-qp.sh "test feature" medium`

### ✅ Echo (Creative Ideation)
- **Was:** No workflows, Q-score 0.50, 0 uses
- **Now:** Primary agent in new brainstorm-qp.sh workflow
- **First test:** Run `./scripts/workflows/brainstorm-qp.sh "improve API latency"`

### ✅ Lens (Performance Analysis)
- **Was:** No workflows, Q-score 0.50, 0 uses
- **Now:** Primary in new analysis-qp.sh; secondary in code-learning-qp.sh
- **First test:** Run `./scripts/workflows/analysis-qp.sh "database query performance"`

### ✅ code-review-qp.sh
- **Before:** Codex only (hardcoded AGENT="Codex")
- **Now:** Routes Codex + QA + Prism based on complexity
- **Impact:** QA + Prism now get code review opportunities

### ✅ code-learning-qp.sh
- **Before:** Codex + Echo + Chronicle
- **Now:** Includes Lens for performance/analysis on standard/deep
- **Impact:** Learning sessions now include perf analysis

---

## Testing & Validation

### Quick Verification (All 8 Workflows Active)

```bash
cd /home/art/.openclaw/workspace

# Test new workflows
./scripts/workflows/analysis-qp.sh "memory usage patterns" standard
./scripts/workflows/brainstorm-qp.sh "optimize caching strategy" standard

# Test updated workflows
./scripts/workflows/code-review-qp.sh "feature X" medium
./scripts/workflows/code-learning-qp.sh "web servers" standard

# Test existing workflows
./scripts/workflows/research-qp.sh "compare databases" standard
./scripts/workflows/security-audit-qp.sh "API endpoints" standard
```

### Phase 2b Data Collection

- **New workflows:** analysis-qp.sh, brainstorm-qp.sh will generate outcomes
- **Updated workflows:** code-review-qp.sh, code-learning-qp.sh will route to Prism, Lens, Echo
- **Goal:** Collect real Q-learning data for Phase 2b.1 retraining (target: 50+ outcomes by mid-April)
- **Cron status:** Friday 09:00 weekly test runs active (every Friday executes 2 workflows)

---

## Next Steps

1. **Run first tests** — Execute one test from each workflow type
2. **Monitor Q-scores** — Check `data/rl/rl-agent-selection.json` for new agents after runs
3. **Log outcomes** — Each workflow prints outcome logging command at end
4. **Update MEMORY.md** — Document when first Prism/Echo/Lens outcomes are captured
5. **Phase 2b retraining** — After 50+ total outcomes collected, retrain all Q-values

---

_Workflow unification complete. All 11 agents now have active task routing._
