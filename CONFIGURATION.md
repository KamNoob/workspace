# CONFIGURATION.md - Complete Configuration Reference

_OpenClaw configuration files, environment variables, and customization guide_

---

## Overview

This document describes every configuration file, environment variable, and setting in the OpenClaw system.

**Last Updated:** 2026-03-21 17:58 GMT  
**Current Config Status:** ✅ Operational (sensible defaults, ready for customization)

---

## Configuration Files

### 1. OpenClaw Gateway Config

**Location:** `~/.openclaw/config.json`  
**Managed By:** OpenClaw CLI  
**Modify Via:** `openclaw config` commands or direct edit

**Current Status:**
```bash
# View current config (subset)
openclaw config get

# View specific path
gateway config.schema.lookup --path "gateway.bind"

# Apply changes (full config)
gateway config.apply --raw <json>

# Partial update (merges with existing)
gateway config.patch --raw <json>
```

**Key Sections:**

#### Gateway Binding
```json
{
  "gateway": {
    "bind": "127.0.0.1:18789",
    "remoteUrl": null,
    "trustedProxies": [],
    "corsOrigins": ["http://127.0.0.1:18789"]
  }
}
```

**What it does:**
- `bind`: Local address where gateway listens (loopback = not internet-exposed)
- `remoteUrl`: External URL if exposed via reverse proxy (null = local only)
- `trustedProxies`: IP addresses of reverse proxies (configure if behind nginx/Apache)
- `corsOrigins`: Allowed origins for WebSocket connections

**Default:** Loopback only (127.0.0.1:18789), suitable for local agent coordination.

#### Agent Configuration
```json
{
  "agents": {
    "default": "claude-haiku-4-5",
    "models": [
      "anthropic/claude-haiku-4-5",
      "anthropic/claude-sonnet-4-5",
      "anthropic/claude-opus-4-5"
    ],
    "defaultOptions": {
      "contextWindow": 200000,
      "temperature": 0.7,
      "maxTokens": 4096
    }
  }
}
```

**What it does:**
- `default`: Primary model for spawning agents
- `models`: Available models (fallback chain)
- `defaultOptions`: Temperature, context size, token limits

**Current Setting:** Haiku (fastest, most cost-effective) as default.

#### Channel Configuration
```json
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "state": "linked",
      "phone": "+447838254852",
      "accountId": "..."
    }
  }
}
```

**Current State:**
- WhatsApp: ✅ Enabled and linked
- WebChat: ✅ Built-in, always available
- Other channels: Available but not configured

**To Enable New Channel:**
```bash
# Configure Telegram
openclaw config.patch --raw '{"channels": {"telegram": {"enabled": true, "token": "YOUR_TOKEN"}}}'

# Restart gateway
openclaw gateway restart
```

#### Plugins & Skills
```json
{
  "plugins": {
    "entries": [
      {"id": "memory-core", "enabled": true},
      {"id": "device-pair", "enabled": true},
      {"id": "cron", "enabled": true}
    ]
  }
}
```

**Currently Active:**
- ✅ Memory system (memory-core)
- ✅ Device pairing (device-pair)
- ✅ Cron scheduler (cron)

---

### 2. Environment Variables

**Location:** `~/.openclaw/.env`  
**Format:** KEY=VALUE pairs (dotenv)  
**Loaded By:** OpenClaw startup

