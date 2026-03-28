#!/usr/bin/env python3
"""
SQLite Integration Test Suite
Validates migration + adapter functionality
Created: 2026-03-28
"""

import unittest
import sqlite3
import json
import tempfile
from pathlib import Path
from datetime import datetime, timedelta
import sys

# Import adapters (import as-is, test will run these modules)
# Note: These are tested via instantiation below, not direct imports


class TestSQLiteSchema(unittest.TestCase):
    """Test database schema creation and integrity"""
    
    def setUp(self):
        """Create test database"""
        self.temp_db = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
        self.db_path = self.temp_db.name
        self.temp_db.close()
        
        # Create schema
        schema_path = Path(__file__).parent.parent.parent / 'data' / 'morpheus.db.schema.sql'
        with open(schema_path, 'r') as f:
            schema = f.read()
        
        conn = sqlite3.connect(self.db_path)
        conn.executescript(schema)
        conn.close()
    
    def tearDown(self):
        """Clean up test database"""
        Path(self.db_path).unlink()
    
    def test_tables_exist(self):
        """Verify all tables created"""
        conn = sqlite3.connect(self.db_path)
        tables = conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        ).fetchall()
        table_names = [t[0] for t in tables]
        
        expected = ['agents', 'vectors', 'agent_qscores', 'task_outcomes', 
                   'memory_state', 'audit_events', 'sla_metrics']
        
        for table in expected:
            self.assertIn(table, table_names, f"Missing table: {table}")
        
        conn.close()
    
    def test_agents_bootstrapped(self):
        """Verify agents initialized"""
        conn = sqlite3.connect(self.db_path)
        count = conn.execute("SELECT COUNT(*) FROM agents").fetchone()[0]
        self.assertEqual(count, 12, "Should have 12 agents bootstrapped")
        conn.close()
    
    def test_memory_state_initialized(self):
        """Verify memory_state singleton"""
        conn = sqlite3.connect(self.db_path)
        mem = conn.execute("SELECT * FROM memory_state WHERE id = 'singleton'").fetchone()
        self.assertIsNotNone(mem, "Memory state should be initialized")
        conn.close()
    
    def test_foreign_keys_enforced(self):
        """Verify foreign key constraints"""
        conn = sqlite3.connect(self.db_path)
        conn.execute("PRAGMA foreign_keys = ON")
        
        # Try to insert invalid agent_id
        with self.assertRaises(sqlite3.IntegrityError):
            conn.execute(
                "INSERT INTO agent_qscores (id, agent_id, task_type) VALUES (?, ?, ?)",
                ('test', 'nonexistent', 'code')
            )
        
        conn.close()
    
    def test_indexes_created(self):
        """Verify performance indexes"""
        conn = sqlite3.connect(self.db_path)
        indexes = conn.execute(
            "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'"
        ).fetchall()
        
        self.assertGreater(len(indexes), 10, "Should have at least 10 indexes")
        conn.close()


