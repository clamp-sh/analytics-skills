# Mixpanel tool-map

Source: <https://docs.mixpanel.com/docs/mcp> · Auth: OAuth 2.0 + PKCE · Install: hosted at the regional Mixpanel MCP endpoint (US / EU / IN).

Mixpanel's MCP exposes ~18 tools. The query layer (`Run-Query`) is the workhorse: most analytical workflows are a query type (insights, funnels, flows, retention) plus a payload. The schema and metadata tools (`Get-Query-Schema`, `Get-Event-Details`, `Get-Property-Names/Values`) are needed before composing a query against an unfamiliar project.

## Canonical workflow rows

| # | Row | Invocation |
|---|---|---|
| 1 | Setup / event firing check | `Get-Events(name="<event>")` for sample rows; pair with `Get-Property-Names(event=<event>)` to list the property surface |
| 2 | Traffic overview | ⚠ no dedicated overview tool; `Run-Query(type="insights", events=["$pageview"], aggregation="unique")` is the closest one-call answer |
| 3 | Time shape (hourly / daily) | `Run-Query(type="insights", interval="hour" \| "day")` |
| 4 | Channel / referrer split | `Run-Query(type="insights", breakdown="initial_referring_domain")` (or `utm_source` for campaign-driven splits) |
| 5 | Geo / device / cohort splits | `Run-Query(type="insights", breakdown="$country_code" \| "$device" \| "$browser")`; cohort splits via segment filter |
| 6 | Period-over-period comparison | `Run-Query(type="insights")` with two date ranges, or two queries, then diff |
| 7 | Live / realtime | ✗ not exposed; Mixpanel has no realtime endpoint surfaced through MCP |
| 8 | Funnel construction | `Run-Query(type="funnels", steps=[...], conversion_window="7d")` |
| 9 | Cohort definition + retention | Define a cohort in the Mixpanel UI (saved cohort) → `Run-Query(type="retention", cohort=...)`; or `Run-Query(type="retention", born_event=..., return_event=...)` |
| 10 | Revenue (last-touch) | ⚠ `Run-Query(type="insights", aggregation="sum", property="$amount", breakdown="initial_referring_domain")` if revenue is tracked on a property |
| 11 | First-touch attribution | ⚠ via JQL or two-step query; not first-class |
| 12 | Path analysis | `Run-Query(type="flows", from_event=..., to_event=...)` |
| 13 | Page / section engagement | Page-level: `Run-Query(type="insights", events=["$mp_page_view"], breakdown="page")`. Section-level: ✗ not exposed |
| 14 | Instrumentation audit (declared vs observed) | ⚠ `Get-Events` + `Get-Property-Names` enumerate the observed surface; diff against local `event-schema.yaml` client-side |
| 15 | Per-variant exposure (experiments) | ⚠ Mixpanel has no native experiment tool; experiments must be tracked as events. `Run-Query(type="insights", events=["$experiment_started"], breakdown="variant")` |
| 16 | Per-variant conversion (experiments) | ⚠ same shape: `Run-Query(type="insights", events=["<conversion>"], filter="variant=<v>")` per variant |
| 17 | User journey lookup | ⚠ `Run-Query` filtered to a `distinct_id` returns the user's events in a project; or `Get-User-Replays-Data` if session replay is enabled |

## Limitations

- **Row 7 (live)**: no realtime path through MCP. Live monitoring is a UI-only feature.
- **Row 11 (first-touch attribution)**: requires JQL or multi-step composition. Mixpanel's attribution model is implicit in the property names tracked.
- **Row 13 (section engagement)**: no section-views extension equivalent.
- **Row 14 (instrumentation audit)**: no one-call drift feed. The lexicon is browseable but the diff is client-side.
- **Row 15-16 (experiments)**: no native experiment surface; relies on the project tracking exposure and conversion as standard events with a `variant` property.

## Notes

- The query type taxonomy (`insights`, `funnels`, `flows`, `retention`) maps roughly 1:1 onto rows 2-9. When in doubt, `Get-Query-Schema` returns the parameter surface for each type.
- Mixpanel charges per query; agents should batch where possible and avoid speculative drilldowns.
- Region selection (US / EU / IN) is project-bound; the MCP enforces it.
