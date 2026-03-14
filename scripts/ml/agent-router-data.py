#!/usr/bin/env python3
"""
Agent Router Data Preparation
==============================

Loads RL execution logs, featurizes tasks, and prepares training data.

Usage:
    python3 agent-router-data.py --load      # Load and explore data
    python3 agent-router-data.py --split     # Create train/test split
    python3 agent-router-data.py --export    # Export to tensor format

Output:
    - data/agent-router-train.pt (PyTorch tensors)
    - data/agent-router-test.pt
    - data/agent-router-vocab.pkl (task vocabulary)
"""

import json
import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.preprocessing import LabelEncoder
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
import pickle
import torch
import argparse
from collections import Counter

# Paths
DATA_DIR = Path("data/rl")
EXEC_LOG = DATA_DIR / "rl-task-execution-log.jsonl"
OUTPUT_DIR = Path("data/models")
OUTPUT_DIR.mkdir(exist_ok=True)

class AgentRouterData:
    """Load and preprocess agent router training data."""
    
    def __init__(self):
        self.df = None
        self.tfidf = None
        self.agent_encoder = None
        self.task_features = None
        self.X_train = None
        self.X_test = None
        self.y_train = None
        self.y_test = None
        
    def load(self):
        """Load execution logs from JSONL."""
        print(f"Loading from {EXEC_LOG}...")
        
        data = []
        with open(EXEC_LOG) as f:
            for i, line in enumerate(f):
                try:
                    record = json.loads(line)
                    data.append(record)
                except json.JSONDecodeError as e:
                    print(f"Warning: Skipping line {i+1}: {e}")
        
        self.df = pd.DataFrame(data)
        print(f"✓ Loaded {len(self.df)} records")
        
        # Basic stats
        print(f"\nTask distribution:")
        print(self.df['task'].value_counts())
        print(f"\nAgent distribution:")
        print(self.df['agent'].value_counts())
        print(f"\nSuccess rate: {self.df['success'].mean():.2%}")
        
        return self
    
    def featurize_tasks(self, max_features=100, ngram_range=(1, 2)):
        """
        Convert task strings to TF-IDF features.
        
        Args:
            max_features: Maximum number of features
            ngram_range: N-gram range for TF-IDF
        """
        print(f"\nFeaturizing tasks (max_features={max_features})...")
        
        # Handle missing task descriptions
        self.df['task_text'] = self.df['task'].fillna('unknown')
        
        # Create TF-IDF vectorizer
        self.tfidf = TfidfVectorizer(
            max_features=max_features,
            ngram_range=ngram_range,
            lowercase=True,
            stop_words='english'
        )
        
        # Fit and transform
        self.task_features = self.tfidf.fit_transform(self.df['task_text'])
        
        print(f"✓ Created {self.task_features.shape[1]}-dimensional features")
        print(f"✓ Vocabulary size: {len(self.tfidf.vocabulary_)}")
        
        return self
    
    def encode_agents(self):
        """Encode agent names as integer labels."""
        print("\nEncoding agents...")
        
        self.agent_encoder = LabelEncoder()
        self.df['agent_id'] = self.agent_encoder.fit_transform(self.df['agent'])
        
        agent_classes = dict(enumerate(self.agent_encoder.classes_))
        print(f"✓ Encoded {len(agent_classes)} agents:")
        for idx, agent in agent_classes.items():
            count = (self.df['agent_id'] == idx).sum()
            print(f"  {idx}: {agent} (n={count})")
        
        return self
    
    def create_split(self, test_size=0.2, random_state=42):
        """Create train/test split."""
        print(f"\nCreating train/test split (test_size={test_size})...")
        
        # Convert sparse matrix to dense
        X = self.task_features.toarray()
        y = self.df['agent_id'].values
        
        # Split
        X_train, X_test, y_train, y_test = train_test_split(
            X, y,
            test_size=test_size,
            random_state=random_state,
            stratify=y  # Ensure balanced splits
        )
        
        self.X_train = torch.FloatTensor(X_train)
        self.X_test = torch.FloatTensor(X_test)
        self.y_train = torch.LongTensor(y_train)
        self.y_test = torch.LongTensor(y_test)
        
        print(f"✓ Train set: {len(self.X_train)} samples")
        print(f"✓ Test set: {len(self.X_test)} samples")
        print(f"✓ Feature dimension: {X.shape[1]}")
        print(f"✓ Number of agents: {len(self.agent_encoder.classes_)}")
        
        return self
    
    def export(self, base_path="data/models"):
        """Export data to PyTorch format."""
        print(f"\nExporting to {base_path}...")
        
        Path(base_path).mkdir(parents=True, exist_ok=True)
        
        # Save tensors
        torch.save({
            'X_train': self.X_train,
            'y_train': self.y_train,
            'X_test': self.X_test,
            'y_test': self.y_test,
            'feature_dim': self.X_train.shape[1],
            'num_agents': len(self.agent_encoder.classes_),
        }, f"{base_path}/agent-router-data.pt")
        
        # Save encoders/vectorizers
        with open(f"{base_path}/agent-router-tfidf.pkl", 'wb') as f:
            pickle.dump(self.tfidf, f)
        
        with open(f"{base_path}/agent-router-encoder.pkl", 'wb') as f:
            pickle.dump(self.agent_encoder, f)
        
        print(f"✓ Saved tensors to {base_path}/agent-router-data.pt")
        print(f"✓ Saved TF-IDF vectorizer")
        print(f"✓ Saved agent encoder")
        
        # Print summary
        print(f"\n--- Summary ---")
        print(f"Training samples: {len(self.X_train)}")
        print(f"Test samples: {len(self.X_test)}")
        print(f"Feature dimension: {self.X_train.shape[1]}")
        print(f"Number of classes: {len(self.agent_encoder.classes_)}")
        print(f"Agent classes: {list(self.agent_encoder.classes_)}")
        
        return self
    
    def summary(self):
        """Print data summary."""
        if self.df is None:
            print("No data loaded. Run .load() first.")
            return
        
        print("\n=== Data Summary ===")
        print(f"Total records: {len(self.df)}")
        print(f"\nColumns: {list(self.df.columns)}")
        print(f"\nFirst few records:")
        print(self.df.head(3).to_string())


def main():
    parser = argparse.ArgumentParser(description="Agent Router Data Preparation")
    parser.add_argument('--load', action='store_true', help='Load and explore data')
    parser.add_argument('--split', action='store_true', help='Create train/test split')
    parser.add_argument('--export', action='store_true', help='Export to tensor format')
    parser.add_argument('--all', action='store_true', help='Do everything')
    parser.add_argument('--output-dir', default='data/models', help='Output directory')
    
    args = parser.parse_args()
    
    # If no args, do all steps
    if not (args.load or args.split or args.export or args.all):
        args.all = True
    
    data = AgentRouterData()
    
    if args.load or args.all:
        data.load()
        data.summary()
    
    if args.split or args.all:
        if data.df is None:
            data.load()
        data.featurize_tasks()
        data.encode_agents()
        data.create_split()
    
    if args.export or args.all:
        if data.X_train is None:
            if data.df is None:
                data.load()
            data.featurize_tasks()
            data.encode_agents()
            data.create_split()
        data.export(args.output_dir)
    
    print("\n✅ Data preparation complete!")


if __name__ == '__main__':
    main()
