import type { CheckResult } from '@deucalion/probe-core';
import { getCurrentStates, getHistory, getProbeInfo } from './db.js';
import type { AggregationDO } from './aggregator.js';

export { AggregationDO } from './aggregator.js';

interface Env {
  DB: D1Database;
  AGGREGATION_DO: DurableObjectNamespace<AggregationDO>;
}

const AGGREGATION_DO_ID = 'singleton';

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === '/health' && request.method === 'GET') {
      return json({ ok: true, variant: 'a', timestamp: new Date().toISOString() });
    }

    if (url.pathname === '/ingest' && request.method === 'POST') {
      return handleIngest(request, env);
    }

    if (url.pathname === '/status' && request.method === 'GET') {
      return handleStatus(env);
    }

    if (url.pathname.startsWith('/history/') && request.method === 'GET') {
      const monitorId = url.pathname.split('/history/')[1];
      if (!monitorId) {
        return json({ error: 'Missing monitorId' }, 400);
      }
      return handleHistory(env, monitorId);
    }

    if (url.pathname === '/probe-info' && request.method === 'GET') {
      return handleProbeInfo(env);
    }

    return json({ error: 'Not Found' }, 404);
  },
};

async function handleIngest(request: Request, env: Env): Promise<Response> {
  let results: CheckResult[];
  try {
    results = (await request.json()) as CheckResult[];
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  if (!Array.isArray(results)) {
    return json({ error: 'Body must be an array of CheckResult' }, 400);
  }

  // Forward to Durable Object
  const id = env.AGGREGATION_DO.idFromName(AGGREGATION_DO_ID);
  const stub = env.AGGREGATION_DO.get(id);
  await stub.ingestResults(results);

  return json({ ok: true, ingested: results.length });
}

async function handleStatus(env: Env): Promise<Response> {
  // Try DO first for hot state, fall back to D1
  try {
    const id = env.AGGREGATION_DO.idFromName(AGGREGATION_DO_ID);
    const stub = env.AGGREGATION_DO.get(id);
    const status = await stub.getStatus();

    if (Object.keys(status).length > 0) {
      return json({ monitors: status });
    }
  } catch {
    // DO not available, fall back to D1
  }

  // Fall back to D1
  const rows = await getCurrentStates(env.DB);
  const monitors: Record<string, { state: string; latencyMs: number; lastChecked: string; probes: Record<string, unknown> }> = {};

  for (const row of rows) {
    if (!monitors[row.monitor_id]) {
      monitors[row.monitor_id] = {
        state: row.state,
        latencyMs: row.latency_ms,
        lastChecked: row.last_checked_at,
        probes: {},
      };
    }
    monitors[row.monitor_id].probes[row.probe_id] = {
      state: row.state,
      latencyMs: row.latency_ms,
      lastChecked: row.last_checked_at,
      statusCode: row.status_code,
    };
    if (row.state === 'down') {
      monitors[row.monitor_id].state = 'down';
    }
  }

  return json({ monitors });
}

async function handleHistory(env: Env, monitorId: string): Promise<Response> {
  const rows = await getHistory(env.DB, monitorId);
  return json({ monitorId, results: rows });
}

async function handleProbeInfo(env: Env): Promise<Response> {
  const rows = await getProbeInfo(env.DB);
  return json({ probes: rows });
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
