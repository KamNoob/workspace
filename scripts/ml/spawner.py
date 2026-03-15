#!/usr/bin/env python3
"""
spawner.py

PRODUCTION SPAWNER (Phase 6)

Default entry point for all spawn operations.
Integrates: Phase 5 (45%) + Phase 6A (15%) = 60% cost savings
Plus: Phase 6B quality improvements (anomaly detection, collaboration)
"""

import subprocess
import sys

def main():
    """Route to Phase 6 spawner."""
    result = subprocess.run(
        [sys.executable, "scripts/ml/spawner-phase6-deployed.py"] + sys.argv[1:],
        cwd="/home/art/.openclaw/workspace"
    )
    sys.exit(result.returncode)

if __name__ == "__main__":
    main()
