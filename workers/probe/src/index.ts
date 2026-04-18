import { runHttpCheck } from '@deucalion/probe-core';
import type { MonitorConfig, CheckResult } from '@deucalion/probe-core';

interface RunBatchRequest {
  monitors: MonitorConfig[];
  probeId: string;
}

export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === '/health' && request.method === 'GET') {
      return handleHealth(request);
    }

    if (url.pathname === '/run-batch' && request.method === 'POST') {
      return handleRunBatch(request);
    }

    return new Response(JSON.stringify({ error: 'Not Found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};

function handleHealth(request: Request): Response {
  const cf = (request as Request & { cf?: IncomingRequestCfProperties }).cf;
  return new Response(
    JSON.stringify({
      ok: true,
      colo: cf?.colo ?? 'unknown',
      timestamp: new Date().toISOString(),
    }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    },
  );
}

async function handleRunBatch(request: Request): Promise<Response> {
  let body: RunBatchRequest;
  try {
    body = (await request.json()) as RunBatchRequest;
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (!body.monitors || !Array.isArray(body.monitors) || !body.probeId) {
    return new Response(
      JSON.stringify({ error: 'Missing required fields: monitors (array) and probeId (string)' }),
      {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }

  // Extract placement metadata from the request
  const cf = (request as Request & { cf?: IncomingRequestCfProperties }).cf;
  const colo = cf?.colo ?? 'unknown';
  const cfRay = request.headers.get('CF-Ray') ?? 'unknown';

  // Run all checks concurrently
  const settledResults = await Promise.allSettled(
    body.monitors.map((monitor) => runHttpCheck(monitor, body.probeId)),
  );

  // Attach placement metadata to each result
  const results: CheckResult[] = settledResults.map((settled, i) => {
    if (settled.status === 'fulfilled') {
      return {
        ...settled.value,
        placementRequested: 'cloudflare.com:443',
        placementObserved: `${colo}|${cfRay}`,
      };
    }
    // Rejected promise — should be rare since runHttpCheck already catches errors
    return {
      monitorId: body.monitors[i].id,
      probeId: body.probeId,
      startedAt: new Date().toISOString(),
      finishedAt: new Date().toISOString(),
      latencyMs: 0,
      state: 'down' as const,
      statusCode: 0,
      errorMessage: String(settled.reason),
      errorCode: 'INTERNAL_ERROR',
      placementRequested: 'cloudflare.com:443',
      placementObserved: `${colo}|${cfRay}`,
    };
  });

  return new Response(JSON.stringify(results), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}
