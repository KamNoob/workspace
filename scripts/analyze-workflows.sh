#!/bin/bash
# analyze-workflows.sh — Analyze workflow performance and recommend optimizations

set -e

LOG_FILE="$HOME/.openclaw/workspace/workflow-execution-log.jsonl"
REPORT_FILE="$HOME/.openclaw/workspace/workflow-analysis-report.md"

# Use Python for analysis
python3 - <<'PYTHON_SCRIPT'
import json
from collections import defaultdict
from datetime import datetime
from pathlib import Path

# Paths
log_file = Path.home() / ".openclaw/workspace/workflow-execution-log.jsonl"
report_file = Path.home() / ".openclaw/workspace/workflow-analysis-report.md"

# Load workflow outcomes
workflows = []
if log_file.exists():
    with open(log_file) as f:
        for line in f:
            line = line.strip()
            if line and line.startswith('{'):
                workflows.append(json.loads(line))

if not workflows:
    print("No workflow data yet.")
    exit(0)

# Aggregate stats per workflow
stats = defaultdict(lambda: {
    "total": 0,
    "success": 0,
    "failure": 0,
    "total_time": 0.0,
    "times": []
})

for wf in workflows:
    flow = wf["flow_name"]
    stats[flow]["total"] += 1
    if wf["success"]:
        stats[flow]["success"] += 1
    else:
        stats[flow]["failure"] += 1
    time = float(wf.get("time_minutes", 0))
    stats[flow]["total_time"] += time
    stats[flow]["times"].append(time)

# Calculate metrics
results = []
for flow, data in stats.items():
    success_rate = data["success"] / data["total"] if data["total"] > 0 else 0
    avg_time = data["total_time"] / data["total"] if data["total"] > 0 else 0
    results.append({
        "flow": flow,
        "total": data["total"],
        "success": data["success"],
        "failure": data["failure"],
        "success_rate": success_rate,
        "avg_time": avg_time
    })

# Sort by success rate, then by average time
results.sort(key=lambda x: (-x["success_rate"], x["avg_time"]))

# Generate report
report = f"""# Workflow Performance Analysis

**Generated:** {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC  
**Total Workflows Executed:** {len(workflows)}  
**Unique Workflows:** {len(results)}

---

## Performance Rankings

"""

for i, r in enumerate(results, 1):
    report += f"""### {i}. {r['flow']}
- **Success Rate:** {r['success_rate']:.1%} ({r['success']}/{r['total']})
- **Average Time:** {r['avg_time']:.1f} minutes
- **Failures:** {r['failure']}

"""

# Recommendations
report += """---

## Recommendations

"""

if results:
    best = results[0]
    report += f"""### ✅ Best Performer: {best['flow']}
- Success rate: {best['success_rate']:.1%}
- Average time: {best['avg_time']:.1f} minutes
- **Recommendation:** Use this workflow whenever applicable.

"""

    if len(results) > 1:
        worst = results[-1]
        if worst['success_rate'] < 0.7:
            report += f"""### ⚠️ Needs Improvement: {worst['flow']}
- Success rate: {worst['success_rate']:.1%} (below 70%)
- **Recommendation:** Review this workflow, identify failure patterns, adjust PROCESS_FLOWS.md.

"""

    # Time efficiency
    fast_flows = [r for r in results if r['avg_time'] < 5.0 and r['total'] >= 3]
    if fast_flows:
        report += f"""### ⚡ Fastest Workflows (< 5 minutes)
"""
        for r in fast_flows[:3]:
            report += f"- **{r['flow']}**: {r['avg_time']:.1f} min avg ({r['success_rate']:.1%} success)\n"

# Save report
with open(report_file, 'w') as f:
    f.write(report)

print(f"✓ Workflow analysis complete: {len(workflows)} executions analyzed")
print(f"✓ Report saved to: {report_file}")

# Print summary
print("\n--- Top 3 Workflows by Success Rate ---")
for i, r in enumerate(results[:3], 1):
    print(f"{i}. {r['flow']:40} {r['success_rate']:6.1%} success, {r['avg_time']:5.1f} min avg")

PYTHON_SCRIPT
