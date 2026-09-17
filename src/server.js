import http from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const port = Number.parseInt(process.env.PORT ?? "8080", 10);
const publicDirectory = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "public");
const statusPage = await readFile(path.join(publicDirectory, "index.html"), "utf8");
const mascotImage = await readFile(path.join(publicDirectory, "mona-single.png"));

let appInsights;
if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  const module = await import("applicationinsights");
  appInsights = module.default ?? module;
  appInsights
    .setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
    .setAutoCollectConsole(true, true)
    .setAutoCollectDependencies(true)
    .setAutoCollectExceptions(true)
    .setAutoCollectPerformance(true, true)
    .start();
}

function respond(response, statusCode, body) {
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store"
  });
  response.end(JSON.stringify(body));
}

function respondHtml(response) {
  response.writeHead(200, {
    "Content-Type": "text/html; charset=utf-8",
    "Cache-Control": "no-store"
  });
  response.end(statusPage);
}

function reportException(error) {
  appInsights?.defaultClient?.trackException({ exception: error });
  console.error(error);
}

function getOrdersPayload() {
  const orders = [
    { id: "demo-1001", status: "processing" },
    { id: "demo-1002", status: "shipped" }
  ];

  return {
    orders
  };
}

function handleRequest(request, response) {
  const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);

  if (url.pathname === "/mona-single.png") {
    response.writeHead(200, {
      "Content-Type": "image/png",
      "Cache-Control": "public, max-age=3600"
    });
    response.end(mascotImage);
    return;
  }

  if (url.pathname === "/health") {
    respond(response, 200, { status: "healthy", timestamp: new Date().toISOString() });
    return;
  }

  if (url.pathname === "/api/orders") {
    try {
      respond(response, 200, getOrdersPayload());
    } catch (error) {
      reportException(error);
      respond(response, 500, { error: "internal_server_error" });
    }
    return;
  }

  if (url.pathname === "/") {
    respondHtml(response);
    return;
  }

  respond(response, 404, { error: "not_found" });
}

const server = http.createServer(handleRequest);
server.listen(port, () => {
  console.log(`incident-to-rca-demo listening on port ${port}`);
});

function shutdown(signal) {
  console.log(`received ${signal}; shutting down`);
  server.close((error) => {
    if (error) {
      console.error("server shutdown failed", error);
      process.exitCode = 1;
    }
  });
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
