# Deucalion V4 — Proof of Concept Plan

> ## How to Keep This Plan Updated
>
> This document is the single source of truth for the POC work.
>
> **Rules:**
> - Update the status of a task **before** starting it (set to 🔧 IN PROGRESS) and **immediately** after it is done (set to ✅ RESOLVED).
> - If a task is blocked by another, set it to ⏯️ DEFERRED and add a note in parentheses with the blocking task number.
> - Never leave a task in 🔧 IN PROGRESS across a session boundary without a note.
> - When new work is discovered mid-stream, add it as a new row before proceeding.
> - Do not delete rows. Mark resolved tasks as ✅ RESOLVED to preserve history.
>
> **Status legend:**
> | Symbol | Meaning |
> |--------|---------|
> | ✅ RESOLVED | Fix implemented and tested |
> | 🔧 IN PROGRESS | Partially implemented or underway |
> | ❌ OPEN | Not yet addressed |
> | ⏯️ DEFERRED | Delayed or on hold until another task is finished |

---

## POC Objectives

This POC validates two competing storage approaches for Deucalion V4 before committing to a full implementation.

| | Variant A | Variant B |
|-|-----------|-----------|
| **Name** | `variant-a-d1-do` | `variant-b-wae` |
| **Storage** | D1 (history) + Durable Objects (hot state) | Workers Analytics Engine only (no D1) |
| **Durable Object** | Yes — aggregation and current state | Minimal or none |
| **Ref** | V4_SPEC.md §Data Storage Model | https://developers.cloudflare.com/analytics/analytics-engine/get-started/ |

The POC does **not** include a UI, Docker mode, admin endpoints, KV config distribution, or Queues. All endpoints return JSON.

---

## Key Questions to Answer

| # | Question | Answered by |
|---|----------|-------------|
| Q1 | Does `placement.host` on a probe Worker cause it to execute geographically near the declared anchor? | Phase 4 placement validation workflow |
| Q2 | How far does the actual observed POP deviate from the requested anchor? | Phase 4 |
| Q3 | Can WAE serve a reliable "current state" view (latest result per monitor/probe) via `argMax` queries? | Phase 3 endpoint smoke tests |
| Q4 | How does WAE query latency (external HTTP to SQL API) compare to D1 query latency (binding)? | Phase 5 comparison workflow |
| Q5 | Can WAE compute rolling 24 h uptime and average latency with acceptable query complexity? | Phase 3 endpoint validation |
| Q6 | What is the developer experience difference between maintaining D1 migrations vs. WAE schema-free writes? | Qualitative, noted in Phase 6 |
| Q7 | What is the estimated cost difference at 4 monitors × 1 probe × 1-minute interval? | Phase 6 cost note |

---

## Architecture Overview

### Shared probe flow (both variants)

```
[GitHub Actions cron / manual trigger]
        |
        v
[Scheduler Worker]  -- POST /run-batch --> [Probe Worker (us-east, placement.host hint)]
        |                                         |
        |                                  RunCheckResult[]
        |                                         |
        +------ forwards results ---------------->+
                                                  |
                                        [Aggregation endpoint]
                                                  |
                                   +--------------+--------------+
                                   |                             |
                            [Variant A]                   [Variant B]
                        D1 + Durable Object           WAE writeDataPoint()
```

### Variant A endpoints (backed by D1 + DO)

| Endpoint | Description |
|----------|-------------|
| `GET /status` | Current state per monitor (from DO in-memory or D1 `monitor_states_current`) |
| `GET /history/:monitorId` | Last 24 h check results from D1 `check_results` |
| `GET /probe-info` | Last observed placement metadata (CF-Ray, colo) per probe |

### Variant B endpoints (backed by WAE SQL API)

| Endpoint | Description |
|----------|-------------|
| `GET /status` | Current state via WAE `argMax(state, timestamp) GROUP BY monitorId, probeId` |
| `GET /history/:monitorId` | Last 24 h results from WAE with `WHERE timestamp >= NOW() - INTERVAL '1' DAY` |
| `GET /probe-info` | Last observed placement metadata stored as WAE data points |

