# Prototype — Rapid Development Sandbox

**Purpose:** Safe, isolated space for experiments, tests, and new features without affecting production code.

**Guidelines:**
- 🧪 Experiments and proofs-of-concept
- 🔧 Temporary utilities and one-offs
- 📝 Draft documentation
- 🚀 Feature branches before merge to main
- ⚠️ NOT for production code (use main workspace)

---

## Structure

```
prototype/
├── experiments/       (Ad-hoc tests)
├── features/        (New feature development)
├── drafts/          (Draft docs, ideas)
├── tests/           (Test suites)
└── temp/            (Temporary files, auto-cleanup)
```

---

## Lifecycle

1. **Create:** Add files to `experiments/` or `features/`
2. **Develop:** Iterate freely (no impact on production)
3. **Test:** Add tests to `tests/`
4. **Review:** Move to docs/guides or scripts once stable
5. **Archive:** Move proven code to main workspace
6. **Cleanup:** Delete obsolete experiments (monthly)

---

## Examples

**New agent feature:**
```bash
cp agents/AGENTS_CONFIG.md prototype/features/new-agent.md
# Edit and test
# Move to agents/ when ready
```

**Experimental script:**
```bash
cat > prototype/experiments/test-qdrant.sh << 'EOF'
#!/bin/bash
# Test hybrid search implementation
EOF
bash prototype/experiments/test-qdrant.sh
```

**Draft documentation:**
```bash
cat > prototype/drafts/neural-network-v2.md << 'EOF'
# Neural Network v2 Design
EOF
# Review and move to docs/ml/ when ready
```

---

## Cleanup Schedule

- **Weekly:** Review `temp/`, delete obsolete files
- **Monthly:** Archive successful experiments to main workspace
- **Quarterly:** Deep cleanup, consolidate learnings

---

**Owner:** Morpheus  
**Last Updated:** 2026-03-09
