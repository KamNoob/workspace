#!/usr/bin/env python3
"""
Phase 7B SQLite Adapter
Replaces JSON file I/O with SQLite queries
Purpose: Phase 7B insights generation with database backend
Created: 2026-03-28
"""

import sqlite3
import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Tuple

class Phase7BAdapter:
    """Adapter for Phase 7B Insights Generator with SQLite backend"""
    
    def __init__(self, db_path: str = None):
        if db_path is None:
            db_path = Path(__file__).parent.parent.parent / 'data' / 'morpheus.db'
        
        self.db_path = db_path
        self.conn = sqlite3.connect(str(db_path))
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("PRAGMA foreign_keys = ON")
    
    def get_task_outcomes_since(self, hours: int = 24) -> List[Dict]:
        """Get task outcomes from last N hours"""
        cutoff = datetime.utcnow() - timedelta(hours=hours)
        
        rows = self.conn.execute("""
            SELECT 
                id, agent_id, task_type, status, outcome_quality,
                execution_time_ms, tokens_used, cost_usd, completed_at
            FROM task_outcomes
            WHERE completed_at > ? AND status IS NOT NULL
            ORDER BY completed_at DESC
        """, (cutoff.isoformat(),)).fetchall()
        
        return [dict(row) for row in rows]
    
    def get_agent_performance_metrics(self) -> Dict[str, Dict]:
        """Get per-agent performance summary"""
        rows = self.conn.execute("""
            SELECT 
                a.id, a.name, a.role,
                COUNT(o.id) as total_tasks,
                SUM(CASE WHEN o.status = 'success' THEN 1 ELSE 0 END) as successes,
                SUM(CASE WHEN o.status = 'failure' THEN 1 ELSE 0 END) as failures,
                AVG(o.outcome_quality) as avg_quality,
                SUM(o.cost_usd) as total_cost
            FROM agents a
            LEFT JOIN task_outcomes o ON a.id = o.agent_id
            GROUP BY a.id, a.name, a.role
        """).fetchall()
        
        metrics = {}
        for row in rows:
            row_dict = dict(row)
            agent_id = row_dict.pop('id')
            metrics[agent_id] = row_dict
        
        return metrics
    
    def get_task_type_distribution(self) -> Dict[str, int]:
        """Get distribution of task types executed"""
        rows = self.conn.execute("""
            SELECT task_type, COUNT(*) as count
            FROM task_outcomes
            WHERE completed_at > datetime('now', '-7 days')
            GROUP BY task_type
            ORDER BY count DESC
        """).fetchall()
        
        return {row['task_type']: row['count'] for row in rows}
    
    def get_qlearning_convergence_status(self) -> Dict:
        """Check Q-learning convergence metrics"""
        rows = self.conn.execute("""
            SELECT 
                agent_id, task_type, q_value, confidence,
                visits, successes, failures
            FROM agent_qscores
            WHERE q_value > 0.5
            ORDER BY q_value DESC
            LIMIT 20
        """).fetchall()
        
        return {
            'top_scores': [dict(row) for row in rows],
            'count': len(rows),
            'avg_q': self.conn.execute(
                "SELECT AVG(q_value) as avg FROM agent_qscores"
            ).fetchone()['avg']
        }
    
    def get_sla_status(self) -> Dict:
        """Get latest SLA metrics"""
        row = self.conn.execute("""
            SELECT * FROM sla_metrics
            ORDER BY metric_date DESC
            LIMIT 1
        """).fetchone()
        
        if row:
            return dict(row)
        return {}
    
    def get_cost_analysis(self, days: int = 7) -> Dict:
        """Analyze cost trends over last N days"""
        cutoff = datetime.utcnow() - timedelta(days=days)
        
        rows = self.conn.execute("""
            SELECT 
                DATE(completed_at) as date,
                COUNT(*) as task_count,
                SUM(cost_usd) as total_cost,
                AVG(cost_usd) as avg_cost,
                SUM(tokens_used) as total_tokens
            FROM task_outcomes
            WHERE completed_at > ? AND status = 'success'
            GROUP BY DATE(completed_at)
            ORDER BY date DESC
        """, (cutoff.isoformat(),)).fetchall()
        
        return {
            'daily_breakdown': [dict(row) for row in rows],
            'total_cost': sum(row['total_cost'] or 0 for row in rows),
            'avg_daily_cost': sum(row['total_cost'] or 0 for row in rows) / max(len(rows), 1)
        }
    
    def get_memory_insights(self) -> Dict:
        """Get memory system health metrics"""
        mem = self.conn.execute("SELECT * FROM memory_state WHERE id = 'singleton'").fetchone()
        
        if mem:
            mem_dict = dict(mem)
            recall_rate = 0
            if mem_dict['total_recalls'] > 0:
                recall_rate = mem_dict['successful_recalls'] / mem_dict['total_recalls']
            
            mem_dict['recall_rate'] = recall_rate
            return mem_dict
        
        return {}
    
    def log_phase7b_insights(self, insights: Dict) -> None:
        """Log Phase 7B insights output to audit events"""
        self.conn.execute("""
            INSERT INTO audit_events
            (id, timestamp, event_type, details, severity)
            VALUES (?, ?, ?, ?, ?)
        """, (
            f"insights_{int(datetime.utcnow().timestamp())}",
            datetime.utcnow().isoformat(),
            'phase7b_insights',
            json.dumps(insights),
            'info'
        ))
        self.conn.commit()
    
    def generate_insights_report(self) -> Dict:
        """Generate comprehensive Phase 7B insights report"""
        insights = {
            'timestamp': datetime.utcnow().isoformat(),
            'agent_performance': self.get_agent_performance_metrics(),
            'task_distribution': self.get_task_type_distribution(),
            'qlearning_status': self.get_qlearning_convergence_status(),
            'sla_status': self.get_sla_status(),
            'cost_analysis': self.get_cost_analysis(),
            'memory_health': self.get_memory_insights()
        }
        
        # Log to audit trail
        self.log_phase7b_insights(insights)
        
        return insights
    
    def close(self):
        """Close database connection"""
        self.conn.close()
    
    def __enter__(self):
        return self
    
    def __exit__(self, *args):
        self.close()


