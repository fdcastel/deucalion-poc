import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { runHttpCheck } from './check.js';
import type { MonitorConfig } from './types.js';

const testMonitor: MonitorConfig = {
  id: 'test-monitor',
  type: 'http',
  url: 'https://example.com',
  expectedStatus: 200,
  timeoutMs: 5000,
};

describe('runHttpCheck', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('returns "up" when status matches expectedStatus', async () => {
    const mockFetch = vi.mocked(fetch);
    mockFetch.mockResolvedValueOnce(new Response('OK', { status: 200 }));

    const result = await runHttpCheck(testMonitor, 'probe-1');

    expect(result.state).toBe('up');
    expect(result.statusCode).toBe(200);
    expect(result.monitorId).toBe('test-monitor');
    expect(result.probeId).toBe('probe-1');
    expect(result.errorMessage).toBeUndefined();
    expect(result.latencyMs).toBeGreaterThanOrEqual(0);
    expect(result.startedAt).toBeTruthy();
    expect(result.finishedAt).toBeTruthy();
  });

  it('returns "down" when status does not match expectedStatus', async () => {
    const mockFetch = vi.mocked(fetch);
    mockFetch.mockResolvedValueOnce(new Response('Not Found', { status: 404 }));

    const result = await runHttpCheck(testMonitor, 'probe-1');

    expect(result.state).toBe('down');
    expect(result.statusCode).toBe(404);
    expect(result.errorMessage).toBe('Unexpected status 404');
  });

  it('returns "down" with TIMEOUT errorCode on abort', async () => {
    const mockFetch = vi.mocked(fetch);
    mockFetch.mockRejectedValueOnce(new DOMException('The operation was aborted', 'AbortError'));

    const result = await runHttpCheck(testMonitor, 'probe-1');

    expect(result.state).toBe('down');
    expect(result.statusCode).toBe(0);
    expect(result.errorCode).toBe('TIMEOUT');
    expect(result.errorMessage).toBe('Request timed out');
  });

  it('returns "down" with FETCH_ERROR on network errors', async () => {
    const mockFetch = vi.mocked(fetch);
    mockFetch.mockRejectedValueOnce(new TypeError('Failed to fetch'));

    const result = await runHttpCheck(testMonitor, 'probe-1');

    expect(result.state).toBe('down');
    expect(result.statusCode).toBe(0);
    expect(result.errorCode).toBe('FETCH_ERROR');
    expect(result.errorMessage).toContain('Failed to fetch');
  });

  it('respects external AbortSignal', async () => {
    const controller = new AbortController();
    const mockFetch = vi.mocked(fetch);
    mockFetch.mockRejectedValueOnce(new DOMException('The operation was aborted', 'AbortError'));

    controller.abort();
    const result = await runHttpCheck(testMonitor, 'probe-1', controller.signal);

    expect(result.state).toBe('down');
    expect(result.errorCode).toBe('TIMEOUT');
  });

  it('uses default timeout when timeoutMs is not set', async () => {
    const monitorNoTimeout: MonitorConfig = {
      id: 'no-timeout',
      type: 'http',
      url: 'https://example.com',
      expectedStatus: 200,
    };

    const mockFetch = vi.mocked(fetch);
    mockFetch.mockResolvedValueOnce(new Response('OK', { status: 200 }));

    const result = await runHttpCheck(monitorNoTimeout, 'probe-1');

    expect(result.state).toBe('up');
  });
});
