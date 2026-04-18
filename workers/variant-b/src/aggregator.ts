import type { CheckResult } from '@deucalion/probe-core';

interface AnalyticsEngineDataset {
  writeDataPoint(event: {
    blobs?: string[];
    doubles?: number[];
    indexes?: string[];
  }): void;
}

/**
 * Write check results to WAE as data points.
 *
 * Blob layout:
 *   blob1 = monitorId
 *   blob2 = probeId
 *   blob3 = state ('up' | 'down')
 *   blob4 = placementObserved
 *   blob5 = errorMessage
 *
 * Double layout:
 *   double1 = latencyMs
 *   double2 = statusCode
 *
 * Index: monitorId (for efficient filtering)
 */
export function writeCheckResults(
  results: CheckResult[],
  dataset: AnalyticsEngineDataset,
): void {
  for (const r of results) {
    dataset.writeDataPoint({
      blobs: [
        r.monitorId,
        r.probeId,
        r.state,
        r.placementObserved ?? '',
        r.errorMessage ?? '',
      ],
      doubles: [r.latencyMs, r.statusCode],
      indexes: [r.monitorId],
    });
  }
}
