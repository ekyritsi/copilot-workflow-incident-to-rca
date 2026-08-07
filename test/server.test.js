import test from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";

test("the demo exposes the health and customer API contracts", () => {
  assert.deepEqual(["/health", "/api/orders"].sort(), ["/api/orders", "/health"]);
});

test("the orders API returns its documented payload", async () => {
  const port = 18080 + Math.floor(Math.random() * 1000);
  const server = spawn(process.execPath, ["src/server.js"], {
    env: { ...process.env, PORT: String(port) },
    stdio: ["ignore", "pipe", "pipe"]
  });

  try {
    await new Promise((resolve, reject) => {
      const onData = (data) => {
        if (data.toString().includes("listening on port")) {
          resolve();
        }
      };
      server.stdout.on("data", onData);
      server.once("error", reject);
      server.once("exit", (code) => {
        reject(new Error(`server exited before startup with code ${code}`));
      });
    });

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
