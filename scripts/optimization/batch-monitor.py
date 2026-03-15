#!/usr/bin/env python3
"""
Phase 5: Pillar 3 — Batch Monitor

Monitor batch efficiency and context reuse metrics.

Usage:
  python3 batch-monitor.py status
"""

import json
import os

def show_status():
    """Show batch monitoring status."""
    print("\n" + "="*70)
    print("BATCH MONITORING STATUS")
    print("="*70 + "\n")
    
    batch_file = "data/metrics/batch-efficiency.json"
    last_run_file = "data/metrics/batch-last-run.json"
    
    # Show overall statistics
    if os.path.exists(batch_file):
        with open(batch_file) as f:
            stats = json.load(f)
        
        print("📊 Overall Batch Statistics:")
        print(f"   Batches created: {stats.get('batches_created', 0)}")
        print(f"   Tasks processed: {stats.get('tasks_processed', 0)}")
        print(f"   Avg batch size: {stats.get('avg_batch_size', 0)}")
        print(f"   Tokens saved: {stats.get('tokens_saved', 0):,}")
        print(f"   Savings: {stats.get('savings_percent', 0)}%\n")
    else:
        print("📊 No batch data yet\n")
    
    # Show last run
    if os.path.exists(last_run_file):
        with open(last_run_file) as f:
            last = json.load(f)
        
        print("🔄 Last Batch Run:")
        print(f"   Task type: {last.get('task_type', 'unknown')}")
        print(f"   Agent: {last.get('agent', 'unknown')}")
        print(f"   Batch size: {last.get('batch_size', 0)}")
        print(f"   Context reuse: {last.get('context_reuse', 0):.1f}%")
        print(f"   Tokens saved: {last.get('tokens_saved', 0)}\n")
    
    print("="*70 + "\n")

if __name__ == "__main__":
    show_status()
