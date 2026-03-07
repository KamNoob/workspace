#!/usr/bin/env python3

"""
Research Refresh Monitor
Parses RESEARCH_INDEX.md and identifies stale research needing updates
Usage: ./check-research-refresh.py [--json] [--stale-only]
"""

import re
import sys
from datetime import datetime, timedelta
from pathlib import Path

WORKSPACE = Path.home() / ".openclaw" / "workspace"
INDEX_FILE = WORKSPACE / "RESEARCH_INDEX.md"

def parse_research_index():
    """Parse RESEARCH_INDEX.md and extract all research entries"""
    
    if not INDEX_FILE.exists():
        print(f"❌ Research index not found: {INDEX_FILE}")
        sys.exit(1)
    
    content = INDEX_FILE.read_text()
    
    # Split by #### headers (research entries)
    entries = []
    current_entry = {}
    
    for line in content.split('\n'):
        # New research entry
        if line.startswith('####'):
            if current_entry:
                entries.append(current_entry)
            current_entry = {
                'title': line.replace('####', '').strip(),
                'file': None,
                'status': None,
                'created': None,
                'refresh_days': None,
                'next_refresh': None,
                'tags': []
            }
        
        # Parse fields
        elif '**File:**' in line:
            match = re.search(r'`([^`]+)`', line)
            if match:
                current_entry['file'] = match.group(1)
        
        elif '**Status:**' in line:
            current_entry['status'] = line.split('**Status:**')[1].strip()
        
        elif '**Created:**' in line:
            current_entry['created'] = line.split('**Created:**')[1].strip()
        
        elif '**Refresh:**' in line:
            match = re.search(r'(\d+) days \(next: ([\d-]+)\)', line)
            if match:
                current_entry['refresh_days'] = int(match.group(1))
                current_entry['next_refresh'] = match.group(2)
        
        elif '**Tags:**' in line:
            tags_str = line.split('**Tags:**')[1].strip()
            current_entry['tags'] = [t.strip() for t in tags_str.split(',')]
    
    # Add last entry
    if current_entry and current_entry.get('title'):
        entries.append(current_entry)
    
    return entries

def check_staleness(entries):
    """Check which research entries need refresh"""
    
    today = datetime.now().date()
    results = []
    
    for entry in entries:
        if not entry.get('next_refresh'):
            continue
        
        next_date = datetime.strptime(entry['next_refresh'], '%Y-%m-%d').date()
        days_until = (next_date - today).days
        
        status = 'fresh'
        if days_until < 0:
            status = 'overdue'
        elif days_until <= 7:
            status = 'due_soon'
        
        results.append({
            **entry,
            'days_until_refresh': days_until,
            'status_freshness': status
        })
    
    return results

def print_results(results, stale_only=False, json_output=False):
    """Print results in human-readable or JSON format"""
    
    if json_output:
        import json
        print(json.dumps(results, indent=2))
        return
    
    # Group by status
    overdue = [r for r in results if r['status_freshness'] == 'overdue']
    due_soon = [r for r in results if r['status_freshness'] == 'due_soon']
    fresh = [r for r in results if r['status_freshness'] == 'fresh']
    
    print("🔍 Research Refresh Status\n")
    print("=" * 80)
    
    if overdue:
        print(f"\n🔴 OVERDUE ({len(overdue)} entries)")
        for r in overdue:
            days_late = abs(r['days_until_refresh'])
            print(f"  ⚠️  {r['title']}")
            print(f"      File: {r['file']}")
            print(f"      Overdue by: {days_late} days (was due: {r['next_refresh']})")
            print(f"      Refresh cycle: {r['refresh_days']} days")
            print()
    
    if due_soon and not stale_only:
        print(f"\n🟡 DUE SOON ({len(due_soon)} entries)")
        for r in due_soon:
            print(f"  📅 {r['title']}")
            print(f"      File: {r['file']}")
            print(f"      Due in: {r['days_until_refresh']} days ({r['next_refresh']})")
            print()
    
    if fresh and not stale_only:
        print(f"\n🟢 FRESH ({len(fresh)} entries)")
        for r in fresh:
            print(f"  ✓ {r['title']}: {r['days_until_refresh']} days until refresh")
    
    print("\n" + "=" * 80)
    print(f"\n📊 Summary:")
    print(f"  Overdue: {len(overdue)}")
    print(f"  Due Soon (≤7 days): {len(due_soon)}")
    print(f"  Fresh: {len(fresh)}")
    print(f"  Total: {len(results)}")
    
    if overdue:
        print(f"\n💡 Next Steps:")
        print(f"  1. Review overdue research topics")
        print(f"  2. Trigger Scout to update: spawn Scout with research task")
        print(f"  3. Update RESEARCH_INDEX.md with new 'next' date")
        return 1  # Exit code 1 if stale research found
    
    return 0

def main():
    stale_only = '--stale-only' in sys.argv
    json_output = '--json' in sys.argv
    
    entries = parse_research_index()
    
    if not entries:
        print("⚠️  No research entries found in index")
        sys.exit(0)
    
    results = check_staleness(entries)
    exit_code = print_results(results, stale_only, json_output)
    sys.exit(exit_code)

if __name__ == '__main__':
    main()
