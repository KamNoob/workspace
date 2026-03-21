# PHASE 12B-i: RLVR Implementation Kanban

**Status:** APPROVED (2026-03-21 19:20 UTC)  
**Start Date:** Monday 2026-03-24  
**Go-Live Date:** Wednesday 2026-03-26  
**Owner:** Codex (implementation), QA (testing), Chronicle (docs), Sentinel (deploy)

---

## Epic: RLVR Core Implementation

### Backlog → In Progress → Done

#### Sprint 1: Core Scripts (Mon-Tue 2026-03-24 to 2026-03-25)

**Task 1.1: rlvr-calculator.jl [IN PROGRESS]**
- [ ] Create: `scripts/ml/rlvr-calculator.jl`
- [ ] Implement: `calculate_verifiable_reward()` function
  - [ ] Base reward (success/failure)
  - [ ] Latency penalty (0 to -0.15)
  - [ ] Cost penalty (0 to -0.10)
  - [ ] Quality bonus (0 to +0.15)
  - [ ] Final reward clamped [0, 1]
- [ ] Implement: `check_sla_constraints()` function
  - [ ] latency_p50_meets_sla
  - [ ] success_rate_meets_sla
  - [ ] cost_meets_sla
  - [ ] quality_meets_sla
  - [ ] overall_sla_compliant
- [ ] Tests: Unit tests (10+ test cases)
  - [ ] Test edge cases (penalty/bonus boundaries)
  - [ ] Test constraint violations
  - [ ] Test reward clamping
- **Effort:** 2-3 hours | **Status:** TODO | **Owner:** Codex

**Task 1.2: rlvr-verifier.jl [BLOCKED on 1.1]**
- [ ] Create: `scripts/ml/rlvr-verifier.jl`
- [ ] Implement: `generate_daily_verification_report()` function
  - [ ] Read audit logs (task outcomes)
  - [ ] Aggregate by agent + task type
  - [ ] Calculate daily metrics (success rate, latency percentiles, cost, quality)
  - [ ] Check constraints for each metric
  - [ ] Generate report JSON
- [ ] Implement: `detect_violations()` function
  - [ ] Find agents with SLA breaches
  - [ ] Recommend actions (freeze Q? investigate?)
- [ ] Logging: Create `reward_verification` event records
  - [ ] Include constraint check results
  - [ ] Include action recommended
- [ ] Tests: Integration tests (3-5 test cases)
  - [ ] Test report generation
  - [ ] Test violation detection
  - [ ] Test event logging
- **Effort:** 1.5-2 hours | **Status:** TODO | **Owner:** Codex

**Task 1.3: spawner-matrix-rlvr.jl [BLOCKED on 1.1 + 1.2]**
- [ ] Modify: `scripts/ml/spawner-matrix.jl`
- [ ] Add: `verify_and_update_q()` function wrapper
  - [ ] Call `check_sla_constraints()` before Q-update
  - [ ] If constraints OK: allow Q-update
  - [ ] If constraints violated: freeze Q, log alert
  - [ ] Return success/failure status
- [ ] Integration: Call from task outcome handler
  - [ ] ~10 lines modification
  - [ ] Zero breaking changes
- [ ] Logging: Append `reward_verification` event on every outcome
- [ ] Tests: Integration tests (5-10 test cases)
  - [ ] Test Q-update allowed (constraints OK)
  - [ ] Test Q-update blocked (constraints violated)
  - [ ] Test event logging
  - [ ] Test backward compatibility (Phase 7A still works)
- **Effort:** 1-1.5 hours | **Status:** TODO | **Owner:** Codex

**Task 1.4: rlvr-auditor.jl [BLOCKED on 1.2]**
- [ ] Create: `scripts/ml/rlvr-auditor.jl`
- [ ] Implement: `generate_compliance_report()` function
  - [ ] Read `reward_verification` events
  - [ ] Aggregate by time period (daily, weekly, monthly)
  - [ ] Calculate compliance % per agent
  - [ ] Generate audit report (JSON)
- [ ] Implement: `generate_sla_dashboard()` function
  - [ ] SLA compliance status per agent
  - [ ] Trend graphs (compliance over time)
  - [ ] Violations summary
- [ ] Logging: Save reports to `data/audit-reports/`
  - [ ] Daily: `2026-03-21-rlvr-daily.json`
  - [ ] Weekly: `2026-03-21-rlvr-weekly.json`
  - [ ] Monthly: `2026-03-rlvr-monthly.json`
- [ ] Tests: Report generation tests (3-5 test cases)
  - [ ] Test daily report
  - [ ] Test weekly report
  - [ ] Test compliance % calculation
- **Effort:** 1-1.5 hours | **Status:** TODO | **Owner:** Codex

#### Sprint 2: Testing & Validation (Tue 2026-03-25)

**Task 2.1: Unit Test Suite [BLOCKED on Sprint 1]**
- [ ] Create: `test/test-rlvr.jl`
- [ ] Reward calculation tests (10 test cases)
  - [ ] Success case
  - [ ] Failure case
  - [ ] Penalty boundaries
  - [ ] Bonus boundaries
  - [ ] Clamping [0, 1]
