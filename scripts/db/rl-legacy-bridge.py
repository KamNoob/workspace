#!/usr/bin/env python3
"""
RL Legacy Bridge: Ingest legacy outcomes into Q-learning state.
Updates rl-agent-selection.json with success signals from rl-legacy-outcomes.jsonl
"""

import json
from pathlib import Path
from collections import defaultdict

WORKSPACE = Path.home() / ".openclaw" / "workspace"
LEGACY_LOG = WORKSPACE / "data" / "rl" / "rl-legacy-outcomes.jsonl"
RL_STATE = WORKSPACE / "data" / "rl" / "rl-agent-selection.json"

# Learning rate for legacy data integration
LEGACY_LEARNING_RATE = 0.05  # Conservative (don't overwrite recent data)

def load_legacy_outcomes():
    """Load all legacy outcomes."""
    outcomes = []
    try:
        with open(LEGACY_LOG) as f:
            for line in f:
                if line.strip():
                    outcomes.append(json.loads(line))
    except FileNotFoundError:
        print(f"No legacy outcomes file found: {LEGACY_LOG}")
    return outcomes


def load_rl_state():
    """Load current RL agent selection state."""
    try:
        with open(RL_STATE) as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"RL state file not found: {RL_STATE}")
        return {"task_types": {}}


def integrate_legacy_outcomes(rl_state, outcomes):
    """
    Integrate legacy outcomes into Q-learning state.
    For each (agent, task) pair, update success counts.
    """
    updated_pairs = set()
    
    for outcome in outcomes:
        agent = outcome.get("agent", "Unknown")
        task_type = outcome.get("task_type", "unknown")
        success = outcome.get("success", False)
        
        # Skip Unknown agents and unknown tasks (insufficient signal)
        if agent == "Unknown" or task_type == "unknown":
            continue
        
        # Initialize task type if needed
        if task_type not in rl_state.get("task_types", {}):
            rl_state["task_types"][task_type] = {"agents": {}}
        
        task_entry = rl_state["task_types"][task_type]
        agents_dict = task_entry.get("agents", {})
        
        # Initialize agent if needed
        if agent not in agents_dict:
            agents_dict[agent] = {
                "q_score": 0.5,
                "success_count": 0,
                "failure_count": 0,
                "total_uses": 0,
                "success_rate": 0.0,
                "last_updated": outcome.get("timestamp"),
            }
        
        agent_entry = agents_dict[agent]
        
        # Update counts
        if success:
            agent_entry["success_count"] += 1
        else:
            agent_entry["failure_count"] += 1
        
        agent_entry["total_uses"] += 1
        agent_entry["success_rate"] = (
            agent_entry["success_count"] / agent_entry["total_uses"]
            if agent_entry["total_uses"] > 0 else 0.0
        )
        
        # Update Q-score using legacy learning rate (conservative)
        # New Q = Old Q + learning_rate * (success - old Q)
        old_q = agent_entry["q_score"]
        new_q = old_q + LEGACY_LEARNING_RATE * (float(success) - old_q)
        agent_entry["q_score"] = round(new_q, 4)
        agent_entry["last_updated"] = outcome.get("timestamp")
        
        updated_pairs.add((agent, task_type))
    
    return updated_pairs


def save_rl_state(rl_state):
    """Save updated RL state."""
    RL_STATE.parent.mkdir(parents=True, exist_ok=True)
    with open(RL_STATE, "w") as f:
        json.dump(rl_state, f, indent=2)


def main():
    print("\n" + "="*70)
    print("🧠 RL LEGACY BRIDGE: Integrating Legacy Outcomes into Q-Learning")
    print("="*70)
    
    # Load data
    outcomes = load_legacy_outcomes()
    rl_state = load_rl_state()
    
    if not outcomes:
        print("\n⚠️  No legacy outcomes to integrate.")
        return
    
    print(f"\n📊 Integrating {len(outcomes)} outcomes into Q-learning state...")
    
    # Integrate
    updated_pairs = integrate_legacy_outcomes(rl_state, outcomes)
    
    # Save
    save_rl_state(rl_state)
    
    # Summary
    print(f"\n✅ Updated {len(updated_pairs)} (agent, task) pairs")
    print(f"\nPairs updated:")
    for agent, task in sorted(updated_pairs):
        task_data = rl_state["task_types"].get(task, {}).get("agents", {}).get(agent, {})
        q = task_data.get("q_score", 0)
        sr = task_data.get("success_rate", 0)
        total = task_data.get("total_uses", 0)
        print(f"  {agent:15} + {task:12} → Q={q:.4f}, SR={sr*100:.1f}% ({total} uses)")
    
    print("\n" + "="*70)
    print("✅ Legacy integration complete. Q-values warmed with historical data.")
    print("="*70 + "\n")


if __name__ == "__main__":
    main()
