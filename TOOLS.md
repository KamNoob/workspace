# TOOLS.md - Local Setup & Configuration

_Your development environment, tools, and infrastructure._

---

## System Environment

### Host
- **Hostname:** art-OptiPlex-ubu2
- **OS:** Ubuntu Linux 6.8.0-101-generic (x64)
- **User:** art
- **Home:** /home/art
- **Workspace:** /home/art/.openclaw/workspace

### Runtime Versions
- **Python:** 3.12.3 ✅
- **Node.js:** v24.11.0 ✅
- **npm:** Installed ✅
- **Git:** /usr/bin/git ✅
- **Julia:** 1.12.5 ✅ (`/snap/julia/165/bin/julia`)
- **Bash:** 5+ ✅

### Git Configuration
```bash
user.name = Claude Code
user.email = claude@anthropic.com
```

---

## Critical Setup Status

### ✅ Julia (INSTALLED — Ready for Phase 2a/2b)
**Required for:** QualityPredictor agent spawning system  
**Status:** Installed via snap (v1.12.5, classic)  
**Location:** `/snap/julia/165/bin/julia`  
**Symlink:** `/snap/julia/current/bin/julia`  
**Priority:** Phase 2a/2b can now activate ✅

**Verify installation:**
```bash
/snap/julia/165/bin/julia --version
# julia version 1.12.5
```

**Quick start (Phase 2a Testing):**
```bash
# Test Quality Predictor
/snap/julia/165/bin/julia scripts/ml/agent-spawner-qp.jl --help
/snap/julia/165/bin/julia scripts/ml/agent-spawner-qp.jl --task code --candidates "Codex,QA"

# Or use alias (add to ~/.bashrc for convenience)
alias spawn-smart='/snap/julia/165/bin/julia /home/art/.openclaw/workspace/scripts/ml/agent-spawner-qp.jl'
source ~/.bashrc
spawn-smart --task code --candidates "Codex,QA,Veritas"
```

**Ready-to-run workflow templates:**
```bash
# Make templates executable
chmod +x /home/art/.openclaw/workspace/scripts/workflows/*-qp.sh

# Test code review workflow
cd /home/art/.openclaw/workspace
./scripts/workflows/code-review-qp.sh "test feature" medium

# Test research workflow
./scripts/workflows/research-qp.sh "my research topic" standard

# Test security audit workflow
./scripts/workflows/security-audit-qp.sh "my service" full
```

---

### ✅ Notion Integration (Configured but Verify)
**Purpose:** Task/project syncing, knowledge base, team status  
**Status:** Scripts exist, but .env needs verification

**Required environment variables (in ~/.openclaw/.env):**
```bash
NOTION_KEY=ntn_...                    # Notion API token
NOTION_COMMAND_CENTER_ID=52dab2f6... # Main hub database
NOTION_PROJECTS_DB_ID=...            # Project tracking
NOTION_TASKS_DB_ID=...               # Task board
NOTION_TEAM_DB_ID=...                # Agent/team status
NOTION_KB_DB_ID=...                  # Knowledge base
```

**Verify Notion setup:**
```bash
# Check env variables
env | grep NOTION

# Test API connectivity
curl -H "Authorization: Bearer $NOTION_KEY" https://api.notion.com/v1/users/me

# View workspace sync logs
tail -f ~/sync-logs/memory-to-kb.log
```

**Sync scripts (run automatically via cron):**
- `sync-memory-to-kb.sh` — Daily 00:05 UTC (MEMORY.md → Knowledge Base)
- `sync-tasks-to-cron.sh` — Daily 01:00 UTC (Tasks → Cron Queue)
- `sync-agent-status.sh` — Hourly :00 (Agent Status → Team DB)

---

### ✅ GitHub CLI Integration (Installed)
**Status:** git installed, ready for PR review workflows  
**Location:** /usr/bin/git

**Workflow templates that use it:**
- `scripts/workflows/code-review-qp.sh` — Reviews PRs with agent spawning

