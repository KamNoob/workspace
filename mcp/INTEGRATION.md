# MCP Integration Guide

How to integrate the MCP server with OpenClaw agents and systems.

## Quick Start

### 1. Setup

```bash
cd /home/art/.openclaw/workspace/mcp
npm install
npm run build
npm start
```

Server starts on `localhost:3000` by default.

### 2. Connect Your First Agent

```typescript
import { MCPClient } from './src/client';

const client = new MCPClient('http://localhost:3000');

// Register your agent
await client.registerAgent({
  agentId: 'codex',
  agentName: 'Codex',
  capabilities: ['code-generation', 'debugging'],
  specialization: 'development'
});

// Request context
const response = await client.requestContext({
  query: 'What files need review?',
  agent: 'codex',
  taskType: 'code'
});
```

### 3. Execute Tools

```typescript
// Execute a tool through MCP
const result = await client.executeTool({
  toolName: 'file-read',
  params: { path: '/path/to/file' }
});

if (result.success) {
  console.log('File contents:', result.result);
}
```

## OpenClaw Agent Integration

### Registering Agents with MCP

Each OpenClaw agent should register on startup:

```typescript
// In agent initialization
const server = getMCPServer();

server.registerAgent(agentId, {
  agentId: agentId,
  agentName: agentName,
  capabilities: getAgentCapabilities(),
  specialization: agentSpecialization
});
```

### Agent Capabilities Mapping

| Agent | Capabilities | Specialization |
|-------|--------------|-----------------|
| Codex | code-generation, debugging, refactoring | development |
| Cipher | security-audit, threat-modeling, scanning | security |
| Scout | research, web-search, analysis | research |
| Chronicle | documentation, technical-writing | documentation |
| Sentinel | infrastructure, automation, devops | operations |
| Lens | analysis, debugging, metrics | analysis |
| Veritas | code-review, validation, qa | quality |
| QA | testing, test-automation | testing |
| Prism | mobile-testing, responsive-design | testing |
| Echo | brainstorming, ideation | creative |

### Task Type Routing

MCP uses task types to route requests intelligently:

```typescript
const taskTypeRouting = {
  'code': ['Codex', 'Veritas'],
  'security': ['Cipher'],
  'research': ['Scout', 'Lens'],
  'documentation': ['Chronicle'],
  'infrastructure': ['Sentinel'],
  'testing': ['QA', 'Prism'],
  'creative': ['Echo'],
  'analysis': ['Lens', 'Scout'],
  'review': ['Veritas', 'Codex'],
  'optimization': ['Codex', 'Lens'],
  'compliance': ['Cipher', 'Veritas'],
  'training': ['Chronicle', 'Echo']
};
```

## Resource Integration

### Task Execution Logs

Make task logs available as a resource:

```typescript
server.addResource({
  id: 'task-log',
  name: 'Task Execution Log',
  type: 'memory',
  uri: 'memory://task-log',
  content: fs.readFileSync(
    '/home/art/.openclaw/workspace/data/rl/rl-task-execution-log.jsonl',
    'utf-8'
  ),
  metadata: {
    format: 'jsonl',
    entries: taskLogLines.length,
    lastUpdated: new Date().toISOString()
  }
});
```

### RL Knowledge Base

```typescript
server.addResource({
  id: 'rl-knowledge',
  name: 'RL Knowledge Base',
  type: 'memory',
  uri: 'memory://rl-knowledge',
  content: fs.readFileSync(
    '/home/art/.openclaw/workspace/RL-BOOK-ENHANCED.json',
    'utf-8'
  ),
  metadata: {
    source: 'sutton-barto',
    pages: 548,
    topics: ['mdp', 'temporal-difference', 'q-learning', 'policy-gradient']
  }
});
```

### Agent Q-Learning State

```typescript
server.addResource({
  id: 'agent-qscores',
  name: 'Agent Q-Learning State',
  type: 'memory',
  uri: 'memory://agent-qscores',
  content: fs.readFileSync(
    '/home/art/.openclaw/workspace/data/rl/rl-agent-selection.json',
    'utf-8'
  ),
  metadata: {
    format: 'json',
    agents: 16,
    taskTypes: 12,
    lastUpdate: new Date().toISOString()
  }
});
```

### Configuration Files

```typescript
server.addResource({
  id: 'spawner-config',
  name: 'Agent Spawner Configuration',
  type: 'config',
  uri: 'file:///home/art/.openclaw/workspace/config/spawner-config.json'
});
```

