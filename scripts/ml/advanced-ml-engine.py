#!/usr/bin/env python3
"""
advanced-ml-engine.py

PHASE 6B: ADVANCED ML FEATURES

Three components:
  1. Anomaly Detection — Spot degraded performance
  2. Temporal Dynamics — Time-aware agent selection
  3. Agent Collaboration — Pair agents on complex tasks

Expected value: Better quality + cost optimization
"""

import json
from pathlib import Path
from datetime import datetime, timedelta
from statistics import mean, stdev
from typing import Dict, List, Tuple

class AnomalyDetector:
    """Detect when agent performance drops unexpectedly."""
    
    def __init__(self):
        self.metrics_file = Path("data/rl/rl-task-execution-log.jsonl")
        self.anomaly_file = Path("data/metrics/anomalies.json")
        self.load_history()
    
    def load_history(self):
        """Load task outcome history."""
        self.history = []
        if self.metrics_file.exists():
            with open(self.metrics_file) as f:
                for line in f:
                    try:
                        self.history.append(json.loads(line))
                    except:
                        pass
    
    def calculate_baseline(self, agent: str, window_size: int = 20) -> Dict:
        """Calculate baseline performance for agent."""
        agent_outcomes = [h for h in self.history if h.get("agent") == agent][-window_size:]
        
        if not agent_outcomes:
            return {"success_rate": 0.5, "std_dev": 0.1, "count": 0}
        
        successes = sum(1 for o in agent_outcomes if o.get("success", False))
        success_rate = successes / len(agent_outcomes)
        
        # Simple std dev (binary: success or not)
        std_dev = (success_rate * (1 - success_rate)) ** 0.5
        
        return {
            "success_rate": round(success_rate, 3),
            "std_dev": round(std_dev, 3),
            "count": len(agent_outcomes),
            "window_size": window_size
        }
    
    def detect_anomaly(self, agent: str, outcome: bool) -> Dict:
        """Check if recent outcome is anomalous."""
        baseline = self.calculate_baseline(agent)
        expected_rate = baseline["success_rate"]
        std_dev = baseline["std_dev"]
        
        # Single outlier check (simple)
        if outcome == False and expected_rate > 0.8:
            z_score = (expected_rate - 0) / max(std_dev, 0.01)
            if z_score > 2:  # 2 sigma is anomalous
                return {
                    "anomalous": True,
                    "agent": agent,
                    "baseline_success_rate": baseline["success_rate"],
                    "z_score": round(z_score, 2),
                    "severity": "high" if z_score > 3 else "medium",
                    "recommendation": "Investigate or reassign tasks"
                }
        
        return {
            "anomalous": False,
            "agent": agent,
            "baseline_success_rate": baseline["success_rate"]
        }
    
    def status(self) -> Dict:
        """System anomaly status."""
        agents = set(h.get("agent") for h in self.history if h.get("agent"))
        
        anomalies = []
        for agent in agents:
            baseline = self.calculate_baseline(agent)
            if baseline["success_rate"] < 0.5:
                anomalies.append({
                    "agent": agent,
                    "success_rate": baseline["success_rate"],
                    "severity": "low" if baseline["success_rate"] > 0.3 else "high"
                })
        
        return {
            "total_agents_monitored": len(agents),
            "agents_below_threshold": len(anomalies),
            "anomalies": anomalies,
            "timestamp": datetime.utcnow().isoformat()
        }

