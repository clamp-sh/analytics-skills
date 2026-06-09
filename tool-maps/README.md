# Tool-maps

Translation layer between the analytics-skills' canonical workflow rows and each supported analytics platform's MCP surface. The skills themselves stay platform-neutral: the diagnostic method, sample-size discipline, and Pyramid Principle reporting apply everywhere. The per-tool invocation lives here.

## Files

| File | Purpose |
|---|---|
| [`capability-matrix.md`](capability-matrix.md) | One table, all 17 canonical rows × all supported tools, marked `✓ / ⚠ / ✗`. Read this when picking a platform or reasoning about gaps. |
| [`amplitude.md`](amplitude.md) | Amplitude (official, hosted at `mcp.amplitude.com/mcp`). |
| [`clamp.md`](clamp.md) | Clamp (`@clamp-sh/mcp` or hosted). |
| [`ga4.md`](ga4.md) | Google Analytics 4 (official, `googleanalytics/google-analytics-mcp`). |
| [`mixpanel.md`](mixpanel.md) | Mixpanel (official, hosted; OAuth 2.0 + PKCE). |
| [`posthog.md`](posthog.md) | PostHog (official, hosted at `mcp.posthog.com`). |

## How skills consume tool-maps

`analytics-profile-setup` records which tool the project uses in `analytics-profile.md` under `tool_map: <name>`. Other skills load the matching file when they need a specific MCP call.

If `tool_map` is missing, skills nudge the user to run `analytics-profile-setup` to set it. (Legacy profiles written before tool-maps existed are handled separately in `analytics-profile-setup`'s fallback section.)

## The canonical 17 rows

```
1.  Setup / event firing check
2.  Traffic overview
3.  Time shape (hourly / daily)
4.  Channel / referrer split
5.  Geo / device / cohort splits
6.  Period-over-period comparison
7.  Live / realtime
8.  Funnel construction
9.  Cohort definition + retention
10. Revenue (last-touch)
11. First-touch attribution
12. Path analysis
13. Page / section engagement
14. Instrumentation audit (declared vs observed)
15. Per-variant exposure (experiments)
16. Per-variant conversion (experiments)
17. User journey lookup
```

This taxonomy is the union of analytical operations that turn up across the five skills. New rows get added when a skill needs a workflow that doesn't fit one of the existing slots; existing rows don't move (changing the row numbering is a breaking change for any agent or doc that references "row 8").

## Adding a new tool-map

1. Copy `clamp.md` as a template; keep the row numbering and order identical.
2. For each row, fill in the platform's MCP invocation, or mark it `⚠` (achievable with workaround) or `✗` (not exposed) and explain in the `Limitations` section.
3. Add a column to `capability-matrix.md` with the same `✓ / ⚠ / ✗` values.
4. Update the file table in this README.

The tool-maps are the boundary between method and tool. Skills should never reference a vendor-specific tool name directly; they reference the canonical row, and the agent resolves the call via the active tool-map.
