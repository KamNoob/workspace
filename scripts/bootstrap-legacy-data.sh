#!/bin/bash
# bootstrap-legacy-data.sh — Extract historical task outcomes from MEMORY.md and session logs

set -e

echo "🔍 Extracting legacy task data from MEMORY.md and session logs..."

# Bootstrap from documented task completions
cd ~/.openclaw/workspace

# 1. API Security Research (2026-02-28 18:10 GMT) — Scout → Veritas → Chronicle
echo "📝 Found: API Security Research (Feb 28)"
scripts/log-task-outcome.sh research Scout true 0.9 12
scripts/log-task-outcome.sh research Veritas true 0.95 5
scripts/log-task-outcome.sh documentation Chronicle true 0.95 3
scripts/log-workflow.sh "Chain_A_Knowledge_Pipeline" true 20 "API Security 2026 research (verified by Veritas)"

# 2. Agent Roster Update (2026-02-28) — Direct work (Prism + Navigator creation)
echo "📝 Found: Agent Roster Update (Feb 28)"
scripts/log-task-outcome.sh documentation direct true 1.0 15
scripts/log-workflow.sh "Direct_No_Agent" true 15 "Created Prism + Navigator agents, updated docs"

# 3. Web App Debugging Session (2026-02-27 15:20-15:26 GMT) — Direct troubleshooting
echo "📝 Found: Web App Debugging (Feb 27)"
scripts/log-task-outcome.sh code direct false 0.3 60
scripts/log-workflow.sh "Direct_No_Agent" false 60 "Web app polling issue, messages not rendering"

# 4. MEMORY.md Contradiction Fix (2026-02-28 14:05 GMT) — Direct work
echo "📝 Found: MEMORY.md Contradiction Cleanup (Feb 28)"
scripts/log-task-outcome.sh documentation direct true 0.9 20
scripts/log-workflow.sh "Direct_No_Agent" true 20 "Removed outdated Commander project docs, fixed cron jobs"

# 5. Cron Job Cleanup (2026-02-28) — Sentinel-style work but done directly
echo "📝 Found: Cron Job Cleanup (Feb 28)"
scripts/log-task-outcome.sh infrastructure direct true 0.85 10
scripts/log-workflow.sh "Direct_No_Agent" true 10 "Removed broken Commander health-check cron job"

echo ""
echo "✅ Legacy data extraction complete"
echo "→ Triggering Q-score update..."
scripts/update-q-scores.sh

echo ""
echo "✅ Bootstrap complete! Q-Learning now has historical context."