class TemporalDynamics:
    """Time-aware agent selection."""
    
    def __init__(self):
        self.metrics_file = Path("data/rl/rl-task-execution-log.jsonl")
        self.temporal_file = Path("data/metrics/temporal-patterns.json")
        self.load_history()
    
    def load_history(self):
        """Load task outcome history."""
        self.history = []
        if self.metrics_file.exists():
            with open(self.metrics_file) as f:
                for line in f:
                    try:
                        entry = json.loads(line)
                        # Parse timestamp
                        if "timestamp" in entry:
                            entry["hour"] = int(entry["timestamp"].split("T")[1].split(":")[0])
                            self.history.append(entry)
                    except:
                        pass
    
    def analyze_performance_by_time(self) -> Dict:
        """Analyze agent performance by hour of day."""
        hourly_performance = {}
        
        for hour in range(24):
            hour_tasks = [h for h in self.history if h.get("hour") == hour]
            if not hour_tasks:
                continue
            
            successes = sum(1 for h in hour_tasks if h.get("success", False))
            success_rate = successes / len(hour_tasks) if hour_tasks else 0
            
            hourly_performance[hour] = {
                "success_rate": round(success_rate, 3),
                "task_count": len(hour_tasks),
                "optimal_time": success_rate > 0.8
            }
        
        return hourly_performance
    
    def get_best_agents_for_time(self, hour: int) -> Dict:
        """Get best-performing agents for specific hour."""
        hour_tasks = [h for h in self.history if h.get("hour") == hour]
        
        agent_performance = {}
        for task in hour_tasks:
            agent = task.get("agent")
            success = task.get("success", False)
            
            if agent not in agent_performance:
                agent_performance[agent] = {"successes": 0, "total": 0}
            
            agent_performance[agent]["total"] += 1
            if success:
                agent_performance[agent]["successes"] += 1
        
        # Rank agents
        ranked = []
        for agent, perf in agent_performance.items():
            rate = perf["successes"] / perf["total"] if perf["total"] > 0 else 0
            ranked.append((agent, rate, perf["total"]))
        
        ranked.sort(key=lambda x: x[1], reverse=True)
        
        return {
            "hour": hour,
            "ranked_agents": [
                {"agent": a, "success_rate": round(r, 3), "task_count": c}
                for a, r, c in ranked[:3]
            ]
        }
    
    def recommend_timing(self, agent: str) -> Dict:
        """Recommend best times to use this agent."""
        agent_tasks = [h for h in self.history if h.get("agent") == agent]
        
        hour_performance = {}
        for task in agent_tasks:
            hour = task.get("hour", 12)
            success = task.get("success", False)
            
            if hour not in hour_performance:
                hour_performance[hour] = {"successes": 0, "total": 0}
            
            hour_performance[hour]["total"] += 1
            if success:
                hour_performance[hour]["successes"] += 1
        
        # Find best hours
        best_hours = []
        for hour, perf in hour_performance.items():
            rate = perf["successes"] / perf["total"] if perf["total"] > 0 else 0
            if rate > 0.7:
                best_hours.append((hour, rate))
        
        best_hours.sort(key=lambda x: x[1], reverse=True)
        
        return {
            "agent": agent,
            "best_hours": [{"hour": h, "success_rate": round(r, 3)} for h, r in best_hours],
            "recommendation": f"Use {agent} during {[h for h, _ in best_hours[:3]]} UTC for optimal results"
        }

