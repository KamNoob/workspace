#!/usr/bin/env python3
"""
model-selector.py

PHASE 6A: MULTI-MODEL ROUTING

Selects optimal model based on task complexity:
  - Haiku: Simple/routing decisions (cheap, fast)
  - Sonnet: Standard tasks (balanced)
  - Opus: Complex reasoning (powerful, expensive)

Expected savings: 15-20% additional cost reduction
"""

import json
from pathlib import Path
from typing import Dict, Tuple
from datetime import datetime

MODEL_COSTS = {
    "haiku": {"input": 0.000080, "output": 0.00024},    # Cheapest
    "sonnet": {"input": 0.000300, "output": 0.0015},    # Balanced
    "opus": {"input": 0.0015, "output": 0.0060},        # Most expensive
}

# Complexity indicators (keywords that signal task difficulty)
COMPLEXITY_INDICATORS = {
    "haiku": [
        "route", "decide", "select", "categorize", "triage",
        "simple", "quick", "basic", "classify", "map"
    ],
    "sonnet": [
        "code", "develop", "analyze", "write", "document",
        "test", "review", "debug", "refactor", "optimize",
        "research", "explain", "summarize", "extract"
    ],
    "opus": [
        "architecture", "design", "complex", "multi-step", "reasoning",
        "strategy", "planning", "security audit", "vulnerability",
        "advanced", "novel", "breakthrough", "creative", "integrate"
    ]
}

