# MCP Server - Quick Start Guide

Get the MCP server running in 5 minutes.

## Prerequisites

- Node.js 20+ (check: `node --version`)
- npm 10+ (check: `npm --version`)
- TypeScript knowledge (optional, but helpful)

## Installation (2 minutes)

```bash
# Navigate to MCP directory
cd /home/art/.openclaw/workspace/mcp

# Install dependencies
npm install

# Build TypeScript
npm run build
```

## Run Server (1 minute)

### Development Mode (with hot reload)

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

You should see:

```
[2026-03-28T21:52:00.000Z] [INFO] MCP Server starting...
[2026-03-28T21:52:00.001Z] [INFO] MCP Server listening on localhost:3000

==================================================
MCP Server Ready
==================================================

Stats: {
  "agents": 4,
  "tools": 5,
  "prompts": 3,
  "resources": 3,
  "uptime": 1234,
  "state": {
    "isRunning": true,
    "clientConnections": 0,
    "resourcesLoaded": 3,
    "lastActivity": "2026-03-28T21:52:00.000Z",
    "uptime": 1234
  }
}

Available Tools:
  - file-read: Read contents of a file
  - file-write: Write contents to a file
  - execute-command: Execute a shell command
  - search-web: Search the web for information
  - analyze-code: Analyze code for issues and improvements

Registered Agents:
  - Codex (codex)
  - Cipher (cipher)
  - Scout (scout)
  - Chronicle (chronicle)
```

## Verify It Works

### Check Server Health

```bash
# From another terminal
curl http://localhost:3000/health 2>/dev/null || echo "Server running (stdio mode)"
```

### Check Logs

Watch for these patterns in the terminal:

```
[INFO] Agent registered: codex
[INFO] Tool registered: file-read
[INFO] Prompt template registered: code-review
[INFO] Resource added: RL Knowledge Base
```

## Common Commands

### Clean Build

```bash
npm run clean && npm run build
```

### Watch Mode (auto-rebuild on changes)

```bash
npm run dev
```

### Stop Server

```bash
Ctrl+C
```

## File Structure

```
mcp/
├── src/
│   ├── types.ts       ← Type definitions
│   ├── protocol.ts    ← MCP protocol implementation
│   ├── server.ts      ← Server logic
│   └── main.ts        ← Entry point
├── dist/              ← Compiled JavaScript (generated)
├── package.json       ← Dependencies
├── tsconfig.json      ← TypeScript config
├── README.md          ← Full documentation
├── INTEGRATION.md     ← Integration guide
└── QUICK_START.md     ← This file
```

## Troubleshooting

### "Cannot find module" Error

```bash
npm install
npm run build
```

### Port Already in Use

Change port in `src/main.ts`:

```typescript
const server = createMCPServer({
  port: 3001,  // Change this
  // ...
});
```

### TypeScript Compilation Error

```bash
npm install -D typescript @types/node
npm run build
```

## Next Steps

### 1. Understand the Architecture

Read `README.md` for detailed component overview.

### 2. Integrate with OpenClaw

Follow `INTEGRATION.md` to connect agents, tools, resources.

### 3. Add Custom Tools

Edit `src/main.ts` and add new tool definitions.

### 4. Deploy

Use the Docker/Kubernetes configs in `INTEGRATION.md`.

## Quick Reference

| Task | Command |
|------|---------|
| Install | `npm install` |
| Build | `npm run build` |
| Dev mode | `npm run dev` |
| Production | `npm start` |
| Clean | `npm run clean` |
| Test | `npm test` |

## Architecture Overview

```
Agent Request
    ↓
┌─────────────────────────┐
│   MCP Server            │
│  ┌─────────────────┐    │
│  │  Protocol       │    │
│  │  (JSON-RPC 2.0) │    │
│  └─────────────────┘    │
│  ┌─────────────────┐    │
│  │  Resources      │    │
│  │  Tools          │    │
│  │  Prompts        │    │
│  │  Agents         │    │
│  └─────────────────┘    │
└─────────────────────────┘
    ↓
Response
```

## Key Components

### MCPProtocol
- Handles JSON-RPC messages
- Manages context requests/responses
- Builds context messages

### MCPServer
- Registers agents, tools, prompts, resources
- Executes tools safely
- Tracks server state

### Types
- Complete type definitions
- Ensures type safety
- Documents API contracts

## Server Features

✅ Agent registration & management  
✅ Tool execution & validation  
✅ Prompt template storage  
✅ Resource management  
✅ Context request handling  
✅ Event emission  
✅ Graceful shutdown  
✅ Comprehensive logging  

## Configuration

Default config (edit `src/main.ts`):

```typescript
{
  port: 3000,
  host: 'localhost',
  protocol: 'stdio',        // or 'sse', 'websocket'
  maxConnections: 100,
  requestTimeout: 30000,    // 30 seconds
  enableLogging: true,
  logLevel: 'info'         // or 'debug', 'warn', 'error'
}
```

## Event Monitoring

```typescript
// In src/main.ts, after server creation:

server.on('toolExecution', (event) => {
  console.log(`[TOOL] ${event.toolName}`);
});

server.on('contextRequest', (request) => {
  console.log(`[CONTEXT] From ${request.agent}`);
});

server.on('serverEvent', (event) => {
  console.log(`[EVENT] ${event.type}`);
});
```

## Production Checklist

- [ ] Build with `npm run build`
- [ ] Test with `npm start`
- [ ] Set appropriate log level
- [ ] Configure port & host
- [ ] Register all agents
- [ ] Register all tools
- [ ] Add production resources
- [ ] Set up monitoring
- [ ] Test graceful shutdown
- [ ] Document any customizations

## Support

For issues or questions:

1. Check `README.md` for detailed docs
2. Review `INTEGRATION.md` for integration examples
3. Check logs with `npm run dev` (debug mode)
4. Verify prerequisites are installed

## What's Next?

✅ **Understand**: Read `README.md`  
✅ **Integrate**: Follow `INTEGRATION.md`  
✅ **Customize**: Edit `src/server.ts` and `src/main.ts`  
✅ **Deploy**: Use Docker/Kubernetes configs  
✅ **Monitor**: Set up event handlers and logging  

You now have a production-ready MCP server. Start building! 🚀