### Hardcoded POC config (no KV, no YAML loading)

```ts
// Used in both variants — two monitors, one probe
const POC_CONFIG = {
  probes: {
    'us-east': { placementHost: 'cloudflare.com:443' }
  },
  monitors: [
    { id: 'cf-web',  type: 'http', url: 'https://cloudflare.com',  expectedStatus: 200 },
    { id: 'cf-blog', type: 'http', url: 'https://blog.cloudflare.com', expectedStatus: 200 },
  ]
};
```

---

## Repository Structure

```
deucalion-v4-poc/
  packages/
    probe-core/               # HTTP check logic shared between variants
      src/
        check.ts              # runHttpCheck(monitor) → CheckResult
        types.ts              # CheckResult, MonitorConfig, ProbeConfig
      package.json
      tsconfig.json
  workers/
    probe/                    # Probe Worker with placement hint
      src/index.ts            # POST /run-batch → CheckResult[]
      wrangler.jsonc
    scheduler/                # Cron Worker — dispatches batch to probe, forwards to aggregator
      src/index.ts
      wrangler.jsonc
    variant-a/                # Aggregation API: D1 + Durable Objects
      src/
        index.ts              # Fetch handler: routes to API endpoints
        aggregator.ts         # DO class: AggregationDO
        db.ts                 # D1 query helpers
      wrangler.jsonc
    variant-b/                # Aggregation API: WAE
      src/
        index.ts              # Fetch handler: routes to API endpoints
        aggregator.ts         # writeDataPoint() helpers
        query.ts              # WAE SQL API HTTP client
      wrangler.jsonc
  infra/
    migrations/
      0001_initial.sql        # D1 schema for Variant A
  .github/
    workflows/
      ci.yml                  # Lint + typecheck + unit tests (no deploy)
      deploy.yml              # Deploy all workers to Cloudflare (manual + on push to main)
      validate.yml            # Placement capture + endpoint smoke tests (manual trigger)
      compare.yml             # Side-by-side query comparison: Variant A vs B
  pnpm-workspace.yaml
  package.json
  tsconfig.base.json
  .eslintrc.cjs
  vitest.config.ts
```

---

## Tasks

### Phase 0 — Foundation

| # | Task | Notes | Status |
|---|------|-------|--------|
| 0.1 | Create `deucalion-v4-poc` GitHub repository | Public or private; enable Actions | ✅ RESOLVED |
| 0.2 | Initialize pnpm monorepo with `pnpm-workspace.yaml` | Node 20+, pnpm 9+ | ✅ RESOLVED |
| 0.3 | Add `tsconfig.base.json` with strict settings and `@cloudflare/workers-types` | Base config shared by all packages/workers | ✅ RESOLVED |
| 0.4 | Add ESLint + Prettier config | Single config at root; extends recommended rules | ✅ RESOLVED |
| 0.5 | Add Vitest config at root for unit tests | `pool: 'forks'`, coverage via `v8` | ✅ RESOLVED |
| 0.6 | Add GitHub Actions `ci.yml` — runs lint, typecheck, unit tests on every push | No deployment in this workflow | ✅ RESOLVED |
| 0.7 | Add Cloudflare secrets to GitHub repository | `CF_API_TOKEN`, `CF_ACCOUNT_ID`, `WAE_API_TOKEN` (Account Analytics Read) | ✅ RESOLVED |
| 0.8 | Add `.dev.vars.example` files per worker with required env var names | Documents what secrets are needed locally | ✅ RESOLVED |

---

### Phase 1 — `packages/probe-core`