## Tool Integration

### Register OpenClaw Tools

```typescript
// File operations
server.registerTool({
  name: 'file-read',
  description: 'Read file contents',
  category: 'filesystem',
  inputSchema: {
    type: 'object',
    properties: {
      path: { type: 'string' }
    },
    required: ['path']
  }
});

// Execution
server.registerTool({
  name: 'execute-command',
  description: 'Execute shell command',
  category: 'execution',
  inputSchema: {
    type: 'object',
    properties: {
      command: { type: 'string' },
      timeout: { type: 'number' }
    },
    required: ['command']
  }
});

// Agent management
server.registerTool({
  name: 'spawn-agent',
  description: 'Spawn an AI agent for a task',
  category: 'agents',
  inputSchema: {
    type: 'object',
    properties: {
      agentId: { type: 'string' },
      task: { type: 'string' },
      params: { type: 'object' }
    },
    required: ['agentId', 'task']
  }
});

// Learning
server.registerTool({
  name: 'update-q-value',
  description: 'Update Q-learning value for agent-task pair',
  category: 'learning',
  inputSchema: {
    type: 'object',
    properties: {
      agent: { type: 'string' },
      taskType: { type: 'string' },
      outcome: { type: 'number' },
      feedback: { type: 'string' }
    },
    required: ['agent', 'taskType', 'outcome']
  }
});
```

### Implement Tool Handlers

```typescript
class OpenClawMCPServer extends MCPServer {
  protected async executeToolHandler(
    toolName: string,
    params: Record<string, unknown>
  ) {
    switch (toolName) {
      case 'file-read':
        return this.handleFileRead(params.path as string);
      
      case 'execute-command':
        return this.handleExecuteCommand(
          params.command as string,
          params.timeout as number
        );
      
      case 'spawn-agent':
        return this.handleSpawnAgent(
          params.agentId as string,
          params.task as string,
          params.params as Record<string, unknown>
        );
      
      case 'update-q-value':
        return this.handleUpdateQValue(
          params.agent as string,
          params.taskType as string,
          params.outcome as number,
          params.feedback as string
        );
      
      default:
        throw new Error(`Unknown tool: ${toolName}`);
    }
  }

  private async handleFileRead(path: string) {
    const fs = await import('fs/promises');
    return await fs.readFile(path, 'utf-8');
  }

  private async handleExecuteCommand(command: string, timeout?: number) {
    const { exec } = await import('child_process');
    return new Promise((resolve, reject) => {
      const child = exec(command, (error, stdout, stderr) => {
        if (error) reject(error);
        else resolve({ stdout, stderr });
      });
      
      if (timeout) {
        setTimeout(() => child.kill(), timeout);
      }
    });
  }

  private async handleSpawnAgent(
    agentId: string,
    task: string,
    params: Record<string, unknown>
  ) {
    // Delegate to your agent spawning system
    // This would call the spawner-matrix or equivalent
    return {
      agentId,
      task,
      status: 'spawned',
      timestamp: new Date().toISOString()
    };
  }

  private async handleUpdateQValue(
    agent: string,
    taskType: string,
    outcome: number,
    feedback?: string
  ) {
    // Update Q-learning state
    // This would call the feedback validator
    return {
      agent,
      taskType,
      outcome,
      feedback,
      updated: true,
      timestamp: new Date().toISOString()
    };
  }
}
```

## Prompt Template Integration

### Register System Prompts

```typescript
server.registerPrompt({
  name: 'code-review-standard',
  description: 'Standard code review prompt',
  category: 'development',
  template: `You are a code reviewer. Review the following code:

\${code}

Language: \${language}
Focus areas: \${focusAreas}

Provide:
1. Correctness assessment
2. Performance concerns
3. Code style issues
4. Security vulnerabilities
5. Improvement suggestions`,
  variables: ['code', 'language', 'focusAreas']
});

server.registerPrompt({
  name: 'security-audit-thorough',
  description: 'Thorough security audit prompt',
  category: 'security',
  template: `Perform a thorough security audit:

Code:
\${code}

Systems: \${systems}
Threat Model: \${threatModel}

Include:
1. Vulnerability analysis
2. Attack surface mapping
3. Data flow analysis
4. Compliance check
5. Remediation steps`,
  variables: ['code', 'systems', 'threatModel']
});

server.registerPrompt({
  name: 'research-comprehensive',
  description: 'Comprehensive research prompt',
  category: 'research',
  template: `Research the following topic:

