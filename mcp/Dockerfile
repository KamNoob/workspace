FROM node:20-alpine

LABEL maintainer="OpenClaw Team"
LABEL description="Model Context Protocol (MCP) Server for OpenClaw"

WORKDIR /app

# Install dependencies
COPY mcp/package*.json ./
RUN npm ci --only=production

# Copy compiled code
COPY mcp/dist ./dist

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))" || exit 1

# Run server
CMD ["node", "dist/server.js"]
