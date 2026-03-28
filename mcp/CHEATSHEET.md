# MCP Server - Quick Reference Cheatsheet

**One-page guide for common tasks.**

---

## Setup (2 minutes)

```bash
cd /home/art/.openclaw/workspace/mcp
npm install
npm run build
npm start
```

---

## Basic Usage

### Create Server

```typescript
import { createMCPServer } from './src/server';

const server = createMCPServer({
  port: 3000,
  logLevel: 'info'
});

await server.start();
```

### Register Agent

```typescript
server.registerAgent('my-agent', {
  agentId: 'my-agent',
  agentName: 'My Agent',
  capabilities: ['task1', 'task2'],
  specialization: 'domain'
});
```

### Register Tool

```typescript
server.registerTool({
  name: 'my-tool',
  description: 'Does something',
  category: 'category',
  inputSchema: {
    type: 'object',
    properties: {
      param: { type: 'string' }
    },
    required: ['param']
  }
});
```

### Execute Tool

```typescript
const result = await server.executeTool({
  id: 'call-1',
  toolName: 'my-tool',
  params: { param: 'value' }
});

console.log(result.success, result.result);
```

### Register Prompt

```typescript
server.registerPrompt({
  name: 'my-prompt',
  description: 'For my task',
  category: 'domain',
  template: 'Do something with ${variable}',
  variables: ['variable']
});
```

### Add Resource

```typescript
server.addResource({
  id: 'my-resource',
  name: 'My Resource',
  type: 'file',
  uri: 'file:///path/to/resource'
});
```

### Get Agent

```typescript
const agent = server.getAgentContext('agent-id');
console.log(agent.agentName, agent.capabilities);
```

### Get Tool

```typescript
const tool = server.getTool('tool-name');
console.log(tool.description);
```

### Get Prompt

```typescript
const prompt = server.getPrompt('prompt-name');
console.log(prompt.template, prompt.variables);
```

### Get Resource

```typescript
const resource = server.getResource('resource-id');
console.log(resource.name, resource.uri);
```

### List All Tools

```typescript
const tools = server.getTools();
tools.forEach(t => console.log(t.name));
```

### List Prompts by Category

```typescript
const prompts = server.getPromptsByCategory('development');
prompts.forEach(p => console.log(p.name));
```

### List Resources by Type

```typescript
const files = server.getResourcesByType('file');
files.forEach(f => console.log(f.name));
```

### Get Statistics

```typescript
const stats = server.getStats();
console.log(stats.agents, stats.tools, stats.resources);
```

---

## Event Handling

### Tool Execution

```typescript
server.on('toolExecution', (event) => {
  console.log(`Tool: ${event.toolName}`);
  console.log(`Params:`, event.params);
});
```

### Context Request

```typescript
server.on('contextRequest', (request) => {
  console.log(`From: ${request.agent}`);
  console.log(`Query: ${request.query}`);
});
```

### Server Events

```typescript
server.on('serverEvent', (event) => {
  if (event.type === 'start') console.log('Server started');
  if (event.type === 'stop') console.log('Server stopped');
  if (event.type === 'error') console.log('Error:', event.data);
});
```

---

## Configuration

### Server Options

```typescript
const server = createMCPServer({
  port: 3000,              // Listen port
  host: 'localhost',       // Listen host
  protocol: 'stdio',       // stdio|sse|websocket
  maxConnections: 100,     // Max clients
  requestTimeout: 30000,   // Request timeout (ms)
  enableLogging: true,     // Enable logging
  logLevel: 'info'         // debug|info|warn|error
});
```

---

## Build Commands

```bash
npm install              # Install dependencies
npm run build            # Compile TypeScript
npm start                # Production server
npm run dev              # Development mode
npm run clean            # Remove dist/
npm test                 # Run tests
```

---

## Protocol Messages

### Context Request

```json
{
  "id": "req-1",
  "query": "What files?",
  "context": [],
  "agent": "codex",
  "taskType": "code"
}
```

### Tool Call

```json
{
  "id": "call-1",
  "toolName": "file-read",
  "params": { "path": "/file" }
}
```

### Tool Result

```json
{
  "id": "call-1",
  "toolName": "file-read",
  "success": true,
  "result": "contents",
  "executionTime": 45
}
```

---

## Common Patterns

### Setup Full Server

```typescript
import { createMCPServer } from './src/server';

const server = createMCPServer({
  port: 3000,
  enableLogging: true
});

// Register agents
['codex', 'cipher', 'scout'].forEach(id => {
  server.registerAgent(id, {
    agentId: id,
    agentName: id.toUpperCase(),
    capabilities: [],
    specialization: id
  });
});

// Register tools
['file-read', 'execute'].forEach(name => {
  server.registerTool({
    name,
    description: `Tool: ${name}`,
    category: 'tools',
    inputSchema: {}
  });
});

// Start
await server.start();
```

### Monitor Events

```typescript
server.on('toolExecution', console.log);
server.on('contextRequest', console.log);
server.on('serverEvent', console.log);
```

### Graceful Shutdown

```typescript
process.on('SIGINT', async () => {
  console.log('Shutting down...');
  await server.stop();
  process.exit(0);
});
```

---

## Types Quick Reference

```typescript
// Agent
{
  agentId: string;
  agentName: string;
  capabilities: string[];
  specialization: string;
  currentTask?: { id, type, startTime };
}

// Tool
{
  name: string;
  description: string;
  category: string;
  inputSchema: Record<string, unknown>;
}

// Prompt
{
  name: string;
  description: string;
  category: string;
  template: string;
  variables: string[];
}

// Resource
{
  id: string;
  name: string;
  type: 'file'|'url'|'memory'|'config';
  uri: string;
  content?: string;
  metadata?: Record<string, unknown>;
}

// Tool Call
{
  id: string;
  toolName: string;
  params: Record<string, unknown>;
}

// Tool Result
{
  id: string;
  toolName: string;
  success: boolean;
  result: unknown;
  executionTime: number;
  error?: string;
}
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Module not found | `npm install` |
| Port in use | Change port in code |
| Won't start | Check Node 20+, npm 10+ |
| Type errors | `npm run clean && npm run build` |
| Event not firing | Check event name, add handler before action |

---

## Files to Know

| File | Purpose |
|------|---------|
| `src/types.ts` | Type definitions |
| `src/protocol.ts` | Protocol implementation |
| `src/server.ts` | Server core |
| `src/main.ts` | Entry point |
| `README.md` | Full reference |
| `INTEGRATION.md` | Integration guide |

---

## Performance Tips

- Reuse server instance
- Register tools/prompts at startup
- Use event handlers instead of polling
- Cache resource queries
- Batch operations when possible

---

## Next Level

- Read `README.md` for full API
- See `INTEGRATION.md` for OpenClaw integration
- Check `examples/basic-client.ts` for complete example
- Review `src/` for implementation details

---

**Got questions? See the full docs in `README.md` or `INTEGRATION.md`.**

---

_Quick Reference v1.0 — 2026-03-28_
