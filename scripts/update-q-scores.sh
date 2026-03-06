#!/bin/bash
# update-q-scores.sh — Update Q-Learning scores based on task outcomes

set -e

LOG_FILE="$HOME/.openclaw/workspace/rl-task-execution-log.jsonl"
Q_TABLE="$HOME/.openclaw/workspace/rl-agent-selection.json"
BACKUP_DIR="$HOME/.openclaw/workspace/.q-learning-backups"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup current Q-table
BACKUP_FILE="$BACKUP_DIR/rl-agent-selection-$(date +%Y%m%d-%H%M%S).json"
cp "$Q_TABLE" "$BACKUP_FILE"

# Use Python for Q-score updates (more reliable than bash JSON manipulation)
python3 - <<'PYTHON_SCRIPT'
import json
import sys
from datetime import datetime
from pathlib import Path

# Paths
log_file = Path.home() / ".openclaw/workspace/rl-task-execution-log.jsonl"
q_table_file = Path.home() / ".openclaw/workspace/rl-agent-selection.json"

# Load Q-table
with open(q_table_file) as f:
    q_table = json.load(f)

# Load task outcomes
outcomes = []
if log_file.exists():
    with open(log_file) as f:
        for line in f:
            line = line.strip()
            if line and line.startswith('{'):
                outcomes.append(json.loads(line))

if not outcomes:
    print("No outcomes to process yet.")
    sys.exit(0)

# Learning parameters
alpha = q_table["metadata"]["alpha"]  # 0.02 (learning rate)
gamma = q_table["metadata"]["gamma"]  # 0.99 (discount factor)

# Process each outcome
updates = 0
for outcome in outcomes:
    task_type = outcome["task_type"]
    agent = outcome["agent"]
    success = outcome["success"]
    quality = outcome.get("quality_score", 0.5)
    
    # Skip if task_type or agent not in Q-table
    if task_type not in q_table["task_types"]:
        continue
    if agent not in q_table["task_types"][task_type]["agents"]:
        continue
    
    # Calculate reward: success bonus + quality score
    reward = (1.0 if success else 0.0) + quality
    
    # Get current Q-value
    agent_data = q_table["task_types"][task_type]["agents"][agent]
    current_q = agent_data["q_score"]
    
    # Q-Learning update: Q(s,a) = Q(s,a) + α * (reward - Q(s,a))
    # Simplified (no next state, treating as episodic task)
    new_q = current_q + alpha * (reward - current_q)
    
    # Update Q-score and stats
    agent_data["q_score"] = round(new_q, 4)
    agent_data["total_uses"] += 1
    if success:
        agent_data["success_count"] += 1
    else:
        agent_data["failure_count"] += 1
    agent_data["success_rate"] = round(
        agent_data["success_count"] / agent_data["total_uses"], 4
    )
    agent_data["last_updated"] = datetime.utcnow().isoformat() + "Z"
    
    updates += 1

# Add learning log entry
if updates > 0:
    q_table["learning_log"].append({
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "note": f"Processed {updates} outcomes. Q-scores updated based on task results."
    })

# Save updated Q-table
with open(q_table_file, 'w') as f:
    json.dump(q_table, f, indent=2)

print(f"✓ Q-scores updated: {updates} outcomes processed")
print(f"✓ Total logged outcomes: {len(outcomes)}")

# Show top agents per task type
print("\n--- Current Top Agents by Task Type ---")
for task_type, data in q_table["task_types"].items():
    agents = data["agents"]
    if not agents:
        continue
    
    # Sort by Q-score
    sorted_agents = sorted(
        agents.items(),
        key=lambda x: x[1]["q_score"],
        reverse=True
    )
    
    top_agent, top_data = sorted_agents[0]
    print(f"{task_type:15} → {top_agent:10} (Q={top_data['q_score']:.3f}, uses={top_data['total_uses']}, success={top_data['success_rate']:.1%})")

PYTHON_SCRIPT

echo ""
echo "✓ Q-table backed up to: $BACKUP_FILE"