**Verify GitHub access:**
```bash
git remote -v
git status
```

---

## Development Scripts

### ML/RL Tools

| Script | Purpose | Status | Requires |
|--------|---------|--------|----------|
| `scripts/ml/QualityPredictor.jl` | Agent capability scoring | Ready | Julia |
| `scripts/ml/agent-spawner-qp.jl` | CLI + prediction engine | Ready | Julia |
| `scripts/ml/quality-predictor.jl` | Legacy version (backup) | Ready | Julia |
| `scripts/ml/unified-learning-system.jl` | P0+P1+P2 orchestrator | **LIVE** | Julia |
| `scripts/ml/feedback-validator.jl` | P0: Feedback → Q-learning | **LIVE** | Julia |
| `scripts/ml/collaboration-graph.jl` | P1: Agent pair analysis | **LIVE** | Julia |
| `scripts/ml/knowledge-extractor.jl` | P2: Pattern extraction | **LIVE** | Julia |
| `data/rl/rl-agent-selection.json` | Q-learning profiles | Live | — |
| `data/rl/rl-task-execution-log.jsonl` | Outcome tracking | Live | — |
| `data/feedback-logs/feedback-validation.jsonl` | User feedback trail | Live | — |
| `data/collaboration-graph.json` | Agent pair performance | Live | — |
| `data/knowledge-base/extracted-patterns.json` | Solution patterns | Live | — |

### Workflow Templates

| Template | Purpose | Status | Requires |
|----------|---------|--------|----------|
| `scripts/workflows/code-review-qp.sh` | Code review automation | Ready | Julia, git |
| `scripts/workflows/research-qp.sh` | Research task routing | Ready | Julia |
| `scripts/workflows/security-audit-qp.sh` | Security audits | Ready | Julia |
| `scripts/workflows/chain-b-code-dev.sh` | Code development | Ready | — |

**Activate templates:**
```bash
chmod +x /home/art/.openclaw/workspace/scripts/workflows/*-qp.sh
cd /home/art/.openclaw/workspace

# Test one
./scripts/workflows/code-review-qp.sh "test feature" medium
./scripts/workflows/research-qp.sh "my research topic" standard
```

---

## Local Infrastructure

### OpenClaw Gateway
- **Port:** 18789 (loopback)
- **Status:** Running (PID 1862892)
- **Health:** RPC probe OK
- **Log:** /tmp/openclaw/openclaw-2026-03-09.log

**Check status:**
```bash
openclaw status
openclaw gateway status
```

### WhatsApp Integration
- **Status:** Connected ✅
- **Connection:** Via gateway on 18789
- **Messaging:** Enabled for allowed numbers

**Verify:**
```bash
# Check in gateway logs
tail -20 /tmp/openclaw/openclaw-*.log | grep -i whatsapp
```

### Memory & Learning Systems
- **Local Embeddings:** EmbeddingGemma-300M-Q8_0 (local, no API)
- **Search:** Hybrid (85% semantic + 15% keyword)
- **Sync:** Auto-watches workspace files
- **Optimizer:** Q-learning with TD(λ) (live, 98% recall rate)

### New: Unified Learning System (P0+P1+P2)
- **P0 Feedback Validation:** User feedback → Q-learning updates (every 6h)
- **P1 Collaboration Detection:** Agent pairs → performance patterns
- **P2 Knowledge Extraction:** Task outcomes → reusable patterns (warm-start)
- **Status:** ✅ LIVE (deployed 2026-03-28)
- **Cron Jobs:** 
  - Feedback processing: Every 6 hours
  - Full learning cycle: Daily 03:00 UTC
- **Command:** `julia scripts/ml/unified-learning-system.jl --report`
- **Docs:** `docs/LEARNING-SYSTEM.md` (complete reference)

---

## SSH & Remote Access

### SSH Keys
- **Location:** ~/.ssh/
- **Status:** Keys exist (known_hosts configured)
- **Current:** ⚠️ Add your remote hosts as needed

