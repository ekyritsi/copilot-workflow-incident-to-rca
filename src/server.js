import http from "node:http";

const port = Number.parseInt(process.env.PORT ?? "8080", 10);
const failureMode = () => process.env.DEMO_FAILURE_MODE ?? "healthy";

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

function handleRequest(request, response) {
  const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);
  const mode = failureMode();

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
      appInsights?.defaultClient?.trackException({ exception: error });
      console.error(error);
      respond(response, 500, { error: "internal_server_error" });
      return;
    }

    respond(response, 200, {
      orders: [
        { id: "demo-1001", status: "processing" },
        { id: "demo-1002", status: "shipped" }
      ]
    });
    return;
  }

  if (url.pathname === "/") {
    respond(
      response,
      mode === "outage" ? 503 : 200,
      mode === "outage"
        ? { error: "site_unavailable", incident: "INC-DEMO-001" }
        : {
            service: "incident-to-rca-demo",
            message: "The demo application is running.",
            health: "/health",
            orders: "/api/orders"
          }
    );
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

