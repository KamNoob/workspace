# Database Performance Optimization Best Practices (2026)

**Domain:** Data / Performance  
**Created:** 2026-03-07  
**Status:** Active  
**Refresh Cycle:** 90 days (next: 2026-06-05)  
**Confidence:** High  

---

## Executive Summary

Database performance optimization follows 80/20 rule: proper indexing solves 80% of issues. Key techniques: EXPLAIN ANALYZE, covering indexes, query rewriting, connection pooling, and VACUUM. PostgreSQL 17 offers 88x faster bulk loads, improved B-tree efficiency.

---

## Core Optimization Techniques

### 1. Indexing Strategy

**Golden Rules:**
- Index columns in WHERE, JOIN, ORDER BY clauses
- Avoid over-indexing (writes slow down)
- Drop unused indexes (check usage stats)
- Use covering indexes when possible
- Multi-column indexes: most selective column first

**PostgreSQL Index Types:**

**B-tree (default, 90% use cases):**
```sql
-- Single column
CREATE INDEX idx_users_email ON users(email);

-- Multi-column (order matters)
CREATE INDEX idx_orders_status_date ON orders(status, created_at);

-- Covering index (includes non-indexed columns)
CREATE INDEX idx_orders_covering ON orders(customer_id) 
  INCLUDE (total, status);
```

**GiST (geometric, full-text search):**
```sql
CREATE INDEX idx_locations_geo ON locations USING GIST(coordinates);
```

**GIN (JSON, arrays, full-text):**
```sql
CREATE INDEX idx_products_tags ON products USING GIN(tags);
```

**BRIN (large sequential tables):**
```sql
-- For time-series data
CREATE INDEX idx_logs_created ON logs USING BRIN(created_at);
```

**Hash (equality only, rarely used):**
```sql
CREATE INDEX idx_users_hash ON users USING HASH(email);
```

**MySQL Index Types:**

**B-tree (InnoDB default):**
```sql
-- Single column
CREATE INDEX idx_users_email ON users(email);

-- Composite index
CREATE INDEX idx_orders_multi ON orders(status, customer_id, created_at);

-- Full-text (MyISAM or InnoDB)
CREATE FULLTEXT INDEX idx_posts_content ON posts(title, body);
```

**Spatial (GIS data):**
```sql
CREATE SPATIAL INDEX idx_locations ON locations(coordinates);
```

### 2. Query Analysis & Optimization

**PostgreSQL EXPLAIN ANALYZE:**
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT * FROM orders 
WHERE status = 'completed' 
  AND created_at > '2026-01-01'
ORDER BY created_at DESC
LIMIT 100;
```

**Key Metrics:**
- **Seq Scan** → BAD (full table scan)
- **Index Scan** → GOOD (uses index)
- **Bitmap Heap Scan** → OK (index + heap lookup)
- **Execution Time** → Target: <100ms for OLTP

**MySQL EXPLAIN:**
```sql
EXPLAIN FORMAT=TREE
SELECT o.*, c.name
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.status = 'completed'
  AND o.created_at > '2026-01-01';
```

**Key Indicators:**
- **type: ALL** → BAD (full scan)
- **type: index** → OK (index scan)
- **type: ref** → GOOD (indexed lookup)
- **rows** → Lower is better

### 3. Query Rewriting Patterns

**Avoid SELECT *:**
```sql
-- ❌ Bad: Fetches all columns
SELECT * FROM users WHERE id = 1;

-- ✅ Good: Fetch only needed columns
SELECT id, name, email FROM users WHERE id = 1;
```

**Use EXISTS Instead of IN for Large Subqueries:**
```sql
-- ❌ Slow: IN with large subquery
SELECT * FROM orders 
WHERE customer_id IN (
  SELECT id FROM customers WHERE country = 'US'
);

-- ✅ Fast: EXISTS with correlated subquery
SELECT * FROM orders o
WHERE EXISTS (
  SELECT 1 FROM customers c 
  WHERE c.id = o.customer_id AND c.country = 'US'
);
```

**Avoid OR, Use UNION:**
```sql
-- ❌ Slow: OR prevents index usage
SELECT * FROM products 
WHERE category = 'electronics' OR price < 100;

-- ✅ Fast: UNION with separate index scans
SELECT * FROM products WHERE category = 'electronics'
UNION
SELECT * FROM products WHERE price < 100;
```

**Paginate with Keyset Instead of OFFSET:**
```sql
-- ❌ Slow: OFFSET scans all rows
SELECT * FROM posts 
ORDER BY created_at DESC 
LIMIT 10 OFFSET 10000;

