#!/usr/bin/env python3
"""
Knowledge Base SQLite Migration
Migrates all KB JSON files to SQLite morpheus.db

Author: Morpheus
Created: 2026-04-03 23:50 UTC
"""

import sqlite3
import json
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

# Configuration
WORKSPACE_DIR = Path(__file__).parent.parent.parent
DATA_DIR = WORKSPACE_DIR / "data"
DB_PATH = DATA_DIR / "morpheus.db"

# KB files to migrate
KB_FILES = [
    "kb/nikola-tesla-verified.json",
    "kb/nikola-tesla-complete-projects.json",
    "kb/knowledge-base.json",
    "kb/oracle-cloud-infrastructure-2026.json",
    "knowledge-bases/arduino-reference-kb.json",
    "knowledge-base/extracted-patterns.json",
]

def create_kb_schema(conn: sqlite3.Connection) -> None:
    """Create KB tables if they don't exist."""
    cursor = conn.cursor()
    
    # KB Documents table
    cursor.execute("""
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
        )
    """)
    
    # KB Sections (for nested content)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS kb_sections (
            id TEXT PRIMARY KEY,
            document_id TEXT NOT NULL,
            section_name TEXT NOT NULL,
            section_content TEXT,
            order_index INTEGER,
            FOREIGN KEY (document_id) REFERENCES kb_documents(id) ON DELETE CASCADE
        )
    """)
    
    # KB Tags for categorization
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS kb_tags (
            id TEXT PRIMARY KEY,
            tag_name TEXT UNIQUE NOT NULL,
            category TEXT
        )
    """)
    
    # Document-Tag mappings
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS kb_document_tags (
            id TEXT PRIMARY KEY,
            document_id TEXT NOT NULL,
            tag_id TEXT NOT NULL,
            FOREIGN KEY (document_id) REFERENCES kb_documents(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES kb_tags(id) ON DELETE CASCADE
        )
    """)
    
    # Full-Text Search virtual table
    cursor.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS kb_search USING fts5(
            name,
            section_name,
            content,
            category
        )
    """)
    
    # Indexes for performance
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_kb_category ON kb_documents(category)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_kb_created ON kb_documents(created_at)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_kb_sections_doc ON kb_sections(document_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_kb_tags_category ON kb_tags(category)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_kb_doctags_doc ON kb_document_tags(document_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_kb_doctags_tag ON kb_document_tags(tag_id)")
    
    conn.commit()
    print("✅ KB schema created")


def extract_tags(data: Dict) -> List[str]:
    """Extract tags from KB document."""
    tags = []
    
    # Check for explicit tags
    if "tags" in data:
        tags.extend(data["tags"] if isinstance(data["tags"], list) else [data["tags"]])
    
    # Check for category
    if "category" in data:
        tags.append(data["category"])
    
    # Check for title/domain
    if "title" in data:
        # Extract domain keywords from title
        title = data["title"].lower()
        if "oracle" in title or "oci" in title or "fusion" in title:
            tags.extend(["oracle", "oci", "cloud", "erp"])
        elif "tesla" in title:
            tags.extend(["tesla", "physics", "electricity", "patents"])
        elif "arduino" in title:
            tags.extend(["arduino", "hardware", "embedded", "iot"])
    
    return list(set(tags))  # Remove duplicates


def migrate_kb_file(conn: sqlite3.Connection, kb_path: Path) -> Tuple[bool, str]:
    """Migrate single KB file to SQLite."""
    cursor = conn.cursor()
    
    if not kb_path.exists():
        return False, f"File not found: {kb_path}"
    
    try:
        with open(kb_path, 'r') as f:
            data = json.load(f)
        
        # Extract document info
        doc_id = kb_path.stem.replace("-", "_").replace(".", "_")
        doc_name = data.get("title", kb_path.stem)
        category = data.get("category", "general")
        content = json.dumps(data)
        
        # Insert document
        cursor.execute("""
            INSERT OR REPLACE INTO kb_documents 
            (id, name, category, content, source_file, file_size)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            doc_id,
            doc_name,
            category,
            content,
            str(kb_path.relative_to(WORKSPACE_DIR)),
            kb_path.stat().st_size
        ))
        
        # Extract and insert tags
        tags = extract_tags(data)
        for tag in tags:
            tag_id = f"tag_{tag.lower().replace(' ', '_')}"
            cursor.execute("""
                INSERT OR IGNORE INTO kb_tags (id, tag_name, category)
                VALUES (?, ?, ?)
            """, (tag_id, tag, "kb"))
            
            # Map document to tag
            mapping_id = f"{doc_id}_{tag_id}"
            cursor.execute("""
                INSERT OR IGNORE INTO kb_document_tags (id, document_id, tag_id)
                VALUES (?, ?, ?)
            """, (mapping_id, doc_id, tag_id))
        
        # Insert into FTS index
        cursor.execute("""
            INSERT INTO kb_search (name, section_name, content, category)
            VALUES (?, ?, ?, ?)
        """, (doc_name, "", content, category))
        
        conn.commit()
        return True, f"Migrated: {kb_path.name} (size: {kb_path.stat().st_size} bytes)"
        
    except json.JSONDecodeError as e:
        return False, f"JSON parse error in {kb_path}: {e}"
    except Exception as e:
        return False, f"Error migrating {kb_path}: {e}"


def verify_migration(conn: sqlite3.Connection) -> None:
    """Verify migration success."""
    cursor = conn.cursor()
    
    # Count documents
    cursor.execute("SELECT COUNT(*) FROM kb_documents")
    doc_count = cursor.fetchone()[0]
    
    # Count tags
    cursor.execute("SELECT COUNT(*) FROM kb_tags")
    tag_count = cursor.fetchone()[0]
    
    # Count mappings
    cursor.execute("SELECT COUNT(*) FROM kb_document_tags")
    mapping_count = cursor.fetchone()[0]
    
    # Sample documents
    cursor.execute("SELECT id, name, category FROM kb_documents")
    docs = cursor.fetchall()
    
    print(f"\n📊 Migration Verification:")
    print(f"  Documents: {doc_count}")
    print(f"  Tags: {tag_count}")
    print(f"  Mappings: {mapping_count}")
    print(f"\n  Documents in DB:")
    for doc_id, name, category in docs:
        print(f"    - {name} ({category})")


def main():
    """Main migration function."""
    print("🚀 Knowledge Base SQLite Migration")
    print(f"   Source: {DATA_DIR}")
    print(f"   Target: {DB_PATH}")
    print(f"   Time: {datetime.utcnow().isoformat()}Z\n")
    
    # Connect to database
    try:
        conn = sqlite3.connect(str(DB_PATH))
        print("✅ Connected to morpheus.db\n")
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
        return
    
    # Create schema
    try:
        create_kb_schema(conn)
    except Exception as e:
        print(f"❌ Schema creation failed: {e}")
        conn.close()
        return
    
    # Migrate KB files
    print("📂 Migrating KB files:\n")
    success_count = 0
    for kb_file in KB_FILES:
        kb_path = DATA_DIR / kb_file
        success, message = migrate_kb_file(conn, kb_path)
        status = "✅" if success else "❌"
        print(f"  {status} {message}")
        if success:
            success_count += 1
    
    # Verify migration
    print()
    verify_migration(conn)
    
    # Summary
    print(f"\n📈 Migration Summary:")
    print(f"  Files attempted: {len(KB_FILES)}")
    print(f"  Files migrated: {success_count}")
    print(f"  Status: {'✅ SUCCESS' if success_count == len(KB_FILES) else '⚠️  PARTIAL'}")
    
    conn.close()
    print("\n✅ Migration complete!")


if __name__ == "__main__":
    main()
