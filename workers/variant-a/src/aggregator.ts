import { DurableObject } from 'cloudflare:workers';
import type { CheckResult } from '@deucalion/probe-core';
import { insertCheckResults, upsertMonitorStates } from './db.js';

interface MonitorState {
  state: string;
  latencyMs: number;
  lastChecked: string;
  statusCode: number;
}

interface Env {
  DB: D1Database;
}

/**
 * AggregationDO — Durable Object that manages in-memory monitor state
 * and persists check results to D1.
 */
export class AggregationDO extends DurableObject<Env> {
  private stateMap: Map<string, MonitorState> = new Map();

  /**
   * Ingest check results: write to D1 and update in-memory state.
   */
  async ingestResults(results: CheckResult[]): Promise<void> {
    // Write to D1
    await Promise.all([
      insertCheckResults(this.env.DB, results),
      upsertMonitorStates(this.env.DB, results),
    ]);

    // Update in-memory state map
    for (const r of results) {
      const key = `${r.monitorId}|${r.probeId}`;
      this.stateMap.set(key, {
        state: r.state,
        latencyMs: r.latencyMs,
        lastChecked: r.startedAt,
        statusCode: r.statusCode,
      });
    }
  }

  /**
   * Get current status for all monitors.
   */
  getStatus(): Record<string, { state: string; latencyMs: number; lastChecked: string; probes: Record<string, MonitorState> }> {
    const monitors: Record<string, { state: string; latencyMs: number; lastChecked: string; probes: Record<string, MonitorState> }> = {};

    for (const [key, value] of this.stateMap) {
      const [monitorId, probeId] = key.split('|');
      if (!monitors[monitorId]) {
        monitors[monitorId] = {
          state: value.state,
          latencyMs: value.latencyMs,
          lastChecked: value.lastChecked,
          probes: {},
        };
      }
      monitors[monitorId].probes[probeId] = value;
      // Overall state is 'down' if any probe reports 'down'
      if (value.state === 'down') {
        monitors[monitorId].state = 'down';
      }
    }

    return monitors;
  }
}
