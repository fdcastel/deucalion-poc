import type { CheckResult } from '@deucalion/probe-core';

/**
 * Insert check results into D1 check_results table.
 */
export async function insertCheckResults(db: D1Database, results: CheckResult[]): Promise<void> {
  const stmt = db.prepare(
    `INSERT INTO check_results
      (monitor_id, probe_id, started_at, finished_at, latency_ms, state, status_code, error_message, error_code, placement_requested, placement_observed)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  );

  const batch = results.map((r) =>
    stmt.bind(
      r.monitorId,
      r.probeId,
      r.startedAt,
      r.finishedAt,
      r.latencyMs,
      r.state,
      r.statusCode,
      r.errorMessage ?? null,
      r.errorCode ?? null,
      r.placementRequested ?? null,
      r.placementObserved ?? null,
    ),
  );

  await db.batch(batch);
}

/**
 * Upsert current state for each monitor+probe pair.
 */
export async function upsertMonitorStates(db: D1Database, results: CheckResult[]): Promise<void> {
  const stmt = db.prepare(
    `INSERT INTO monitor_states_current (monitor_id, probe_id, state, last_checked_at, latency_ms, status_code)
     VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT (monitor_id, probe_id) DO UPDATE SET
       state = excluded.state,
       last_checked_at = excluded.last_checked_at,
       latency_ms = excluded.latency_ms,
       status_code = excluded.status_code`,
  );

  const batch = results.map((r) =>
    stmt.bind(r.monitorId, r.probeId, r.state, r.startedAt, r.latencyMs, r.statusCode),
  );

  await db.batch(batch);
}

/** Row from monitor_states_current table */
export interface MonitorStateRow {
  monitor_id: string;
  probe_id: string;
  state: string;
  last_checked_at: string;
  latency_ms: number;
  status_code: number;
}

/**
 * Get current state for all monitors from D1.
 */
export async function getCurrentStates(db: D1Database): Promise<MonitorStateRow[]> {
  const result = await db
    .prepare('SELECT * FROM monitor_states_current ORDER BY monitor_id, probe_id')
    .all<MonitorStateRow>();
  return result.results;
}

/** Row from check_results table */
export interface CheckResultRow {
  id: number;
  monitor_id: string;
  probe_id: string;
  started_at: string;
  finished_at: string;
  latency_ms: number;
  state: string;
  status_code: number;
  error_message: string | null;
  error_code: string | null;
  placement_requested: string | null;
  placement_observed: string | null;
  created_at: string;
}

/**
 * Get check results for a specific monitor in the last 24 hours.
 */
export async function getHistory(db: D1Database, monitorId: string): Promise<CheckResultRow[]> {
  const result = await db
    .prepare(
      `SELECT * FROM check_results
       WHERE monitor_id = ? AND started_at >= datetime('now', '-1 day')
       ORDER BY started_at DESC
       LIMIT 500`,
    )
    .bind(monitorId)
    .all<CheckResultRow>();
  return result.results;
}

/** Probe info row */
export interface ProbeInfoRow {
  probe_id: string;
  placement_observed: string | null;
  last_seen: string;
}

/**
 * Get the most recent placement metadata per probe.
 */
export async function getProbeInfo(db: D1Database): Promise<ProbeInfoRow[]> {
  const result = await db
    .prepare(
      `SELECT probe_id, placement_observed, MAX(started_at) AS last_seen
       FROM check_results
       GROUP BY probe_id
       ORDER BY probe_id`,
    )
    .all<ProbeInfoRow>();
  return result.results;
}
