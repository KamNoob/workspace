#!/usr/bin/env python3
"""
Legacy Outcome Ingestion Pipeline
Extracts outcomes from audit logs + workflow logs, feeds into RL training.
Target: Add 60+ data points to RL agent selection convergence.
"""

import json
import sys
from pathlib import Path
from datetime import datetime
from collections import defaultdict

# Workspace paths
WORKSPACE = Path.home() / ".openclaw" / "workspace"
AUDIT_LOG_DIR = WORKSPACE / "data" / "audit-logs"
WORKFLOW_LOG = WORKSPACE / "data" / "logs" / "workflow-execution-log.jsonl"
RL_TASK_LOG = WORKSPACE / "data" / "rl" / "rl-task-execution-log.jsonl"
OUTPUT_FILE = WORKSPACE / "data" / "rl" / "rl-legacy-outcomes.jsonl"

# Task type mapping from workflow names
WORKFLOW_TASK_MAP = {
    "Chain_A_Knowledge_Pipeline": "research",
    "Chain_B_Code_Development": "code",
    "Chain_C_Audit": "security",
    "Chain_D_Validation": "review",
}

# Default agent for workflow (when not in audit logs)
WORKFLOW_AGENT_DEFAULT = {
    "research": "Scout",
    "code": "Codex",
    "security": "Cipher",
    "review": "Veritas",
}


def ingest_audit_logs():
    """Extract task outcomes from audit logs."""
    outcomes = []
    
    for log_file in sorted(AUDIT_LOG_DIR.glob("*.jsonl")):
        try:
            with open(log_file) as f:
                for line in f:
                    if not line.strip():
                        continue
                    record = json.loads(line)
                    
                    # Only include records with agent + success signal
                    if record.get("agent") and "success" in record:
                        outcomes.append({
                            "timestamp": record.get("timestamp"),
                            "agent": record["agent"],
                            "task_type": record.get("task_type", "unknown"),
                            "success": record["success"],
                            "source": "audit-log",
                        })
        except Exception as e:
            print(f"⚠️  Error reading {log_file}: {e}")
    
    return outcomes


def ingest_workflow_logs():
    """Extract task outcomes from workflow execution logs."""
    outcomes = []
    
    try:
        with open(WORKFLOW_LOG) as f:
            for line in f:
                if not line.strip():
                    continue
                record = json.loads(line)
                
                flow_name = record.get("flow_name", "")
                task_type = WORKFLOW_TASK_MAP.get(flow_name, "unknown")
                agent = WORKFLOW_AGENT_DEFAULT.get(task_type, "Unknown")
                
                outcomes.append({
                    "timestamp": record.get("timestamp"),
                    "agent": agent,
                    "task_type": task_type,
                    "success": record.get("success", False),
                    "duration_minutes": record.get("time_minutes"),
                    "source": "workflow-log",
                })
    except FileNotFoundError:
        print(f"⚠️  Workflow log not found: {WORKFLOW_LOG}")
    except Exception as e:
        print(f"⚠️  Error reading workflow logs: {e}")
    
    return outcomes


def dedup_with_existing(new_outcomes):
    """Remove outcomes already in RL task log."""
    existing_timestamps = set()
    
    try:
        with open(RL_TASK_LOG) as f:
            for line in f:
                if line.strip():
                    record = json.loads(line)
                    existing_timestamps.add(record.get("timestamp"))
    except FileNotFoundError:
        pass
    
    filtered = [o for o in new_outcomes if o["timestamp"] not in existing_timestamps]
    return filtered, len(new_outcomes) - len(filtered)


def write_outcomes(outcomes):
    """Append outcomes to RL legacy outcomes file."""
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    with open(OUTPUT_FILE, "a") as f:
        for outcome in outcomes:
            f.write(json.dumps(outcome) + "\n")
    
    return len(outcomes)


def main():
    print("\n" + "="*70)
    print("🔄 LEGACY OUTCOME INGESTION PIPELINE")
    print("="*70)
    
    # 1. Extract outcomes
    print("\n📥 Extracting outcomes...")
    audit_outcomes = ingest_audit_logs()
    print(f"   Audit logs: {len(audit_outcomes)} outcomes")
    
    workflow_outcomes = ingest_workflow_logs()
    print(f"   Workflow logs: {len(workflow_outcomes)} outcomes")
    
    all_outcomes = audit_outcomes + workflow_outcomes
    print(f"   Total: {len(all_outcomes)} outcomes")
    
    # 2. Deduplicate
    print("\n🔍 Deduplicating...")
    unique_outcomes, dupes = dedup_with_existing(all_outcomes)
    print(f"   Duplicates removed: {dupes}")
    print(f"   Unique outcomes: {len(unique_outcomes)}")
    
    # 3. Write
    if unique_outcomes:
        print("\n✍️  Writing to RL legacy outcomes...")
        written = write_outcomes(unique_outcomes)
        print(f"   Written: {written} records to {OUTPUT_FILE.name}")
    else:
        print("\n⚠️  No new outcomes to ingest.")
    
    # 4. Summary
    print("\n📊 SUMMARY")
    print("-"*70)
    agent_counts = defaultdict(int)
    task_counts = defaultdict(int)
    success_counts = defaultdict(int)
    
    for o in unique_outcomes:
        agent_counts[o["agent"]] += 1
        task_counts[o["task_type"]] += 1
        if o["success"]:
            success_counts[f"{o['agent']}:{o['task_type']}"] += 1
    
    print("\nBy Agent:")
    for agent in sorted(agent_counts.keys()):
        count = agent_counts[agent]
        print(f"  {agent}: {count}")
    
    print("\nBy Task Type:")
    for task in sorted(task_counts.keys()):
        count = task_counts[task]
        print(f"  {task}: {count}")
    
    print("\nSuccess Rate (agent:task):")
    for pair in sorted(success_counts.keys()):
        count = success_counts[pair]
        total = sum(1 for o in unique_outcomes if f"{o['agent']}:{o['task_type']}" == pair)
        rate = (count / total * 100) if total > 0 else 0
        print(f"  {pair}: {count}/{total} ({rate:.1f}%)")
    
    print("\n" + "="*70)
    if unique_outcomes:
        print(f"✅ Ingestion complete: {len(unique_outcomes)} new outcomes added to RL pipeline")
    else:
        print("✅ Ingestion complete: No new outcomes to process")
    print("="*70 + "\n")


if __name__ == "__main__":
    main()
