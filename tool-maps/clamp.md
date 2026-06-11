# Clamp tool-map

Source: <https://clamp.sh/mcp> · Auth: project API key (per-project token) · Install: `npm i -g @clamp-sh/mcp`, or use the hosted endpoint.

Clamp's MCP exposes a dedicated tool per workflow row of the canonical taxonomy. Most rows are one call; the few that compose (cohorts, funnels) follow a create-then-query pattern.

## Canonical workflow rows

| # | Row | Invocation |
|---|---|---|
| 1 | Setup / event firing check | `events.list(name="<event>")` confirms the event is recorded; pair with `traffic.overview` for whole-property sanity |
| 2 | Traffic overview (sessions, users, pageviews) | `traffic.overview` |
| 3 | Time shape (hourly or daily) | `traffic.timeseries` |
| 4 | Channel / referrer split | `traffic.breakdown(dimension="referrer_host")` (channel comes back joined per row) or `traffic.breakdown(dimension="channel")` |
| 5 | Geo / device / cohort splits | `traffic.breakdown(dimension="country" \| "city" \| "device_type" \| "browser" \| "os")`; new-vs-returning via `traffic.breakdown(dimension=..., cohort=...)` |
| 6 | Period-over-period comparison | `traffic.compare` |
| 7 | Live / realtime | `traffic.live` |
| 8 | Funnel construction | `funnels.create(name, steps)` then `funnels.list(name)` |
| 9 | Cohort definition + retention | `cohorts.create(name, definition)` then `cohorts.retention(name, periods="1d,7d,14d,30d")`; N-way stack via `cohorts.compare(names="primary,b,c")` (2–10 cohorts, same windows applied to all) |
| 10 | Revenue (SaaS health) | `revenue.summary(period=...)` returns the full KPI bundle (revenue, customers, orders, AOV, LTV, MRR, ARR, per-plan + per-product rollups, prior-period comparison). For dim breakdowns use `revenue.sum(group_by="channel" \| "referrer_host" \| "country" \| ...)`. |
| 11 | First-touch attribution | `revenue.sum(group_by="channel", attribution_model="first_touch")` (acquisition dims only; sample-size sensitive at low N). Filter a breakdown to one source with `first_touch_dim` + `first_touch_value`. |
| 12 | Path analysis | `sessions.paths` |
| 13 | Page / section engagement | `pages.engagement(view="summary" \| "engagement" \| "sections", pathname=...)` (sections requires the section-views SDK extension) |
| 14 | Instrumentation audit (declared vs observed) | `events.observed_schema` diffed against the local `event-schema.yaml`; surfaces dead instrumentation, undeclared events, and silent type drift |
| 15 | Per-variant exposure (experiments) | `events.list(name="$exposure", group_by="variant")` |
| 16 | Per-variant conversion (experiments) | `events.list(name="<conversion>", property="variant", value="<variant_name>")` per variant; channel-mix-shift check adds `group_by="channel"` |
| 17 | User journey lookup | `users.journey(anonymous_id=...)` for one-user reconstruction |

## Limitations

None for the canonical row taxonomy.

## Beyond the canonical taxonomy

Clamp ships error tracking as a first-class signal alongside traffic and revenue. Errors are not in the 17-row taxonomy, but the MCP exposes four read tools for diagnosis that compose with the standard workflow rows:

| Tool | What it returns |
|---|---|
| `errors.list` | Recent `$error` events with full context. Filter by message, fingerprint, browser, OS, device, country, or handled flag. |
| `errors.groups` | Errors deduplicated by server-computed fingerprint (sha256 of normalized message + first stack frame). Each group has count, users_affected, first_seen, last_seen. |
| `errors.timeline` | Error count over time, hourly or daily. Optionally scoped to one fingerprint to chart a single bug's rate. |
| `errors.context` | Breadcrumbs leading to one error: events from the same session before the error timestamp, in chronological order. |

Cross-correlation: errors live in the same event store as traffic and revenue, so questions like "did errors spike after the LinkedIn campaign drove broken-Safari users to /checkout" combine `errors.timeline` with `traffic.timeseries` filtered by campaign and `revenue.sum` for the same period — one MCP, no tool-switching with Sentry.

## Notes

- `traffic.breakdown` accepts a `cohort` filter for new-vs-returning and similar splits without a separate tool.
- `revenue.sum` switches between last-touch and first-touch via the `attribution_model` parameter; only acquisition dims are accepted in first-touch mode. It also accepts `plan`, `product`, `first_touch_dim` + `first_touch_value` filters for drill-in (e.g. "what plans did organic-search customers buy?" — `group_property="plan", first_touch_dim="channel", first_touch_value="organic_search"`).
- `revenue.summary` bundles the entire Revenue tab in one call: revenue, customers, orders, AOV, LTV, MRR (running balance through period end), ARR, per-plan rollup (where `mrr_contribution` is the CUMULATIVE MRR balance per plan, not the in-period delta), per-product rollup, comparison vs prior period, and two mode flags (`is_subscription`, `has_one_time`).
- Mode detection: `is_subscription=true` iff any event carries non-zero `mrr_delta`; `has_one_time=true` iff any non-subscription revenue event landed in the period. Mixed sellers (SaaS + courses, e-comm + memberships) have both set and both breakdowns populated.
- `revenue.retention` is MRR-on-MRR cohort retention: for each window it returns `mature_size` (cohort members old enough to reach the window), `retained`, `retention_rate`, `mrr_at_d` (cumulative MRR through day d), `baseline_mrr_mature`, and `nrr` (net revenue retention; >1.0 = net expansion). Use it to answer "are subscribers expanding or contracting?". Pair with `revenue.summary` to answer "is MRR growing because we're acquiring or because we're retaining?".
- `revenue.timeseries` plots one metric per bucket. `metric` accepts `revenue` (default — sum of Money in bucket), `mrr` (running balance — picks up where the prior period left off), `customers` (distinct paying per bucket), or `transactions` (event count per bucket).
- `events.observed_schema` returns each property's observed type as an array; `properties[key].length > 1` indicates silent type drift across call sites.
- Section engagement (row 13) requires the section-views SDK extension; without it, `view="sections"` returns empty.
