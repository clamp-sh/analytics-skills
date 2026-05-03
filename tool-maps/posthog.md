# PostHog tool-map

Source: <https://posthog.com/docs/model-context-protocol> · Auth: OAuth (region-aware US/EU) or API key bearer · Install: hosted at `mcp.posthog.com`, configurable via the PostHog Wizard.

PostHog's MCP registers ~44 tools. The analytical workhorse is `query-run`, which accepts a typed Query object (`TrendsQuery`, `FunnelsQuery`, `PathsQuery`, `RetentionQuery`, `HogQLQuery`, etc.); there are no separate `query-trends` or `query-funnel` tools. Most named tools cover surrounding workflows (experiments, error tracking, feature flags, surveys, dashboards).

Tool-name source of truth: `schema/tool-definitions.json` in `github.com/PostHog/mcp`.

## Canonical workflow rows

| # | Row | Invocation |
|---|---|---|
| 1 | Setup / event firing check | `event-definitions-list` and `properties-list` for what's declared; `query-run` with a HogQLQuery for `SELECT count() FROM events WHERE event = '<name>'` |
| 2 | Traffic overview | `query-run` with TrendsQuery (`pageview` event, dau / unique-session aggregation) or HogQLQuery aggregate |
| 3 | Time shape (hourly / daily) | `query-run` with TrendsQuery (`interval: "day" \| "hour"`) |
| 4 | Channel / referrer split | `query-run` with TrendsQuery (`breakdownFilter` on `$referring_domain` or `$initial_utm_source`) |
| 5 | Geo / device / cohort splits | `query-run` with TrendsQuery (`breakdownFilter` on `$geoip_country_name`, `$device_type`, `$browser`); cohort splits via `properties` filter |
| 6 | Period-over-period comparison | `query-run` with TrendsQuery (`compareFilter: { compare: true }`) returns current + previous in a single response |
| 7 | Live / realtime | ⚠ no dedicated realtime tool; `query-run` with HogQLQuery on a short timewindow is the closest substitute |
| 8 | Funnel construction | `query-run` with FunnelsQuery (steps array, `funnelOrderType`, conversion window) |
| 9 | Cohort definition + retention | ⚠ no dedicated cohort or retention tools in the registered set. RetentionQuery exists as a typed Query but routing through `query-run` is the only path; cohort definitions are not creatable via MCP today |
| 10 | Revenue (last-touch) | ⚠ depends on `$revenue` tracking; `query-run` HogQLQuery on the events table grouped by referring domain |
| 11 | First-touch attribution | ⚠ HogQLQuery `argMin(properties.$initial_referring_domain, timestamp)` per `distinct_id`, joined back to revenue events |
| 12 | Path analysis | `query-run` with PathsQuery (start_point / end_point / events sequence) |
| 13 | Page / section engagement | ⚠ page-level via `query-run` HogQLQuery on `$pageview` events grouped by `$pathname`; section-level not exposed (no equivalent of Clamp's section-views extension) |
| 14 | Instrumentation audit (declared vs observed) | ⚠ `event-definitions-list` and `property-definitions` enumerate the observed schema; diff against the local `event-schema.yaml` client-side. PostHog has no single-call drift feed |
| 15 | Per-variant exposure (experiments) | `experiment-results-get` returns per-variant exposure and conversion in one call; `experiment-get-all` and `experiment-get` for metadata |
| 16 | Per-variant conversion (experiments) | `experiment-results-get` (same tool; returns variant performance, exposure, and conversion together) |
| 17 | User journey lookup | ✗ no session-recording or per-user journey tool in the registered set today. `query-run` HogQLQuery `SELECT * FROM events WHERE distinct_id = '<id>' ORDER BY timestamp` is the closest approximation; replays are not MCP-accessible |

## Limitations

- **Row 7 (live)**: no realtime aggregation tool; HogQL on a short timewindow is the closest substitute.
- **Row 9 (cohort + retention)**: RetentionQuery exists as a typed Query routed through `query-run`, but there are no cohort CRUD tools and no dedicated retention tool. For non-trivial cohort logic, use HogQL or define cohorts in the PostHog UI first.
- **Row 10/11 (revenue + first-touch)**: PostHog doesn't ship a dedicated revenue or attribution tool. Achievable via HogQL but requires the project to track a `$revenue` property on its conversion events.
- **Row 13 (section engagement)**: no section-views equivalent. Falls back to page-level engagement.
- **Row 14 (instrumentation audit)**: no single-call observed-schema diff. Two-call workaround: list definitions, diff against the YAML client-side.
- **Row 17 (user journey)**: no session-recording MCP tool today. The session replay product exists; it just isn't exposed through MCP.

## Notes

- `query-run` is the single analytical entry point. To use it, pass a Query object whose shape depends on the analysis type (TrendsQuery, FunnelsQuery, PathsQuery, RetentionQuery, HogQLQuery). The MCP doesn't ship `query-trends` / `query-funnel` / `query-retention` as separate tools.
- Beyond analytics: PostHog's MCP exposes `list-errors` / `error-details` (error tracking), `feature-flag-*` (5 tools for flags), `survey-*` (6+ tools for surveys), `dashboard-*` (CRUD), `docs-search` (Inkeep-backed), and `get-llm-total-costs-for-project` (LLM analytics). These don't fit the canonical workflow rows but are useful in adjacent flows.
- PostHog's MCP supports both US and EU regions; reuse whichever region the project's `.env` or workspace already points at.
