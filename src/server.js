import http from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const port = Number.parseInt(process.env.PORT ?? "8080", 10);
const failureMode = () => process.env.DEMO_FAILURE_MODE ?? "healthy";
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

function respondHtml(response, statusCode, mode) {
  response.writeHead(statusCode, {
    "Content-Type": "text/html; charset=utf-8",
    "Cache-Control": "no-store"
  });
  response.end(statusPage.replace("__DEMO_MODE__", JSON.stringify(mode)));
}

function reportException(error) {
  appInsights?.defaultClient?.trackException({ exception: error });
  console.error(error);
}

function getOrdersPayload() {
  return {
    orders: [
      { id: "demo-1001", status: "processing" },
      { id: "demo-1002", status: "shipped" }
    ]
  };
}

function handleRequest(request, response) {
  const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);
  const mode = failureMode();

  if (url.pathname === "/mona-single.png") {
    response.writeHead(200, {
      "Content-Type": "image/png",
      "Cache-Control": "public, max-age=3600"
    });
    response.end(mascotImage);
    return;
  }

  if (url.pathname === "/health") {
    respond(
      response,
      mode === "outage" ? 503 : 200,
      mode === "outage"
        ? { status: "unhealthy", reason: "DEMO_FAILURE_MODE=outage" }
        : { status: "healthy", mode, timestamp: new Date().toISOString() }
    );
    return;
  }

  if (url.pathname === "/api/orders") {
    if (mode === "outage") {
      respond(response, 503, {
        error: "orders_backend_unavailable",
        message: "The simulated orders dependency is unavailable."
      });
      return;
    }

    if (mode === "exception") {
      const error = new Error("Simulated orders serialization regression");
      reportException(error);
      respond(response, 500, { error: "internal_server_error" });
      return;
    }

    try {
      respond(response, 200, getOrdersPayload());
    } catch (error) {
      reportException(error);
      respond(response, 500, { error: "internal_server_error" });
    }
    return;
  }

  if (url.pathname === "/") {
    respondHtml(response, mode === "outage" ? 503 : 200, mode);
    return;
  }

  respond(response, 404, { error: "not_found" });
}

const server = http.createServer(handleRequest);
server.listen(port, () => {
  console.log(`incident-to-rca-demo listening on port ${port}`);
  console.log(`failure mode: ${failureMode()}`);
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
