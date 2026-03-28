/**
 * MCP Server Implementation
 * Manages agent context, resources, tools, and prompt templates
 */

import { EventEmitter } from "events";
import { MCPProtocol } from "./protocol.js";
import {
  MCPServerConfig,
  MCPServerState,
  AgentContext,
  ToolDefinition,
  ToolCall,
  ToolResult,
  PromptTemplate,
  Resource,
  ServerEvent,
} from "./types.js";

export class MCPServer extends EventEmitter {
  private protocol: MCPProtocol;
  private config: MCPServerConfig;
  private state: MCPServerState;
  private agentContexts = new Map<string, AgentContext>();
  private toolDefinitions = new Map<string, ToolDefinition>();
  private promptTemplates = new Map<string, PromptTemplate>();
  private resources = new Map<string, Resource>();
  private startTime = 0;

  constructor(config: Partial<MCPServerConfig> = {}) {
    super();
    this.config = {
      port: 3000,
      host: "localhost",
      protocol: "stdio",
      maxConnections: 100,
      requestTimeout: 30000,
      enableLogging: true,
      logLevel: "info",
      ...config,
    };

    this.protocol = new MCPProtocol(this.config.requestTimeout);
    this.state = {
      isRunning: false,
      clientConnections: 0,
      resourcesLoaded: 0,
      lastActivity: "",
      uptime: 0,
    };

    this.setupProtocolHandlers();
  }

  /**
   * Setup protocol event handlers
   */
  private setupProtocolHandlers() {
    this.protocol.on("contextRequest", (request) => {
      this.handleContextRequest(request);
    });
  }

  /**
   * Start the MCP server
   */
  async start(): Promise<void> {
    this.startTime = Date.now();
    this.state.isRunning = true;
    this.log("info", "MCP Server starting...");

    this.emitEvent({
      type: "start",
      timestamp: new Date().toISOString(),
      source: "server",
      data: { port: this.config.port, host: this.config.host },
    });

    this.log(
      "info",
      `MCP Server listening on ${this.config.host}:${this.config.port}`
    );
  }

  /**
   * Stop the MCP server
   */
  async stop(): Promise<void> {
    this.state.isRunning = false;
    this.log("info", "MCP Server stopping...");

    this.emitEvent({
      type: "stop",
      timestamp: new Date().toISOString(),
      source: "server",
      data: { uptime: this.getUptime() },
    });
  }

  /**
   * Register an agent with the server
   */
  registerAgent(agentId: string, context: AgentContext): void {
    this.agentContexts.set(agentId, context);
    this.updateActivity();
    this.log("info", `Agent registered: ${agentId} (${context.agentName})`);
  }

  /**
   * Unregister an agent
   */
  unregisterAgent(agentId: string): void {
    this.agentContexts.delete(agentId);
    this.updateActivity();
    this.log("info", `Agent unregistered: ${agentId}`);
  }

  /**
   * Get agent context
   */
  getAgentContext(agentId: string): AgentContext | undefined {
    return this.agentContexts.get(agentId);
  }

  /**
   * Register a tool definition
   */
  registerTool(tool: ToolDefinition): void {
    this.toolDefinitions.set(tool.name, tool);
    this.updateActivity();
    this.log("info", `Tool registered: ${tool.name}`);
  }

  /**
   * Get all available tools
   */
  getTools(): ToolDefinition[] {
    return Array.from(this.toolDefinitions.values());
  }

  /**
   * Get tool by name
   */
  getTool(name: string): ToolDefinition | undefined {
    return this.toolDefinitions.get(name);
  }

  /**
   * Register a prompt template
   */
  registerPrompt(template: PromptTemplate): void {
    this.promptTemplates.set(template.name, template);
    this.updateActivity();
    this.log("info", `Prompt template registered: ${template.name}`);
  }

  /**
   * Get prompt template
   */
  getPrompt(name: string): PromptTemplate | undefined {
    return this.promptTemplates.get(name);
  }

