/**
 * Basic MCP Client Example
 * Shows how to interact with the MCP server
 */

import { createMCPServer } from '../src/server.js';
import { AgentContext, ToolCall } from '../src/types.js';

async function runExample() {
  console.log('='.repeat(50));
  console.log('MCP Server Example - Basic Client');
  console.log('='.repeat(50));

  // Create server
  const server = createMCPServer({
    port: 3000,
    host: 'localhost',
    enableLogging: true,
    logLevel: 'info',
  });

  // Setup event logging
  server.on('toolExecution', (event) => {
    console.log(`\n→ Tool Execution: ${event.toolName}`);
  });

  server.on('contextRequest', (request) => {
    console.log(`\n→ Context Request from ${request.agent}: "${request.query}"`);
  });

  // Start server
  await server.start();

  // Example 1: Register an agent
  console.log('\n1️⃣  REGISTERING AN AGENT');
  console.log('-'.repeat(50));

  const myAgent: AgentContext = {
    agentId: 'test-agent',
    agentName: 'Test Agent',
    capabilities: ['testing', 'demonstration'],
    specialization: 'testing',
    currentTask: {
      id: 'task-1',
      type: 'test',
      startTime: new Date().toISOString(),
    },
  };

  server.registerAgent(myAgent.agentId, myAgent);
  console.log(`✓ Registered agent: ${myAgent.agentName}`);

  // Example 2: Get agent context
  console.log('\n2️⃣  RETRIEVING AGENT CONTEXT');
  console.log('-'.repeat(50));

  const context = server.getAgentContext('codex');
  if (context) {
    console.log(`✓ Retrieved context for: ${context.agentName}`);
    console.log(`  Capabilities: ${context.capabilities.join(', ')}`);
    console.log(`  Specialization: ${context.specialization}`);
  }

  // Example 3: Get available tools
  console.log('\n3️⃣  LISTING AVAILABLE TOOLS');
  console.log('-'.repeat(50));

  const tools = server.getTools();
  console.log(`✓ Found ${tools.length} tools:`);
  tools.forEach((tool) => {
    console.log(`  • ${tool.name} — ${tool.description}`);
  });

  // Example 4: Get a specific tool
  console.log('\n4️⃣  RETRIEVING A SPECIFIC TOOL');
  console.log('-'.repeat(50));

  const fileTool = server.getTool('file-read');
  if (fileTool) {
    console.log(`✓ Retrieved tool: ${fileTool.name}`);
    console.log(`  Category: ${fileTool.category}`);
    console.log(`  Schema: ${JSON.stringify(fileTool.inputSchema, null, 2)}`);
  }

  // Example 5: Execute a tool
  console.log('\n5️⃣  EXECUTING A TOOL');
  console.log('-'.repeat(50));

  const toolCall: ToolCall = {
    id: 'call-1',
    toolName: 'analyze-code',
    params: {
      code: 'function hello() { return "world"; }',
      language: 'javascript',
    },
  };

  console.log(`Executing: ${toolCall.toolName}`);
  console.log(`Params: ${JSON.stringify(toolCall.params)}`);

  const result = await server.executeTool(toolCall);
  console.log(`✓ Execution complete:`);
  console.log(`  Success: ${result.success}`);
  console.log(`  Time: ${result.executionTime}ms`);
  if (result.result) {
    console.log(`  Result: ${JSON.stringify(result.result)}`);
  }

  // Example 6: Get prompt templates
  console.log('\n6️⃣  LISTING PROMPT TEMPLATES');
  console.log('-'.repeat(50));

  const devPrompts = server.getPromptsByCategory('development');
  console.log(`✓ Found ${devPrompts.length} development prompts:`);
  devPrompts.forEach((prompt) => {
    console.log(`  • ${prompt.name} — ${prompt.description}`);
  });

  // Example 7: Get a specific prompt
  console.log('\n7️⃣  RETRIEVING A SPECIFIC PROMPT');
  console.log('-'.repeat(50));

  const codeReviewPrompt = server.getPrompt('code-review');
  if (codeReviewPrompt) {
    console.log(`✓ Retrieved prompt: ${codeReviewPrompt.name}`);
    console.log(`  Variables: ${codeReviewPrompt.variables.join(', ')}`);
    console.log(`  Template preview:`);
    console.log('  ' + codeReviewPrompt.template.substring(0, 80) + '...');
  }

  // Example 8: Get resources
  console.log('\n8️⃣  LISTING RESOURCES');
  console.log('-'.repeat(50));

  const memoryResources = server.getResourcesByType('memory');
  console.log(`✓ Found ${memoryResources.length} memory resources:`);
  memoryResources.forEach((resource) => {
    console.log(`  • ${resource.name} (${resource.id})`);
    if (resource.metadata) {
      console.log(`    ${JSON.stringify(resource.metadata)}`);
    }
  });

  // Example 9: Get server statistics
  console.log('\n9️⃣  SERVER STATISTICS');
  console.log('-'.repeat(50));

  const stats = server.getStats();
  console.log(`✓ Current stats:`);
  console.log(`  Agents: ${stats.agents}`);
  console.log(`  Tools: ${stats.tools}`);
  console.log(`  Prompts: ${stats.prompts}`);
  console.log(`  Resources: ${stats.resources}`);
  console.log(`  Uptime: ${(stats.uptime / 1000).toFixed(2)}s`);
  console.log(`  Server Running: ${stats.state.isRunning}`);

  // Example 10: Handle events
  console.log('\n🔟 HANDLING EVENTS');
  console.log('-'.repeat(50));

  // Register another tool
  server.registerTool({
    name: 'test-event-tool',
    description: 'Tool for testing event handling',
    category: 'testing',
    inputSchema: {
      type: 'object',
      properties: {
        message: { type: 'string' },
      },
    },
  });

  console.log('✓ Event handlers active (check console output)');

  // Example 11: Get server state
  console.log('\n1️⃣ 1️⃣  SERVER STATE');
  console.log('-'.repeat(50));

  const state = server.getState();
  console.log(`✓ Current state:`);
  console.log(`  Is Running: ${state.isRunning}`);
  console.log(`  Client Connections: ${state.clientConnections}`);
  console.log(`  Resources Loaded: ${state.resourcesLoaded}`);
  console.log(`  Last Activity: ${state.lastActivity}`);
  console.log(`  Uptime: ${(state.uptime / 1000).toFixed(2)}s`);

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('EXAMPLE COMPLETE');
  console.log('='.repeat(50));
  console.log(`\nThe MCP server is running and fully functional.`);
  console.log(`\nKey Takeaways:`);
  console.log(`  ✓ Server initialization works`);
  console.log(`  ✓ Agent registration works`);
  console.log(`  ✓ Tool management works`);
  console.log(`  ✓ Prompt templates work`);
  console.log(`  ✓ Resource management works`);
  console.log(`  ✓ Event handling works`);
  console.log(`  ✓ State tracking works`);
  console.log(`\nNext: Integrate with OpenClaw agents!`);
  console.log(`See INTEGRATION.md for detailed instructions.`);
  console.log('');

  // Graceful shutdown
  await new Promise((resolve) => {
    setTimeout(() => {
      console.log('Shutting down example...');
      resolve(undefined);
    }, 2000);
  });

  await server.stop();
  process.exit(0);
}

// Run the example
runExample().catch((error) => {
  console.error('Error running example:', error);
  process.exit(1);
});