- [ ] Constraint checking tests (8 test cases)
  - [ ] All constraints met
  - [ ] Single constraint violated
  - [ ] Multiple constraints violated
  - [ ] Edge cases (exactly at threshold)
- [ ] Run: `julia test/test-rlvr.jl`
- [ ] Target: 18/18 tests pass
- **Effort:** 1 hour | **Status:** TODO | **Owner:** QA

**Task 2.2: Integration Tests [BLOCKED on Sprint 1]**
- [ ] Create: `test/test-rlvr-integration.jl`
- [ ] Spawner integration tests (5 test cases)
  - [ ] Q-update allowed (SLA OK)
  - [ ] Q-update blocked (SLA violated)
  - [ ] Event logging (reward_verification)
  - [ ] Backward compatibility (Phase 7A works)
  - [ ] Audit trail written correctly
- [ ] End-to-end test (1 test case)
  - [ ] Task spawn → outcome → verification → Q-update → audit log
  - [ ] Verify full pipeline
- [ ] Run: `julia test/test-rlvr-integration.jl`
- [ ] Target: 6/6 tests pass
- **Effort:** 1.5 hours | **Status:** TODO | **Owner:** QA

**Task 2.3: Scaling Simulation Test [BLOCKED on Sprint 1]**
- [ ] Create: `test/test-rlvr-scaling.jl`
- [ ] Simulate Phase 12A scenario:
  - [ ] Start: 11 agents, 9 task types
  - [ ] Run: 100 task outcomes
  - [ ] Check: RLVR overhead (latency, log growth)
  - [ ] Check: Constraint violations detected early
- [ ] Metrics:
  - [ ] Verification latency < 10ms per outcome
  - [ ] Audit log growth < 50KB
  - [ ] Violations detected within 1 outcome
- [ ] Run: `julia test/test-rlvr-scaling.jl`
- [ ] Target: All metrics within thresholds
- **Effort:** 1 hour | **Status:** TODO | **Owner:** Codex + QA

**Task 2.4: Regression Test Suite [BLOCKED on Sprint 1]**
- [ ] Verify Phase 7A/7B/8A/11A/11B still work:
  - [ ] Phase 7A: Q-learning still updates correctly
  - [ ] Phase 7B: Insights generator still runs
  - [ ] Phase 8A: Drift detector still alerts
  - [ ] Phase 11A: Audit logs still write
  - [ ] Phase 11B: SLA calculator still works
- [ ] Run: Full system test (all subsystems)
- [ ] Target: Zero regressions
- **Effort:** 1 hour | **Status:** TODO | **Owner:** Veritas

#### Sprint 3: Documentation & Deployment (Tue-Wed 2026-03-25 to 2026-03-26)

**Task 3.1: Operations Runbook [BLOCKED on Sprint 2]**
- [ ] Create: `docs/RLVR_OPERATIONS.md`
- [ ] Contents:
  - [ ] Daily verification report (how to read)
  - [ ] Alert procedures (when to escalate)
  - [ ] Q-freeze/unfreeze procedures (when & how)
  - [ ] Escalation matrix (who to call)
  - [ ] Rollback procedures (disable RLVR in 15 min)
  - [ ] Troubleshooting (common issues)
- [ ] Owner: Chronicle
- **Effort:** 1 hour | **Status:** TODO | **Owner:** Chronicle

**Task 3.2: Cron Job Setup [BLOCKED on Sprint 1]**
- [ ] Create daily verification cron job (02:00 UTC)
  - [ ] Run `rlvr-verifier.jl`
  - [ ] Generate daily report
  - [ ] Log results
  - [ ] Alert if violations
- [ ] Create daily auditor cron job (03:00 UTC)
  - [ ] Run `rlvr-auditor.jl`
  - [ ] Generate compliance report
  - [ ] Save to `data/audit-reports/`
- [ ] Commands:
  ```bash
  # Cron entries
  0 2 * * * cd /path/to/workspace && julia scripts/ml/rlvr-verifier.jl >> logs/rlvr-verifier.log 2>&1
  0 3 * * * cd /path/to/workspace && julia scripts/ml/rlvr-auditor.jl >> logs/rlvr-auditor.log 2>&1
  ```
- [ ] Owner: Sentinel
- **Effort:** 30 min | **Status:** TODO | **Owner:** Sentinel

**Task 3.3: Code Review & Merge [BLOCKED on Sprint 2]**
- [ ] Codex submits PR: `feature/phase12b-rlvr-core`
  - [ ] 4 scripts + tests + docs
  - [ ] ~830 lines new code
  - [ ] Full commit history
- [ ] Veritas reviews:
  - [ ] Code quality (Julia style guide)
  - [ ] Test coverage
  - [ ] Security (no secrets in logs?)
  - [ ] Backward compatibility