-- ✅ Fast: Keyset pagination (uses index)
SELECT * FROM posts 
WHERE created_at < '2026-01-15 10:30:00'
ORDER BY created_at DESC 
LIMIT 10;
```

**Avoid Functions on Indexed Columns:**
```sql
-- ❌ Bad: Function prevents index usage
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- ✅ Good: Functional index
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- ✅ Better: Store normalized data
UPDATE users SET email = LOWER(email);
SELECT * FROM users WHERE email = 'user@example.com';
```

### 4. Connection Pooling

**Problem:** Opening connections is expensive (~10-50ms)

**Solution:** Connection pooling (PgBouncer for PostgreSQL, ProxySQL for MySQL)

**PgBouncer Configuration:**
```ini
[databases]
myapp = host=localhost port=5432 dbname=myapp

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction  # or session, statement
max_client_conn = 1000
default_pool_size = 25
```

**Pool Modes:**
- **session** — One connection per user session (safest)
- **transaction** — Pool connections per transaction (faster)
- **statement** — Pool per statement (rarely used)

**ProxySQL (MySQL):**
```sql
-- Add backend server
INSERT INTO mysql_servers (hostgroup_id, hostname, port) 
VALUES (0, '127.0.0.1', 3306);

-- Configure connection pool
UPDATE global_variables 
SET variable_value = '200' 
WHERE variable_name = 'mysql-max_connections';

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### 5. Vacuum & Maintenance (PostgreSQL)

**Why VACUUM?**
- PostgreSQL uses MVCC (multi-version concurrency control)
- Deleted rows marked as "dead tuples" (not immediately removed)
- VACUUM reclaims space, updates statistics

**Auto-Vacuum (enabled by default):**
```sql
-- Check autovacuum settings
SHOW autovacuum;
SHOW autovacuum_naptime;
SHOW autovacuum_vacuum_threshold;

-- View table bloat
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
       n_dead_tup
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

**Manual VACUUM:**
```sql
-- Standard vacuum (non-blocking)
VACUUM ANALYZE orders;

-- Full vacuum (locks table, reclaims max space)
VACUUM FULL orders;

-- Concurrent index rebuild (PostgreSQL 12+)
REINDEX INDEX CONCURRENTLY idx_orders_status;
```

**Optimize (MySQL equivalent):**
```sql
-- Rebuild table and indexes
OPTIMIZE TABLE orders;

-- Analyze table statistics
ANALYZE TABLE orders;
```

### 6. Configuration Tuning

**PostgreSQL (postgresql.conf):**
```ini
# Memory
shared_buffers = 4GB             # 25% of RAM
effective_cache_size = 12GB      # 75% of RAM
work_mem = 64MB                  # Per query operation
maintenance_work_mem = 1GB       # For VACUUM, CREATE INDEX

# Checkpoints
checkpoint_timeout = 15min
checkpoint_completion_target = 0.9
wal_buffers = 16MB

# Query Planner
random_page_cost = 1.1           # For SSDs (default 4.0 for HDDs)
effective_io_concurrency = 200   # For SSDs

# Connections
max_connections = 200
```

**MySQL (my.cnf):**
```ini
[mysqld]
# Memory
innodb_buffer_pool_size = 4G     # 70-80% of RAM
innodb_log_file_size = 512M

# Connections
max_connections = 300
thread_cache_size = 100

# Query Cache (deprecated in MySQL 8.0)
# Use application-level caching instead

# Temporary Tables
tmp_table_size = 64M
max_heap_table_size = 64M

# InnoDB
innodb_flush_log_at_trx_commit = 2  # Faster, slight durability loss
innodb_flush_method = O_DIRECT
```

---

## PostgreSQL 17 Performance Improvements (2026)

### Bulk Loading: 88x Faster
- **COPY FROM** improvements
- **Parallel bulk inserts**
- **Result:** 30s → 340ms (88x speedup)

### B-tree Index Efficiency
- Reduced index bloat
- Faster lookups for UUID and high-cardinality columns

### Incremental VACUUM
- Less aggressive locking
- Better for large tables

---

## Common Performance Killers

### 1. N+1 Query Problem

**Problem:**
```python
# Fetch users
users = db.query("SELECT * FROM users LIMIT 100")

# For each user, fetch orders (N+1 queries)
for user in users:
    orders = db.query(f"SELECT * FROM orders WHERE user_id = {user.id}")
```

**Solution:**
```python
# Single query with JOIN
results = db.query("""
    SELECT u.*, o.*
    FROM users u
    LEFT JOIN orders o ON o.user_id = u.id
    LIMIT 100
""")
```

### 2. Missing Indexes on Foreign Keys

**Problem:**
```sql
-- orders.customer_id has no index
SELECT * FROM orders WHERE customer_id = 123;  -- Seq Scan!
```

**Solution:**
```sql
CREATE INDEX idx_orders_customer ON orders(customer_id);
```

### 3. Large IN Clauses

**Problem:**
```sql
-- 1000+ IDs in IN clause
SELECT * FROM users WHERE id IN (1, 2, 3, ..., 10000);
```

**Solution:**
```sql
-- Use temporary table
CREATE TEMP TABLE temp_ids (id INT);
INSERT INTO temp_ids VALUES (1), (2), (3), ...;

