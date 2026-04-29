# Amplitude tool-map

Source: <https://amplitude.com/docs/amplitude-ai/amplitude-mcp> · Auth: OAuth 2.0 · Install: hosted at `mcp.amplitude.com/mcp` (US / EU regions).

Amplitude's MCP exposes 40+ tools. The query layer (`query_amplitude_data`) covers most analytical rows; named tools exist for cohorts, experiments, charts, and dashboards. The MCP also exposes session replay and notebook CRUD for write-side workflows.

## Canonical workflow rows

| # | Row | Invocation |
|---|---|---|
| 1 | Setup / event firing check | `query_amplitude_data` event-segmentation against the event name; pair with `get_event_details` for property metadata |
| 2 | Traffic overview | `query_amplitude_data` event-segmentation with `pageview` (or equivalent) and unique-user metrics |
| 3 | Time shape (hourly / daily) | `query_amplitude_data` with `interval: "day" \| "hour"` |
| 4 | Channel / referrer split | `query_amplitude_data` with `groupBy: "referrer" \| "utm_source"` |
| 5 | Geo / device / cohort splits | `query_amplitude_data` with `groupBy: "country" \| "device_type" \| "platform"`; cohort splits via `cohortId` |
| 6 | Period-over-period comparison | `query_amplitude_data` accepts two date ranges in one call (returns delta in payload) |
| 7 | Live / realtime | ✗ not exposed; Amplitude has no realtime tool surfaced through MCP |
| 8 | Funnel construction | `query_amplitude_data(type="funnel", events=[...], conversionWindow=...)` |
| 9 | Cohort definition + retention | `get_cohorts` lists saved cohorts; `create_cohort` defines new ones; retention is a query type: `query_amplitude_data(type="retention", startEvent=..., returnEvent=...)` |
| 10 | Revenue (last-touch) | ⚠ via `query_amplitude_data` aggregating revenue events; or `create_metric` for a saved revenue metric. Depends on revenue-event tracking convention |
| 11 | First-touch attribution | ⚠ Amplitude has attribution settings (first-touch, last-touch, custom) at the property level; switching requires platform configuration. Not a one-call MCP parameter |
| 12 | Path analysis | `query_amplitude_data(type="pathfinder", startEvent=...)` |
| 13 | Page / section engagement | Page-level: event-segmentation on `[Amplitude] Page Viewed` events grouped by page property. Section-level: ✗ not exposed |
| 14 | Instrumentation audit (declared vs observed) | ⚠ `get_event_taxonomy` + `get_event_details` enumerate the observed surface; diff against local `event-schema.yaml` client-side |
| 15 | Per-variant exposure (experiments) | `get_experiments` lists active experiments; experiment results are accessible via dedicated experiment tools |
| 16 | Per-variant conversion (experiments) | Same experiment tool returns per-variant conversion rates and exposure counts |
| 17 | User journey lookup | ⚠ `query_amplitude_data` filtered to `userId`/`amplitudeId` returns event stream; session replay tools cover the visual side |

## Limitations

- **Row 7 (live)**: no realtime tool through MCP.
- **Row 10 (revenue last-touch)**: no dedicated revenue tool; expressible via segmentation queries when revenue events are tracked.
- **Row 11 (first-touch attribution)**: configured at the project level in Amplitude's UI; not a per-query parameter. Switching attribution model affects all reports for the workspace.
- **Row 13 (section engagement)**: no section-views equivalent.
- **Row 14 (instrumentation audit)**: no one-call drift feed. Taxonomy + event details enumerate the observed schema; the diff is client-side.

## Notes

- Amplitude's experiment surface is genuinely first-class (one tool, exposure + conversion both accessible). This is rare and worth using when the project runs experiments through Amplitude.
- Cohort retention requires a saved cohort first; for ad-hoc retention, use `query_amplitude_data(type="retention")` with explicit start/return events.
- Session replay (when enabled) is a separate tool family; the user-journey row above prefers the event-stream query for breadth, with replays as a follow-up for visual confirmation.
