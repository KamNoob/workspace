#!/usr/bin/env python3
"""
Task Validator: Ensures task definitions match agent specialization
Prevents routing mismatches that cause low performance
"""

import json
import re
from pathlib import Path
from collections import defaultdict

def analyze_task_log(log_path, sample_size=100):
    """Analyze recent tasks to validate routing alignment"""
    
    tasks = []
    with open(log_path) as f:
        for line in f:
            if line.strip():
                tasks.append(json.loads(line))
    
    # Use recent tasks
    tasks = tasks[-sample_size:]
    
    print("=== TASK VALIDATION ===\n")
    print(f"Analyzing {len(tasks)} recent tasks\n")
    
    # Group by agent + task type + success
    by_agent = defaultdict(lambda: {"success": [], "failed": []})
    
    for task in tasks:
        agent = task.get("agent", "unknown")
        task_type = task.get("task", "unknown")
        success = task.get("success", False)
        
        entry = {
            "task": task_type,
            "success": success,
            "agent": agent,
            "timestamp": task.get("timestamp", "unknown")
        }
        
        if success:
            by_agent[agent]["success"].append(entry)
        else:
            by_agent[agent]["failed"].append(entry)
    
    # Validate agent specialization
    specializations = {
        "Scout": ["research", "analysis", "discovery"],
        "Codex": ["code", "coding", "implementation", "debug", "compile"],
        "Cipher": ["security", "audit", "vulnerability", "threat"],
        "Veritas": ["review", "validation", "testing", "quality", "check"],
        "QA": ["test", "testing", "unit", "integration", "edge case"],
        "Chronicle": ["documentation", "write", "document", "guide"],
        "Sentinel": ["infrastructure", "deploy", "devops", "config"],
        "Prism": ["responsive", "mobile", "css", "ui", "style"],
        "Echo": ["brainstorm", "ideation", "creative", "concept"],
    }
    
    issues = []
    
    print("Agent-Task Alignment:\n")
    for agent in sorted(by_agent.keys()):
        data = by_agent[agent]
        total = len(data["success"]) + len(data["failed"])
        success_rate = len(data["success"]) / total if total > 0 else 0
        
        # Get specialization
        spec = specializations.get(agent, [])
        
        # Check if failed tasks match specialization
        failed_tasks = [t["task"] for t in data["failed"]]
        
        mismatches = []
        for failed_task in failed_tasks:
            # Simple keyword matching
            if not any(kw in failed_task.lower() for kw in spec):
                mismatches.append(failed_task)
        
        # Status indicator
        if success_rate >= 0.75:
            status = "✅"
        elif success_rate >= 0.50:
            status = "🟡"
        else:
            status = "❌"
        
        print(f"{status} {agent:12} {success_rate:.0%}  ({len(data['success'])}/{total})")
        
        # Show specialization
        if spec:
            print(f"   Specializes: {', '.join(spec[:3])}")
        
        # Show mismatches
        if mismatches:
            issues.append((agent, mismatches))
            print(f"   ⚠️  Mismatched tasks: {mismatches[:2]}")
        
        print()
    
    # Summary
    print("\n=== VALIDATION SUMMARY ===\n")
    
    if not issues:
        print("✅ All agents appear well-aligned to their specialization")
        return True
    else:
        print(f"⚠️  {len(issues)} agent(s) showing misalignment:\n")
        for agent, mismatches in issues:
            print(f"  • {agent}: {', '.join(mismatches[:3])}")
            print(f"    Action: Review spawner routing for '{agent}'")
        
        return False

def recommend_fixes():
    """Suggest fixes for misaligned routing"""
    print("\n=== RECOMMENDATIONS ===\n")
    print("To stabilize task-agent alignment:")
    print("  1. Review task definitions in spawner-matrix.jl")
    print("  2. Verify task keywords match agent specialization")
    print("  3. For new task types: test with 5 easy examples first")
    print("  4. Use phase7b-learnings.json to see which agents actually succeed")
    print("  5. Update routing config if pattern shows consistent mismatch\n")

if __name__ == "__main__":
    log_path = Path("data/rl/rl-task-execution-log.jsonl")
    
    if log_path.exists():
        success = analyze_task_log(str(log_path))
        recommend_fixes()
    else:
        print(f"❌ Task log not found: {log_path}")
