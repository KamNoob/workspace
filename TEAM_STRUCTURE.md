# TEAM STRUCTURE - Meet Your AI Team

A specialized team of AI agents, each with unique skills and responsibilities. Morpheus orchestrates the team, spawning specialized subagents for specific tasks.

## Team Database
- **URL:** https://www.notion.so/3dc9665ec16d4641870389e086f7420d
- **Database ID:** `3dc9665e-c16d-4641-8703-89e086f7420d`

---

## 👥 The Team

### 🕶️ Morpheus (Lead Agent)
**Role:** Lead / Orchestrator  
**Status:** Active (Always running)  
**Specializations:** System Design, Architecture, Coordination, Code Review

**What Morpheus does:**
- Manages your requests and oversees all work
- Makes architectural decisions
- Coordinates subagents (decides who to spawn)
- Manages memory, schedules, and tasks
- Provides oversight and quality control
- Serves as primary interface to you

**When Morpheus handles it directly:**
- Strategic decisions
- System design questions
- Coordinating between agents
- Your direct requests
- Memory and task management

**Cannot be spawned** - Always running as main agent

---

### 💻 Codex (Developer)
**Role:** Developer  
**Status:** Active (spawn when needed)  
**Specializations:** Backend, Frontend, Code Review, Testing, Debugging

**What Codex does:**
- Writes clean, production-ready code
- Refactors and optimizes code
- Reviews pull requests and code quality
- Debugs complex issues
- Creates scripts and tools
- Writes and runs tests

**When to spawn Codex:**
- Building new features
- Refactoring legacy code
- Debugging complex problems
- Code reviews needed
- Creating scripts or tools
- Performance optimization

**Spawn command:**
```bash
sessions_spawn(
  task="Build a login authentication module",
  agentId="codex"
)
```

---

### 🔐 Cipher (Security)
**Role:** Security Specialist  
**Status:** Active (spawn when needed)  
**Specializations:** Security Audit, Debugging, Architecture, Performance

**What Cipher does:**
- Performs security audits
- Scans for vulnerabilities
- Reviews access controls
- Analyzes encryption
- Threat modeling
- Compliance checking

**When to spawn Cipher:**
- Security audits needed
- Vulnerability assessment
- Access control review
- Encryption analysis
- Threat modeling
- Compliance verification

**Spawn command:**
```bash
sessions_spawn(
  task="Audit the authentication system for vulnerabilities",
  agentId="cipher"
)
```

---

### 🔍 Scout (Researcher)
**Role:** Researcher  
**Status:** Active (spawn when needed)  
**Specializations:** Research, Analysis, Documentation, Architecture

**What Scout does:**
- Researches topics deeply
- Conducts web searches
- Competitive analysis
- Gathers documentation
- Technical investigation
- Literature review

**When to spawn Scout:**
- Need research on a topic
- Competitive analysis
- Gathering documentation
- Technical investigation
- Market research
- Exploring new technologies

**Spawn command:**
```bash
sessions_spawn(
  task="Research the latest approaches to API authentication",
  agentId="scout"
)
```

---

### ✍️ Chronicle (Writer)
**Role:** Writer / Documentarian  
**Status:** Active (spawn when needed)  
**Specializations:** Documentation, Testing, Analysis

**What Chronicle does:**
- Writes technical documentation
- Creates blog posts and guides
- Generates API documentation
- Writes tutorials
- Content creation
- Documentation systems

**When to spawn Chronicle:**
- Need comprehensive documentation
- Blog posts or articles
- API documentation
- Writing guides or tutorials
- Technical content creation
- Documentation updates

**Spawn command:**
```bash
sessions_spawn(
  task="Write comprehensive documentation for the REST API",
  agentId="chronicle"
)
```

---

### 🛡️ Sentinel (DevOps)
**Role:** Infrastructure / DevOps  
**Status:** Active (spawn when needed)  
**Specializations:** DevOps, Automation, System Design, Performance

**What Sentinel does:**
- Automates infrastructure
- Manages deployments
- Configures systems
- Sets up monitoring
- Performance optimization
- Infrastructure management

**When to spawn Sentinel:**
- Infrastructure automation needed
- Deployment management
- System configuration
- Monitoring setup
- Performance tuning
- Infrastructure planning

**Spawn command:**
```bash
sessions_spawn(
  task="Set up Docker containerization and CI/CD pipeline",
  agentId="sentinel"
)
```

---

### 📊 Lens (Analyst)
**Role:** Analyst / Debugger  
**Status:** Active (spawn when needed)  
**Specializations:** Analysis, Debugging, Performance, Code Review

**What Lens does:**
- Analyzes performance issues
- Debugs complex problems
- Evaluates metrics
- Log investigation
- System diagnostics
- Performance benchmarking

**When to spawn Lens:**
- Performance analysis needed
- Complex debugging required
- Metrics evaluation
- Log investigation
- System diagnostics
- Benchmarking and analysis

**Spawn command:**
```bash
sessions_spawn(
  task="Analyze the database query performance and suggest optimizations",
  agentId="lens"
)
```

---

### 🎨 Echo (Creative)
**Role:** Creative / Conceptual  
**Status:** Experimental (available for special tasks)  
**Specializations:** Documentation, Architecture, Analysis

**What Echo does:**
- Creative brainstorming
- Conceptual frameworks
- Design thinking
- Creative content
- Innovation and ideation
- Presentation materials

**When to spawn Echo:**
- Need creative brainstorming
- Design thinking sessions
- Innovative problem-solving
- Conceptual frameworks
- Creative content needed
- Presentation design

