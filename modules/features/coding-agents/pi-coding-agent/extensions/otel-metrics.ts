// pi has no OTLP exporter of its own, so usage is pushed to the local Alloy
// receiver (my.services.otel-collector) as OTLP/JSON. Sums are sent as deltas
// because these series carry no per-process label: Alloy merges deltas from
// concurrent sessions, whereas cumulative values would overwrite each other.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const endpoint = "http://localhost:4318/v1/metrics";
const flushDelayMs = 10_000;
const AGGREGATION_TEMPORALITY_DELTA = 1;

type Attributes = Record<string, string>;
type Point = { name: string; unit: string; attributes: Attributes; value: number };

const pending = new Map<string, Point>();
let windowStart = Date.now();
let timer: ReturnType<typeof setTimeout> | undefined;

function add(name: string, unit: string, attributes: Attributes, value: number) {
  if (!Number.isFinite(value) || value === 0) {
    return;
  }
  const key = `${name}\0${JSON.stringify(Object.entries(attributes).sort())}`;
  const point = pending.get(key);
  if (point) {
    point.value += value;
  } else {
    pending.set(key, { name, unit, attributes, value });
  }
  if (!timer) {
    timer = setTimeout(() => void flush(), flushDelayMs);
    timer.unref?.();
  }
}

function nanos(ms: number): string {
  return (BigInt(ms) * 1_000_000n).toString();
}

async function flush() {
  if (timer) {
    clearTimeout(timer);
    timer = undefined;
  }
  if (pending.size === 0) {
    return;
  }
  const start = nanos(windowStart);
  const end = Date.now();
  windowStart = end;
  const byMetric = new Map<string, Point[]>();
  for (const point of pending.values()) {
    byMetric.set(point.name, [...(byMetric.get(point.name) ?? []), point]);
  }
  pending.clear();

  const metrics = [...byMetric].map(([name, points]) => ({
    name,
    unit: points[0].unit,
    sum: {
      aggregationTemporality: AGGREGATION_TEMPORALITY_DELTA,
      isMonotonic: true,
      dataPoints: points.map((p) => ({
        attributes: Object.entries(p.attributes).map(([key, value]) => ({
          key,
          value: { stringValue: value },
        })),
        startTimeUnixNano: start,
        timeUnixNano: nanos(end),
        asDouble: p.value,
      })),
    },
  }));
  const body = {
    resourceMetrics: [
      {
        resource: {
          attributes: [{ key: "service.name", value: { stringValue: "pi" } }],
        },
        scopeMetrics: [{ scope: { name: "pi-otel-metrics" }, metrics }],
      },
    ],
  };
  try {
    await fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(2_000),
    });
  } catch {
    // Telemetry must never disturb a session; a missing collector just loses
    // this window.
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (event) => {
    add("pi.session.count", "1", { reason: event.reason }, 1);
  });

  pi.on("message_end", (event) => {
    const message = event.message;
    if (message.role !== "assistant") {
      return;
    }
    const attributes = { model: message.model, provider: message.provider };
    const { usage } = message;
    // Token type names follow Claude Code's so one dashboard query shape fits
    // both agents.
    add("pi.token.usage", "tokens", { ...attributes, type: "input" }, usage.input);
    add("pi.token.usage", "tokens", { ...attributes, type: "output" }, usage.output);
    add("pi.token.usage", "tokens", { ...attributes, type: "cacheRead" }, usage.cacheRead);
    add("pi.token.usage", "tokens", { ...attributes, type: "cacheCreation" }, usage.cacheWrite);
    add("pi.cost.usage", "USD", attributes, usage.cost.total);
  });

  pi.on("tool_execution_end", (event) => {
    add("pi.tool.call", "1", { tool: event.toolName, success: String(!event.isError) }, 1);
  });

  pi.on("session_shutdown", async () => {
    await flush();
  });
}
