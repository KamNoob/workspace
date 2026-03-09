---
name: build-your-own-x
description: Access 345+ step-by-step tutorials for building popular technologies from scratch (databases, web servers, git, docker, neural networks, etc.). Use when seeking implementation guidance, architecture understanding, or learning resources for building complex systems. Supports searching by technology name, programming language, or category. Triggers when Codex needs to understand how to build something, learn by implementing, or reference educational tutorials for technical domains.
---

# Build Your Own X - Tutorial Discovery

This skill provides access to a curated collection of **345+ high-quality tutorials** for implementing popular technologies from scratch. Perfect for understanding architecture, learning deep technical concepts, and seeing real implementation examples.

**Philosophy:** *"What I cannot create, I do not understand" — Richard Feynman.*

## Quick Start

Search for tutorials by technology, language, or category:

```bash
# Search by technology
byox search database
byox search "web server"

# Search by language
byox language python
byox language go

# Browse a category
byox category "Build your own Git"

# Get a random tutorial for exploration
byox random
```

## Available Categories (26)

- 3D Renderer
- Augmented Reality
- BitTorrent Client
- Blockchain / Cryptocurrency
- Bot
- Command-Line Tool
- Database
- Docker
- Emulator / Virtual Machine
- Front-end Framework / Library
- Game
- Git
- Network Stack
- Neural Network
- Operating System
- Physics Engine
- Programming Language
- Regex Engine
- Search Engine
- Shell
- Template Engine
- Text Editor
- Visual Recognition System
- Voxel Engine
- Web Browser
- Web Server

## How to Use This Skill

### Finding Tutorials

Use the CLI tool to query tutorials:

```bash
# List all categories
byox list

# Search tutorials (matches title, language, or category)
byox search <query>

# Get all tutorials for a category
byox category "<category name>"

# Get all tutorials for a specific language
byox language <language>

# Get statistics about available tutorials
byox stats

# Get a random tutorial for exploration
byox random
```

### Understanding the Output

Each tutorial entry shows:

```
<Category> | <Language>
  <Tutorial Title>
  <URL to Tutorial>
```

Example:
```
Build your own Database | Go
  Building a KVDB from Scratch
  https://example.com/build-kvdb-go
```

### Common Use Cases

**Learning System Architecture:**
- `byox search database` — Learn how databases are built
- `byox search "web server"` — Understand HTTP servers
- `byox search git` — Deep dive into version control

**Language-Specific Learning:**
- `byox language python` — Build things in Python
- `byox language rust` — Systems programming tutorials
- `byox language javascript` — Web and Node.js implementations

**Getting Started:**
- `byox stats` — See what's available and most popular languages
- `byox random` — Discover something new
- `byox list` — Browse all categories

## Integration with Codex

When Codex needs to:

1. **Understand how something works** → Search the database for tutorials
2. **Learn implementation patterns** → Find language-specific examples
3. **Design architecture** → Reference real implementations in tutorial guides
4. **Answer "how do I build X?"** → Query relevant tutorials

Codex can reference these tutorials when explaining concepts, suggesting approaches, or providing educational resources.

## Tutorial Statistics

- **Total Tutorials:** 345+
- **Total Categories:** 26
- **Most Popular Languages:** JavaScript, Python, Go, Rust, C++, TypeScript, Java
- **Popular Domains:** Databases, Web Servers, Programming Languages, Networks, Games

## Examples

### Search by Technology

```bash
$ byox search blockchain
Found 8 tutorial(s):

Build your own Blockchain / Cryptocurrency | JavaScript
  Create a Blockchain From Scratch
  https://example.com/blockchain-js

Build your own Blockchain / Cryptocurrency | Python
  Build Your Own Cryptocurrency
  https://example.com/crypto-python
```

### Search by Language

```bash
$ byox language rust
Found 12 tutorial(s):

Build your own WebServer | Rust
  Building a Web Server in Rust
  https://example.com/webserver-rust

Build your own Programming Language | Rust
  Crafting Interpreters in Rust
  https://example.com/interpreter-rust
```

### Get Statistics

```bash
$ byox stats

Statistics:
  Total Categories: 26
  Total Tutorials: 345

Top Languages:
  JavaScript: 45
  Python: 38
  Go: 32
  C++: 28
  Rust: 25
  TypeScript: 20
  Java: 18
```

## Files in This Skill

- **lib/byox-index.js** — Core search and query library
- **bin/byox-cli.js** — Command-line interface tool
- **references/tutorials-index.json** — Structured tutorial database (345+ entries)

## Notes

- Tutorial index is machine-parsed from the original repository
- All tutorials are links to external resources (books, blogs, GitHub repos)
- Languages are community-contributed and vary by technology
- For new tutorials, visit https://github.com/KamNoob/build-your-own-x

## Further Reading

- **Original Repository:** https://github.com/KamNoob/build-your-own-x
- **Concept:** Learning by building (Feynman Technique)
- **Best For:** Deep technical understanding, architecture learning, implementation guidance