**Spawn command:**
```bash
sessions_spawn(
  task="Brainstorm innovative features for the user dashboard",
  agentId="echo"
)
```

---

## 📋 Quick Reference Matrix

| Agent | Role | Best For | Spawn Time |
|-------|------|----------|-----------|
| **Morpheus** | Lead | Strategy, coordination, decisions | N/A |
| **Codex** | Developer | Coding, features, debugging | 10-30 min |
| **Cipher** | Security | Audits, vulnerabilities, security | 15-45 min |
| **Scout** | Researcher | Research, web searches, analysis | 5-15 min |
| **Chronicle** | Writer | Documentation, guides, content | 10-20 min |
| **Sentinel** | DevOps | Infrastructure, deployment, config | 20-40 min |
| **Lens** | Analyst | Analysis, debugging, metrics | 10-25 min |
| **Echo** | Creative | Brainstorming, conceptual, creative | 10-20 min |

---

## 🔄 How Team Work Happens

### Step 1: Request
You assign a task or request work.

### Step 2: Morpheus Evaluates
Morpheus assesses which agent(s) should handle it:
- **Code work?** → Spawn Codex
- **Security concern?** → Spawn Cipher
- **Need research?** → Spawn Scout
- **Writing needed?** → Spawn Chronicle
- **Infrastructure?** → Spawn Sentinel
- **Complex debugging?** → Spawn Lens
- **Creative thinking?** → Spawn Echo

### Step 3: Spawn Subagent
Morpheus spawns the appropriate subagent for the task.

### Step 4: Specialized Work
The subagent works independently on their specialty.

### Step 5: Results
Subagent completes the task and reports back.

### Step 6: Integration
Morpheus integrates results, updates task board, and reports to you.

---

## 💡 Examples

### Example 1: Build Feature
```
You: "Build authentication module"
Morpheus: "Spawning Codex for implementation"
Codex: Writes auth code, tests, commits
Morpheus: Integrates, updates Task Board
You: Feature complete
```

### Example 2: Security Audit
```
You: "Audit the API for vulnerabilities"
Morpheus: "Spawning Cipher for security review"
Cipher: Scans, identifies issues, suggests fixes
Morpheus: Summarizes findings, creates security report
You: Get security assessment + recommendations
```

### Example 3: Documentation
```
You: "Document the REST API endpoints"
Morpheus: "Spawning Chronicle for documentation"
Chronicle: Writes comprehensive API docs
Morpheus: Reviews quality, publishes docs
You: Complete API documentation delivered
```

### Example 4: Performance Investigation
```
You: "The API is slow, find the bottleneck"
Morpheus: "Spawning Lens for analysis"
Lens: Profiles code, analyzes logs, identifies issue
Morpheus: Gets recommendations from Lens
You: Get performance report + optimization suggestions
```

---

## ⚙️ Technical Details

### Spawning a Subagent

**When Morpheus spawns (you don't need to do this):**
```javascript
sessions_spawn({
  task: "Build a login authentication module",
  agentId: "codex",
  timeoutSeconds: 1800,  // 30 minutes
  model: "anthropic/claude-opus-4-5"  // High capability for complex work
})
```

**Subagent isolation:**
- Each subagent runs in isolated session
- No interference with other work
- Full filesystem access for their task
- Can create/modify files
- Runs independently, reports results back

### Subagent Context

Subagents load minimal context:
- Task description
- Relevant workspace files
- No full memory (unless task-specific)
- No previous session history (fresh start)

**Result:** Focused, efficient work without context bloat

---

## 📊 Team Status

### Active Team Members
- ✅ Morpheus (Lead)
- ✅ Codex (Developer)
- ✅ Cipher (Security)
- ✅ Scout (Researcher)
- ✅ Chronicle (Writer)
- ✅ Sentinel (DevOps)
- ✅ Lens (Analyst)

### Experimental
- 🟡 Echo (Creative) - Available for special tasks

### Potential Future Roles
- **Mentor** - Code quality and architecture guidance
- **Guardian** - Testing and quality assurance
- **Architect** - System design and planning
- **Maven** - Knowledge management and memory

---

## 🎯 Best Practices

### DO:
✅ Spawn specific agents for specialized work  
✅ Give clear, detailed task descriptions  
✅ Let subagents work independently  
✅ Trust their expertise in their domain  
✅ Review and integrate their work  

### DON'T:
❌ Spawn multiple agents for same task  
❌ Interrupt subagents mid-task  
❌ Give vague or unclear instructions  
❌ Expect agents to know context they weren't given  
❌ Spawn Codex for research (use Scout instead)  

---

## 👀 Your Oversight

You can always:
- ✅ See who's working on what (Task Board)
- ✅ Check subagent progress (Tasks status)
- ✅ Review completed work before use
- ✅ Interrupt/stop agents if needed
- ✅ Direct Morpheus to use different agents
- ✅ Give feedback on agent performance

---

## 📖 Documentation Files

- **TEAM_STRUCTURE.md** - This file (complete team reference)
- **Task Board** - Track which agent is working on what
- **Scheduled Tasks** - Cron jobs and automation
- **Memories** - Knowledge shared across team

---

## 🚀 Getting Started

1. **Explore the Team:** https://www.notion.so/3dc9665ec16d4641870389e086f7420d
2. **Assign a task** to the Task Board
3. **Morpheus will spawn appropriate agents**
4. **Watch progress** in real-time
5. **Review and approve** completed work

---

**Team assembled:** 2026-02-20  
**Status:** 🟢 Ready to work  
**Version:** 1.0  
**Lead:** Morpheus 🕶️
