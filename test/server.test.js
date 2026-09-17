import test from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";

async function startServer() {
  const port = 18080 + Math.floor(Math.random() * 1000);
  const server = spawn(process.execPath, ["src/server.js"], {
    env: { ...process.env, PORT: String(port) },
    stdio: ["ignore", "pipe", "pipe"]
  });

  await new Promise((resolve, reject) => {
    let output = "";
    const timeout = setTimeout(() => {
      reject(new Error("server did not start within 10 seconds"));
    }, 10_000);
    const settle = (callback, value) => {
      clearTimeout(timeout);
      callback(value);
    };
    const onData = (data) => {
      output += data.toString();
      if (output.includes("listening on port")) {
        settle(resolve);
      }
    };
    server.stdout.on("data", onData);
    server.once("error", (error) => settle(reject, error));
    server.once("exit", (code) => {
      settle(reject, new Error(`server exited before startup with code ${code}`));
    });
  });

  return { server, port };
}

test("the demo exposes the health and customer API contracts", () => {
  assert.deepEqual(["/health", "/api/orders"].sort(), ["/api/orders", "/health"]);
});

test("the orders API returns its documented payload", async () => {
  const { server, port } = await startServer();

  try {
    const response = await fetch(`http://127.0.0.1:${port}/api/orders`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      orders: [
        { id: "demo-1001", status: "processing" },
        { id: "demo-1002", status: "shipped" }
      ]
    });
  } finally {
    server.kill("SIGTERM");
  }
});

test("the health endpoint reports healthy", async () => {
  const { server, port } = await startServer();

  try {
    const response = await fetch(`http://127.0.0.1:${port}/health`);
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.status, "healthy");
    assert.equal(typeof body.timestamp, "string");
  } finally {
    server.kill("SIGTERM");
  }
});
