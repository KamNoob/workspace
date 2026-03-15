#!/usr/bin/env python3
"""
spawner-matrix-auto.py

Unified spawner that auto-routes to Phase 5-enhanced version.
All Phase 5 optimizations happen transparently.
"""

import subprocess
import json
import sys
import os

def spawn(task: str, candidates: list) -> dict:
    """Auto-spawn with Phase 5 optimizations."""
    
    # Call Phase 5 enhanced spawner
    cmd = [
        "julia",
        os.path.join(os.path.dirname(__file__), "spawner-matrix-phase5.jl"),
        "spawn",
        task
    ] + candidates
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            return {"error": result.stderr}
    except Exception as e:
        return {"error": str(e)}

def log_outcome(task: str, agent: str, success: bool) -> dict:
    """Log outcome and update Q-values."""
    
    cmd = [
        "julia",
        os.path.join(os.path.dirname(__file__), "spawner-matrix-phase5.jl"),
        "log",
        task,
        agent,
        "true" if success else "false"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            return {"error": result.stderr}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 spawner-matrix-auto.py spawn <task> <agent1> [<agent2> ...]")
        print("       python3 spawner-matrix-auto.py log <task> <agent> <success>")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "spawn":
        task = sys.argv[2]
        candidates = sys.argv[3:]
        result = spawn(task, candidates)
        print(json.dumps(result, indent=2))
        
        # Print Phase 5 status
        if result.get("phase5_enabled"):
            print("\n✅ Phase 5 optimizations active:")
            print(f"   Cache warmed: {result.get('phase5_cache_warmed')}")
            print(f"   Prompt loaded: {result.get('phase5_prompt_loaded')}")
    
    elif cmd == "log":
        task = sys.argv[2]
        agent = sys.argv[3]
        success = sys.argv[4] == "true"
        result = log_outcome(task, agent, success)
        print(json.dumps(result, indent=2))
    
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