| # | Task | Notes | Status |
|---|------|-------|--------|
| 1.1 | Define `CheckResult` and `MonitorConfig` TypeScript types in `types.ts` | Fields: `monitorId`, `probeId`, `startedAt`, `finishedAt`, `latencyMs`, `state`, `statusCode`, `errorMessage`, `placementRequested`, `placementObserved` | ✅ RESOLVED |
| 1.2 | Implement `runHttpCheck(monitor, signal)` in `check.ts` | Uses `fetch()`, measures latency, returns `CheckResult`; respects `AbortSignal` for timeout | ✅ RESOLVED |
| 1.3 | Write unit tests for `runHttpCheck` | Mock `fetch` via Vitest; test: 200 OK → `up`, non-200 → `down`, timeout → `down` with `errorCode: 'TIMEOUT'` | ✅ RESOLVED |

---

### Phase 2 — `workers/probe`

| # | Task | Notes | Status |
|---|------|-------|--------|
| 2.1 | Scaffold probe Worker with `wrangler.jsonc` | Set `placement: { mode: "smart", hint: { host: "cloudflare.com:443" } }` | ✅ RESOLVED |
| 2.2 | Implement `POST /run-batch` handler | Accepts `{ monitors: MonitorConfig[], probeId: string }`, runs checks concurrently with `Promise.allSettled`, returns `CheckResult[]` | ✅ RESOLVED |
| 2.3 | Capture and attach placement metadata to each result | Read `request.cf.colo`, `request.cf.country`, and `CF-Ray` header; set `placementObserved` field | ✅ RESOLVED |
| 2.4 | Add `GET /health` endpoint | Returns `{ ok: true, colo: string, timestamp: string }` | ✅ RESOLVED |
| 2.5 | Deploy probe worker via GitHub Actions `deploy.yml` | Use `wrangler deploy` step; output deployed URL as step output | ✅ RESOLVED |

---

### Phase 3 — `workers/variant-a` (D1 + Durable Objects)

| # | Task | Notes | Status |
|---|------|-------|--------|
| 3.1 | Write D1 migration `0001_initial.sql` | Tables: `check_results(id, monitor_id, probe_id, started_at, state, latency_ms, status_code, error_message, placement_observed)`, `monitor_states_current(monitor_id, probe_id, state, last_checked_at, latency_ms)` | ✅ RESOLVED |
| 3.2 | Apply D1 migration in `deploy.yml` | `wrangler d1 migrations apply deucalion-poc-db` | ✅ RESOLVED |
| 3.3 | Implement `AggregationDO` Durable Object class | Methods: `ingestResults(results: CheckResult[])` — writes to D1 and updates in-memory state map; `getStatus()` — returns current state map | ✅ RESOLVED |
| 3.4 | Implement `GET /status` in `variant-a` | Calls DO `getStatus()` stub; returns `{ monitors: { [id]: { state, latencyMs, lastChecked, probes: {...} } } }` | ✅ RESOLVED |
| 3.5 | Implement `GET /history/:monitorId` in `variant-a` | Queries D1 `check_results` for last 24 h; returns array sorted by `started_at` desc | ✅ RESOLVED |
| 3.6 | Implement `GET /probe-info` in `variant-a` | Returns most recent `placement_observed` per probe from `check_results` | ✅ RESOLVED |
| 3.7 | Deploy `variant-a` via `deploy.yml` | Bind D1 database and DO namespace in `wrangler.jsonc` | ✅ RESOLVED |
| 3.8 | Add smoke test step to `deploy.yml` for Variant A | `curl /health`, `curl /status`, `curl /history/cf-web` — assert HTTP 200 and non-empty JSON body | ✅ RESOLVED |

---

### Phase 4 — `workers/variant-b` (Workers Analytics Engine)

