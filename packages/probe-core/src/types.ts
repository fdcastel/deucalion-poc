/** State of a single check */
export type CheckState = 'up' | 'down';

/** Configuration for a single monitor */
export interface MonitorConfig {
  /** Unique identifier for the monitor */
  id: string;
  /** Check type — only HTTP is supported in the POC */
  type: 'http';
  /** URL to check */
  url: string;
  /** Expected HTTP status code (e.g. 200) */
  expectedStatus: number;
  /** Timeout in milliseconds (default: 10000) */
  timeoutMs?: number;
}

/** Configuration for a single probe */
export interface ProbeConfig {
  /** Placement hint host for Cloudflare smart placement */
  placementHost: string;
}

/** Result of a single HTTP check */
export interface CheckResult {
  /** Monitor that was checked */
  monitorId: string;
  /** Probe that performed the check */
  probeId: string;
  /** ISO 8601 timestamp when the check started */
  startedAt: string;
  /** ISO 8601 timestamp when the check finished */
  finishedAt: string;
  /** Round-trip latency in milliseconds */
  latencyMs: number;
  /** Whether the target is up or down */
  state: CheckState;
  /** HTTP status code received (0 if connection failed) */
  statusCode: number;
  /** Error message if the check failed */
  errorMessage?: string;
  /** Error code for programmatic handling */
  errorCode?: string;
  /** Requested placement host */
  placementRequested?: string;
  /** Observed Cloudflare colo code */
  placementObserved?: string;
}

/** Hardcoded POC configuration */
export const POC_CONFIG = {
  probes: {
    'us-east': { placementHost: 'cloudflare.com:443' } as ProbeConfig,
  },
  monitors: [
    { id: 'cf-web', type: 'http' as const, url: 'https://cloudflare.com', expectedStatus: 200 },
    {
      id: 'cf-blog',
      type: 'http' as const,
      url: 'https://blog.cloudflare.com',
      expectedStatus: 200,
    },
  ] satisfies MonitorConfig[],
};
