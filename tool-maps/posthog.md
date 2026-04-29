# PostHog tool-map

Source: <https://posthog.com/docs/model-context-protocol> · Auth: OAuth (region-aware US/EU) or API key bearer · Install: hosted at `mcp.posthog.com`, configurable via the PostHog Wizard.

PostHog ships MCP changes weekly. The invocations below reference PostHog concepts (Trends, Funnels, Retention, Paths, HogQL) rather than frozen tool names; the agent should resolve the current tool name from the MCP server's tool list at runtime. The vendor's docs are authoritative.

## Canonical workflow rows

| # | Row | Invocation |
|---|---|---|
| 1 | Setup / event firing check | List events for the project; or `query(HogQL)` `SELECT event, count() FROM events WHERE event = '<name>' GROUP BY event` |
| 2 | Traffic overview | Trends insight with `pageview` event + `dau`/`unique_session` aggregations; or HogQL aggregate |
| 3 | Time shape (hourly / daily) | Trends insight with `interval: "day" \| "hour"` |
| 4 | Channel / referrer split | Trends insight with `breakdown: "$referring_domain"` (or `$initial_utm_source` for first-touch flavour) |
| 5 | Geo / device / cohort splits | Trends insight with `breakdown: "$geoip_country_name" \| "$device_type" \| "$browser"`; cohort splits via `cohort` filter |
| 6 | Period-over-period comparison | Trends insight with `compare: true` (returns previous-period series alongside current) |
| 7 | Live / realtime | ⚠ no first-class realtime tool; closest path is `query(HogQL)` against the last few minutes of events |
| 8 | Funnel construction | Funnel insight: ordered list of event steps with conversion window |
| 9 | Cohort definition + retention | Cohort create (event-based or property-based) → Retention insight scoped to the cohort |
| 10 | Revenue (last-touch) | ⚠ depends on revenue tracking convention; `query(HogQL)` `SELECT sum(properties.$revenue), properties.$initial_referring_domain FROM events WHERE event = 'purchase' GROUP BY ...` |
| 11 | First-touch attribution | ⚠ HogQL `argMin(properties.$initial_referring_domain, timestamp)` per `distinct_id`, joined back to revenue events |
| 12 | Path analysis | Paths insight (start_point / end_point / events sequence) |
| 13 | Page / section engagement | Page-level: trends/HogQL on `$pageview` events grouped by `$pathname`. Section-level: ✗ not exposed (no equivalent of Clamp's section-views extension) |
| 14 | Instrumentation audit (declared vs observed) | ⚠ list event/property definitions via the MCP definitions tool, diff against the local `event-schema.yaml` client-side; PostHog has no single-call "observed schema" feed |
| 15 | Per-variant exposure (experiments) | Experiments tool returns variant + exposure data; or `query(HogQL)` against `$feature_flag_called` events grouped by `feature_flag_response` |
| 16 | Per-variant conversion (experiments) | Experiments tool's results endpoint returns per-variant conversion; or HogQL joining exposure to conversion event by `distinct_id` |
| 17 | User journey lookup | Session replays list filtered by `distinct_id`; or `query(HogQL)` `SELECT * FROM events WHERE distinct_id = '<id>' ORDER BY timestamp` |

## Limitations

- **Row 7 (live)**: no realtime aggregation tool; HogQL on a short timewindow is the closest substitute.
- **Row 10/11 (revenue + first-touch)**: PostHog doesn't ship a dedicated revenue tool. Achievable via HogQL but requires the project to be tracking a `$revenue` property on its conversion events.
- **Row 13 (section engagement)**: no section-views equivalent. Falls back to page-level engagement.
- **Row 14 (instrumentation audit)**: no single-call observed-schema diff. Two-call workaround: list definitions, diff against the YAML client-side.

## Notes

- Prefer Trends/Funnel/Retention/Paths insights over raw HogQL when the row is expressible that way; the insight tools return well-shaped output the agent can read directly.
- HogQL is the universal escape hatch when an insight type doesn't fit (e.g. revenue + first-touch). Treat it as SQL with PostHog-flavoured `properties.<key>` access.
- PostHog's MCP supports both US and EU regions; the agent should reuse whichever region the project's `.env` or workspace already points at.
