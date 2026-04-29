# Capability matrix

Coverage of the canonical 17-row analytics-skills workflow across supported MCP surfaces. Each cell is `✓` (one-call native), `⚠` (achievable but takes a workaround, multiple calls, or a setting change) or `✗` (not exposed in the current MCP wrapper).

Last reviewed: 2026-04-29. Vendors ship MCP changes regularly; values may shift. Per-row invocations live in each tool-map.

| # | Row | Clamp | PostHog | Mixpanel | Amplitude | GA4 |
|---|---|:-:|:-:|:-:|:-:|:-:|
| 1 | Setup / event firing check | ✓ | ✓ | ✓ | ✓ | ✓ |
| 2 | Traffic overview | ✓ | ✓ | ⚠ | ✓ | ✓ |
| 3 | Time shape (hourly / daily) | ✓ | ✓ | ✓ | ✓ | ✓ |
| 4 | Channel / referrer split | ✓ | ✓ | ✓ | ✓ | ✓ |
| 5 | Geo / device / cohort splits | ✓ | ✓ | ✓ | ✓ | ✓ |
| 6 | Period-over-period comparison | ✓ | ✓ | ✓ | ✓ | ✓ |
| 7 | Live / realtime | ✓ | ⚠ | ✗ | ✗ | ✓ |
| 8 | Funnel construction | ✓ | ✓ | ✓ | ✓ | ✗ |
| 9 | Cohort definition + retention | ✓ | ✓ | ✓ | ✓ | ✗ |
| 10 | Revenue (last-touch) | ✓ | ⚠ | ⚠ | ⚠ | ✓ |
| 11 | First-touch attribution | ✓ | ⚠ | ⚠ | ⚠ | ⚠ |
| 12 | Path analysis | ✓ | ✓ | ✓ | ✓ | ⚠ |
| 13 | Page / section engagement | ✓ | ⚠ | ⚠ | ⚠ | ⚠ |
| 14 | Instrumentation audit | ✓ | ⚠ | ⚠ | ⚠ | ⚠ |
| 15 | Per-variant exposure | ✓ | ✓ | ⚠ | ✓ | ⚠ |
| 16 | Per-variant conversion | ✓ | ✓ | ⚠ | ✓ | ⚠ |
| 17 | User journey lookup | ✓ | ✓ | ⚠ | ⚠ | ✗ |

## Reading the matrix

A `✓` means one MCP call returns the answer in the shape the skill expects. A `⚠` means the data is reachable but the agent has to compose two or more calls, write a SQL/HogQL query, change a setting in the platform first, or accept a partial answer. A `✗` means the wrapper does not expose the underlying API surface at all and the workflow row falls back to a non-MCP path (e.g. BigQuery export for GA4 funnels).

The `⚠` count predicts how chatty the agent will be on a given platform. Vendors expose different surfaces; the matrix tracks what each one ships, not what each one could ship.

## When the matrix lies

Three failure modes:

- **A vendor ships new tools.** Particularly likely for PostHog and Amplitude, both of which iterate their MCP weekly. Open the per-tool map for the source-of-truth invocation.
- **A `⚠` is actually fine.** A workaround that's "two calls instead of one" is barely worse than `✓` for most workflows. Read the per-tool map's `Limitations` section to judge.
- **A `✓` requires platform-specific setup.** Funnels in PostHog need the funnel insight definition; cohorts in Amplitude need a saved cohort. The matrix tracks API capability, not whether the user has done their own configuration.
