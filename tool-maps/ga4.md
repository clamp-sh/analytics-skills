# GA4 tool-map

Source: <https://github.com/googleanalytics/google-analytics-mcp> · Auth: OAuth 2.0 via Application Default Credentials, read-only scope · Install: `pipx run analytics-mcp` (PyPI: `analytics-mcp`).

Google's official MCP wraps GA4 Data API v1beta. Seven tools total; the workhorses are `run_report` (Data API) and `run_realtime_report` (Realtime API). `run_report` accepts the full GA4 FilterExpression shape (`and_group` / `or_group` / `not_expression`, all numeric and string operators), arbitrary standard + custom dimensions and metrics, multiple named date ranges in a single call, and OrderBy. The wrapper does NOT currently expose `runFunnelReport`, `runPivotReport`, `batchRunReports`, `cohort_spec`, or `pivots`; these fields exist in the Data API protobuf but are dropped by the Python wrapper.

## Canonical workflow rows

| # | Row | Invocation |
|---|---|---|
| 1 | Setup / event firing check | `run_report(metrics=["eventCount"], dimensions=["eventName"], dimension_filter={...eventName==<name>})` |
| 2 | Traffic overview | `run_report(metrics=["sessions","activeUsers","screenPageViews"], date_ranges=[{...}])` |
| 3 | Time shape (hourly / daily) | `run_report(dimensions=["date"]` (or `"dateHour"` for hourly) `, metrics=[...])` |
| 4 | Channel / referrer split | `run_report(dimensions=["sessionDefaultChannelGroup"]` (or `"sessionSource"`/`"sessionMedium"`) `, metrics=["sessions","conversions"])` |
| 5 | Geo / device / cohort splits | `run_report(dimensions=["country" \| "deviceCategory" \| "browser"], metrics=[...])`; new-vs-returning via `dimensions=["newVsReturning"]` |
| 6 | Period-over-period comparison | Single call with two `date_ranges` entries (use `name` per range to distinguish in output) |
| 7 | Live / realtime | `run_realtime_report(metrics=["activeUsers"], dimensions=[...])` |
| 8 | Funnel construction | ✗ not exposed; `runFunnelReport` is a Data API method but the Python wrapper does not register it. Fall back to BigQuery export of the GA4 events table. |
| 9 | Cohort definition + retention | ✗ not exposed; `cohort_spec` exists in `RunReportRequest` but the wrapper at `core.py` never sets it. Fall back to BigQuery export. |
| 10 | Revenue (last-touch) | `run_report(dimensions=["sessionDefaultChannelGroup"], metrics=["totalRevenue","purchaseRevenue"])` |
| 11 | First-touch attribution | ⚠ GA4 supports first-click attribution as a property-level setting (`Attribution settings → Reporting attribution model`). Switching is a workspace change, not a per-query parameter. Sessions-based first-touch can be approximated with `firstUserDefaultChannelGroup` dimension. |
| 12 | Path analysis | ⚠ no path-exploration wrapper; `run_report` returns aggregates only. Fall back to BigQuery export for sequence-level path analysis. |
| 13 | Page / section engagement | Page-level: `run_report(dimensions=["pagePath"], metrics=["screenPageViews","userEngagementDuration"])`. Section-level: ✗ not exposed (no section-views equivalent in GA4). |
| 14 | Instrumentation audit (declared vs observed) | ⚠ `get_custom_dimensions_and_metrics` returns custom defs; standard event metadata via `get_property_details`. Diff against local `event-schema.yaml` client-side. |
| 15 | Per-variant exposure (experiments) | ⚠ if exposure is tracked as a custom event with a `variant` parameter: `run_report(dimensions=["customEvent:variant"], metrics=["eventCount"], dimension_filter={...eventName==<exposure>})` |
| 16 | Per-variant conversion (experiments) | ⚠ same shape, conversion event in the filter |
| 17 | User journey lookup | ✗ not exposed in `run_report`; Data API does not return per-user event sequences. Fall back to BigQuery export. |

## Limitations

- **Row 8 (funnels)** and **Row 9 (cohort retention)**: protobuf fields exist (`runFunnelReport` exists, `RunReportRequest.cohort_spec` exists) but the Python wrapper at `analytics_mcp/tools/reporting/core.py` does not surface them. Open issue with the upstream repo, or fall back to BigQuery export, or use the GA4 UI for these workflows.
- **Row 11 (first-touch attribution)**: GA4's attribution model is set at the property level. The MCP does not expose attribution-model selection per query. Workaround: use the `first*` dimension family (`firstUserDefaultChannelGroup`, `firstUserSource`, etc.) which always reflect first-touch regardless of property setting.
- **Row 12 (path analysis)**: no MCP tool for path/exploration reports. BigQuery is the canonical path for event-sequence analysis on GA4.
- **Row 17 (user journey)**: Data API is aggregation-only by design; per-user event reconstruction requires the BigQuery export.

## BigQuery fallback

For projects on GA4 with BigQuery export enabled (free tier supported as of 2026), the missing rows above are all expressible as SQL against the `events_YYYYMMDD` table. A future companion tool-map for BigQuery would cover funnels, cohort retention, path analysis, and user journey via standard SQL on the events partition. For now, the agent should suggest enabling BigQuery export when the user's question hits a `✗` row.

## Notes

- `run_report` is more capable than its single-tool appearance suggests: the FilterExpression shape supports `and_group` / `or_group` / `not_expression` nesting and operators including `BEGINS_WITH`, `EXACT`, `IN_LIST`, `BETWEEN`. Most workflow rows above translate to one parameterised `run_report` call.
- Period-over-period (row 6) is genuinely first-class: pass two named entries in `date_ranges` and the response includes a `dateRange` column to distinguish them.
- The `first*` dimension family (`firstUserDefaultChannelGroup`, `firstUserSource`, `firstUserMedium`, `firstUserCampaignName`) is GA4's canonical first-touch surface and works regardless of the workspace's attribution-model setting.
