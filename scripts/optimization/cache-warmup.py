#!/usr/bin/env python3
"""
Phase 5: Pillar 1 — Cache Warmup (Python version)
"""
import json
import os
from datetime import datetime

print("\n" + "="*70)
print("PHASE 5: PILLAR 1 — CACHE WARMUP")
print("="*70 + "\n")

files = [
    "SOUL.md",
    "IDENTITY.md",
    "AGENTS.md",
    "MEMORY.md"
]

total_tokens = 0
total_size = 0

print("Loading context files...")
for fname in files:
    if os.path.exists(fname):
        with open(fname) as f:
            content = f.read()
            size = len(content)
            tokens = len(content.split()) * int(1.3)  # Rough estimate
            total_tokens += tokens
            total_size += size
            print(f"  ✓ {fname}: {tokens} tokens")
    else:
        print(f"  ✗ {fname}: Not found")

print(f"\n✅ Bundle ready: {total_tokens} tokens, {total_size} chars")

warmup = {
    "timestamp": datetime.now().isoformat(),
    "total_tokens": total_tokens,
    "total_size": total_size,
    "files": files,
    "status": "ready"
}

os.makedirs("data/metrics", exist_ok=True)
with open("data/metrics/cache-warmup-state.json", "w") as f:
    json.dump(warmup, f, indent=2)

print("✅ Saved warmup state\n" + "="*70 + "\n")