class ModelSelector:
    def __init__(self):
        self.metrics_file = Path("data/metrics/model-routing-metrics.json")
        self.load_metrics()
    
    def load_metrics(self):
        """Load routing metrics from disk."""
        if self.metrics_file.exists():
            with open(self.metrics_file) as f:
                data = json.load(f)
                self.stats = data.get("stats", {})
                self.routing_history = data.get("history", [])
        else:
            self.stats = {m: {"count": 0, "cost": 0, "success": 0} for m in MODEL_COSTS.keys()}
            self.routing_history = []
    
    def save_metrics(self):
        """Save routing metrics to disk."""
        with open(self.metrics_file, 'w') as f:
            json.dump({
                "stats": self.stats,
                "history": self.routing_history[-1000:],  # Keep last 1000
                "timestamp": datetime.utcnow().isoformat()
            }, f, indent=2)
    
    def calculate_complexity(self, task: str) -> float:
        """
        Calculate task complexity (0.0 = simple, 1.0 = complex).
        Based on keyword matching with proper weighting.
        """
        task_lower = task.lower()
        
        # Count complexity keywords
        haiku_matches = sum(1 for keyword in COMPLEXITY_INDICATORS["haiku"] if keyword in task_lower)
        sonnet_matches = sum(1 for keyword in COMPLEXITY_INDICATORS["sonnet"] if keyword in task_lower)
        opus_matches = sum(1 for keyword in COMPLEXITY_INDICATORS["opus"] if keyword in task_lower)
        
        # If any opus keywords, it's complex
        if opus_matches > 0:
            return min(0.9 + (opus_matches * 0.05), 1.0)
        
        # If multiple sonnet keywords, it's medium-complex
        if sonnet_matches >= 2:
            return 0.4 + (sonnet_matches * 0.1)
        
        # If one sonnet keyword, it's medium
        if sonnet_matches == 1:
            return 0.4
        
        # Otherwise simple
        return 0.1 + (haiku_matches * 0.05)
    
    def select_model(self, task: str, agent: str = None) -> Dict:
        """
        Select optimal model for task.
        Returns: {"model": "haiku|sonnet|opus", "complexity": float, "reason": str}
        """
        complexity = self.calculate_complexity(task)
        
        # Model selection based on complexity
        if complexity < 0.33:
            model = "haiku"
            reason = f"Simple task (complexity {complexity:.2f})"
        elif complexity < 0.66:
            model = "sonnet"
            reason = f"Standard task (complexity {complexity:.2f})"
        else:
            model = "opus"
            reason = f"Complex task (complexity {complexity:.2f})"
        
        # Estimate tokens for this task
        avg_input_tokens = 2000  # Estimated
        avg_output_tokens = 1000  # Estimated
        
        cost = (avg_input_tokens * MODEL_COSTS[model]["input"] + 
                avg_output_tokens * MODEL_COSTS[model]["output"])
        
        result = {
            "model": model,
            "complexity": round(complexity, 3),
            "reason": reason,
            "task": task,
            "agent": agent or "unknown",
            "estimated_cost": round(cost, 6),
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Track routing
        self.routing_history.append(result)
        self.stats[model]["count"] += 1
        self.stats[model]["cost"] += cost
        self.save_metrics()
        
        return result
    
    def compare_models(self, task: str) -> Dict:
        """Compare cost/quality of all 3 models for a task."""
        complexity = self.calculate_complexity(task)
        avg_input = 2000
        avg_output = 1000
        
        comparison = {}
        for model, costs in MODEL_COSTS.items():
            cost = avg_input * costs["input"] + avg_output * costs["output"]
            comparison[model] = {
                "cost": round(cost, 6),
                "speed": "fast" if model == "haiku" else "medium" if model == "sonnet" else "slow",
                "quality": "basic" if model == "haiku" else "good" if model == "sonnet" else "excellent"
            }
        
        # Calculate savings vs always using Opus
        opus_cost = comparison["opus"]["cost"]
        
        selected = self.select_model(task)
        selected_cost = comparison[selected["model"]]["cost"]
        savings = opus_cost - selected_cost
        savings_pct = (savings / opus_cost * 100) if opus_cost > 0 else 0
        
        return {
            "task": task,
            "complexity": round(complexity, 3),
            "selected_model": selected["model"],
            "comparison": comparison,
            "savings_vs_opus": round(savings, 6),
            "savings_percent": round(savings_pct, 1)
        }
    
    def status(self) -> Dict:
        """Routing status and metrics."""
        total_routed = sum(s["count"] for s in self.stats.values())
        total_cost = sum(s["cost"] for s in self.stats.values())
        
        model_distribution = {}
        for model, stat in self.stats.items():
            if total_routed > 0:
                pct = (stat["count"] / total_routed) * 100
                model_distribution[model] = {
                    "count": stat["count"],
                    "percent": round(pct, 1),
                    "cost": round(stat["cost"], 6),
                    "avg_per_task": round(stat["cost"] / max(1, stat["count"]), 6)
                }
        
        # Estimate monthly savings
        monthly_tasks = total_routed  # Assume this month's volume
        opus_all_cost = monthly_tasks * (2000 * MODEL_COSTS["opus"]["input"] + 
                                         1000 * MODEL_COSTS["opus"]["output"])
        savings = opus_all_cost - total_cost
        
        return {
            "total_routed": total_routed,
            "total_cost": round(total_cost, 6),
            "model_distribution": model_distribution,
            "estimated_monthly_savings": round(savings, 2),
            "savings_percent": round((savings / opus_all_cost * 100) if opus_all_cost > 0 else 0, 1)
        }

def main():
    import sys
    
    selector = ModelSelector()
    
    if len(sys.argv) < 2:
        print("Usage: python3 model-selector.py <command> [task]")
        print("Commands:")
        print("  select <task>      - Select model for task")
        print("  compare <task>     - Compare all models")
        print("  status             - Show routing metrics")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "select":
        if len(sys.argv) < 3:
            print("Usage: model-selector.py select <task>")
            sys.exit(1)
        task = sys.argv[2]
        result = selector.select_model(task)
        print(json.dumps(result, indent=2))
    
    elif cmd == "compare":
        if len(sys.argv) < 3:
            print("Usage: model-selector.py compare <task>")
            sys.exit(1)
        task = sys.argv[2]
        result = selector.compare_models(task)
        print(json.dumps(result, indent=2))
    
    elif cmd == "status":
        result = selector.status()
        print(json.dumps(result, indent=2))
    
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
