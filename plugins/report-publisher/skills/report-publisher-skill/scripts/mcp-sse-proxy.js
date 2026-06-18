#!/usr/bin/env node
/**
 * MCP stdio-to-Streamable-HTTP proxy for Report Portal publisher.
 * Bridges Claude Desktop (stdio) to the FastMCP Streamable HTTP server.
 * Uses only Node.js built-in modules — no external dependencies.
 *
 * Streamable HTTP protocol:
 *   - POST /mcp with JSON-RPC request body
 *   - Response is text/event-stream with the JSON-RPC response as SSE events
 *   - Each response body contains: event: message\ndata: <json>\n\n
 */

const http = require("http");
const https = require("https");
const { URL } = require("url");

const MCP_PUBLISH_API_KEY = process.env.MCP_PUBLISH_API_KEY || "";
const MCP_SERVER_URL = process.env.MCP_SERVER_URL || "https://reports.resal.dev/mcp";
const MCP_HOST_HEADER = process.env.MCP_HOST_HEADER || "";
const MCP_ALLOW_CUSTOM_SERVER_URL = process.env.MCP_ALLOW_CUSTOM_SERVER_URL === "1";
const APPROVED_MCP_HOSTS = new Set(["reports.resal.dev", "reports.abushanab.net"]);

if (!MCP_PUBLISH_API_KEY) {
  console.error("Error: MCP_PUBLISH_API_KEY environment variable is required");
  process.exit(1);
}

const baseUrl = MCP_SERVER_URL.replace(/\/$/, "");
const mcpUrl = new URL(baseUrl);

if (!MCP_ALLOW_CUSTOM_SERVER_URL) {
  if (mcpUrl.protocol !== "https:") {
    console.error("Error: MCP_SERVER_URL must use https unless MCP_ALLOW_CUSTOM_SERVER_URL=1 is set");
    process.exit(1);
  }
  if (!APPROVED_MCP_HOSTS.has(mcpUrl.hostname) || !mcpUrl.pathname.startsWith("/mcp")) {
    console.error(
      "Error: MCP_SERVER_URL must point to an approved Report Portal /mcp endpoint " +
      "(reports.resal.dev or reports.abushanab.net). Set MCP_ALLOW_CUSTOM_SERVER_URL=1 only for an approved diagnostic.",
    );
    process.exit(1);
  }
}

let mcpSessionId = null;

function sanitizeErrorBody(body) {
  return body.split(MCP_PUBLISH_API_KEY).join("<REDACTED>");
}

// ----- HTTP Request Helper (returns response object with SSE stream) -----
function postMCPMessage(bodyJson) {
  return new Promise((resolve, reject) => {
    const client = mcpUrl.protocol === "https:" ? https : http;
    const body = JSON.stringify(bodyJson);
    const headers = {
      "Content-Type": "application/json",
      "Accept": "application/json, text/event-stream",
      "Authorization": `Bearer ${MCP_PUBLISH_API_KEY}`,
      "Content-Length": Buffer.byteLength(body, "utf8"),
    };
    if (MCP_HOST_HEADER) {
      headers["Host"] = MCP_HOST_HEADER;
    }
    if (mcpSessionId) {
      headers["Mcp-Session-Id"] = mcpSessionId;
    }

    const options = {
      hostname: mcpUrl.hostname,
      port: mcpUrl.port || (mcpUrl.protocol === "https:" ? 443 : 80),
      path: mcpUrl.pathname,
      method: "POST",
      headers,
    };

    const req = client.request(options, (res) => {
      // Capture session ID from first response
      if (!mcpSessionId && res.headers["mcp-session-id"]) {
        mcpSessionId = res.headers["mcp-session-id"];
      }

      if (res.statusCode !== 200) {
        let errorBody = "";
        res.on("data", (chunk) => { errorBody += chunk; });
        res.on("end", () => {
          reject(new Error(`HTTP ${res.statusCode}: ${sanitizeErrorBody(errorBody)}`));
        });
        return;
      }

      let buffer = "";
      let resolved = false;

      res.on("data", (chunk) => {
        buffer += chunk.toString();
        // Parse SSE events from buffer
        while (true) {
          const eventEnd = buffer.indexOf("\n\n");
          if (eventEnd === -1) break;
          const eventBlock = buffer.slice(0, eventEnd);
          buffer = buffer.slice(eventEnd + 2);

          const lines = eventBlock.split("\n");
          let eventName = "message";
          let data = null;
          for (const line of lines) {
            if (line.startsWith("event: ")) {
              eventName = line.slice(7);
            } else if (line.startsWith("data: ")) {
              data = line.slice(6);
            }
          }
          if (data) {
            try {
              const parsed = JSON.parse(data);
              sendMessage(parsed);
              if (!resolved) {
                resolved = true;
                resolve();
              }
            } catch (err) {
              console.error("[proxy] Failed to parse SSE data:", data);
            }
          }
        }
      });

      res.on("end", () => {
        // Response stream ended — resolve if not already
        if (!resolved) {
          resolved = true;
          resolve();
        }
      });

      res.on("error", (err) => {
        reject(err);
      });
    });

    req.on("error", (err) => {
      reject(err);
    });

    req.write(body);
    req.end();
  });
}

// ----- Stdio I/O -----
let stdinBuffer = "";

process.stdin.setEncoding("utf8");

process.stdin.on("data", (chunk) => {
  stdinBuffer += chunk;
  while (true) {
    const contentLengthMatch = stdinBuffer.match(/Content-Length: (\d+)\r\n/);
    if (!contentLengthMatch) break;
    const contentLength = parseInt(contentLengthMatch[1], 10);
    const headerEnd = stdinBuffer.indexOf("\r\n\r\n");
    if (headerEnd === -1) break;
    const messageStart = headerEnd + 4;
    if (stdinBuffer.length < messageStart + contentLength) break;
    const message = stdinBuffer.slice(messageStart, messageStart + contentLength);
    stdinBuffer = stdinBuffer.slice(messageStart + contentLength);
    handleStdioMessage(message);
  }
});

process.stdin.on("end", () => {
  process.exit(0);
});

async function handleStdioMessage(message) {
  let request;
  try {
    request = JSON.parse(message);
  } catch (err) {
    sendError(null, -32700, "Parse error: " + err.message);
    return;
  }

  try {
    await postMCPMessage(request);
  } catch (err) {
    const id = request.id !== undefined ? request.id : null;
    sendError(id, -32603, "Internal error: " + err.message);
  }
}

function sendMessage(message) {
  const json = JSON.stringify(message);
  const header = `Content-Length: ${Buffer.byteLength(json, "utf8")}\r\n\r\n`;
  process.stdout.write(header + json);
}

function sendError(id, code, message) {
  sendMessage({
    jsonrpc: "2.0",
    id,
    error: { code, message },
  });
}

// ----- Start -----
console.error(`[proxy] MCP Streamable HTTP proxy ready — ${mcpUrl.toString()}`);
console.error("[proxy] Waiting for stdio messages...");
