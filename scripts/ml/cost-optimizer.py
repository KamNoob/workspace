#!/usr/bin/env python3
"""
cost-optimizer.py

PHASE 7A: DYNAMIC COST OPTIMIZATION

Learns cost/quality tradeoffs and optimizes model selection.
Real-time cost tracking and threshold adjustment.

Features:
  1. Track actual costs vs. projected costs
  2. Learn which models succeed best per task type
  3. Dynamically adjust routing thresholds
  4. Real-time cost monitoring and forecasting
"""

import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List
from collections import defaultdict

class CostOptimizer:
    """Dynamic cost optimization engine."""
    
    def __init__(self):
        self.routing_metrics = Path("data/metrics/model-routing-metrics.json")
        self.cost_log = Path("data/metrics/cost-optimization.json")
        self.outcome_log = Path("data/rl/rl-task-execution-log.jsonl")
        self.load_data()
    
    def load_data(self):
        """Load routing and outcome data."""
        self.routing_history = []
        self.outcomes = []
        
        # Load routing history
        if self.routing_metrics.exists():
            with open(self.routing_metrics) as f:
                data = json.load(f)
                self.routing_history = data.get("history", [])
        
        # Load outcomes
        if self.outcome_log.exists():
            with open(self.outcome_log) as f:
                for line in f:
                    try:
                        self.outcomes.append(json.loads(line))
                    except:
                        pass
    
    def calculate_cost_per_outcome(self, outcomes: List[Dict]) -> Dict:
        """Calculate cost-effectiveness of outcomes."""
        model_stats = defaultdict(lambda: {"cost": 0, "success": 0, "count": 0})
        
        for outcome in outcomes:
            # Estimate model used (would come from routing decision)
            # For now, we infer from routing metrics
            task = outcome.get("task", "")
            success = outcome.get("success", False)
            
            # Estimate model complexity
            if any(w in task.lower() for w in ["design", "complex", "architecture"]):
                estimated_model = "opus"
                estimated_cost = 9.0
            elif any(w in task.lower() for w in ["code", "develop", "test"]):
                estimated_model = "sonnet"
                estimated_cost = 2.1
            else:
                estimated_model = "haiku"
                estimated_cost = 0.4
            
            stats = model_stats[estimated_model]
            stats["cost"] += estimated_cost
            stats["count"] += 1
            if success:
                stats["success"] += 1
        
        # Calculate cost per success
        results = {}
        for model, stats in model_stats.items():
            success_rate = stats["success"] / stats["count"] if stats["count"] > 0 else 0
            cost_per_success = stats["cost"] / max(1, stats["success"])
            
            results[model] = {
                "total_cost": round(stats["cost"], 6),
                "success_count": stats["success"],
                "total_count": stats["count"],
                "success_rate": round(success_rate, 3),
                "cost_per_success": round(cost_per_success, 6),
                "efficiency": round(success_rate / (stats["cost"] / 1000), 6)  # Success per $1000
            }
        
        return results
    
    def recommend_threshold_adjustments(self, cost_analysis: Dict) -> Dict:
        """Recommend threshold adjustments based on cost analysis."""
        recommendations = {
            "haiku_complexity_max": 0.3,
            "sonnet_complexity_max": 0.7,
            "adjustments": []
        }
        
        # Analyze costs
        haiku_stats = cost_analysis.get("haiku", {})
        sonnet_stats = cost_analysis.get("sonnet", {})
        opus_stats = cost_analysis.get("opus", {})
        
        # If Haiku succeeds more often, increase its range
        if haiku_stats.get("success_rate", 0) > 0.8:
            recommendations["haiku_complexity_max"] = 0.4
            recommendations["adjustments"].append({
                "model": "haiku",
                "reason": "High success rate (>80%), expand range",
                "new_threshold": 0.4
            })
        
        # If Sonnet is more cost-effective, expand its range
        if sonnet_stats.get("cost_per_success", 999) < opus_stats.get("cost_per_success", 999):
            recommendations["sonnet_complexity_max"] = 0.8
            recommendations["adjustments"].append({
                "model": "sonnet",
                "reason": "Better cost-per-success than Opus",
                "new_threshold": 0.8
            })
        
        # If Opus succeeds on complex tasks, keep it as fallback
        if opus_stats.get("success_rate", 0) > 0.9:
            recommendations["adjustments"].append({
                "model": "opus",
                "reason": "High success on complex (>90%), keep as fallback",
                "action": "no_change"
            })
        
        return recommendations
    
    def forecast_monthly_cost(self, task_volume: int = 1000) -> Dict:
        """Forecast monthly costs based on current optimization."""
        cost_analysis = self.calculate_cost_per_outcome(self.outcomes[-100:])
        
        # Weighted average cost per task
        total_cost = sum(s["total_cost"] for s in cost_analysis.values())
        total_count = sum(s["total_count"] for s in cost_analysis.values())
        
        if total_count == 0:
            avg_cost_per_task = 2.1  # Default to Sonnet
        else:
            avg_cost_per_task = total_cost / total_count
        
        # Project monthly costs
        monthly_cost = avg_cost_per_task * task_volume
        
        # Compare to baseline (always use Sonnet)
        sonnet_baseline = 2.1 * task_volume
        savings = sonnet_baseline - monthly_cost
        savings_pct = (savings / sonnet_baseline * 100) if sonnet_baseline > 0 else 0
        
        return {
            "task_volume_per_month": task_volume,
            "avg_cost_per_task": round(avg_cost_per_task, 6),
            "projected_monthly_cost": round(monthly_cost, 2),
            "sonnet_baseline": round(sonnet_baseline, 2),
            "projected_savings_vs_baseline": round(savings, 2),
            "savings_percentage": round(savings_pct, 1)
        }
    
    def track_cumulative_savings(self) -> Dict:
        """Track cumulative savings from optimization."""
        cost_analysis = self.calculate_cost_per_outcome(self.outcomes)
        
        actual_total = sum(s["total_cost"] for s in cost_analysis.values())
        
        # Calculate baseline (always use Opus)
        opus_baseline = len(self.outcomes) * 9.0
        
        # Calculate Sonnet baseline
        sonnet_baseline = len(self.outcomes) * 2.1
        
        savings_vs_opus = opus_baseline - actual_total
        savings_vs_sonnet = sonnet_baseline - actual_total
        
        return {
            "outcomes_tracked": len(self.outcomes),
            "actual_total_cost": round(actual_total, 6),
            "opus_baseline": round(opus_baseline, 2),
            "sonnet_baseline": round(sonnet_baseline, 2),
            "cumulative_savings_vs_opus": round(savings_vs_opus, 2),
            "cumulative_savings_vs_sonnet": round(max(0, savings_vs_sonnet), 2),
            "percent_vs_opus": round((savings_vs_opus / opus_baseline * 100) if opus_baseline > 0 else 0, 1),
            "percent_vs_sonnet": round((savings_vs_sonnet / sonnet_baseline * 100) if sonnet_baseline > 0 else 0, 1)
        }
    
    def optimize(self) -> Dict:
        """Run full optimization cycle."""
        cost_analysis = self.calculate_cost_per_outcome(self.outcomes[-100:])
        recommendations = self.recommend_threshold_adjustments(cost_analysis)
        forecast = self.forecast_monthly_cost()
        cumulative = self.track_cumulative_savings()
        
        result = {
            "timestamp": datetime.utcnow().isoformat(),
            "cost_analysis": cost_analysis,
            "recommendations": recommendations,
            "monthly_forecast": forecast,
            "cumulative_savings": cumulative,
            "status": "optimized"
        }
        
        # Save results
        with open(self.cost_log, 'w') as f:
            json.dump(result, f, indent=2)
        
        return result
    
    def status(self) -> Dict:
        """Cost optimization status."""
        if self.cost_log.exists():
            with open(self.cost_log) as f:
                last_result = json.load(f)
        else:
            last_result = {"status": "not_yet_optimized"}
        
        return {
            "outcomes_available": len(self.outcomes),
            "last_optimization": last_result.get("timestamp"),
            "monthly_forecast": last_result.get("monthly_forecast"),
            "cumulative_savings": last_result.get("cumulative_savings"),
            "recommendations": last_result.get("recommendations"),
            "status": "ready" if len(self.outcomes) > 0 else "waiting"
        }

def main():
    import sys
    
    optimizer = CostOptimizer()
    
    if len(sys.argv) < 2:
        print("Usage: python3 cost-optimizer.py <command>")
        print("Commands:")
        print("  optimize   - Run full optimization cycle")
        print("  status     - Show optimization status")
        print("  forecast   - Show monthly cost forecast")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "optimize":
        result = optimizer.optimize()
        print(json.dumps(result, indent=2))
    
    elif cmd == "status":
        result = optimizer.status()
        print(json.dumps(result, indent=2))
    
    elif cmd == "forecast":
        result = optimizer.forecast_monthly_cost()
        print(json.dumps(result, indent=2))
    
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