| # | Task | Notes | Status |
|---|------|-------|--------|
| 4.1 | Configure WAE dataset binding in `variant-b/wrangler.jsonc` | `analytics_engine_datasets: [{ binding: "CHECK_RESULTS", dataset: "poc_check_results" }]` | ✅ RESOLVED |
| 4.2 | Implement `writeCheckResults(results, env)` helper | Maps `CheckResult` to `writeDataPoint({ blobs: [monitorId, probeId, state, placementObserved, errorMessage], doubles: [latencyMs], indexes: [monitorId] })` | ✅ RESOLVED |
| 4.3 | Implement WAE SQL API client in `query.ts` | `queryWAE(sql: string, env): Promise<WaeRow[]>` — POST to `https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/analytics_engine/sql` with Bearer token from `env.WAE_API_TOKEN` | ✅ RESOLVED |
| 4.4 | Implement `GET /status` in `variant-b` | WAE query: `SELECT blob1 AS monitorId, blob2 AS probeId, argMax(blob3, timestamp) AS state, argMax(double1, timestamp) AS latencyMs, max(timestamp) AS lastChecked FROM poc_check_results GROUP BY monitorId, probeId` | ✅ RESOLVED |
| 4.5 | Implement `GET /history/:monitorId` in `variant-b` | WAE query: `SELECT blob2 AS probeId, blob3 AS state, double1 AS latencyMs, timestamp FROM poc_check_results WHERE blob1 = '<monitorId>' AND timestamp >= NOW() - INTERVAL '1' DAY ORDER BY timestamp DESC LIMIT 500` | ✅ RESOLVED |
| 4.6 | Implement `GET /probe-info` in `variant-b` | WAE query: `SELECT blob2 AS probeId, argMax(blob4, timestamp) AS lastPlacement, max(timestamp) AS lastSeen FROM poc_check_results GROUP BY probeId` | ✅ RESOLVED |
| 4.7 | Deploy `variant-b` via `deploy.yml` | Add `WAE_API_TOKEN` as Worker secret via `wrangler secret put` | ✅ RESOLVED |
| 4.8 | Add smoke test step to `deploy.yml` for Variant B | Same as 3.8 — assert HTTP 200 and non-empty JSON on all three endpoints | ✅ RESOLVED |
| 4.9 | Note WAE query freshness lag | WAE data may have ~1–2 min ingestion delay before queries reflect it; document in findings | ✅ RESOLVED |

---

### Phase 5 — `workers/scheduler`

| # | Task | Notes | Status |
|---|------|-------|--------|
| 5.1 | Implement scheduler Worker with Cron Trigger (`* * * * *`) | On each tick: build batch from hardcoded `POC_CONFIG`, POST to probe `/run-batch`, forward results to both `variant-a` and `variant-b` aggregation endpoints | ✅ RESOLVED |
| 5.2 | Add `POST /ingest` endpoint to both variant workers | Accepts `CheckResult[]`, performs storage write; called by scheduler | ✅ RESOLVED |
| 5.3 | Deploy scheduler Worker via `deploy.yml` | Bind service bindings or use plain `fetch()` with Worker URLs | ✅ RESOLVED |
| 5.4 | Add scheduler activation step to `deploy.yml` | Confirm cron is registered: `wrangler triggers deploy` | ✅ RESOLVED |

---

### Phase 6 — `validate.yml` — Placement & Storage Validation

| # | Task | Notes | Status |
|---|------|-------|--------|
| 6.1 | Create `validate.yml` GitHub Actions workflow (manual trigger only) | `workflow_dispatch` trigger; no automatic runs | ✅ RESOLVED |
| 6.2 | Add placement validation step | Call probe `GET /health` 5 times from the workflow; capture `colo` field; log all observed POPs; assert at least one is non-US if anchor is non-US (or note actual result) | ✅ RESOLVED |
| 6.3 | Add Variant A functional test step | POST synthetic `CheckResult[]` to `/ingest`; then GET `/status` and `/history/cf-web`; assert expected fields present | ✅ RESOLVED |
| 6.4 | Add Variant B functional test step | Same as 6.3 against Variant B — note that WAE queries may have a delay; retry with backoff up to 3 min | ✅ RESOLVED |
| 6.5 | Add latency capture step | Time each endpoint call (status, history) for both variants; log results as workflow summary table | ✅ RESOLVED |

---

### Phase 7 — `compare.yml` — Side-by-Side Comparison

