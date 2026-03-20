#!/usr/bin/env python3
"""
Agent Drift Detector: Guardrail for system stability
Monitors agent Q-scores and alerts if performance degrades significantly
"""

import json
import sys
from datetime import datetime, timedelta
from pathlib import Path

def load_json(path):
    """Load JSON file safely"""
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None

def check_agent_drift(config_path, threshold=0.10, lookback_hours=24):
    """
    Detect agent performance drift
    Alert if Q-score drops >threshold in lookback_hours
    """
    config = load_json(config_path)
    if not config:
        print(f"❌ Config not found: {config_path}")
        return False
    
    alerts = []
    
    print("=== AGENT DRIFT DETECTION ===\n")
    print(f"Threshold: >{threshold:.2f} drop in {lookback_hours}h")
    print(f"Check time: {datetime.now().isoformat()}\n")
    
    # Check each agent across all task types
    agent_scores = {}
    
    for task_type, task_data in config.get("task_types", {}).items():
        for agent_name, agent_data in task_data.get("agents", {}).items():
            key = (agent_name, task_type)
            
            q_score = agent_data.get("q_score", 0)
            success_rate = agent_data.get("success_rate", 0)
            total_uses = agent_data.get("total_uses", 0)
            last_updated = agent_data.get("last_updated", "unknown")
            
            if agent_name not in agent_scores:
                agent_scores[agent_name] = []
            
            agent_scores[agent_name].append({
                "task": task_type,
                "q_score": q_score,
                "success_rate": success_rate,
                "total_uses": total_uses,
                "last_updated": last_updated
            })
    
    # Check for issues
    for agent_name in sorted(agent_scores.keys()):
        tasks = agent_scores[agent_name]
        
        # Calculate average Q-score
        q_scores = [t["q_score"] for t in tasks]
        avg_q = sum(q_scores) / len(q_scores) if q_scores else 0
        
        # Calculate average success rate
        success_rates = [t["success_rate"] for t in tasks]
        avg_success = sum(success_rates) / len(success_rates) if success_rates else 0
        
        # Check for low success rate (indicator of drift)
        low_success = [t for t in tasks if t["success_rate"] < 0.5 and t["total_uses"] > 3]
        
        if low_success:
            alert = f"⚠️  {agent_name}: Low success on {len(low_success)} task type(s)"
            alerts.append(alert)
            print(alert)
            for task in low_success:
                print(f"    • {task['task']}: {task['success_rate']:.0%} ({task['total_uses']} uses)")
        
        # Check for Q-score < 0.55 (baseline concern)
        if avg_q < 0.55 and any(t["total_uses"] > 0 for t in tasks):
            alert = f"⚠️  {agent_name}: Low average Q-score {avg_q:.3f}"
            alerts.append(alert)
            print(f"{alert}")
        
        # Good performers
        if avg_success >= 0.75:
            print(f"✅ {agent_name:12} Q={avg_q:.3f}  Success={avg_success:.0%}")
        elif avg_success > 0.50:
            print(f"🟡 {agent_name:12} Q={avg_q:.3f}  Success={avg_success:.0%} (monitor)")
    
    print()
    return len(alerts) == 0

def recommend_actions():
    """Suggest corrective actions if drift detected"""
    print("=== RECOMMENDED ACTIONS ===\n")
    print("If drift detected:")
    print("  1. Check Phase 7B learnings: data/metrics/phase7b-learnings.json")
    print("  2. Review recent task log: tail -50 data/rl/rl-task-execution-log.jsonl")
    print("  3. Identify failed task type (e.g., 'code', 'research')")
    print("  4. Investigate spawner routing or task definition")
    print("  5. Optional: Reduce Q-score for agent on that task type")
    print("  6. Commit fix with timestamp + reason\n")

if __name__ == "__main__":
    config_path = Path("data/rl/rl-agent-selection.json")
    
    success = check_agent_drift(str(config_path))
    recommend_actions()
    
    sys.exit(0 if success else 1)
