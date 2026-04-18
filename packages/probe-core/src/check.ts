import type { CheckResult, MonitorConfig } from './types.js';

const DEFAULT_TIMEOUT_MS = 10_000;

/**
 * Run an HTTP check against a single monitor.
 *
 * Uses `fetch()` to make a GET request, measures latency, and returns
 * a `CheckResult`. Respects the provided `AbortSignal` for timeout.
 */
export async function runHttpCheck(
  monitor: MonitorConfig,
  probeId: string,
  signal?: AbortSignal,
): Promise<CheckResult> {
  const timeoutMs = monitor.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const startedAt = new Date();

  // Create an internal abort controller for timeout if no external signal provided
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  // If an external signal is provided, forward its abort
  if (signal) {
    if (signal.aborted) {
      controller.abort();
    } else {
      signal.addEventListener('abort', () => controller.abort(), { once: true });
    }
  }

  try {
    const response = await fetch(monitor.url, {
      method: 'GET',
      signal: controller.signal,
      redirect: 'follow',
    });

    const finishedAt = new Date();
    const latencyMs = finishedAt.getTime() - startedAt.getTime();
    const isUp = response.status === monitor.expectedStatus;

    return {
      monitorId: monitor.id,
      probeId,
      startedAt: startedAt.toISOString(),
      finishedAt: finishedAt.toISOString(),
      latencyMs,
      state: isUp ? 'up' : 'down',
      statusCode: response.status,
      errorMessage: isUp ? undefined : `Unexpected status ${response.status}`,
    };
  } catch (err: unknown) {
    const finishedAt = new Date();
    const latencyMs = finishedAt.getTime() - startedAt.getTime();
    const isTimeout =
      (err instanceof DOMException && err.name === 'AbortError') ||
      (err instanceof Error && err.name === 'AbortError');

    return {
      monitorId: monitor.id,
      probeId,
      startedAt: startedAt.toISOString(),
      finishedAt: finishedAt.toISOString(),
      latencyMs,
      state: 'down',
      statusCode: 0,
      errorMessage: isTimeout ? 'Request timed out' : String(err),
      errorCode: isTimeout ? 'TIMEOUT' : 'FETCH_ERROR',
    };
  } finally {
    clearTimeout(timeoutId);
  }
}