class TestPhase7BAdapter(unittest.TestCase):
    """Test Phase 7B SQLite adapter"""
    
    def setUp(self):
        """Create test database with data"""
        self.temp_db = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
        self.db_path = self.temp_db.name
        self.temp_db.close()
        
        # Initialize schema
        schema_path = Path(__file__).parent.parent.parent / 'data' / 'morpheus.db.schema.sql'
        with open(schema_path, 'r') as f:
            schema = f.read()
        
        conn = sqlite3.connect(self.db_path)
        conn.executescript(schema)
        
        # Insert test data
        conn.execute("""
            INSERT INTO agent_qscores (id, agent_id, task_type, q_value, visits, successes)
            VALUES (?, ?, ?, ?, ?, ?)
        """, ('qs_1', 'codex', 'code', 0.85, 10, 8))
        
        conn.execute("""
            INSERT INTO task_outcomes (id, task_id, agent_id, task_type, status, outcome_quality, 
                                     execution_time_ms, tokens_used, cost_usd, completed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, ('outcome_1', 'task_1', 'codex', 'code', 'success', 0.92, 1200, 850, 0.015,
              datetime.utcnow().isoformat()))
        
        conn.execute("""
            INSERT INTO audit_events (id, timestamp, event_type, agent_id, details, severity)
            VALUES (?, ?, ?, ?, ?, ?)
        """, ('audit_1', datetime.utcnow().isoformat(), 'task_spawn', 'codex', '{}', 'info'))
        
        conn.commit()
        conn.close()
    
    def tearDown(self):
        """Clean up"""
        Path(self.db_path).unlink()
    
    def test_adapter_initialization(self):
        """Test adapter creates connection"""
        # Import here to avoid circular dependency
        sys.path.insert(0, str(Path(__file__).parent))
        from phase7b_sqlite_adapter import Phase7BAdapter
        adapter = Phase7BAdapter(self.db_path)
        self.assertIsNotNone(adapter.conn)
        adapter.close()
    
    def test_get_agent_performance(self):
        """Test agent performance metrics"""
        from phase7b_sqlite_adapter import Phase7BAdapter
        adapter = Phase7BAdapter(self.db_path)
        metrics = adapter.get_agent_performance_metrics()
        
        self.assertIn('codex', metrics)
        self.assertEqual(metrics['codex']['total_tasks'], 1)
        self.assertEqual(metrics['codex']['successes'], 1)
        
        adapter.close()
    
    def test_get_qlearning_status(self):
        """Test Q-learning status"""
        from phase7b_sqlite_adapter import Phase7BAdapter
        adapter = Phase7BAdapter(self.db_path)
        status = adapter.get_qlearning_convergence_status()
        
        self.assertIn('top_scores', status)
        self.assertGreater(status['count'], 0)
        self.assertIsNotNone(status['avg_q'])
        
        adapter.close()
    
    def test_generate_insights(self):
        """Test insights report generation"""
        from phase7b_sqlite_adapter import Phase7BAdapter
        adapter = Phase7BAdapter(self.db_path)
        insights = adapter.generate_insights_report()
        
        expected_keys = ['timestamp', 'agent_performance', 'task_distribution',
                        'qlearning_status', 'sla_status', 'cost_analysis', 'memory_health']
        
        for key in expected_keys:
            self.assertIn(key, insights, f"Missing key: {key}")
        
        adapter.close()


class TestMemoryConsolidation(unittest.TestCase):
    """Test memory consolidation and cleanup"""
    
    def setUp(self):
        """Create test database"""
        self.temp_db = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
        self.db_path = self.temp_db.name
        self.temp_db.close()
        
        # Initialize schema
        schema_path = Path(__file__).parent.parent.parent / 'data' / 'morpheus.db.schema.sql'
        with open(schema_path, 'r') as f:
            schema = f.read()
        
        conn = sqlite3.connect(self.db_path)
        conn.executescript(schema)
        
        # Insert old vectors
        old_date = (datetime.utcnow() - timedelta(days=31)).isoformat()
        conn.execute("""
            INSERT INTO vectors (id, content, embedding, created_at)
            VALUES (?, ?, ?, ?)
        """, ('old_vec', 'test', b'dummy', old_date))
        
        # Insert old outcomes
        conn.execute("""
            INSERT INTO task_outcomes (id, task_id, agent_id, task_type, status, completed_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, ('old_outcome', 'task_1', 'codex', 'code', 'success', old_date))
        
        conn.commit()
        conn.close()
    
    def tearDown(self):
        """Clean up"""
        Path(self.db_path).unlink()
    
    def test_consolidation_dry_run(self):
        """Test consolidation dry-run"""
        from memory_consolidation import MemoryConsolidation
        consolidation = MemoryConsolidation(self.db_path)
        
        # Should not raise errors
        consolidation.run_consolidation(dry_run=True)
        
        # Verify data unchanged
        conn = sqlite3.connect(self.db_path)
        vectors = conn.execute("SELECT COUNT(*) FROM vectors").fetchone()[0]
        outcomes = conn.execute("SELECT COUNT(*) FROM task_outcomes").fetchone()[0]
        conn.close()
        
        self.assertEqual(vectors, 1, "Dry-run should not delete vectors")
        self.assertEqual(outcomes, 1, "Dry-run should not delete outcomes")
        
        consolidation.close()
    
    def test_consolidation_live(self):
        """Test consolidation with changes"""
        from memory_consolidation import MemoryConsolidation
        consolidation = MemoryConsolidation(self.db_path)
        
        # Run consolidation
        consolidation.run_consolidation(dry_run=False)
        
        # Verify old data removed
        conn = sqlite3.connect(self.db_path)
        vectors = conn.execute("SELECT COUNT(*) FROM vectors").fetchone()[0]
        outcomes = conn.execute("SELECT COUNT(*) FROM task_outcomes").fetchone()[0]
        conn.close()
        
        self.assertEqual(vectors, 0, "Old vectors should be deleted")
        self.assertEqual(outcomes, 0, "Old outcomes should be archived")
        
        consolidation.close()


def run_tests():
    """Run all tests with detailed output"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test suites
    suite.addTests(loader.loadTestsFromTestCase(TestSQLiteSchema))
    suite.addTests(loader.loadTestsFromTestCase(TestPhase7BAdapter))
    suite.addTests(loader.loadTestsFromTestCase(TestMemoryConsolidation))
    
    # Run with verbose output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Tests run: {result.testsRun}")
    print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    
    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    exit(run_tests())