SELECT u.* FROM users u
JOIN temp_ids t ON u.id = t.id;
```

### 4. Unindexed ORDER BY

**Problem:**
```sql
-- No index on created_at
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;  -- Sort!
```

**Solution:**
```sql
CREATE INDEX idx_orders_created ON orders(created_at DESC);
```

### 5. Redundant Indexes

**Problem:**
```sql
-- Index 1
CREATE INDEX idx_orders_status ON orders(status);

-- Index 2 (redundant for most queries)
CREATE INDEX idx_orders_status_created ON orders(status, created_at);
```

**Solution:** Drop `idx_orders_status` if `idx_orders_status_created` covers all use cases

---

## Monitoring & Diagnostics

### PostgreSQL: pg_stat_statements

**Enable Extension:**
```sql
CREATE EXTENSION pg_stat_statements;
```

**Find Slow Queries:**
```sql
SELECT query, 
       calls,
       total_exec_time / 1000 AS total_time_sec,
       mean_exec_time / 1000 AS avg_time_sec,
       (total_exec_time / sum(total_exec_time) OVER ()) * 100 AS pct_time
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 20;
```

**Find Unused Indexes:**
```sql
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;
```

### MySQL: Performance Schema

**Enable (MySQL 8.0+):**
```sql
-- Already enabled by default
SHOW VARIABLES LIKE 'performance_schema';
```

**Find Slow Queries:**
```sql
SELECT DIGEST_TEXT,
       COUNT_STAR AS exec_count,
       AVG_TIMER_WAIT / 1000000000000 AS avg_time_sec,
       SUM_TIMER_WAIT / 1000000000000 AS total_time_sec
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME = 'myapp'
ORDER BY SUM_TIMER_WAIT DESC
LIMIT 20;
```

**Find Unused Indexes:**
```sql
SELECT OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE INDEX_NAME IS NOT NULL
  AND COUNT_STAR = 0
  AND INDEX_NAME != 'PRIMARY'
ORDER BY OBJECT_SCHEMA, OBJECT_NAME;
```

---

## Tools & Resources

**Query Optimization:**
- **EverSQL** — Automated SQL optimization (PostgreSQL, MySQL)
- **pgMustard** — PostgreSQL EXPLAIN visualizer
- **MySQL Workbench** — Visual query analysis

**Monitoring:**
- **pgAdmin 4** — PostgreSQL GUI
- **pg_stat_statements** — Built-in query stats
- **Percona Monitoring and Management (PMM)** — MySQL/PostgreSQL monitoring

**Connection Pooling:**
- **PgBouncer** — PostgreSQL connection pooler
- **ProxySQL** — MySQL proxy and load balancer

---

## Performance Checklist

### Query-Level
- [ ] Use EXPLAIN ANALYZE before deploying
- [ ] Index all WHERE/JOIN/ORDER BY columns
- [ ] Avoid SELECT *, fetch only needed columns
- [ ] Paginate with keyset (not OFFSET)
- [ ] Batch inserts/updates (not row-by-row)

### Schema-Level
- [ ] Foreign keys indexed
- [ ] Covering indexes for frequent queries
- [ ] Drop unused/redundant indexes
- [ ] Normalize data (avoid functions on indexed columns)
- [ ] Partition large tables (>100M rows)

### Configuration-Level
- [ ] shared_buffers = 25% RAM (PostgreSQL)
- [ ] innodb_buffer_pool_size = 70% RAM (MySQL)
- [ ] Connection pooling enabled
- [ ] Autovacuum tuned (PostgreSQL)
- [ ] random_page_cost = 1.1 for SSDs

### Application-Level
- [ ] Connection pooling (PgBouncer, ProxySQL)
- [ ] Query result caching (Redis, Memcached)
- [ ] Async queries where possible
- [ ] Avoid N+1 query problem
- [ ] Monitor slow queries (pg_stat_statements, Performance Schema)

---

## Tags

database, performance, optimization, PostgreSQL, MySQL, indexing, query-optimization, EXPLAIN, connection-pooling, pgbouncer, proxysql, vacuum, pg_stat_statements, performance-schema

---

**Sources:** Rapydo, OneUpTime, Medium (DevBoost Lab), MOGE (2025-2026)  
**Verified:** 2026-03-07  
**Next Refresh:** 2026-06-05 (90 days)
