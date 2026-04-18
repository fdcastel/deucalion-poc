import { POC_CONFIG } from '@deucalion/probe-core';
import type { CheckResult } from '@deucalion/probe-core';

interface Env {
  PROBE_WORKER_URL: string;
  VARIANT_A_URL: string;
  VARIANT_B_URL: string;
}

export default {
  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(runScheduledCheck(env));
  },

  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === '/health' && request.method === 'GET') {
      return json({ ok: true, worker: 'scheduler', timestamp: new Date().toISOString() });
    }

    // Manual trigger endpoint for testing
    if (url.pathname === '/trigger' && request.method === 'POST') {
      try {
        await runScheduledCheck(env);
        return json({ ok: true, message: 'Check cycle completed' });
      } catch (err) {
        return json({ error: err instanceof Error ? err.message : 'Internal error' }, 500);
      }
    }

    return json({ error: 'Not Found' }, 404);
  },
};

async function runScheduledCheck(env: Env): Promise<void> {
  const probeId = 'us-east';

  // Step 1: Send batch to probe worker
  const probeResponse = await fetch(`${env.PROBE_WORKER_URL}/run-batch`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      monitors: POC_CONFIG.monitors,
      probeId,
    }),
  });

  if (!probeResponse.ok) {
    const text = await probeResponse.text();
    throw new Error(`Probe worker returned ${probeResponse.status}: ${text}`);
  }

  const results: CheckResult[] = (await probeResponse.json()) as CheckResult[];
  console.log(`Received ${results.length} check results from probe ${probeId}`);

  // Step 2: Forward results to both variants concurrently
  const [variantAResult, variantBResult] = await Promise.allSettled([
    forwardResults(env.VARIANT_A_URL, results),
    forwardResults(env.VARIANT_B_URL, results),
  ]);

  if (variantAResult.status === 'rejected') {
    console.error('Variant A ingest failed:', variantAResult.reason);
  }
  if (variantBResult.status === 'rejected') {
    console.error('Variant B ingest failed:', variantBResult.reason);
  }
}

async function forwardResults(baseUrl: string, results: CheckResult[]): Promise<void> {
  const response = await fetch(`${baseUrl}/ingest`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(results),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Ingest to ${baseUrl} returned ${response.status}: ${text}`);
  }
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