Topic: \${topic}
Depth: \${depth}
Sources: \${sources}

Provide:
1. Overview
2. Key findings
3. Recent developments
4. Relevant research
5. Conclusions`,
  variables: ['topic', 'depth', 'sources']
});
```

## Context Resolution

### Implement Custom Context Handler

```typescript
server.on('contextRequest', async (request) => {
  // Request context from task log
  const taskLog = server.getResource('task-log');
  
  // Search for related tasks
  const relatedTasks = searchTaskLog(taskLog, request.query);
  
  // Get agent knowledge base
  const agentKB = getAgentKnowledgeBase(request.agent);
  
  // Combine context
  const context = [
    ...relatedTasks.map(t => ({
      type: 'text',
      content: JSON.stringify(t),
      metadata: { source: 'task-log', taskId: t.id }
    })),
    ...agentKB.map(kb => ({
      type: 'text',
      content: kb.content,
      metadata: { source: 'kb', topic: kb.topic }
    }))
  ];

  // Return context
  const response = {
    id: request.id,
    results: context,
    metadata: {
      source: 'mcp',
      timestamp: new Date().toISOString(),
      agent: request.agent
    }
  };

  server.protocol.fulfillRequest(request.id, response);
});
```

## Monitoring & Metrics

### Enable Server Monitoring

```typescript
setInterval(() => {
  const stats = server.getStats();
  console.log('MCP Stats:', stats);
  
  // Log to monitoring system
  logMetrics({
    agents: stats.agents,
    tools: stats.tools,
    resources: stats.resources,
    uptime: stats.uptime
  });
}, 60000); // Every minute
```

### Track Tool Execution

```typescript
server.on('toolExecution', (event) => {
  logToolMetrics({
    tool: event.toolName,
    params: event.params,
    timestamp: new Date().toISOString()
  });
});
```

## Deployment

### Docker Integration

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY mcp/package*.json ./
RUN npm ci --only=production

COPY mcp/dist ./dist
COPY config ./config

EXPOSE 3000

CMD ["node", "dist/server.js"]
```

### Kubernetes Integration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mcp-server
spec:
  selector:
    app: mcp-server
  ports:
    - port: 3000
      targetPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-server
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: mcp
          image: openclaw/mcp-server:latest
          ports:
            - containerPort: 3000
          resources:
            limits:
              memory: "512Mi"
              cpu: "500m"
```

## Testing MCP Integration

### Unit Tests

```typescript
describe('MCP Server Integration', () => {
  let server: MCPServer;

  beforeEach(() => {
    server = createMCPServer();
  });

  it('should register agents', () => {
    server.registerAgent('test-agent', {
      agentId: 'test-agent',
      agentName: 'Test',
      capabilities: ['test'],
      specialization: 'test'
    });

    expect(server.getAgentContext('test-agent')).toBeDefined();
  });

  it('should execute tools', async () => {
    server.registerTool({
      name: 'test-tool',
      description: 'Test',
      category: 'test',
      inputSchema: {}
    });

    const result = await server.executeTool({
      id: 'call-1',
      toolName: 'test-tool',
      params: {}
    });

    expect(result.success).toBe(true);
  });
});
```

### Integration Tests

```bash
npm test -- --grep "integration"
```

## Troubleshooting

### Agent Connection Issues

```bash
# Check if server is running
curl http://localhost:3000/health

# Check agent registration
curl http://localhost:3000/agents

# Check available tools
curl http://localhost:3000/tools
```

### Tool Execution Failures

1. Check tool is registered
2. Verify parameters match schema
3. Check server logs for errors
4. Increase logging verbosity

### Context Resolution Delays

1. Check resource availability
2. Monitor context request queue
3. Increase request timeout if needed
4. Profile with debug logging

## Next Steps

1. **Extend with more tools** — Add custom tools for your use case
2. **Add authentication** — Secure MCP server with auth tokens
3. **Implement caching** — Cache context results for faster access
4. **Add monitoring** — Integrate with monitoring/alerting systems
5. **Scale horizontally** — Deploy multiple MCP instances
6. **Custom context handlers** — Implement domain-specific context logic

## References

- MCP Architecture: See `README.md`
- OpenClaw Agents: `/home/art/.openclaw/workspace/AGENTS.md`
- Q-Learning System: `/home/art/.openclaw/workspace/docs/LEARNING-SYSTEM.md`
- Configuration: `/home/art/.openclaw/workspace/CONFIGURATION.md`
