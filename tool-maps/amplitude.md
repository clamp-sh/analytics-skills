# Amplitude tool-map

Source: <https://amplitude.com/docs/amplitude-ai/amplitude-mcp> · Auth: OAuth 2.0 · Install: hosted at `mcp.amplitude.com/mcp` (US / EU regions).

Amplitude's MCP exposes ~40 tools across discovery, retrieval, query, creation, editing, session replay, customer feedback, and agent analytics. The analytical workhorse is `query_amplitude_data` for ad-hoc segmentation/funnel/retention work; saved charts and dashboards are accessed via `query_chart` / `get_charts`. Experiments are first-class with `query_experiment` returning per-variant performance and statistical significance in one call.

## Canonical workflow rows

| # | Row | Invocation |
|---|---|---|
| 1 | Setup / event firing check | `query_amplitude_data` segmentation against the event name; `get_event_properties` for property metadata; `search` for event discovery |
| 2 | Traffic overview | `query_amplitude_data` segmentation with pageview event + unique-user metrics |
| 3 | Time shape (hourly / daily) | `query_amplitude_data` with daily/hourly interval |
| 4 | Channel / referrer split | `query_amplitude_data` with `groupBy` on a referrer or `utm_source` event property |
| 5 | Geo / device / cohort splits | `query_amplitude_data` with `groupBy` on country / device_type / platform; cohort splits via `cohortId` |
| 6 | Period-over-period comparison | ⚠ no documented two-range parameter on `query_amplitude_data`; comparison handled via two calls or via a saved chart's comparison config (`query_chart`) |
| 7 | Live / realtime | ✗ not exposed; Amplitude has no realtime tool surfaced through MCP |
| 8 | Funnel construction | `query_amplitude_data` (funnel analysis is one of the supported query modes alongside event segmentation and retention) |
| 9 | Cohort definition + retention | `get_cohorts` lists saved cohorts; `create_cohort` defines new ones; retention via `query_amplitude_data` |
| 10 | Revenue (last-touch) | ⚠ via `query_amplitude_data` aggregating revenue events; or `create_metric` for a saved revenue metric. Depends on revenue-event tracking convention |
| 11 | First-touch attribution | ⚠ Amplitude has attribution settings (first-touch, last-touch, custom) at the property level; switching requires platform configuration. Not a one-call MCP parameter |
| 12 | Path analysis | ⚠ no `pathfinder` query type documented for `query_amplitude_data`; path analysis flows through `query_chart` against a saved Pathfinder chart |
| 13 | Page / section engagement | ⚠ page-level via segmentation on `[Amplitude] Page Viewed`; section-level not exposed |
| 14 | Instrumentation audit (declared vs observed) | ⚠ `get_event_properties` + `search` enumerate the observed surface; diff against local `event-schema.yaml` client-side. No single-call drift feed |
| 15 | Per-variant exposure (experiments) | `get_experiments` lists experiments + metadata; `query_experiment` returns per-variant exposure |
| 16 | Per-variant conversion (experiments) | `query_experiment` ("variant performance and statistical significance") returns conversion + significance in one call |
| 17 | User journey lookup | `get_users` for user metadata; `list_session_replays` and `get_session_replay_events` for session-level reconstruction; `get_session_replays` for replay rendering |

## Limitations

- **Row 6 (period-over-period)**: `query_amplitude_data` has no documented dual-range parameter. Either issue two calls and diff client-side, or use `query_chart` against a saved chart that has comparison configured at chart level.
- **Row 7 (live)**: no realtime tool through MCP.
- **Row 10 (revenue last-touch)**: no dedicated revenue tool; expressible via segmentation queries when revenue events are tracked.
- **Row 11 (first-touch attribution)**: configured at the project level in Amplitude's UI; not a per-query parameter. Switching attribution model affects all reports for the workspace.
- **Row 12 (path analysis)**: not directly available through `query_amplitude_data`; requires a saved Pathfinder chart accessed via `query_chart`.
- **Row 13 (section engagement)**: no section-views equivalent.
- **Row 14 (instrumentation audit)**: no one-call drift feed. `get_event_properties` + `search` enumerate the observed schema; the diff is client-side.

## Notes

- `query_experiment` is unusually direct: one call returns variant performance, exposure, and statistical significance. Most other platforms require composing exposure and conversion events manually.
- Amplitude's MCP includes tool families outside the canonical taxonomy: customer feedback (`get_feedback_*`, 5 tools), agent analytics for LLM-app observability (`query_agent_analytics_*`, 6 tools), feature flag CRUD (`get_flags`, `create_flags`, `update_flag`, `get_deployments`), and `render_chart` (visual rendering). These don't fit the canonical workflow rows but are useful in adjacent flows.
- `get_from_url` is a unique discovery primitive: pass an Amplitude URL and it resolves to the underlying chart/dashboard/experiment object.
