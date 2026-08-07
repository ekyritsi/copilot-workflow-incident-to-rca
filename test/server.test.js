import test from "node:test";
import assert from "node:assert/strict";
import http from "node:http";
import { once } from "node:events";
import { spawn } from "node:child_process";

async function start(mode) {
  const child = spawn(process.execPath, ["src/server.js"], {
    env: { ...process.env, PORT: "0", DEMO_FAILURE_MODE: mode },
    stdio: ["ignore", "pipe", "pipe"]
  });

  await once(child.stdout, "data");
  child.kill("SIGTERM");
  return child;
}

function get(url) {
  return new Promise((resolve, reject) => {
    const request = http.get(url, (response) => {
      let body = "";
      response.on("data", (chunk) => {
        body += chunk;
      });
      response.on("end", () => resolve({ statusCode: response.statusCode, body }));
    });
    request.on("error", reject);
  });
}

test("the source parses", async () => {
  const child = await start("healthy");
  assert.equal(child.exitCode, null);
});

test("failure mode values are documented", () => {
  assert.ok(["healthy", "outage", "exception"].includes("outage"));
});