**Add a remote host:**
```bash
# First-time connection (adds to known_hosts)
ssh your_user@your_host

# Or add key-based auth:
ssh-keygen -t ed25519 -f ~/.ssh/id_your_host -C "art@art-OptiPlex"
ssh-copy-id -i ~/.ssh/id_your_host your_user@your_host
```

**Common remotes (add as needed):**
```bash
# Example git remote for code repos
git remote add origin git@github.com:your-org/your-repo.git

# Example data server
# ssh art@data-server.local
```

---

## API Keys & Credentials

### Stored Securely
**Location:** ~/.openclaw/.env (gitignored, not tracked)

**What's configured:**
- OPENCLAW_GATEWAY_TOKEN (internal gateway auth)
- NOTION_KEY + database IDs (task/project syncing)
- Other API keys (as needed, see SYNC_SCRIPTS_MANIFEST.md)

**Managing credentials:**
```bash
# View current (use with caution)
env | grep -E "NOTION|OPENCLAW|API|TOKEN|KEY"

# Update a credential
echo 'NEW_VALUE' > ~/.openclaw/.env  # Edit carefully
systemctl --user restart openclaw-gateway
```

**Best practice:** Keep .env in ~/.openclaw/ (never in git), reload after changes.

---

## Development Configuration

### Code Editor (VS Code)
- **Location:** /snap/code or ~/.config/Code
- **Extensions:** Various language servers installed
- **Workspace:** Linked to /home/art/.openclaw/workspace

**Settings:**
```bash
# Open workspace settings
code /home/art/.openclaw/workspace
```

### Shell Environment
- **Default Shell:** bash
- **Aliases:** Add to ~/.bashrc as needed

**Useful aliases (optional):**
```bash
# Add to ~/.bashrc
alias spawn-smart='/path/to/julia /home/art/.openclaw/workspace/scripts/ml/agent-spawner-qp.jl'
alias oc='openclaw'
alias ocgw='openclaw gateway'
```

### Git Hooks (Optional)
- **Location:** .git/hooks/
- **Use case:** Auto-log commits, trigger syncs
- **Current:** Not configured (add as needed)

---

## NPM & Node Configuration

### Global Packages
**Installed:**
- openclaw CLI (main package)
- clawhub CLI (skill management)
- Various skill packages (in ~/.npm-global/lib/node_modules/)

**Workspace node_modules:**
```bash
ls -la /home/art/.openclaw/workspace/node_modules/ | head -20
```

**Install dependencies:**
```bash
cd /home/art/.openclaw/workspace
npm install  # If package.json exists
```

---

## Python Environment

### System Python
- **Version:** Python 3.12.3
- **pip:** Installed ✅
- **venv:** Available ✅

### Virtual Environments
**Workspace venv (if exists):**
```bash
# Create one if needed
python3 -m venv /home/art/.openclaw/workspace/venv
source /home/art/.openclaw/workspace/venv/bin/activate

# Install deps
pip install -r requirements.txt  # If it exists
```

### Data Science Stack
**Available (basic check):**
```bash
pip list | grep -E "pandas|numpy|scipy|scikit|tensorflow|torch"
```

**Install if needed:**
```bash
pip install numpy pandas scipy scikit-learn
```

---

## Voice & Audio (Optional)

### TTS (Text-to-Speech)
**Status:** sag skill (ElevenLabs TTS) — currently disabled

**If enabling:**
```bash
# In openclaw config: enable sag skill
# Requires ElevenLabs API key
```

**Preferred voice profile (if needed):**
- Voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod (if available)

---

## System Monitoring

### Resource Monitoring
**Quick check:**
```bash
# CPU, memory, load
top -bn1 | head -20

# Disk usage
df -h /
du -sh /home/art/.openclaw/workspace

# Network
netstat -tlnp | grep 18789  # Gateway port
```

### OpenClaw Health
```bash
# Gateway status
openclaw gateway status

# View recent logs
tail -50 /tmp/openclaw/openclaw-*.log

# Check cron jobs
openclaw cron list
```

