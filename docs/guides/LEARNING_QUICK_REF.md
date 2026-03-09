# Learning System Quick Reference — Morpheus

**For use during task execution**

---

## After Every Agent Task

```bash
scripts/log-task-outcome.sh <task_type> <agent> <success> <quality> <time>
```

**Task types:** research | code | security | infrastructure | analysis | documentation

**Example:**
```bash
scripts/log-task-outcome.sh research Scout true 0.9 8.5
```

---

## After Every Workflow

```bash
scripts/log-workflow.sh "<flow_name>" <success> <time> "<notes>"
```

**Common workflows:**
- Chain_A_Knowledge_Pipeline
- Chain_B_Code_Development  
- Chain_D_Research_Implementation
- Direct_No_Agent

**Example:**
```bash
scripts/log-workflow.sh "Chain_A_Knowledge_Pipeline" true 5.2 "research completed"
```

---

## Quality Scoring

| Score | Meaning |
|-------|---------|
| 0.9-1.0 | Excellent |
| 0.7-0.9 | Good |
| 0.5-0.7 | Acceptable |
| 0.3-0.5 | Poor |
| 0.0-0.3 | Failed |

---

## Check Q-Learning Status

```bash
scripts/update-q-scores.sh  # Manual trigger
cat workflow-analysis-report.md  # View workflow rankings
```

---

**Every 5 task outcomes:** Q-scores update automatically  
**Every 10 workflows:** Analysis runs automatically
