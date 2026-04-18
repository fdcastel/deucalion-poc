import type { CheckResult } from '@deucalion/probe-core';
import { writeCheckResults } from './aggregator.js';
import { queryWAE } from './query.js';

interface Env {
  CHECK_RESULTS: AnalyticsEngineDataset;
  CF_ACCOUNT_ID: string;
  WAE_API_TOKEN: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === '/health' && request.method === 'GET') {
      return json({ ok: true, variant: 'b', timestamp: new Date().toISOString() });
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

  writeCheckResults(results, env.CHECK_RESULTS);

  return json({ ok: true, ingested: results.length });
}

async function handleStatus(env: Env): Promise<Response> {
  const sql = `
    SELECT
      blob1 AS monitorId,
      blob2 AS probeId,
      argMax(blob3, timestamp) AS state,
      argMax(double1, timestamp) AS latencyMs,
      max(timestamp) AS lastChecked
    FROM poc_check_results
    GROUP BY monitorId, probeId
  `;

  try {
    const rows = await queryWAE(sql, env.CF_ACCOUNT_ID, env.WAE_API_TOKEN);
    const monitors: Record<string, { state: string; latencyMs: number; lastChecked: string; probes: Record<string, unknown> }> = {};

    for (const row of rows) {
      const monitorId = row.monitorId as string;
      const probeId = row.probeId as string;

      if (!monitors[monitorId]) {
        monitors[monitorId] = {
          state: row.state as string,
          latencyMs: row.latencyMs as number,
          lastChecked: row.lastChecked as string,
          probes: {},
        };
      }
      monitors[monitorId].probes[probeId] = {
        state: row.state,
        latencyMs: row.latencyMs,
        lastChecked: row.lastChecked,
      };
      if (row.state === 'down') {
        monitors[monitorId].state = 'down';
      }
    }

    return json({ monitors });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
}

async function handleHistory(env: Env, monitorId: string): Promise<Response> {
  // Sanitize monitorId to prevent SQL injection
  const safeMonitorId = monitorId.replace(/[^a-zA-Z0-9_-]/g, '');

  const sql = `
    SELECT
      blob2 AS probeId,
      blob3 AS state,
      double1 AS latencyMs,
      double2 AS statusCode,
      blob5 AS errorMessage,
      timestamp
    FROM poc_check_results
    WHERE blob1 = '${safeMonitorId}'
      AND timestamp >= NOW() - INTERVAL '1' DAY
    ORDER BY timestamp DESC
    LIMIT 500
  `;

  try {
    const rows = await queryWAE(sql, env.CF_ACCOUNT_ID, env.WAE_API_TOKEN);
    return json({ monitorId, results: rows });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
}

async function handleProbeInfo(env: Env): Promise<Response> {
  const sql = `
    SELECT
      blob2 AS probeId,
      argMax(blob4, timestamp) AS lastPlacement,
      max(timestamp) AS lastSeen
    FROM poc_check_results
    GROUP BY probeId
  `;

  try {
    const rows = await queryWAE(sql, env.CF_ACCOUNT_ID, env.WAE_API_TOKEN);
    return json({ probes: rows });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