  /**
   * Get all prompts in category
   */
  getPromptsByCategory(category: string): PromptTemplate[] {
    return Array.from(this.promptTemplates.values()).filter(
      (p) => p.category === category
    );
  }

  /**
   * Add a resource
   */
  addResource(resource: Resource): void {
    this.resources.set(resource.id, resource);
    this.state.resourcesLoaded = this.resources.size;
    this.updateActivity();
    this.log("info", `Resource added: ${resource.name} (${resource.type})`);
  }

  /**
   * Get resource
   */
  getResource(id: string): Resource | undefined {
    return this.resources.get(id);
  }

  /**
   * Get all resources of type
   */
  getResourcesByType(type: string): Resource[] {
    return Array.from(this.resources.values()).filter((r) => r.type === type);
  }

  /**
   * Execute a tool
   */
  async executeTool(toolCall: ToolCall): Promise<ToolResult> {
    const startTime = Date.now();
    const tool = this.getTool(toolCall.toolName);

    if (!tool) {
      return {
        id: toolCall.id,
        toolName: toolCall.toolName,
        success: false,
        result: null,
        executionTime: Date.now() - startTime,
        error: `Tool not found: ${toolCall.toolName}`,
      };
    }

    try {
      this.log("debug", `Executing tool: ${tool.name}`);

      // Emit tool execution event
      this.emit("toolExecution", {
        toolName: tool.name,
        params: toolCall.params,
      });

      // Simulate tool execution (override in subclass or via event handlers)
      const result = await this.executeToolHandler(tool.name, toolCall.params);

      return {
        id: toolCall.id,
        toolName: toolCall.toolName,
        success: true,
        result,
        executionTime: Date.now() - startTime,
      };
    } catch (error) {
      return {
        id: toolCall.id,
        toolName: toolCall.toolName,
        success: false,
        result: null,
        executionTime: Date.now() - startTime,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * Execute tool handler (override point for custom tools)
   */
  protected async executeToolHandler(
    toolName: string,
    params: Record<string, unknown>
  ): Promise<unknown> {
    this.log("debug", `Tool handler for ${toolName}: ${JSON.stringify(params)}`);
    return { executed: true, tool: toolName };
  }

  /**
   * Handle incoming context request
   */
  private async handleContextRequest(request: any): Promise<void> {
    this.updateActivity();
    this.log("debug", `Context request from ${request.agent}: ${request.query}`);

    // Emit event for handling
    this.emit("contextRequest", request);
  }

  /**
   * Get current server state
   */
  getState(): MCPServerState {
    return {
      ...this.state,
      uptime: this.getUptime(),
    };
  }

  /**
   * Get server uptime in milliseconds
   */
  private getUptime(): number {
    return this.startTime ? Date.now() - this.startTime : 0;
  }

  /**
   * Update last activity timestamp
   */
  private updateActivity(): void {
    this.state.lastActivity = new Date().toISOString();
  }

  /**
   * Emit server event
   */
  private emitEvent(event: ServerEvent): void {
    this.emit("serverEvent", event);
    this.log(event.type, JSON.stringify(event.data));
  }

  /**
   * Logging utility
   */
  private log(level: string, message: string): void {
    if (!this.config.enableLogging) return;

    const levelValues = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3,
    };
    const configLevel = levelValues[this.config.logLevel] || 1;
    const messageLevel = levelValues[level as keyof typeof levelValues] || 1;

    if (messageLevel >= configLevel) {
      const timestamp = new Date().toISOString();
      console.log(`[${timestamp}] [${level.toUpperCase()}] ${message}`);
    }
  }

  /**
   * Get statistics
   */
  getStats() {
    return {
      agents: this.agentContexts.size,
      tools: this.toolDefinitions.size,
      prompts: this.promptTemplates.size,
      resources: this.resources.size,
      uptime: this.getUptime(),
      state: this.getState(),
    };
  }
}

// Export singleton instance for ease of use
export function createMCPServer(config?: Partial<MCPServerConfig>): MCPServer {
  return new MCPServer(config);
}
