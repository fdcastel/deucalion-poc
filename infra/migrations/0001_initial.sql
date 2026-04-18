-- Deucalion V4 POC — Variant A D1 Schema

CREATE TABLE IF NOT EXISTS check_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  monitor_id TEXT NOT NULL,
  probe_id TEXT NOT NULL,
  started_at TEXT NOT NULL,
  finished_at TEXT NOT NULL,
  latency_ms REAL NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('up', 'down')),
  status_code INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  error_code TEXT,
  placement_requested TEXT,
  placement_observed TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_check_results_monitor_started
  ON check_results (monitor_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_check_results_probe
  ON check_results (probe_id, started_at DESC);

CREATE TABLE IF NOT EXISTS monitor_states_current (
  monitor_id TEXT NOT NULL,
  probe_id TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('up', 'down')),
  last_checked_at TEXT NOT NULL,
  latency_ms REAL NOT NULL,
  status_code INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (monitor_id, probe_id)
);