class AgentCollaboration:
    """Pair agents on complex tasks."""
    
    def __init__(self):
        self.metrics_file = Path("data/rl/rl-task-execution-log.jsonl")
        self.collab_file = Path("data/metrics/collaborations.json")
        self.load_history()
    
    def load_history(self):
        """Load task outcome history."""
        self.history = []
        if self.metrics_file.exists():
            with open(self.metrics_file) as f:
                for line in f:
                    try:
                        self.history.append(json.loads(line))
                    except:
                        pass
    
    def find_complementary_agents(self, agent1: str) -> List[Tuple[str, float]]:
        """Find agents that work well with agent1."""
        # Group tasks by type
        task_types = {}
        for task in self.history:
            if task.get("agent") != agent1:
                continue
            
            task_type = task.get("task", "general").split()[0]
            if task_type not in task_types:
                task_types[task_type] = []
            task_types[task_type].append(task)
        
        # For each task type, find which other agents succeeded on similar tasks
        complementary = {}
        for task_type, tasks in task_types.items():
            other_agent_tasks = [t for t in self.history 
                                if t.get("task", "").startswith(task_type) and t.get("agent") != agent1]
            
            for other_task in other_agent_tasks:
                other_agent = other_task.get("agent")
                if other_agent not in complementary:
                    complementary[other_agent] = {"collaborations": 0, "successes": 0}
                
                complementary[other_agent]["collaborations"] += 1
                if other_task.get("success"):
                    complementary[other_agent]["successes"] += 1
        
        # Rank by success rate
        ranked = []
        for agent, stats in complementary.items():
            rate = stats["successes"] / stats["collaborations"] if stats["collaborations"] > 0 else 0
            ranked.append((agent, rate))
        
        ranked.sort(key=lambda x: x[1], reverse=True)
        return ranked[:3]  # Top 3
    
    def recommend_collaboration(self, task: str, primary_agent: str) -> Dict:
        """Recommend collaboration for complex task."""
        # Simple heuristic: complex tasks (with keywords) benefit from pairing
        complex_keywords = ["architecture", "design", "complex", "multi", "advanced", "novel"]
        is_complex = any(keyword in task.lower() for keyword in complex_keywords)
        
        if not is_complex:
            return {
                "task": task,
                "primary_agent": primary_agent,
                "recommendation": "No collaboration needed",
                "pair_agent": None
            }
        
        # Find complementary agent
        complements = self.find_complementary_agents(primary_agent)
        
        if complements:
            pair_agent, success_rate = complements[0]
            return {
                "task": task,
                "primary_agent": primary_agent,
                "pair_agent": pair_agent,
                "success_rate": round(success_rate, 3),
                "recommendation": f"Pair {primary_agent} with {pair_agent} for this complex task",
                "expected_improvement": "5-10% quality boost from collaboration"
            }
        
        return {
            "task": task,
            "primary_agent": primary_agent,
            "recommendation": "Use primary agent alone",
            "pair_agent": None
        }

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python3 advanced-ml-engine.py <command> [args...]")
        print("Commands:")
        print("  anomaly-status          - Show anomaly detection status")
        print("  anomaly-check <agent>   - Check specific agent")
        print("  temporal-status         - Show temporal performance patterns")
        print("  temporal-time <hour>    - Best agents for hour (0-23)")
        print("  temporal-agent <agent>  - Best times for agent")
        print("  collab <agent>          - Find collaborative partners")
        print("  collab-task <task> <agent> - Recommend collaboration for task")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "anomaly-status":
        detector = AnomalyDetector()
        result = detector.status()
        print(json.dumps(result, indent=2))
    
    elif cmd == "anomaly-check":
        if len(sys.argv) < 3:
            print("Usage: advanced-ml-engine.py anomaly-check <agent>")
            sys.exit(1)
        detector = AnomalyDetector()
        baseline = detector.calculate_baseline(sys.argv[2])
        print(json.dumps(baseline, indent=2))
    
    elif cmd == "temporal-status":
        temporal = TemporalDynamics()
        result = temporal.analyze_performance_by_time()
        print(json.dumps(result, indent=2))
    
    elif cmd == "temporal-time":
        if len(sys.argv) < 3:
            print("Usage: advanced-ml-engine.py temporal-time <hour>")
            sys.exit(1)
        temporal = TemporalDynamics()
        result = temporal.get_best_agents_for_time(int(sys.argv[2]))
        print(json.dumps(result, indent=2))
    
    elif cmd == "temporal-agent":
        if len(sys.argv) < 3:
            print("Usage: advanced-ml-engine.py temporal-agent <agent>")
            sys.exit(1)
        temporal = TemporalDynamics()
        result = temporal.recommend_timing(sys.argv[2])
        print(json.dumps(result, indent=2))
    
    elif cmd == "collab":
        if len(sys.argv) < 3:
            print("Usage: advanced-ml-engine.py collab <agent>")
            sys.exit(1)
        collab = AgentCollaboration()
        result = collab.find_complementary_agents(sys.argv[2])
        print(json.dumps({"agent": sys.argv[2], "complementary_agents": [{"agent": a, "success_rate": round(r, 3)} for a, r in result]}, indent=2))
    
    elif cmd == "collab-task":
        if len(sys.argv) < 4:
            print("Usage: advanced-ml-engine.py collab-task <task> <agent>")
            sys.exit(1)
        collab = AgentCollaboration()
        result = collab.recommend_collaboration(sys.argv[2], sys.argv[3])
        print(json.dumps(result, indent=2))
    
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