- [ ] Veritas approves or requests changes
- [ ] Merge to main
- **Effort:** 1 hour review | **Status:** TODO | **Owner:** Veritas

**Task 3.4: Production Deployment [BLOCKED on 3.3]**
- [ ] Sentinel deploys:
  - [ ] Copy scripts to production `/scripts/ml/`
  - [ ] Update spawner-matrix.jl (swap version)
  - [ ] Set up cron jobs (Task 3.2)
  - [ ] Verify audit logs writing
- [ ] Smoke test:
  - [ ] Spawn a task
  - [ ] Verify task_spawn event logged
  - [ ] Verify task_outcome logged
  - [ ] Verify reward_verification event logged
  - [ ] Verify Q-update occurred (or blocked if SLA)
- [ ] Cutover time: 19:00 UTC Wed 2026-03-26
- **Effort:** 1 hour | **Status:** TODO | **Owner:** Sentinel

---

## Post-Deployment Monitoring (Thu-Fri 2026-03-27 to 2026-03-28)

**Daily Checks:**
- [ ] Review daily RLVR verification report
- [ ] Check for constraint violations
- [ ] Monitor Phase 12A agent scaling (5 agents + RLVR)
- [ ] Alert if Q-freeze triggered (investigate why)
- [ ] Verify cron jobs ran successfully

**Refinement Work:**
- [ ] If SLA thresholds too strict: loosen slightly
- [ ] If violations cascading: check for root cause
- [ ] If RLVR overhead noticeable: optimize
- [ ] Update thresholds based on real data

**Sign-Off Criteria:**
- ✅ Zero regressions in Phase 7A/7B/8A/11A/11B
- ✅ All constraint checks working correctly
- ✅ Audit trail immutable + complete
- ✅ Cron jobs running on schedule
- ✅ Phase 12A scaling protected (no SLA breaches missed)

---

## Risk Tracking

| Risk | Mitigation | Status |
|------|-----------|--------|
| Implementation overruns (8-10h vs. 6-8h estimate) | Buffer built in (started with realistic estimate) | OK |
| Q-learning stagnates (SLA too strict) | Start with warning-only, escalate after validation | TBD |
| Audit log size explodes | Rotate logs daily, compress weekly | PENDING |
| RLVR verification becomes bottleneck | Run async after outcome logged | PENDING |
| Constraint violations cascade | Per-agent isolation in Q-freeze logic | DESIGN PHASE |

---

## Dependency Chain

```
Sprint 1 (Scripts) [4 tasks]
    ↓
    ├→ Task 1.1: rlvr-calculator.jl
    ├→ Task 1.2: rlvr-verifier.jl (blocks on 1.1)
    ├→ Task 1.3: spawner-matrix-rlvr.jl (blocks on 1.1 + 1.2)
    ├→ Task 1.4: rlvr-auditor.jl (blocks on 1.2)
    ↓
Sprint 2 (Testing) [4 tasks]
    ├→ Task 2.1: Unit tests (blocks on Sprint 1)
    ├→ Task 2.2: Integration tests (blocks on Sprint 1)
    ├→ Task 2.3: Scaling tests (blocks on Sprint 1)
    ├→ Task 2.4: Regression tests (blocks on Sprint 1)
    ↓
Sprint 3 (Deploy) [4 tasks]
    ├→ Task 3.1: Runbook (blocks on Sprint 2)
    ├→ Task 3.2: Cron setup (blocks on Sprint 1)
    ├→ Task 3.3: Code review (blocks on Sprint 2)
    ├→ Task 3.4: Production deploy (blocks on 3.3)
    ↓
GO-LIVE: Wed 2026-03-26 (critical path: ~8-10 hours)
```

---

## Success Metrics

**Code Quality:**
- ✅ 830 lines new code
- ✅ 18+ unit tests pass
- ✅ 6+ integration tests pass
- ✅ Zero linting issues

**Performance:**
- ✅ Verification latency < 10ms per outcome
- ✅ Audit log growth < 50KB/day
- ✅ Cron jobs complete in < 1 minute

**Operational:**
- ✅ All constraint checks working
- ✅ Audit trail immutable + queryable
- ✅ Alerts trigger on SLA violations
- ✅ Q-learning gates functioning

**Business:**
- ✅ Phase 12A protected (scaling monitored)
- ✅ Zero regressions in existing systems
- ✅ Compliance-ready audit trail
- ✅ 2026 research trends addressed

---

## Communication Plan

**Status Updates:**
- Daily EOD (Thu-Fri 2026-03-27 to 2026-03-28): RLVR status to Art
- Post-deployment: Monitor & refine (3-5 days)
- Weekly review: Integration with Phase 12A outcomes

**Escalation:**
- If implementation blocked: Notify Art immediately
- If testing fails: Debug + re-plan
- If deployment issues: Rollback to pre-RLVR in 15 min

---

_Kanban created: 2026-03-21 19:20 UTC_  
_Status: READY FOR IMPLEMENTATION_  
_Next: Codex starts Mon 2026-03-24_