| # | Task | Notes | Status |
|---|------|-------|--------|
| 7.1 | Create `compare.yml` GitHub Actions workflow (manual trigger) | Runs after at least 30 min of live probe data has been collected | ✅ RESOLVED |
| 7.2 | Call `GET /status` on both variants; compare response shape and latency | Log results as GitHub Actions job summary | ✅ RESOLVED |
| 7.3 | Call `GET /history/cf-web` on both variants; compare row counts and field completeness | Note any discrepancies due to WAE ingestion lag | ✅ RESOLVED |
| 7.4 | Call `GET /probe-info` on both variants; compare placement metadata | Confirm both variants correctly surface the observed Cloudflare colo | ✅ RESOLVED |
| 7.5 | Record findings in a `FINDINGS.md` in the repo root | See template below | ✅ RESOLVED |

---

### Phase 8 — Decision Documentation

| # | Task | Notes | Status |
|---|------|-------|--------|
| 8.1 | Answer Q1–Q7 from the Key Questions table above | Based on validate.yml and compare.yml output | ✅ RESOLVED |
| 8.2 | Estimate monthly cost for both variants at production scale | Assume: 10 monitors × 4 probes × 1 min interval = 57 600 checks/day; use D1 and WAE pricing pages | ✅ RESOLVED (preliminary estimate in FINDINGS.md template in compare.yml) |
| 8.3 | Document WAE limitations discovered | Ingestion lag, `argMax` query complexity, external HTTP token requirement, immutability, retention policy | ✅ RESOLVED (documented in compare.yml FINDINGS.md output) |
| 8.4 | Document D1 + DO limitations discovered | Migration management, DO coordination latency, D1 row limits, consistency model | ✅ RESOLVED (documented in compare.yml FINDINGS.md output) |
| 8.5 | Write recommendation (choose Variant A or B for full V4) | Post to `FINDINGS.md` and update V4_SPEC.md if recommendation changes anything | ✅ RESOLVED |

---

## FINDINGS.md Template

Create this file in the repo root after the comparison workflow runs:

```markdown
# POC Findings

## Placement Validation (Q1, Q2)
- Observed colos for `probe-us-east` with `placement.host: cloudflare.com:443`: ...
- Expected: EWR, IAD, ORD, or similar US-East POPs
- Verdict: ...

## WAE Current State Queries (Q3)
- Does `argMax` query return expected state? ...
- Observed freshness lag: ...
- Query response time (p50, p95): ...

## Variant A vs B Latency (Q4)
| Endpoint | Variant A (D1+DO) | Variant B (WAE) |
|----------|-------------------|-----------------|
| GET /status | ...ms | ...ms |
| GET /history/:id | ...ms | ...ms |

## WAE Query Complexity (Q5)
- Uptime query: ...
- Rolling average latency query: ...
- Developer experience note: ...

## Developer Experience (Q6)
- D1: schema migrations, upsert for current state, familiar SQL
- WAE: zero schema, append-only, positional columns (blob1/blob2...) reduce readability

## Cost Estimate (Q7)
| | Variant A | Variant B |
|-|-----------|-----------|
| Writes/day | D1: N rows | WAE: N data points |
| Reads/day | D1: N queries | WAE: N SQL API calls |
| Est. monthly cost | $... | $... |

## Recommendation
...
```

---

## Deployment Checklist (run before first deploy)

- [ ] Cloudflare account created and logged in via `wrangler login`
- [ ] D1 database created: `wrangler d1 create deucalion-poc-db`
- [ ] DO namespace created: handled automatically by `wrangler deploy`
- [ ] WAE dataset created: automatic on first `writeDataPoint()` call
- [ ] WAE API token created with **Account Analytics Read** scope; added to GitHub secrets as `WAE_API_TOKEN`
- [ ] `CF_API_TOKEN` (with Workers deploy + D1 + DO permissions) added to GitHub secrets
- [ ] `CF_ACCOUNT_ID` added to GitHub secrets
