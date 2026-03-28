/**
 * Model Context Protocol Implementation
 * Handles JSON-RPC 2.0 message passing and context management
 */

import { EventEmitter } from "events";
import {
  MCPRequest,
  MCPResponse,
  MCPError,
  MCPNotification,
  ContextRequest,
  ContextResponse,
  ContextMessage,
  Resource,
  ResourceIndex,
} from "./types.js";

export class MCPProtocol extends EventEmitter {
  private requestId = 0;
  private pendingRequests = new Map<
    string | number,
    {
      resolve: (value: unknown) => void;
      reject: (reason?: unknown) => void;
      timeout: NodeJS.Timeout;
    }
  >();
  private requestTimeout: number;

  constructor(requestTimeout = 30000) {
    super();
    this.requestTimeout = requestTimeout;
  }

  /**
   * Encode a request as JSON-RPC 2.0
   */
  encodeRequest(method: string, params?: Record<string, unknown>): MCPRequest {
    const id = ++this.requestId;
    return {
      jsonrpc: "2.0",
      id,
      method,
      params,
    };
  }

  /**
   * Encode a response as JSON-RPC 2.0
   */
  encodeResponse(
    id: string | number,
    result?: Record<string, unknown>,
    error?: MCPError
  ): MCPResponse {
    if (error) {
      return {
        jsonrpc: "2.0",
        id,
        error,
      };
    }
    return {
      jsonrpc: "2.0",
      id,
      result,
    };
  }

  /**
   * Encode a notification as JSON-RPC 2.0
   */
  encodeNotification(
    method: string,
    params?: Record<string, unknown>
  ): MCPNotification {
    return {
      jsonrpc: "2.0",
      method,
      params,
    };
  }

  /**
   * Decode and validate incoming message
   */
  decodeMessage(data: string): unknown {
    try {
      return JSON.parse(data);
    } catch (err) {
      throw {
        code: -32700,
        message: "Parse error",
        data: err,
      };
    }
  }

  /**
   * Validate JSON-RPC message structure
   */
  validateMessage(msg: unknown): msg is MCPRequest | MCPNotification {
    if (typeof msg !== "object" || msg === null) return false;
    const m = msg as Record<string, unknown>;
    return (
      m.jsonrpc === "2.0" &&
      typeof m.method === "string" &&
      (typeof m.id === "string" ||
        typeof m.id === "number" ||
        m.id === undefined)
    );
  }

  /**
   * Process incoming context request
   */
  async handleContextRequest(request: ContextRequest): Promise<ContextResponse> {
    this.emit("contextRequest", request);

    return new Promise((resolve) => {
      const timeout = setTimeout(() => {
        resolve({
          id: request.id,
          results: [],
          metadata: {
            source: "mcp",
            timestamp: new Date().toISOString(),
            agent: request.agent,
          },
        });
      }, this.requestTimeout);

      this.once(`contextResponse:${request.id}`, (response) => {
        clearTimeout(timeout);
        resolve(response);
      });
    });
  }

  /**
   * Build context from available resources
   */
  buildContextMessage(
    content: string,
    type: "text" | "image" | "resource" = "text",
    metadata?: Record<string, unknown>
  ): ContextMessage {
    return {
      type,
      content,
      metadata: {
        timestamp: new Date().toISOString(),
        ...metadata,
      },
    };
  }

  /**
   * Merge context messages (for multi-source context)
   */
  mergeContext(...messages: ContextMessage[]): ContextMessage {
    const merged = messages
      .map((m) => m.content)
      .filter(Boolean)
      .join("\n---\n");

    return {
      type: "text",
      content: merged,
      metadata: {
        merged: true,
        count: messages.length,
        timestamp: new Date().toISOString(),
      },
    };
  }

  /**
   * Create resource index from available resources
   */
  createResourceIndex(resources: Resource[]): ResourceIndex {
    const totalSize = resources.reduce(
      (sum, r) => sum + (r.content?.length || 0),
      0
    );

    return {
      resources,
      lastUpdated: new Date().toISOString(),
      totalSize,
    };
  }

  /**
   * Wait for response to a sent request
   */
  async waitForResponse(
    requestId: string | number
  ): Promise<MCPResponse> {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(requestId);
        reject(new Error(`Request ${requestId} timed out`));
      }, this.requestTimeout);

      this.pendingRequests.set(requestId, {
        resolve: (value) => {
          clearTimeout(timeout);
          this.pendingRequests.delete(requestId);
          resolve(value as MCPResponse);
        },
        reject: (reason) => {
          clearTimeout(timeout);
          this.pendingRequests.delete(requestId);
          reject(reason);
        },
        timeout,
      });
    });
  }

  /**
   * Fulfill pending request
   */
  fulfillRequest(id: string | number, response: unknown) {
    const pending = this.pendingRequests.get(id);
    if (pending) {
      pending.resolve(response);
    }
  }

  /**
   * Reject pending request
   */
  rejectRequest(id: string | number, error: unknown) {
    const pending = this.pendingRequests.get(id);
    if (pending) {
      pending.reject(error);
    }
  }
}
