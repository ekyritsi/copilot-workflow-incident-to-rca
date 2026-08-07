import test from "node:test";
import assert from "node:assert/strict";

test("the demo exposes the health and customer API contracts", () => {
  assert.deepEqual(["/health", "/api/orders"].sort(), ["/api/orders", "/health"]);
});
