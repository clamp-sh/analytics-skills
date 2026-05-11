# Mixpanel tool-map

Source: <https://docs.mixpanel.com/docs/mcp> · Auth: OAuth 2.0 + PKCE · Install: hosted at the regional Mixpanel MCP endpoint (US / EU / IN).

Mixpanel's MCP registers 22 tools across 5 groups: Analytics (3), Dashboards (6), Data Discovery (7), Data Management (6), Session Replays (1). The analytical workhorse is `Run-Query`, whose `type` is exactly one of `insights`, `funnels`, `flows`, `retention`. JQL is **not** exposed via MCP.

## Canonical workflow rows

| # | Row | Invocation |
|---|---|---|
| 1 | Setup / event firing check | `Get-Events(name="<event>")` for sample rows; `Get-Event-Details` for full metadata; `Get-Property-Names(event=<event>)` to list the property surface |
| 2 | Traffic overview | ⚠ no dedicated overview tool; `Run-Query(type="insights", events=["$pageview"], aggregation="unique")` is the closest one-call answer |
| 3 | Time shape (hourly / daily) | `Run-Query(type="insights", interval="hour" \| "day")` |
| 4 | Channel / referrer split | `Run-Query(type="insights", breakdown="initial_referring_domain")` (or `utm_source` for campaign-driven splits) |
| 5 | Geo / device / cohort splits | `Run-Query(type="insights", breakdown="$country_code" \| "$device" \| "$browser")` |
| 6 | Period-over-period comparison | ⚠ requires two `Run-Query` calls; the MCP does not document a built-in dual-range parameter (the UI's "Compare to past" is not exposed as an MCP arg) |
| 7 | Live / realtime | ✗ not exposed; Mixpanel has no realtime endpoint surfaced through MCP |
| 8 | Funnel construction | `Run-Query(type="funnels", steps=[...], conversion_window="7d")` |
| 9 | Cohort definition + retention | ⚠ retention queries via `Run-Query(type="retention")` work, but cohort *creation* is not in the MCP. Cohorts must be pre-saved in the Mixpanel UI before the agent can scope retention to them |
| 10 | Revenue (last-touch) | ⚠ `Run-Query(type="insights", aggregation="sum", property="$amount", breakdown="initial_referring_domain")` if revenue is tracked on a property |
| 11 | First-touch attribution | ✗ JQL is not exposed via MCP, so the only path is `Run-Query` insights breakdown on `initial_*` properties; no first-class attribution flow |
| 12 | Path analysis | `Run-Query(type="flows", from_event=..., to_event=...)` |
| 13 | Page / section engagement | ⚠ page-level via `Run-Query(type="insights", events=["$mp_page_view"], breakdown="page")`; section-level not exposed |
| 14 | Instrumentation audit (declared vs observed) | `Get-Issues` is a first-class data-quality tool ("Get data quality issues filtered by event, property, type, or date") with `Dismiss-Issues` for resolution. Pair with `Get-Events` / `Get-Event-Details` / `Get-Property-Names` for the observed surface |
| 15 | Per-variant exposure (experiments) | ⚠ Mixpanel has no native experiment tool; experiments must be tracked as standard events. `Run-Query(type="insights", events=["$experiment_started"], breakdown="variant")` |
| 16 | Per-variant conversion (experiments) | ⚠ same shape: `Run-Query(type="insights", events=["<conversion>"], filter="variant=<v>")` per variant, or a `funnels` query with the variant filter |
| 17 | User journey lookup | `Get-User-Replays-Data` is a dedicated tool ("Analyze a specific user's replays alongside their event data"); pair with `Run-Query` filtered to the user's `distinct_id` for full event reconstruction |

## Limitations

- **Row 6 (period-over-period)**: no documented single-call dual-range parameter. The UI's "Compare to past" feature isn't surfaced through MCP. Two queries + client-side delta.
- **Row 7 (live)**: no realtime path through MCP. Live monitoring is a UI-only feature.
- **Row 9 (cohort + retention)**: cohort CRUD is not in the MCP surface. Cohorts must be pre-saved in the Mixpanel UI; the agent can only query retention against existing cohorts.
- **Row 11 (first-touch attribution)**: JQL is not exposed via MCP. Only achievable via `initial_*` property breakdowns in insights queries; that's not a real attribution flow, just a partial workaround.
- **Row 13 (section engagement)**: no section-views extension equivalent.
- **Row 15-16 (experiments)**: no native experiment tool; relies on the project tracking exposure and conversion as standard events with a `variant` property.

## Notes

- `Run-Query` accepts exactly four `type` values: `insights`, `funnels`, `flows`, `retention`. No `segmentation`, no `jql`, no `realtime`. When in doubt, `Get-Query-Schema` returns the parameter surface for each type.
- Mixpanel charges per query; agents should batch where possible and avoid speculative drilldowns.
- Region selection (US / EU / IN) is project-bound; the MCP enforces it.
- Beyond analytics: dashboards CRUD (6 tools: `Create-Dashboard`, `List-Dashboards`, `Get-Dashboard`, `Update-Dashboard`, `Duplicate-Dashboard`, `Delete-Dashboard`), saved reports (`Get-Report`), lexicon management (6 tools: `Edit-Event`, `Edit-Property`, `Create-Tag`, `Rename-Tag`, `Delete-Tag`, `Get-Lexicon-URL`), and `Get-Projects`. These don't fit the canonical workflow rows but are useful in adjacent flows.
