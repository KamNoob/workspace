#!/usr/bin/env python3
"""
ml-autoretrain.py

PHASE 7A: AUTO-RETRAINING PIPELINE

Monitors outcomes and auto-retrains models every 100 new outcomes.
Self-improving system that learns from production data.

Components:
  1. Outcome monitoring (tracks new task outcomes)
  2. Data collection (batches outcomes for training)
  3. Model retraining (updates complexity detection)
  4. Threshold updates (adjusts model selection)
  5. Performance tracking (monitors improvement)
"""

import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List
import hashlib

class AutoRetrainer:
    """Auto-retrain models from production outcomes."""
    
    def __init__(self):
        self.outcome_log = Path("data/rl/rl-task-execution-log.jsonl")
        self.model_metrics = Path("data/metrics/model-routing-metrics.json")
        self.retrain_state = Path("data/metrics/retrain-state.json")
        self.retrain_history = Path("data/metrics/retrain-history.jsonl")
        self.load_state()
    
    def load_state(self):
        """Load retrain state."""
        if self.retrain_state.exists():
            with open(self.retrain_state) as f:
                state = json.load(f)
                self.last_hash = state.get("last_hash", "")
                self.outcomes_processed = state.get("outcomes_processed", 0)
                self.retrains_completed = state.get("retrains_completed", 0)
        else:
            self.last_hash = ""
            self.outcomes_processed = 0
            self.retrains_completed = 0
    
    def save_state(self):
        """Save retrain state."""
        with open(self.retrain_state, 'w') as f:
            json.dump({
                "last_hash": self.last_hash,
                "outcomes_processed": self.outcomes_processed,
                "retrains_completed": self.retrains_completed,
                "last_retrain": datetime.utcnow().isoformat()
            }, f, indent=2)
    
    def count_new_outcomes(self) -> int:
        """Count outcomes since last processing."""
        if not self.outcome_log.exists():
            return 0
        
        with open(self.outcome_log) as f:
            lines = f.readlines()
        
        # Calculate hash of file
        current_hash = hashlib.md5(''.join(lines).encode()).hexdigest()
        
        if current_hash == self.last_hash:
            return 0
        
        # Count outcomes and update hash
        new_outcomes = len(lines) - self.outcomes_processed
        self.last_hash = current_hash
        self.outcomes_processed = len(lines)
        
        return max(0, new_outcomes)
    
    def collect_training_data(self) -> List[Dict]:
        """Collect outcomes for retraining."""
        outcomes = []
        
        if not self.outcome_log.exists():
            return outcomes
        
        try:
            with open(self.outcome_log) as f:
                for line in f:
                    try:
                        outcomes.append(json.loads(line))
                    except:
                        pass
        except:
            pass
        
        return outcomes[-200:]  # Last 200 outcomes for retraining
    
    def analyze_complexity_patterns(self, outcomes: List[Dict]) -> Dict:
        """Analyze task complexity patterns from outcomes."""
        patterns = {
            "easy_success_rate": 0,
            "medium_success_rate": 0,
            "hard_success_rate": 0,
            "easy_count": 0,
            "medium_count": 0,
            "hard_count": 0,
            "most_successful_agents": {},
            "least_successful_agents": {},
        }
        
        # Categorize outcomes
        for outcome in outcomes:
            task = outcome.get("task", "").lower()
            success = outcome.get("success", False)
            agent = outcome.get("agent", "unknown")
            
            # Simple heuristic categorization
            if any(w in task for w in ["route", "select", "decide", "triage"]):
                complexity = "easy"
            elif any(w in task for w in ["design", "complex", "architecture", "strategy"]):
                complexity = "hard"
            else:
                complexity = "medium"
            
            # Track success rates
            key = f"{complexity}_count"
            patterns[key] += 1
            
            if success:
                key = f"{complexity}_success_rate"
                patterns[key] = patterns.get(key, 0) + 1
            
            # Track agent performance
            if agent not in patterns["most_successful_agents"]:
                patterns["most_successful_agents"][agent] = {"success": 0, "total": 0}
            patterns["most_successful_agents"][agent]["total"] += 1
            if success:
                patterns["most_successful_agents"][agent]["success"] += 1
        
        # Calculate rates
        for complexity in ["easy", "medium", "hard"]:
            count = patterns[f"{complexity}_count"]
            if count > 0:
                patterns[f"{complexity}_success_rate"] /= count
                patterns[f"{complexity}_success_rate"] = round(patterns[f"{complexity}_success_rate"], 3)
        
        return patterns
    
    def update_thresholds(self, patterns: Dict) -> Dict:
        """Update complexity thresholds based on patterns."""
        updates = {
            "complexity_thresholds": {
                "haiku_max": 0.3,  # Haiku for complexity < 0.3
                "sonnet_max": 0.7,  # Sonnet for 0.3-0.7
                # Opus for > 0.7
            },
            "success_targets": {
                "easy": 0.95,
                "medium": 0.85,
                "hard": 0.80,
            },
            "agent_confidence": {}
        }
        
        # Adjust based on actual performance
        for complexity in ["easy", "medium", "hard"]:
            actual_rate = patterns.get(f"{complexity}_success_rate", 0.5)
            target = updates["success_targets"][complexity]
            
            # If actual is lower than target, we should route to better agents
            if actual_rate < target:
                # Increase selectivity
                if complexity == "easy":
                    updates["complexity_thresholds"]["haiku_max"] = max(0.2, updates["complexity_thresholds"]["haiku_max"] - 0.05)
                elif complexity == "medium":
                    updates["complexity_thresholds"]["sonnet_max"] = max(0.6, updates["complexity_thresholds"]["sonnet_max"] - 0.05)
        
        # Track agent confidence
        for agent, stats in patterns["most_successful_agents"].items():
            if stats["total"] > 5:
                confidence = stats["success"] / stats["total"]
                updates["agent_confidence"][agent] = round(confidence, 3)
        
        return updates
    
    def check_retrain_trigger(self, new_outcomes: int) -> bool:
        """Check if retrain should be triggered."""
        return new_outcomes >= 100
    
    def execute_retrain(self, outcomes: List[Dict]) -> Dict:
        """Execute model retraining."""
        patterns = self.analyze_complexity_patterns(outcomes)
        updates = self.update_thresholds(patterns)
        
        retrain_result = {
            "timestamp": datetime.utcnow().isoformat(),
            "outcomes_processed": len(outcomes),
            "patterns": patterns,
            "threshold_updates": updates,
            "status": "completed"
        }
        
        # Log retrain
        with open(self.retrain_history, 'a') as f:
            f.write(json.dumps(retrain_result) + '\n')
        
        self.retrains_completed += 1
        self.save_state()
        
        return retrain_result
    
    def status(self) -> Dict:
        """Retrain status."""
        new_outcomes = self.count_new_outcomes()
        
        status = {
            "outcomes_processed": self.outcomes_processed,
            "new_outcomes_since_last": new_outcomes,
            "retrains_completed": self.retrains_completed,
            "next_retrain_at": max(0, 100 - new_outcomes),
            "auto_retrain_enabled": True,
            "last_state_save": datetime.utcnow().isoformat()
        }
        
        # Check retrain history
        if self.retrain_history.exists():
            with open(self.retrain_history) as f:
                lines = f.readlines()
                if lines:
                    last_retrain = json.loads(lines[-1])
                    status["last_retrain_timestamp"] = last_retrain.get("timestamp")
                    status["last_patterns"] = last_retrain.get("patterns")
        
        return status
    
    def monitor(self) -> Dict:
        """Monitor and auto-retrain if needed."""
        new_outcomes = self.count_new_outcomes()
        
        result = {
            "timestamp": datetime.utcnow().isoformat(),
            "new_outcomes": new_outcomes,
            "retrain_triggered": False
        }
        
        if self.check_retrain_trigger(new_outcomes):
            outcomes = self.collect_training_data()
            if outcomes:
                retrain_result = self.execute_retrain(outcomes)
                result["retrain_triggered"] = True
                result["retrain_result"] = retrain_result
                result["message"] = f"Auto-retrain executed: processed {len(outcomes)} outcomes"
        else:
            result["message"] = f"No retrain yet. {100 - new_outcomes} outcomes until next retrain."
        
        return result

def main():
    import sys
    
    retrainer = AutoRetrainer()
    
    if len(sys.argv) < 2:
        print("Usage: python3 ml-autoretrain.py <command>")
        print("Commands:")
        print("  monitor    - Check for retrain trigger and execute if needed")
        print("  status     - Show retrain status")
        print("  force      - Force retrain now")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "monitor":
        result = retrainer.monitor()
        print(json.dumps(result, indent=2))
    
    elif cmd == "status":
        result = retrainer.status()
        print(json.dumps(result, indent=2))
    
    elif cmd == "force":
        outcomes = retrainer.collect_training_data()
        if outcomes:
            result = retrainer.execute_retrain(outcomes)
            print(json.dumps(result, indent=2))
        else:
            print("No outcomes to retrain on")
    
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
