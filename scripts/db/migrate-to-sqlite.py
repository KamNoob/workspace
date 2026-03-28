#!/usr/bin/env python3
"""
Migration Script: JSON → SQLite
Morpheus AI System Database Migration
Purpose: Migrate existing JSON files to SQLite schema V3
Created: 2026-03-28
"""

import sqlite3
import json
import os
import sys
from pathlib import Path
from datetime import datetime
import struct
import hashlib
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

WORKSPACE_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = WORKSPACE_ROOT / 'data'
DB_PATH = DATA_DIR / 'morpheus.db'
SCHEMA_PATH = DATA_DIR / 'morpheus.db.schema.sql'

class MorpheusDBMigration:
    def __init__(self, db_path, dry_run=False):
        self.db_path = db_path
        self.dry_run = dry_run
        self.stats = {
            'vectors_migrated': 0,
            'qscores_migrated': 0,
            'outcomes_migrated': 0,
            'audit_events_migrated': 0,
            'errors': 0
        }
    
    def connect(self):
        """Connect to SQLite database"""
        if self.db_path.exists():
            logger.warning(f"Database exists: {self.db_path}")
            if not self.dry_run:
                response = input("Overwrite? (y/n): ")
                if response.lower() != 'y':
                    logger.info("Migration cancelled")
                    sys.exit(0)
        
        self.conn = sqlite3.connect(str(self.db_path))
        self.conn.execute("PRAGMA foreign_keys = ON")
        logger.info(f"Connected to {self.db_path}")
    
    def init_schema(self):
        """Initialize schema from SQL file"""
        if not SCHEMA_PATH.exists():
            logger.error(f"Schema file not found: {SCHEMA_PATH}")
            sys.exit(1)
        
        with open(SCHEMA_PATH, 'r') as f:
            schema = f.read()
        
        if not self.dry_run:
            self.conn.executescript(schema)
            self.conn.commit()
            logger.info("Schema initialized")
        else:
            logger.info("[DRY RUN] Schema initialization skipped")
    
    def migrate_memory_optimizer(self):
        """Migrate .memory-optimizer-state.json → memory_state table"""
        state_file = WORKSPACE_ROOT / '.memory-optimizer-state.json'
        if not state_file.exists():
            logger.warning(f"Memory state file not found: {state_file}")
            return
        
        try:
            with open(state_file, 'r') as f:
                data = json.load(f)
            
            stats = data.get('stats', {})
            metadata = data.get('metadata', {})
            
            if not self.dry_run:
                self.conn.execute("""
                    UPDATE memory_state SET
                        total_recalls = ?,
                        successful_recalls = ?,
                        total_stores = ?,
                        failed_stores = ?,
                        consolidation_runs = ?,
                        avg_lookup_time_ms = ?,
                        last_consolidation = ?,
                        learning_phase = ?,
                        consolidation_status = ?
                    WHERE id = 'singleton'
                """, (
                    stats.get('total_recalls', 0),
                    stats.get('successful_recalls', 0),
                    stats.get('total_stores', 0),
                    stats.get('failed_stores', 0),
                    stats.get('consolidation_runs', 0),
                    stats.get('avg_lookup_time', 0.0),
                    metadata.get('last_consolidation'),
                    metadata.get('learning_phase', 'exploitation'),
                    metadata.get('consolidation_status', 'optimal')
                ))
                self.conn.commit()
            
            logger.info(f"Migrated memory state (recalls: {stats.get('total_recalls', 0)})")
        except Exception as e:
            logger.error(f"Failed to migrate memory state: {e}")
            self.stats['errors'] += 1
    
    def migrate_qscores(self):
        """Migrate rl-agent-selection.json → agent_qscores table"""
        qscores_file = WORKSPACE_ROOT / 'data' / 'rl' / 'rl-agent-selection.json'
        if not qscores_file.exists():
            logger.warning(f"Q-scores file not found: {qscores_file}")
            return
        
        try:
            with open(qscores_file, 'r') as f:
                data = json.load(f)
            
            # Build agent name → id mapping
            agent_map = {}
            agent_rows = self.conn.execute("SELECT id, name FROM agents").fetchall()
            for row in agent_rows:
                agent_map[row[1]] = row[0]  # name -> id
            
            task_types = data.get('task_types', {})
            count = 0
            
            if not self.dry_run:
                for task_type, task_data in task_types.items():
                    if not isinstance(task_data, dict):
                        continue
                    agents = task_data.get('agents', {})
                    if not isinstance(agents, dict):
                        continue
                    
                    for agent_name, q_value in agents.items():
                        # Map agent name from file to agent ID in DB
                        agent_id = agent_map.get(agent_name)
                        if not agent_id:
                            logger.debug(f"Agent not found in DB: {agent_name}")
                            continue
                        # Handle both float and dict values
                        if isinstance(q_value, dict):
                            q_val = q_value.get('q_score', q_value.get('q_value', 0.5))
                            visits = q_value.get('total_uses', 0)
                            successes = q_value.get('success_count', 0)
                            failures = q_value.get('failure_count', 0)
                        else:
                            q_val = float(q_value) if q_value is not None else 0.5
                            visits = 0
                            successes = 0
                            failures = 0
                        
                        score_id = f"{agent_id}_{task_type}_{int(datetime.now().timestamp())}_{hash(str(q_val)) % 1000}"
                        try:
                            self.conn.execute("""
                                INSERT INTO agent_qscores 
                                (id, agent_id, task_type, q_value, visits, successes, failures, avg_outcome_quality)
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                            """, (score_id, agent_id, task_type, q_val, visits, successes, failures, q_val))
                            count += 1
                        except (sqlite3.IntegrityError, ValueError) as ex:
                            logger.debug(f"Skipped {agent_name}/{task_type}: {ex}")
                
                self.conn.commit()
            else:
                for task_type, task_data in task_types.items():
                    if isinstance(task_data, dict):
                        count += len(task_data.get('agents', {}))
            
            self.stats['qscores_migrated'] = count
            logger.info(f"Migrated Q-scores ({count} agent-task pairs)")
        except Exception as e:
            logger.error(f"Failed to migrate Q-scores: {e}")
            self.stats['errors'] += 1
    
    def migrate_task_outcomes(self):
        """Migrate rl-task-execution-log.jsonl → task_outcomes table"""
        outcomes_file = WORKSPACE_ROOT / 'data' / 'rl' / 'rl-task-execution-log.jsonl'
        if not outcomes_file.exists():
            logger.warning(f"Task outcomes file not found: {outcomes_file}")
            return
        
        try:
            count = 0
            with open(outcomes_file, 'r') as f:
                for line in f:
                    if not line.strip():
                        continue
                    outcome = json.loads(line)
                    
                    if not self.dry_run:
                        try:
                            self.conn.execute("""
                                INSERT INTO task_outcomes 
                                (id, task_id, agent_id, task_type, status, outcome_quality, 
                                 execution_time_ms, tokens_used, cost_usd, completed_at, metadata)
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                            """, (
                                outcome.get('id', f"task_{int(datetime.now().timestamp())}"),
                                outcome.get('task_id', ''),
                                outcome.get('agent_id', ''),
                                outcome.get('task_type', ''),
                                outcome.get('status', 'unknown'),
                                outcome.get('quality', 0.5),
                                outcome.get('execution_time_ms', 0),
                                outcome.get('tokens_used', 0),
                                outcome.get('cost_usd', 0.0),
                                outcome.get('completed_at'),
                                json.dumps(outcome)
                            ))
                            count += 1
                        except sqlite3.IntegrityError:
                            pass
            
            if not self.dry_run:
                self.conn.commit()
            
            self.stats['outcomes_migrated'] = count
            logger.info(f"Migrated task outcomes ({count} records)")
        except Exception as e:
            logger.error(f"Failed to migrate task outcomes: {e}")
            self.stats['errors'] += 1
    
    def migrate_audit_logs(self):
        """Migrate audit logs (JSONL) → audit_events table"""
        audit_dir = WORKSPACE_ROOT / 'data' / 'audit-logs'
        if not audit_dir.exists():
            logger.warning(f"Audit logs directory not found: {audit_dir}")
            return
        
        try:
            count = 0
            for audit_file in sorted(audit_dir.glob('*.jsonl')):
                with open(audit_file, 'r') as f:
                    for line in f:
                        if not line.strip():
                            continue
                        event = json.loads(line)
                        
                        if not self.dry_run:
                            try:
                                self.conn.execute("""
                                    INSERT INTO audit_events
                                    (id, timestamp, event_type, agent_id, task_id, details, severity)
                                    VALUES (?, ?, ?, ?, ?, ?, ?)
                                """, (
                                    event.get('id', f"audit_{int(datetime.now().timestamp())}"),
                                    event.get('timestamp'),
                                    event.get('event_type', 'unknown'),
                                    event.get('agent_id'),
                                    event.get('task_id'),
                                    json.dumps(event.get('details', {})),
                                    event.get('severity', 'info')
                                ))
                                count += 1
                            except sqlite3.IntegrityError:
                                pass
            
            if not self.dry_run:
                self.conn.commit()
            
            self.stats['audit_events_migrated'] = count
            logger.info(f"Migrated audit events ({count} events)")
        except Exception as e:
            logger.error(f"Failed to migrate audit logs: {e}")
            self.stats['errors'] += 1
    
    def run(self):
        """Execute full migration"""
        try:
            if self.dry_run:
                logger.info("=" * 60)
                logger.info("DRY RUN MODE - No changes will be made")
                logger.info("=" * 60)
            
            self.connect()
            self.init_schema()
            self.migrate_memory_optimizer()
            self.migrate_qscores()
            self.migrate_task_outcomes()
            self.migrate_audit_logs()
            
            if not self.dry_run:
                self.conn.close()
            
            self.print_summary()
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            sys.exit(1)
    
    def print_summary(self):
        """Print migration summary"""
        logger.info("=" * 60)
        logger.info("MIGRATION SUMMARY")
        logger.info("=" * 60)
        logger.info(f"Memory state: ✓")
        logger.info(f"Q-scores: {self.stats['qscores_migrated']} agent-task pairs")
        logger.info(f"Task outcomes: {self.stats['outcomes_migrated']} records")
        logger.info(f"Audit events: {self.stats['audit_events_migrated']} events")
        logger.info(f"Errors: {self.stats['errors']}")
        if self.dry_run:
            logger.info("\n[DRY RUN] No changes applied. Run without --dry-run to execute.")

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Migrate Morpheus JSON files to SQLite')
    parser.add_argument('--dry-run', action='store_true', help='Preview migration without applying changes')
    parser.add_argument('--db', type=Path, default=DB_PATH, help='Database path')
    args = parser.parse_args()
    
    migration = MorpheusDBMigration(args.db, dry_run=args.dry_run)
    migration.run()
