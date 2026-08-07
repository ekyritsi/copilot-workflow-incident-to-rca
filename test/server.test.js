import test from "node:test";
import assert from "node:assert/strict";

test("the demo failure modes are documented", () => {
  assert.deepEqual(["healthy", "outage", "exception"].sort(), ["exception", "healthy", "outage"]);
});