**Important:** Never commit .env to git (it's .gitignored).

#### Core Variables (Already Set)
```bash
OPENCLAW_GATEWAY_TOKEN=<internal-token>
OPENCLAW_GATEWAY_URL=ws://127.0.0.1:18789
OPENCLAW_HOME=~/.openclaw
OPENCLAW_WORKSPACE=/home/art/.openclaw/workspace
```

#### Optional: Notion Integration (Not Yet Configured)
```bash
# When adding Notion sync support, add:
NOTION_KEY=ntn_...
NOTION_COMMAND_CENTER_ID=52dab2f6-...
NOTION_PROJECTS_DB_ID=...
NOTION_TASKS_DB_ID=...
NOTION_TEAM_DB_ID=...
NOTION_KB_DB_ID=...
```

**How to Set:**
```bash
# Edit .env directly
nano ~/.openclaw/.env

# Add variables (one per line)
NOTION_KEY=ntn_xxxxx
NOTION_COMMAND_CENTER_ID=52dab2f6-xxxxx

# Restart gateway to load new variables
openclaw gateway restart
```

#### Optional: Voice/TTS (Not Yet Configured)
```bash
# ElevenLabs for text-to-speech
ELEVENLABS_API_KEY=sk_...
ELEVENLABS_VOICE_ID=EXAVITQu4vr4xnSDxMaL  # Optional: specific voice
```

#### Optional: External APIs
```bash
# Web search (already have Brave built-in)
TAVILY_API_KEY=tvly-...  # For enhanced research

# Analytics (optional)
DATADOG_API_KEY=...
```

**Loading .env in Scripts:**
```bash
# In bash scripts, source it
source ~/.openclaw/.env

# Then use
echo $NOTION_KEY
```

---

### 3. Memory Configuration

**Location:** `.memory-optimizer-state.json` (workspace root)  
**Type:** JSON state file (auto-managed)

**Current Configuration:**
```json
{
  "algorithm": "q-learning-tdlambda",
  "hyperparameters": {
    "learning_rate": 0.1,
    "discount_factor": 0.95,
    "lambda": 0.9,
    "epsilon": 0.1
  },
  "stats": {
    "total_recalls": 142,
    "failed_recalls": 3,
    "success_rate": 0.979,
    "avg_lookup_ms": 2.3
  }
}
```

**What to Modify:**
- `learning_rate`: How fast Q-values update (0.1 = moderate)
- `discount_factor`: Weight of future rewards (0.95 = high)
- `lambda`: Eligibility trace decay (0.9 = good balance)
- `epsilon`: Exploration rate (0.1 = mostly exploit, some explore)

**When to Change:**
- Agents converging too slowly? Increase `learning_rate` (0.1 → 0.2)
- Too much random exploration? Decrease `epsilon` (0.1 → 0.05)
- Forgetting recent changes? Increase `lambda` (0.9 → 0.95)

**Do NOT modify manually unless you know RL.** Phase 7B updates this automatically.

---

### 4. Task Routing Configuration

**Location:** `data/rl/rl-agent-selection.json`  
**Type:** JSON (Q-learning state for agent selection)  
**Managed By:** Phase 7A/7B learning system

**Current Configuration:**
```json
{
  "task_types": {
    "research": {
      "agents": {
        "Scout": {"q_score": 0.803, "success_rate": 0.89, "avg_latency_ms": 4200},
        "Chronicle": {"q_score": 0.616, "success_rate": 0.67, "avg_latency_ms": 5100},
        "Codex": {"q_score": 0.40, "success_rate": 0.33, "avg_latency_ms": 6000}
      },
      "optimal_agent": "Scout"
    },
    "code": {
      "agents": {
        "Codex": {"q_score": 0.75, "success_rate": 0.85, "avg_latency_ms": 3800},
        "QA": {"q_score": 0.70, "success_rate": 0.80, "avg_latency_ms": 4100},
        "Veritas": {"q_score": 0.70, "success_rate": 0.78, "avg_latency_ms": 4300}
      },
      "optimal_agent": "Codex"
    },
    "security": {
      "agents": {
        "Cipher": {"q_score": 0.90, "success_rate": 0.93, "avg_latency_ms": 5200},
        "Sentinel": {"q_score": 0.532, "success_rate": 0.57, "avg_latency_ms": 6800}
      },
      "optimal_agent": "Cipher"
    }
  }
}
```

**Customization Options:**

**Option 1: Adjust Agent Priority (Manual)**
```json
// Prefer Veritas over Codex for code tasks (for testing)
"code": {
  "agent_order": ["Veritas", "Codex", "QA"],
  "force_agent": null  // Set to "Veritas" to force always
}
```

**Option 2: Add New Task Type**
```json
{
  "my_custom_task": {
    "agents": {
      "Sentinel": {"q_score": 0.55},
      "Echo": {"q_score": 0.45}
    },
    "optimal_agent": "Sentinel"
  }
}
```

**Option 3: Block an Agent from a Task**
```json
// In research, prevent Codex from being selected
"research": {
  "blocked_agents": ["Codex"],
  "agents": { /* ... */ }
}
```

**When to Modify:**
- Agent performing poorly? Phase 7B will update Q-scores automatically
- Want to test different agent? Use `force_agent` temporarily
- Adding new task type? Add entry to `task_types` dict

**DO NOT edit Q-scores manually** — Phase 7B updates them based on real outcomes.

---

### 5. SLA Configuration (Phase 11B)

**Location:** `scripts/ml/sla-calculator.jl` (embedded in script)  
**Type:** Julia constants  
**Managed By:** SLA calculator job

**Current SLA Targets:**
```julia
# Success rate target
SLA_SUCCESS_RATE = 0.95  # 95% tasks should succeed

# Latency targets (milliseconds)
SLA_LATENCY_MEAN = 5000   # Average should be < 5 seconds
SLA_LATENCY_P95 = 15000   # 95th percentile < 15 seconds

# Cost targets (tokens per task)
SLA_COST_MEAN = 2000      # Average cost < 2000 tokens
SLA_COST_MAX = 5000       # Max cost < 5000 tokens

# Quality targets (0-1 scale)
SLA_QUALITY_MIN = 0.75    # Minimum quality score 0.75
```

**To Customize:**
```bash
# Edit SLA script
nano scripts/ml/sla-calculator.jl

# Change targets
SLA_SUCCESS_RATE = 0.98   # Stricter success requirement
SLA_LATENCY_MEAN = 3000   # Faster response target

# Save and restart daily cron
# (or run manually: julia scripts/ml/sla-calculator.jl)
```

**SLA Output:** `data/sla-metrics/YYYY-MM-DD.json`
```json
{
  "date": "2026-03-21",
  "metrics": {
    "success_rate": 0.96,
    "latency_mean_ms": 4800,
    "latency_p95_ms": 14200,
    "cost_mean_tokens": 1950,
    "quality_score": 0.82
  },
  "sla_status": {
    "success_rate": "PASS",
    "latency": "PASS",
    "cost": "PASS",
    "quality": "WARN"
  }
}
```

---

### 6. Compliance Configuration (Phase 11C)

**Location:** `scripts/ml/compliance-reporter.jl`  
**Type:** Julia script (constants + logic)  

**Current Compliance Checks:**
```julia
# Audit completeness
AUDIT_COMPLETENESS_TARGET = 1.0  # 100% of tasks logged

# Anomaly detection thresholds
ANOMALY_AGENT_THRESHOLD = 0.5    # Flag agents with Q < 0.5
ANOMALY_FAILURE_THRESHOLD = 0.1  # Flag if 10%+ tasks fail

# Data retention
AUDIT_LOG_RETENTION_DAYS = 90     # Keep audit logs 90 days
COMPLIANCE_REPORT_RETENTION = 365 # Keep reports 1 year

# Regulatory requirements
AUDIT_IMMUTABLE = true            # Logs are immutable
AUDIT_TIMESTAMPED = true          # Every log entry has timestamp
AUDIT_USER_TRACKED = true         # Log who triggered task
```

**Compliance Output:** `data/compliance-reports/YYYY-WW.json`
```json
{
  "week": "2026-W12",
  "period": "2026-03-17 to 2026-03-23",
  "audit_status": {
    "total_tasks": 487,
    "logged_tasks": 487,
    "completeness": 1.0,
    "status": "COMPLIANT"
  },
  "agent_anomalies": [
    {"agent": "Chronicle", "q_score": 0.616, "status": "WARN"}
  ],
  "security_summary": {
    "breaches": 0,
    "failures": 5,
    "recovery_time_ms": 234
  }
}
```

---

### 7. Cron Job Configuration

**Location:** OpenClaw cron scheduler (internal)  
**Managed By:** `openclaw cron` commands

**View All Jobs:**
```bash
openclaw cron list
```

**Add New Job:**
```bash
# Example: Daily report at 10:00 AM
openclaw cron add \
  --name "Daily Report" \
  --schedule "cron" \
  --expr "0 10 * * *" \
  --tz "Europe/London" \
  --payload "systemEvent" \
  --text "Running daily report generation" \
  --sessionTarget "main"
```

**Modify Existing Job:**
```bash
# Update schedule for job ID: abc123
openclaw cron update abc123 \
  --patch '{"schedule": {"expr": "0 11 * * *"}}'

# Disable job
openclaw cron update abc123 --patch '{"enabled": false}'

# Re-enable
openclaw cron update abc123 --patch '{"enabled": true}'
```

**Delete Job:**
```bash
openclaw cron remove abc123
```

**Check Job Status:**
```bash
# List runs for a job
openclaw cron runs abc123 --limit 10

# Trigger job immediately
openclaw cron run abc123
```

**Current Sync Jobs (Created 2026-03-21):**

| Job ID | Name | Schedule | Status |
|--------|------|----------|--------|
| `f2a2f272-de61-41e5-86f9-05dacff13f67` | Sync: Memory to KB | 00:05 UTC | ✅ Active |
| `32ba23a0-abe0-40df-b58c-1f1af8f972bb` | Sync: Tasks to Cron | 01:00 UTC | ✅ Active |
| `a1c1f39c-2c30-473a-9894-03c7e06e64ee` | Sync: Agent Status | Every hour | ✅ Active |
| `e00a56cf-69b2-4daa-8b95-c296ef3c2fb5` | Phase 11 SLA Daily | 02:00 UTC | ✅ Active |
| `6b9ed0c0-35fb-4cbd-bd0e-21c5012905ea` | Phase 11 Compliance Weekly | 10:00 Mon | ✅ Active |

---

### 8. Git Configuration

**Location:** `.git/config` (repository root)  
**Current Configuration:**
```bash
[user]
  name = Claude Code
  email = claude@anthropic.com

[core]
  repositoryformatversion = 0
  filemode = true
  ignorestat = false

[remote "origin"]
  url = https://github.com/KamNoob/workspace.git
  fetch = +refs/heads/*:refs/remotes/origin/*
```

**Modify User Name/Email:**
```bash
git config user.name "Your Name"
git config user.email "your@email.com"

# Or globally
git config --global user.name "Your Name"
```

**View All Git Config:**
```bash
git config --list
git config --list --show-origin  # Show where each setting comes from
```

**Important:** GitHub remote is set. All commits automatically push to origin.

---

### 9. Obsidian Vault Configuration

**Location:** `~/Obsidian/Main/` (vault root)  
**Managed By:** Obsidian app

**Vault-Level Settings (in Obsidian):**
```
Settings → Files & Links:
  • New file location: Main folder
  • Default Markdown format: CommonMark
  • Attachments folder: Attachments/

Settings → Community Plugins:
  • (Currently none; using core features only)
```

**Current Vault Content:**
- Tesla-369-Obsession.md (1 note)
- Expandable for future notes

**To Add More Notes:**
```bash
# Create new note directly
cat > ~/Obsidian/Main/My-Note.md << 'EOF'
# My Note

This is a new Obsidian note.
EOF

# Obsidian will pick it up automatically
```

---

## Environment-Specific Configuration

### Development Environment (Current)
```bash
Gateway binding: 127.0.0.1:18789 (loopback only)
Models: All (Haiku default, Sonnet/Opus available)
Logging: Verbose (/tmp/openclaw/openclaw-*.log)
Debug mode: Off (set OPENCLAW_DEBUG=1 to enable)
Audit: Full (all tasks logged to JSON-L)
```

### Production-Ready Setup (If Deploying)
```bash
# Gateway exposed via reverse proxy
gateway:
  bind: "0.0.0.0:18789"  # Listen on all interfaces
  trustedProxies: ["192.168.1.100"]  # Trust nginx/Apache
  remoteUrl: "https://openclaw.example.com"

# Stricter SLA targets
SLA_SUCCESS_RATE = 0.99
SLA_LATENCY_MEAN = 2000

# Enable alerting
ALERT_CHANNEL = "slack"
SLACK_WEBHOOK = "..."
```

**Note:** Current setup is development/local. Customization needed for production deployment.

---

## Configuration Checklist

### ✅ Essentials (All Set)
- [x] Gateway running on loopback (127.0.0.1:18789)
- [x] WhatsApp connected
- [x] Git repository configured
- [x] Agent models available
- [x] Cron scheduler active
- [x] Audit logging enabled

### 🟡 Optional (Not Yet Configured)
- [ ] Notion API integration (NOTION_KEY)
- [ ] Advanced TTS (ELEVENLABS_API_KEY)
- [ ] Tavily search enhancement (TAVILY_API_KEY)
- [ ] Reverse proxy exposure (if needed)
- [ ] Email alerts (for cron failures)
- [ ] Slack/Discord hooks (for notifications)

### 🔍 For Future Review
- [ ] SLA targets (currently 0.95 success rate)
- [ ] Compliance thresholds (currently 1.0 audit completeness)
- [ ] Model selection (currently Haiku default)
- [ ] Agent Q-score thresholds (currently auto-tuned)

---

## Common Configuration Tasks

### Task 1: Switch Default Model to Sonnet
```bash
# Edit config
openclaw config.patch --raw '{"agents": {"default": "anthropic/claude-sonnet-4-5"}}'

# Restart
openclaw gateway restart

# Verify
openclaw status | grep "Model"
```

### Task 2: Add Notion Integration
```bash
# Get Notion API key from https://www.notion.so/my-integrations
# Add to ~/.openclaw/.env
echo "NOTION_KEY=ntn_xxxxx" >> ~/.openclaw/.env
echo "NOTION_COMMAND_CENTER_ID=52dab2f6-xxxxx" >> ~/.openclaw/.env

# Restart
openclaw gateway restart

# Update sync scripts to use Notion API
# (currently stubbed, need implementation)
```

### Task 3: Increase SLA Success Target
```bash
# Edit compliance script
nano scripts/ml/sla-calculator.jl

# Change:
# SLA_SUCCESS_RATE = 0.95
# to:
# SLA_SUCCESS_RATE = 0.98

# Next daily run (02:00 UTC) will use new target
```

### Task 4: Adjust Agent Q-Score Thresholds
```bash
# Edit task routing config
nano data/rl/rl-agent-selection.json

# Add custom thresholds:
# "agent_min_q_score": 0.6  # Don't use agents below 0.6
# "success_rate_minimum": 0.75

# Changes take effect next Phase 7B run (hourly)
```

### Task 5: Enable Debug Logging
```bash
# Temporarily enable verbose logging
export OPENCLAW_DEBUG=1

# View logs
tail -f /tmp/openclaw/openclaw-*.log | grep "DEBUG"

# Disable when done
unset OPENCLAW_DEBUG
```

---

## Troubleshooting Configuration

### Gateway Won't Start
```bash
# Check logs
tail -20 /tmp/openclaw/openclaw-*.log | grep -i error

# Verify config is valid JSON
cat ~/.openclaw/config.json | jq . || echo "Invalid JSON"

# Restore from backup
git checkout ~/.openclaw/config.json

# Restart
openclaw gateway restart
```

### WhatsApp Disconnected
```bash
# Wait 30 seconds (reconnection attempt)
sleep 30

# Check status
openclaw status | grep WhatsApp

# If still disconnected, re-auth
# (scan QR code in gateway dashboard or CLI)
```

### Cron Jobs Not Running
```bash
# List jobs and status
openclaw cron list

# Check if enabled
openclaw cron list | grep "enabled.*false"

# Enable if needed
openclaw cron update <job-id> --patch '{"enabled": true}'

# Trigger manually
openclaw cron run <job-id>

# Check last run
openclaw cron runs <job-id> --limit 1
```

### Memory/Learning Not Updating
```bash
# Check Phase 7B is running
openclaw cron list | grep "Phase 7B"

# Verify task log exists
ls -lh data/rl/rl-task-execution-log.jsonl

# Force immediate insights run
openclaw cron run <phase7b-job-id>

# Check output
cat phase7b-learnings.json | jq .
```

---

## Configuration Best Practices

1. **Use Environment Variables for Secrets**
   - Never hardcode API keys in config files
   - Always store in `.env` (gitignored)
   - Load at runtime: `source ~/.openclaw/.env`

2. **Version Control Configuration**
   - Commit safe configs to git (`config.json` structure OK)
   - Never commit `.env` or secrets
   - Document changes in commit messages

3. **Test Configuration Changes**
   - Use `--patch` for partial updates (safer)
   - Test cron jobs manually before scheduling
   - Monitor logs after changes

4. **Backup Before Major Changes**
   - `git commit` before large config edits
   - Keep `.env` backup (offline, encrypted)
   - Test restore procedures quarterly

5. **Automate Repetitive Configuration**
   - Use scripts for common tasks
   - Document in shell scripts (version controlled)
   - Example: `scripts/config/enable-notion.sh`

---

## Configuration Schema Reference

**Full schema available:**
```bash
# View entire schema
openclaw config.schema.lookup

# View specific subsection
openclaw config.schema.lookup --path "gateway"
openclaw config.schema.lookup --path "agents"
openclaw config.schema.lookup --path "channels"
```

**Useful Paths:**
```
gateway.bind
gateway.trustedProxies
agents.default
agents.models
channels.whatsapp
plugins.entries
```

---

## Version History

| Date | Config | Status |
|------|--------|--------|
| 2026-03-21 | Sync infrastructure added | ✅ Live |
| 2026-03-21 | Phase 11 (Audit+SLA+Compliance) | ✅ Live |
| 2026-03-15 | Phase 7B (Hourly Insights) | ✅ Live |
| 2026-03-09 | Base gateway + agent team | ✅ Live |

---

## Support & Next Steps

**For Configuration Questions:**
1. Check this document first
2. Run `openclaw config.schema.lookup --path "<question>"`
3. Review example in INFRASTRUCTURE.md
4. Contact Art via WhatsApp if stuck

**Common Next Steps:**
- [ ] Set up Notion integration (when credentials available)
- [ ] Enable TTS for voice outputs (when ELEVENLABS_API_KEY ready)
- [ ] Customize SLA targets based on workload
- [ ] Add custom cron jobs as needed

---

**Document Created:** 2026-03-21 17:58 GMT  
**By:** Morpheus (Lead Agent)  
**Status:** ✅ Complete & Ready for Use  
**Next Review:** On next config change