---

## Common Tasks

### Start a Dev Session
```bash
cd /home/art/.openclaw/workspace
git status
openclaw status
```

### Run a Workflow
```bash
# Code review (requires Julia)
./scripts/workflows/code-review-qp.sh "my PR" high

# Research task
./scripts/workflows/research-qp.sh "my topic" standard

# Security audit
./scripts/workflows/security-audit-qp.sh "my service" full
```

### Check Agent Selection
```bash
# View Q-learning profiles
cat data/rl/rl-agent-selection.json | jq '.task_types'

# View prediction log
tail -20 rl-prediction-log.jsonl | jq '.'
```

### Update Memory
```bash
# Check what was logged today
ls -la memory/2026-03-09*.md

# Update long-term memory
edit MEMORY.md
git add MEMORY.md
git commit -m "memory: update from daily session"
```

### Sync Tasks to Cron
```bash
# Manual trigger (normally runs daily at 01:00 UTC)
bash /home/art/.openclaw/sync-scripts/sync-tasks-to-cron.sh

# Check logs
tail -20 ~/sync-logs/tasks-to-cron.log
```

---

## TODO: Setup Actions

- [x] **Install Julia** — ✅ Installed (snap, v1.12.5)
- [x] **Activate Phase 2a/2b** — ✅ Completed via workflows
- [ ] **Verify Notion env** — Check NOTION_KEY + database IDs in ~/.openclaw/.env
- [ ] **Test GitHub CLI** — Run a code-review workflow
- [ ] **Add SSH hosts** — If you use remote servers, configure them
- [ ] **Configure Python venv** — If data engineering work needs specific packages
- [ ] **Enable TTS (optional)** — If you want voice features

### Recent Completions (2026-03-28)
- [x] **P0 Feedback Validation System** — ✅ Live, processes feedback every 6h
- [x] **P1 Collaboration Detection** — ✅ Live, identifies high-performing agent pairs
- [x] **P2 Knowledge Extraction** — ✅ Live, builds queryable pattern database
- [x] **Unified Learning Pipeline** — ✅ Live, full cycle runs daily 03:00 UTC
- [x] **Learning System Documentation** — ✅ Complete at `docs/LEARNING-SYSTEM.md`

---

## Quick Reference

| Tool | Location | Command | Status |
|------|----------|---------|--------|
| Julia | /snap/julia/165/bin/julia | `julia --version` | ✅ Ready |
| Python | /usr/bin/python3 | `python3 --version` | ✅ |
| Node | /usr/bin/node | `node --version` | ✅ |
| Git | /usr/bin/git | `git --version` | ✅ |
| OpenClaw | ~/.npm-global/bin/openclaw | `openclaw status` | ✅ |
| Notion Sync | ~/sync-scripts/ | `bash sync-*.sh` | ✅ (needs env) |
| **Learning System** | scripts/ml/ | `julia unified-learning-system.jl --report` | ✅ **LIVE** |
| Q-Learning | scripts/ml/ | `julia feedback-validator.jl` | ✅ **LIVE** |
| Collaboration | scripts/ml/ | `julia collaboration-graph.jl --analyze` | ✅ **LIVE** |
| Knowledge Base | scripts/ml/ | `julia knowledge-extractor.jl --extract` | ✅ **LIVE** |

---

## Notes

- **Julia is critical** for Phase 2a/2b activation. Install it first.
- **Notion credentials** need to be set in ~/.openclaw/.env (not in git).
- **Workflow scripts** are ready; just need Julia + activation.
- **SSH/remote work** — Add your servers/keys as needed.
- **Python/Node packages** — Keep venv clean, use requirements.txt for reproducibility.

---

_Created: 2026-03-09 15:10 GMT_  
_Source: System check + SYNC_SCRIPTS_MANIFEST.md + PHASE2A/2B docs_  
_Next: Install Julia, verify Notion, activate workflows_
