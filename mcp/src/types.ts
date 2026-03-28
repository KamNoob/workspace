/**
 * MCP Protocol Type Definitions
 * Implements Model Context Protocol specification for agent-to-context communication
 */

// Core Protocol Messages
export interface MCPRequest {
  jsonrpc: "2.0";
  id: string | number;
  method: string;
  params?: Record<string, unknown>;
}

export interface MCPResponse {
  jsonrpc: "2.0";
  id: string | number;
  result?: Record<string, unknown>;
  error?: MCPError;
}

export interface MCPError {
  code: number;
  message: string;
  data?: unknown;
}

export interface MCPNotification {
  jsonrpc: "2.0";
  method: string;
  params?: Record<string, unknown>;
}

// Context Protocol Messages
export interface ContextMessage {
  type: "text" | "image" | "resource";
  content: string;
  metadata?: Record<string, unknown>;
}

export interface ContextRequest {
  id: string;
  query: string;
  context: ContextMessage[];
  agent: string;
  taskType: string;
}

export interface ContextResponse {
  id: string;
  results: ContextMessage[];
  metadata: {
    source: string;
    timestamp: string;
    agent: string;
  };
}

// Resource Management
export interface Resource {
  id: string;
  name: string;
  type: "file" | "url" | "memory" | "config";
  uri: string;
  content?: string;
  metadata?: Record<string, unknown>;
}

export interface ResourceIndex {
  resources: Resource[];
  lastUpdated: string;
  totalSize: number;
}

// Tool Definitions
export interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: Record<string, unknown>;
  category: string;
}

export interface ToolCall {
  id: string;
  toolName: string;
  params: Record<string, unknown>;
  context?: ContextMessage[];
}

export interface ToolResult {
  id: string;
  toolName: string;
  success: boolean;
  result: unknown;
  executionTime: number;
  error?: string;
}

// Prompt Templates
export interface PromptTemplate {
  name: string;
  description: string;
  template: string;
  variables: string[];
  category: string;
}

// Server State
export interface MCPServerState {
  isRunning: boolean;
  clientConnections: number;
  resourcesLoaded: number;
  lastActivity: string;
  uptime: number;
}

// Configuration
export interface MCPServerConfig {
  port: number;
  host: string;
  protocol: "stdio" | "sse" | "websocket";
  maxConnections: number;
  requestTimeout: number;
  enableLogging: boolean;
  logLevel: "debug" | "info" | "warn" | "error";
}

// Agent Integration
export interface AgentContext {
  agentId: string;
  agentName: string;
  capabilities: string[];
  specialization: string;
  currentTask?: {
    id: string;
    type: string;
    startTime: string;
  };
}

// Event Types
export interface MCPEvent {
  type: string;
  timestamp: string;
  source: string;
  data: Record<string, unknown>;
}

export interface ServerEvent extends MCPEvent {
  type: "start" | "stop" | "error" | "clientConnect" | "clientDisconnect";
}

export interface ContextEvent extends MCPEvent {
  type: "contextLoaded" | "contextUpdated" | "contextCleared";
}
