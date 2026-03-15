#!/usr/bin/env python3
"""
Phase 5: Pillar 3 — Task Batcher

Groups similar tasks together for batch processing.
Reuses agent context across multiple tasks to save tokens.

Usage:
  python3 task-batcher.py --queue /path/to/tasks.jsonl --batch-size 4
  python3 task-batcher.py --status
"""

import json
import os
import sys
from datetime import datetime
from typing import List, Dict
import argparse

def detect_task_type(task: Dict) -> str:
    """Detect task type from description."""
    desc = task.get("description", "").lower()
    task_name = task.get("task", "").lower()
    
    # Keywords for each type
    keywords = {
        "code": ["code", "develop", "implement", "debug", "refactor", "function", "class"],
        "research": ["research", "analyze", "study", "investigate", "find", "paper", "article"],
        "security": ["security", "audit", "threat", "vulnerability", "penetration", "attack"],
        "documentation": ["document", "guide", "write", "spec", "api", "readme"],
        "testing": ["test", "qa", "validate", "check", "verify", "benchmark"],
        "infrastructure": ["infra", "deploy", "devops", "ci", "cd", "docker", "kubernetes"],
    }
    
    text = f"{desc} {task_name}"
    
    # Find best match
    scores = {}
    for task_type, words in keywords.items():
        score = sum(1 for word in words if word in text)
        scores[task_type] = score
    
    if max(scores.values()) > 0:
        return max(scores, key=scores.get)
    return "general"

def group_tasks_by_type(tasks: List[Dict]) -> Dict[str, List[Dict]]:
    """Group tasks by type."""
    groups = {}
    for task in tasks:
        task_type = detect_task_type(task)
        if task_type not in groups:
            groups[task_type] = []
        groups[task_type].append(task)
    return groups

def create_batches(tasks: List[Dict], batch_size: int = 4) -> List[List[Dict]]:
    """Create batches of similar tasks."""
    groups = group_tasks_by_type(tasks)
    batches = []
    
    for task_type, task_list in groups.items():
        # Split into batches of batch_size
        for i in range(0, len(task_list), batch_size):
            batch = task_list[i:i+batch_size]
            batches.append(batch)
    
    return batches

def calculate_savings(batches: List[List[Dict]], context_per_task: int = 5500) -> Dict:
    """Calculate token savings from batching."""
    total_tasks = sum(len(batch) for batch in batches)
    total_batches = len(batches)
    avg_batch_size = total_tasks / total_batches if total_batches > 0 else 0
    
    # Each batch pays context cost once, then amortizes across tasks
    tokens_serial = total_tasks * context_per_task
    tokens_batched = total_batches * context_per_task + (total_tasks * 100)  # 100 tokens per task for routing
    
    savings_tokens = tokens_serial - tokens_batched
    savings_percent = (savings_tokens / tokens_serial * 100) if tokens_serial > 0 else 0
    
    return {
        "total_tasks": total_tasks,
        "total_batches": total_batches,
        "avg_batch_size": round(avg_batch_size, 2),
        "tokens_serial": tokens_serial,
        "tokens_batched": tokens_batched,
        "tokens_saved": int(savings_tokens),
        "savings_percent": round(savings_percent, 1)
    }

def show_status():
    """Show current batching status."""
    batch_file = "data/metrics/batch-efficiency.json"
    
    if not os.path.exists(batch_file):
        metrics = {
            "batches_created": 0,
            "tasks_processed": 0,
            "tokens_saved": 0,
            "status": "initialized"
        }
    else:
        with open(batch_file) as f:
            metrics = json.load(f)
    
    print("\n" + "="*70)
    print("TASK BATCHER STATUS")
    print("="*70 + "\n")
    
    print("📊 Batching Metrics:")
    print(f"   Batches created: {metrics.get('batches_created', 0)}")
    print(f"   Tasks processed: {metrics.get('tasks_processed', 0)}")
    print(f"   Tokens saved: {metrics.get('tokens_saved', 0):,}")
    print(f"   Status: {metrics.get('status', 'unknown')}\n")
    
    print("="*70 + "\n")

def main():
    parser = argparse.ArgumentParser(description="Task batcher for Phase 5 optimization")
    parser.add_argument("--queue", help="Path to task queue (JSONL)")
    parser.add_argument("--batch-size", type=int, default=4, help="Tasks per batch")
    parser.add_argument("--status", action="store_true", help="Show status")
    
    args = parser.parse_args()
    
    if args.status:
        show_status()
        return
    
    if not args.queue:
        print("Error: Provide --queue or --status")
        sys.exit(1)
    
    # Load tasks
    if not os.path.exists(args.queue):
        print(f"Error: Queue file not found: {args.queue}")
        sys.exit(1)
    
    tasks = []
    with open(args.queue) as f:
        for line in f:
            if line.strip():
                tasks.append(json.loads(line))
    
    print("\n" + "="*70)
    print("TASK BATCHER")
    print("="*70 + "\n")
    
    print(f"Loaded {len(tasks)} tasks")
    print(f"Batch size: {args.batch_size}\n")
    
    # Create batches
    batches = create_batches(tasks, args.batch_size)
    
    # Calculate savings
    savings = calculate_savings(batches, context_per_task=5500)
    
    print("📊 Batching Results:")
    print(f"   Batches: {savings['total_batches']}")
    print(f"   Avg batch size: {savings['avg_batch_size']}")
    print(f"   Tokens saved: {savings['tokens_saved']:,}")
    print(f"   Savings: {savings['savings_percent']}%\n")
    
    # Save metrics
    os.makedirs("data/metrics", exist_ok=True)
    metrics = {
        "timestamp": datetime.now().isoformat(),
        "batches_created": savings['total_batches'],
        "tasks_processed": savings['total_tasks'],
        "avg_batch_size": savings['avg_batch_size'],
        "tokens_saved": savings['tokens_saved'],
        "savings_percent": savings['savings_percent'],
        "status": "complete"
    }
    
    with open("data/metrics/batch-efficiency.json", "w") as f:
        json.dump(metrics, f, indent=2)
    
    print("✅ Metrics saved: data/metrics/batch-efficiency.json\n")
    print("="*70 + "\n")

if __name__ == "__main__":
    main()