def main():
    """Generate Phase 7B insights and print report"""
    import pprint
    
    with Phase7BAdapter() as adapter:
        insights = adapter.generate_insights_report()
        
        print("\n" + "=" * 70)
        print("PHASE 7B INSIGHTS REPORT")
        print("=" * 70)
        print(f"Generated: {insights['timestamp']}\n")
        
        print("AGENT PERFORMANCE:")
        for agent_id, metrics in insights['agent_performance'].items():
            if metrics['total_tasks'] > 0:
                success_rate = metrics['successes'] / metrics['total_tasks'] * 100
                print(f"  {metrics['name']:<15} | Tasks: {metrics['total_tasks']:>3} | "
                      f"Success: {success_rate:>5.1f}% | Quality: {metrics['avg_quality']:.2f} | "
                      f"Cost: ${metrics['total_cost']:.2f}")
        
        print("\nTASK DISTRIBUTION:")
        for task_type, count in insights['task_distribution'].items():
            print(f"  {task_type:<20} | {count:>3} tasks")
        
        print("\nQ-LEARNING STATUS:")
        ql = insights['qlearning_status']
        print(f"  Top performing agent-task pairs: {ql['count']}")
        print(f"  Average Q-value: {ql['avg_q']:.3f}")
        
        print("\nCOST ANALYSIS (7d):")
        ca = insights['cost_analysis']
        print(f"  Total cost: ${ca['total_cost']:.2f}")
        print(f"  Daily average: ${ca['avg_daily_cost']:.2f}")
        
        print("\nMEMORY HEALTH:")
        mh = insights['memory_health']
        if mh:
            print(f"  Recall rate: {mh['recall_rate']:.1%}")
            print(f"  Avg lookup: {mh['avg_lookup_time_ms']:.1f}ms")
            print(f"  Status: {mh['consolidation_status']}")
        
        print("\n" + "=" * 70)

if __name__ == '__main__':
    main()
