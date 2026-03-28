/**
 * MCP Server Entry Point
 * Initializes and runs the server with sample configuration
 */

import { createMCPServer } from "./server.js";
import { AgentContext, ToolDefinition, PromptTemplate, Resource } from "./types.js";

async function main() {
  // Create and configure MCP server
  const server = createMCPServer({
    port: 3000,
    host: "localhost",
    protocol: "stdio",
    enableLogging: true,
    logLevel: "info",
  });

  // Register sample agents
  const agents: AgentContext[] = [
    {
      agentId: "codex",
      agentName: "Codex",
      capabilities: ["code-generation", "debugging", "refactoring"],
      specialization: "development",
      currentTask: {
        id: "task-001",
        type: "code",
        startTime: new Date().toISOString(),
      },
    },
    {
      agentId: "cipher",
      agentName: "Cipher",
      capabilities: ["security-audit", "threat-modeling", "vulnerability-scanning"],
      specialization: "security",
    },
    {
      agentId: "scout",
      agentName: "Scout",
      capabilities: ["research", "web-search", "analysis"],
      specialization: "research",
    },
    {
      agentId: "chronicle",
      agentName: "Chronicle",
      capabilities: ["documentation", "technical-writing"],
      specialization: "documentation",
    },
  ];

  agents.forEach((agent) => {
    server.registerAgent(agent.agentId, agent);
  });

  // Register sample tools
  const tools: ToolDefinition[] = [
    {
      name: "file-read",
      description: "Read contents of a file",
      category: "filesystem",
      inputSchema: {
        type: "object",
        properties: {
          path: { type: "string", description: "File path" },
        },
        required: ["path"],
      },
    },
    {
      name: "file-write",
      description: "Write contents to a file",
      category: "filesystem",
      inputSchema: {
        type: "object",
        properties: {
          path: { type: "string", description: "File path" },
          content: { type: "string", description: "File content" },
        },
        required: ["path", "content"],
      },
    },
    {
      name: "execute-command",
      description: "Execute a shell command",
      category: "execution",
      inputSchema: {
        type: "object",
        properties: {
          command: { type: "string", description: "Command to execute" },
          timeout: { type: "number", description: "Timeout in milliseconds" },
        },
        required: ["command"],
      },
    },
    {
      name: "search-web",
      description: "Search the web for information",
      category: "research",
      inputSchema: {
        type: "object",
        properties: {
          query: { type: "string", description: "Search query" },
          limit: { type: "number", description: "Number of results" },
        },
        required: ["query"],
      },
    },
    {
      name: "analyze-code",
      description: "Analyze code for issues and improvements",
      category: "analysis",
      inputSchema: {
        type: "object",
        properties: {
          code: { type: "string", description: "Code to analyze" },
          language: { type: "string", description: "Programming language" },
        },
        required: ["code"],
      },
    },
  ];

  tools.forEach((tool) => {
    server.registerTool(tool);
  });

  // Register sample prompt templates
  const prompts: PromptTemplate[] = [
    {
      name: "code-review",
      description: "Prompt for code review task",
      category: "development",
      template: `Review the following code for:
1. Correctness and potential bugs
2. Performance optimizations
3. Code style and readability
4. Security vulnerabilities

Code:
\${code}

Language: \${language}`,
      variables: ["code", "language"],
    },
    {
      name: "security-audit",
      description: "Prompt for security audit",
      category: "security",
      template: `Perform a security audit on the following code:
1. Identify potential vulnerabilities
2. Check for insecure patterns
3. Recommend fixes
4. Assess risk level

Code:
\${code}

Focus areas: \${focusAreas}`,
      variables: ["code", "focusAreas"],
    },
    {
      name: "documentation",
      description: "Prompt for generating documentation",
      category: "documentation",
      template: `Generate documentation for:

Subject: \${subject}
Type: \${docType}
Target Audience: \${audience}

Details:
\${details}

Include: examples, use cases, API reference`,
      variables: ["subject", "docType", "audience", "details"],
    },
  ];

  prompts.forEach((prompt) => {
    server.registerPrompt(prompt);
  });

  // Register sample resources
  const resources: Resource[] = [
    {
      id: "rl-knowledge",
      name: "RL Knowledge Base",
      type: "memory",
      uri: "memory://rl-knowledge",
      metadata: { source: "sutton-barto", pages: 548 },
    },
    {
      id: "task-log",
      name: "Task Execution Log",
      type: "memory",
      uri: "memory://task-log",
      metadata: { format: "jsonl", entries: 1000 },
    },
    {
      id: "config",
      name: "System Configuration",
      type: "config",
      uri: "file:///home/art/.openclaw/workspace/config",
    },
  ];

  resources.forEach((resource) => {
    server.addResource(resource);
  });

  // Setup event handlers
  server.on("toolExecution", (event) => {
    console.log(`\n[TOOL] ${event.toolName}`);
    console.log(`Params: ${JSON.stringify(event.params, null, 2)}`);
  });

  server.on("contextRequest", (request) => {
    console.log(`\n[CONTEXT] From ${request.agent}`);
    console.log(`Query: ${request.query}`);
  });

  server.on("serverEvent", (event) => {
    console.log(`\n[EVENT] ${event.type}`);
  });

  // Start server
  await server.start();

  // Print server info
  console.log("\n" + "=".repeat(50));
  console.log("MCP Server Ready");
  console.log("=".repeat(50));
  console.log(`\nStats: ${JSON.stringify(server.getStats(), null, 2)}`);
  console.log(`\nAvailable Tools:`);
  server.getTools().forEach((tool) => {
    console.log(`  - ${tool.name}: ${tool.description}`);
  });
  console.log(`\nRegistered Agents:`);
  agents.forEach((agent) => {
    console.log(`  - ${agent.agentName} (${agent.agentId})`);
  });

  // Handle graceful shutdown
  process.on("SIGINT", async () => {
    console.log("\n\nShutting down MCP Server...");
    await server.stop();
    process.exit(0);
  });

  process.on("SIGTERM", async () => {
    console.log("\n\nShutting down MCP Server...");
    await server.stop();
    process.exit(0);
  });
}

// Run the server
main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
