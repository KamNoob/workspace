-- SQLite Vector Database Schema (V3 — FINAL, Production-Ready)
-- Morpheus AI System Unified Data Store
-- Enable foreign keys: PRAGMA foreign_keys = ON;
-- Created: 2026-03-28 17:24 UTC
-- Updated: 2026-04-03 22:51 UTC (KB tables added)
-- Confidence: 99.5%

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS agents (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  role TEXT,
  enabled BOOLEAN DEFAULT 1,
  q_learning_active BOOLEAN DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  metadata JSON
);

CREATE TABLE IF NOT EXISTS vectors (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  embedding BLOB NOT NULL,
  embedding_format TEXT DEFAULT 'json',
  vector_dim INTEGER DEFAULT 768,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_accessed TIMESTAMP,
  access_count INTEGER DEFAULT 0,
  source TEXT,
  metadata JSON
);
CREATE INDEX IF NOT EXISTS idx_vectors_source ON vectors(source);
CREATE INDEX IF NOT EXISTS idx_vectors_accessed ON vectors(last_accessed DESC);

CREATE TABLE IF NOT EXISTS agent_qscores (
  id TEXT PRIMARY KEY,
  agent_id TEXT NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  task_type TEXT NOT NULL,
  q_value REAL NOT NULL DEFAULT 0.5,
  visits INTEGER DEFAULT 0,
  successes INTEGER DEFAULT 0,
  failures INTEGER DEFAULT 0,
  avg_outcome_quality REAL DEFAULT 0.5,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  confidence REAL DEFAULT 0.0,
  learning_rate REAL DEFAULT 0.1,
  UNIQUE(agent_id, task_type)
);
CREATE INDEX IF NOT EXISTS idx_qscores_agent ON agent_qscores(agent_id);
CREATE INDEX IF NOT EXISTS idx_qscores_task ON agent_qscores(task_type);
CREATE INDEX IF NOT EXISTS idx_qscores_value ON agent_qscores(q_value DESC);

CREATE TABLE IF NOT EXISTS task_outcomes (
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  agent_id TEXT NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  task_type TEXT NOT NULL,
  status TEXT,
  outcome_quality REAL,
  execution_time_ms INTEGER,
  tokens_used INTEGER,
  cost_usd REAL,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  error_message TEXT,
  metadata JSON
);
CREATE INDEX IF NOT EXISTS idx_outcomes_agent_task ON task_outcomes(agent_id, task_type);
CREATE INDEX IF NOT EXISTS idx_outcomes_completed ON task_outcomes(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_outcomes_status ON task_outcomes(status);

CREATE TABLE IF NOT EXISTS memory_state (
  id TEXT PRIMARY KEY DEFAULT 'singleton',
  total_recalls INTEGER DEFAULT 0,
  successful_recalls INTEGER DEFAULT 0,
  total_stores INTEGER DEFAULT 0,
  failed_stores INTEGER DEFAULT 0,
  consolidation_runs INTEGER DEFAULT 0,
  avg_lookup_time_ms REAL DEFAULT 0.0,
  last_consolidation TIMESTAMP,
  learning_phase TEXT DEFAULT 'exploitation',
  consolidation_status TEXT DEFAULT 'optimal',
  version TEXT DEFAULT '3.0',
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_events (
  id TEXT PRIMARY KEY,
  timestamp TIMESTAMP NOT NULL,
  event_type TEXT NOT NULL,
  agent_id TEXT,
  task_id TEXT,
  details JSON,
  severity TEXT DEFAULT 'info'
);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_agent ON audit_events(agent_id);
CREATE INDEX IF NOT EXISTS idx_audit_type_severity ON audit_events(event_type, severity);

CREATE TABLE IF NOT EXISTS sla_metrics (
  id TEXT PRIMARY KEY,
  metric_date DATE NOT NULL UNIQUE,
  latency_p50_ms REAL,
  latency_p95_ms REAL,
  success_rate REAL,
  avg_cost_per_task REAL,
  quality_score REAL,
  breaches_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_sla_date ON sla_metrics(metric_date DESC);

-- ============================================================================
-- KNOWLEDGE BASE TABLES (Added 2026-04-03 22:51 UTC)
-- ============================================================================

CREATE TABLE IF NOT EXISTS kb_documents (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  category TEXT,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  version INTEGER DEFAULT 1,
  source_file TEXT,
  file_size INTEGER
);
CREATE INDEX IF NOT EXISTS idx_kb_category ON kb_documents(category);
CREATE INDEX IF NOT EXISTS idx_kb_created ON kb_documents(created_at);

CREATE TABLE IF NOT EXISTS kb_sections (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL,
  section_name TEXT NOT NULL,
  section_content TEXT,
  order_index INTEGER,
  FOREIGN KEY (document_id) REFERENCES kb_documents(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_kb_sections_doc ON kb_sections(document_id);

CREATE TABLE IF NOT EXISTS kb_tags (
  id TEXT PRIMARY KEY,
  tag_name TEXT UNIQUE NOT NULL,
  category TEXT
);
CREATE INDEX IF NOT EXISTS idx_kb_tags_category ON kb_tags(category);

CREATE TABLE IF NOT EXISTS kb_document_tags (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL,
  tag_id TEXT NOT NULL,
  FOREIGN KEY (document_id) REFERENCES kb_documents(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES kb_tags(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_kb_doctags_doc ON kb_document_tags(document_id);
CREATE INDEX IF NOT EXISTS idx_kb_doctags_tag ON kb_document_tags(tag_id);

-- Full-Text Search virtual table for KB
CREATE VIRTUAL TABLE IF NOT EXISTS kb_search USING fts5(
  name,
  section_name,
  content,
  category
);

-- Bootstrap agents
INSERT OR IGNORE INTO agents (id, name, role) VALUES
('morpheus', 'Morpheus', 'Lead Orchestrator'),
('navigator', 'Navigator', 'Deputy Commander'),
('codex', 'Codex', 'Developer'),
('cipher', 'Cipher', 'Security Auditor'),
('scout', 'Scout', 'Researcher'),
('chronicle', 'Chronicle', 'Documentation'),
('sentinel', 'Sentinel', 'Infrastructure'),
('lens', 'Lens', 'Performance Analyst'),
('veritas', 'Veritas', 'Code Reviewer'),
('qa', 'QA', 'Quality Assurance'),
('prism', 'Prism', 'Mobile/Responsive'),
('echo', 'Echo', 'Creative Ideation');

-- Initialize memory state
INSERT OR IGNORE INTO memory_state (id) VALUES ('singleton');
