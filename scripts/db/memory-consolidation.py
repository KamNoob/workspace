#!/usr/bin/env python3
"""
Memory Consolidation & Database Maintenance
Cleans up old vectors, prunes stale records, optimizes database
Purpose: Memory hygiene (equivalent to Phase 5 memory pruning)
Created: 2026-03-28
"""

import sqlite3
import logging
from datetime import datetime, timedelta
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MemoryConsolidation:
    """Database maintenance and memory consolidation"""
    
    def __init__(self, db_path: str = None):
        if db_path is None:
            db_path = Path(__file__).parent.parent.parent / 'data' / 'morpheus.db'
        
        self.db_path = db_path
        self.conn = sqlite3.connect(str(db_path))
        self.conn.execute("PRAGMA foreign_keys = ON")
        self.stats = {
            'vectors_deleted': 0,
            'old_outcomes_archived': 0,
            'old_events_archived': 0,
            'db_size_before_kb': 0,
            'db_size_after_kb': 0
        }
    
    def get_db_size(self) -> int:
        """Get current database size in KB"""
        return Path(self.db_path).stat().st_size // 1024
    
    def prune_old_vectors(self, days: int = 30, dry_run: bool = False) -> int:
        """Delete vectors older than N days that haven't been accessed"""
        cutoff = datetime.utcnow() - timedelta(days=days)
        
        # Find vectors to delete
        old_vectors = self.conn.execute("""
            SELECT id FROM vectors
            WHERE created_at < ? OR (last_accessed < ? AND access_count < 5)
            ORDER BY last_accessed ASC
        """, (cutoff.isoformat(), cutoff.isoformat())).fetchall()
        
        count = len(old_vectors)
        
        if not dry_run and count > 0:
            vector_ids = [v[0] for v in old_vectors]
            placeholders = ','.join('?' * len(vector_ids))
            self.conn.execute(f"DELETE FROM vectors WHERE id IN ({placeholders})", vector_ids)
            self.conn.commit()
        
        self.stats['vectors_deleted'] = count
        logger.info(f"{'[DRY RUN] ' if dry_run else ''}Pruned {count} old vectors (>{days}d old)")
        
        return count
    
    def archive_old_outcomes(self, days: int = 90, dry_run: bool = False) -> int:
        """Archive task outcomes older than N days to separate table"""
        cutoff = datetime.utcnow() - timedelta(days=days)
        
        # Create archive table if it doesn't exist
        if not dry_run:
            self.conn.execute("""
                CREATE TABLE IF NOT EXISTS task_outcomes_archive AS
                SELECT * FROM task_outcomes WHERE 1=0
            """)
        
        # Find old outcomes
        old_outcomes = self.conn.execute("""
            SELECT COUNT(*) as count FROM task_outcomes
            WHERE completed_at < ?
        """, (cutoff.isoformat(),)).fetchone()['count']
        
        if not dry_run and old_outcomes > 0:
            # Move to archive
            self.conn.execute("""
                INSERT INTO task_outcomes_archive
                SELECT * FROM task_outcomes
                WHERE completed_at < ?
            """, (cutoff.isoformat(),))
            
            # Delete from main table
            self.conn.execute("""
                DELETE FROM task_outcomes
                WHERE completed_at < ?
            """, (cutoff.isoformat(),))
            
            self.conn.commit()
        
        self.stats['old_outcomes_archived'] = old_outcomes
        logger.info(f"{'[DRY RUN] ' if dry_run else ''}Archived {old_outcomes} outcomes (>{days}d old)")
        
        return old_outcomes
    
    def archive_old_audit_events(self, days: int = 180, dry_run: bool = False) -> int:
        """Archive audit events older than N days"""
        cutoff = datetime.utcnow() - timedelta(days=days)
        
        # Create archive table if it doesn't exist
        if not dry_run:
            self.conn.execute("""
                CREATE TABLE IF NOT EXISTS audit_events_archive AS
                SELECT * FROM audit_events WHERE 1=0
            """)
        
        # Find old events
        old_events = self.conn.execute("""
            SELECT COUNT(*) as count FROM audit_events
            WHERE timestamp < ?
        """, (cutoff.isoformat(),)).fetchone()['count']
        
        if not dry_run and old_events > 0:
            # Move to archive
            self.conn.execute("""
                INSERT INTO audit_events_archive
                SELECT * FROM audit_events
                WHERE timestamp < ?
            """, (cutoff.isoformat(),))
            
            # Delete from main table
            self.conn.execute("""
                DELETE FROM audit_events
                WHERE timestamp < ?
            """, (cutoff.isoformat(),))
            
            self.conn.commit()
        
        self.stats['old_events_archived'] = old_events
        logger.info(f"{'[DRY RUN] ' if dry_run else ''}Archived {old_events} events (>{days}d old)")
        
        return old_events
    
    def update_memory_state(self, dry_run: bool = False) -> None:
        """Update memory consolidation timestamp"""
        if not dry_run:
            self.conn.execute("""
                UPDATE memory_state
                SET last_consolidation = ?,
                    consolidation_runs = consolidation_runs + 1
                WHERE id = 'singleton'
            """, (datetime.utcnow().isoformat(),))
            self.conn.commit()
        
        logger.info(f"{'[DRY RUN] ' if dry_run else ''}Updated memory consolidation timestamp")
    
    def optimize_database(self, dry_run: bool = False) -> None:
        """Run SQLite optimizations (VACUUM, ANALYZE)"""
        if not dry_run:
            logger.info("Running ANALYZE...")
            self.conn.execute("ANALYZE")
            
            logger.info("Running VACUUM...")
            self.conn.execute("VACUUM")
            
            self.conn.commit()
        
        logger.info(f"{'[DRY RUN] ' if dry_run else ''}Database optimization complete")
    
    def get_database_stats(self) -> dict:
        """Get current database statistics"""
        stats = {}
        
        tables = {
            'vectors': 'SELECT COUNT(*) as count FROM vectors',
            'task_outcomes': 'SELECT COUNT(*) as count FROM task_outcomes',
            'audit_events': 'SELECT COUNT(*) as count FROM audit_events',
            'agent_qscores': 'SELECT COUNT(*) as count FROM agent_qscores'
        }
        
        for table_name, query in tables.items():
            count = self.conn.execute(query).fetchone()['count']
            stats[table_name] = count
        
        return stats
    
    def run_consolidation(self, dry_run: bool = False) -> None:
        """Run full consolidation process"""
        self.stats['db_size_before_kb'] = self.get_db_size()
        
        logger.info("=" * 70)
        logger.info(f"MEMORY CONSOLIDATION {'[DRY RUN]' if dry_run else '[LIVE]'}")
        logger.info("=" * 70)
        
        # Get stats before
        logger.info("\nDatabase stats BEFORE:")
        stats_before = self.get_database_stats()
        for table, count in stats_before.items():
            logger.info(f"  {table}: {count} records")
        
        # Run consolidation
        logger.info("\nRunning consolidation steps...")
        self.prune_old_vectors(days=30, dry_run=dry_run)
        self.archive_old_outcomes(days=90, dry_run=dry_run)
        self.archive_old_audit_events(days=180, dry_run=dry_run)
        self.update_memory_state(dry_run=dry_run)
        self.optimize_database(dry_run=dry_run)
        
        # Get stats after
        logger.info("\nDatabase stats AFTER:")
        stats_after = self.get_database_stats()
        for table, count in stats_after.items():
            before = stats_before.get(table, 0)
            delta = before - count
            logger.info(f"  {table}: {count} records (deleted: {delta})")
        
        self.stats['db_size_after_kb'] = self.get_db_size()
        
        # Summary
        logger.info("\n" + "=" * 70)
        logger.info("CONSOLIDATION SUMMARY")
        logger.info("=" * 70)
        logger.info(f"Vectors pruned: {self.stats['vectors_deleted']}")
        logger.info(f"Outcomes archived: {self.stats['old_outcomes_archived']}")
        logger.info(f"Events archived: {self.stats['old_events_archived']}")
        logger.info(f"Database size: {self.stats['db_size_before_kb']} KB → {self.stats['db_size_after_kb']} KB "
                   f"({self.stats['db_size_before_kb'] - self.stats['db_size_after_kb']} KB freed)")
        
        if dry_run:
            logger.info("\n[DRY RUN] No changes applied. Run with --live to execute.")
    
    def close(self):
        """Close database connection"""
        self.conn.close()


def main():
    """Run memory consolidation"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Memory consolidation and database maintenance')
    parser.add_argument('--live', action='store_true', help='Apply changes (default is dry-run)')
    parser.add_argument('--db', type=Path, default=None, help='Database path')
    args = parser.parse_args()
    
    try:
        consolidation = MemoryConsolidation(args.db)
        consolidation.run_consolidation(dry_run=not args.live)
        consolidation.close()
    except Exception as e:
        logger.error(f"Consolidation failed: {e}")
        exit(1)


if __name__ == '__main__':
    main()
