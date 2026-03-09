#!/usr/bin/env python3
"""
Qdrant Indexing System
Scans workspace documents and indexes them with embeddings for semantic search.
"""

import os
import json
import hashlib
import logging
import argparse
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, List, Tuple
import sys

# Try to import required libraries
try:
    from qdrant_client import QdrantClient
    from qdrant_client.models import Distance, VectorParams, PointStruct
except ImportError:
    print("Error: qdrant-client not installed. Install with: pip install qdrant-client")
    sys.exit(1)

try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    print("Error: sentence-transformers not installed. Install with: pip install sentence-transformers")
    sys.exit(1)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class QdrantIndexer:
    """Manages document indexing into Qdrant vector database."""
    
    COLLECTION_NAME = "knowledge"
    EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
    VECTOR_SIZE = 384
    BATCH_SIZE = 32
    
    SCAN_DIRS = ["docs", "agents", "config", "scripts", "memory", "prototype"]
    EXTENSIONS = {".md", ".txt", ".json"}
    SKIP_PATTERNS = {"node_modules", ".git", "__pycache__", ".pytest_cache", ".venv", "venv", "archive"}
    
    def __init__(self, workspace_root: str, qdrant_url: str = "http://localhost:6333"):
        self.workspace_root = Path(workspace_root)
        self.qdrant_url = qdrant_url
        self.state_file = self.workspace_root / "data" / ".qdrant_index_state.json"
        
        try:
            self.client = QdrantClient(url=qdrant_url)
            logger.info(f"✓ Connected to Qdrant at {qdrant_url}")
        except Exception as e:
            logger.error(f"✗ Failed to connect to Qdrant: {e}")
            raise
        
        logger.info(f"Loading embedding model: {self.EMBEDDING_MODEL}")
        self.model = SentenceTransformer(self.EMBEDDING_MODEL)
        logger.info("✓ Embedding model loaded")
        
        self.file_state = self._load_state()
        
    def _load_state(self) -> Dict:
        if self.state_file.exists():
            try:
                with open(self.state_file) as f:
                    return json.load(f)
            except Exception as e:
                logger.warning(f"Could not load state: {e}")
        return {"files": {}, "last_full_index": None}
    
    def _save_state(self):
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.state_file, 'w') as f:
            json.dump(self.file_state, f, indent=2)
    
    def _get_file_hash(self, filepath: Path) -> str:
        sha256 = hashlib.sha256()
        with open(filepath, "rb") as f:
            for block in iter(lambda: f.read(4096), b""):
                sha256.update(block)
        return sha256.hexdigest()
    
    def _should_skip(self, path: Path) -> bool:
        for pattern in self.SKIP_PATTERNS:
            if pattern in path.parts:
                return True
        return False
    
    def _extract_text(self, filepath: Path) -> Optional[str]:
        try:
            if filepath.suffix == ".json":
                with open(filepath) as f:
                    return json.dumps(json.load(f), indent=2)
            else:
                with open(filepath, encoding='utf-8') as f:
                    return f.read()
        except Exception as e:
            logger.warning(f"Could not read {filepath}: {e}")
            return None
    
    def _chunk_text(self, text: str, chunk_size: int = 500, overlap: int = 100) -> List[Tuple[str, int]]:
        chunks = []
        words = text.split()
        chunk_words = []
        chunk_index = 0
        
        for word in words:
            chunk_words.append(word)
            if len(chunk_words) >= chunk_size:
                chunk_text = ' '.join(chunk_words)
                if chunk_text.strip():
                    chunks.append((chunk_text, chunk_index))
                    chunk_index += 1
                chunk_words = chunk_words[-overlap:]
        
        if chunk_words:
            chunks.append((' '.join(chunk_words), chunk_index))
        
        return chunks if chunks else [("", 0)]
    
    def _ensure_collection_exists(self):
        try:
            self.client.get_collection(self.COLLECTION_NAME)
            logger.info(f"✓ Collection '{self.COLLECTION_NAME}' exists")
        except:
            logger.info(f"Creating collection '{self.COLLECTION_NAME}'...")
            self.client.create_collection(
                collection_name=self.COLLECTION_NAME,
                vectors_config=VectorParams(size=self.VECTOR_SIZE, distance=Distance.COSINE)
            )
            logger.info(f"✓ Collection created")
    
    def _get_max_point_id(self) -> int:
        try:
            info = self.client.get_collection(self.COLLECTION_NAME)
            return info.points_count
        except:
            return 0
    
    def index_files(self, full: bool = False) -> Dict:
        logger.info("Starting indexing...")
        self._ensure_collection_exists()
        
        stats = {
            "files_scanned": 0,
            "files_indexed": 0,
            "chunks_indexed": 0,
            "errors": 0,
            "skipped": 0,
            "files": {}
        }
        
        # Collect files to process
        files_to_process = []
        for scan_dir in self.SCAN_DIRS:
            dir_path = self.workspace_root / scan_dir
            if not dir_path.exists():
                continue
            
            for filepath in dir_path.rglob("*"):
                if filepath.is_file() and filepath.suffix in self.EXTENSIONS:
                    if self._should_skip(filepath):
                        stats["skipped"] += 1
                        continue
                    
                    stats["files_scanned"] += 1
                    relative_path = str(filepath.relative_to(self.workspace_root))
                    current_hash = self._get_file_hash(filepath)
                    
                    if not full and relative_path in self.file_state["files"]:
                        if self.file_state["files"][relative_path] == current_hash:
                            stats["skipped"] += 1
                            continue
                    
                    files_to_process.append((filepath, relative_path, current_hash))
        
        logger.info(f"Indexing {len(files_to_process)} files...")
        
        # Index files
        points_batch = []
        point_id = self._get_max_point_id() + 1
        
        for filepath, relative_path, file_hash in files_to_process:
            try:
                text = self._extract_text(filepath)
                if not text or not text.strip():
                    stats["skipped"] += 1
                    continue
                
                chunks = self._chunk_text(text)
                chunk_texts = [chunk[0] for chunk in chunks]
                embeddings = self.model.encode(chunk_texts)
                
                for (chunk_text, chunk_idx), embedding in zip(chunks, embeddings):
                    point = PointStruct(
                        id=point_id,
                        vector=embedding.tolist(),
                        payload={
                            "filename": relative_path,
                            "file_type": filepath.suffix,
                            "chunk_index": chunk_idx,
                            "text": chunk_text[:1000],
                            "indexed_at": datetime.now().isoformat(),
                            "tags": [filepath.parent.name, filepath.suffix[1:]]
                        }
                    )
                    points_batch.append(point)
                    point_id += 1
                    stats["chunks_indexed"] += 1
                
                stats["files_indexed"] += 1
                self.file_state["files"][relative_path] = file_hash
                stats["files"][relative_path] = "indexed"
                logger.info(f"  ✓ {relative_path} ({len(chunks)} chunks)")
                
                # Batch upsert
                if len(points_batch) >= self.BATCH_SIZE:
                    self.client.upsert(
                        collection_name=self.COLLECTION_NAME,
                        points=points_batch
                    )
                    points_batch = []
                    
            except Exception as e:
                stats["errors"] += 1
                logger.error(f"  ✗ {relative_path}: {e}")
        
        # Final batch
        if points_batch:
            self.client.upsert(
                collection_name=self.COLLECTION_NAME,
                points=points_batch
            )
        
        self.file_state["last_full_index"] = datetime.now().isoformat()
        self._save_state()
        
        return stats
    
    def test_search(self, query: str, limit: int = 3) -> List[Dict]:
        """Test hybrid search with a query."""
        logger.info(f"Testing search: '{query}'")
        
        query_embedding = self.model.encode(query).tolist()
        results = self.client.search(
            collection_name=self.COLLECTION_NAME,
            query_vector=query_embedding,
            limit=limit,
            query_filter=None
        )
        
        hits = []
        for result in results:
            hit = {
                "score": result.score,
                "filename": result.payload.get("filename"),
                "chunk_index": result.payload.get("chunk_index"),
                "preview": result.payload.get("text")[:100] + "..."
            }
            hits.append(hit)
            logger.info(f"  Score: {result.score:.3f} | {hit['filename']} (chunk {hit['chunk_index']})")
        
        return hits

def main():
    parser = argparse.ArgumentParser(description="Qdrant indexing system")
    parser.add_argument("--full", action="store_true", help="Force full re-indexing")
    parser.add_argument("--test-query", type=str, help="Test search with a query")
    parser.add_argument("--workspace", default="/home/art/.openclaw/workspace", help="Workspace root")
    
    args = parser.parse_args()
    
    try:
        indexer = QdrantIndexer(args.workspace)
        
        # Run indexing
        stats = indexer.index_files(full=args.full)
        
        logger.info("\n" + "="*60)
        logger.info("INDEXING COMPLETE")
        logger.info("="*60)
        logger.info(f"Files scanned: {stats['files_scanned']}")
        logger.info(f"Files indexed: {stats['files_indexed']}")
        logger.info(f"Total chunks: {stats['chunks_indexed']}")
        logger.info(f"Skipped: {stats['skipped']}")
        logger.info(f"Errors: {stats['errors']}")
        logger.info("="*60 + "\n")
        
        # Test search if requested
        if args.test_query:
            logger.info(f"\nTesting search with query: '{args.test_query}'")
            results = indexer.test_search(args.test_query)
        
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
