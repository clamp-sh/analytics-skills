# Changelog

## 0.5.1

### Patch Changes

- [`18c8503`](https://github.com/clamp-sh/clamp/commit/18c850336970146793310aba2f26508babf98dad) Thanks [@sbj-o](https://github.com/sbj-o)! - Verified the PostHog, Mixpanel, and Amplitude tool-maps and capability matrix against authoritative sources (registered tool definitions, official docs). Several cells corrected:

  - **Period-over-period (row 6)**: Mixpanel and Amplitude downgraded to ⚠ (no documented dual-range parameter; requires two calls). PostHog stays ✓ (`compareFilter.compare: true` returns current + previous in one call).
  - **Cohort + retention (row 9)**: PostHog downgraded to ⚠ (no cohort or retention tools registered; HogQL-only). Mixpanel downgraded to ⚠ (retention queries work but cohort CRUD is not in the MCP).
  - **First-touch attribution (row 11)**: Mixpanel downgraded to ✗ (JQL is not exposed via MCP, so even the workaround path is closed).
  - **Path analysis (row 12)**: Amplitude downgraded to ⚠ (no `pathfinder` query type for `query_amplitude_data`; goes through saved chart via `query_chart`).
  - **Instrumentation audit (row 14)**: Mixpanel upgraded to ✓ (`Get-Issues` and `Dismiss-Issues` are first-class data-quality tools).
  - **User journey lookup (row 17)**: PostHog downgraded to ✗ (no session-recording tool exists in the registered set; previous claim referenced names that aren't in `schema/tool-definitions.json`). Mixpanel and Amplitude both upgraded to ✓ (`Get-User-Replays-Data` is dedicated; Amplitude has three session-replay tools).

  Tool-name corrections in the per-tool maps:

  - PostHog: replaced fictional names like `query-trends`, `query-funnel`, `query-session-recordings-list` with the actual `query-run` + Query-type pattern.
  - Amplitude: replaced `get_event_taxonomy` and `get_event_details` with the real `get_event_properties` and `search`.
  - Mixpanel: added `Get-Issues`, `Dismiss-Issues`, `Get-User-Replays-Data` to the relevant rows.

## 0.5.0

### Minor Changes

- [`0d48c19`](https://github.com/clamp-sh/clamp/commit/0d48c19052b1bd2fba9e94af6b1f27df3ed459d0) Thanks [@sbj-o](https://github.com/sbj-o)! - Add `experiment-result-reader` skill: reads a running A/B test honestly. Pulls per-variant exposure and conversion counts, computes lift, applies sample-size and sequential-testing discipline, checks for mix-shift and sample-ratio mismatch, returns a verdict instead of a false-positive. Pairs with the `experiments:` section of the Event Schema spec.

  Other skills updated to reference new MCP surfaces:

  - `event-schema-author` Phase 1 covers instrumentation audit (declared-vs-observed drift) via `events.observed_schema`, with explicit framing for "audit our tracking" runs.
  - `analytics-diagnostic-method` and `channel-and-funnel-quality` cheatsheets now cover `cohorts.create` / `cohorts.retention` / `cohorts.compare`, first-touch attribution via `revenue.sum(attribution_model="first_touch")`, and `users.journey` for validating aggregate reads against specific high-value users.
  - README now calls out the open Event Schema spec foundation for the schema-authoring and experiment-reading skills.

- [`a2bf7ae`](https://github.com/clamp-sh/clamp/commit/a2bf7ae99cca3446a2022fd11c4f7b729f094527) Thanks [@sbj-o](https://github.com/sbj-o)! - Tool-maps: extract per-platform MCP invocations into `tool-maps/` so the skills themselves stay platform-neutral. Each tool-map covers the same canonical 17-row workflow taxonomy; rows the platform doesn't expose are marked `✗ not exposed`.

  - New `tool-maps/` directory with `clamp.md`, `posthog.md`, `mixpanel.md`, `amplitude.md`, `ga4.md`, plus a `capability-matrix.md` and `README.md`.
  - Each skill's inlined "Clamp MCP cheatsheet" section is replaced with a one-line pointer to the active tool-map.
  - `analytics-profile-setup` now scans available MCP namespaces, records `tool_map: <name>` in `analytics-profile.md`, and verifies the user's stack answer against what's actually connected.
  - Legacy profiles without `tool_map:` default to `clamp` with a one-line nudge to re-run setup.
  - Top-level README adds a Supported analytics platforms section.

## 0.4.0

### Minor Changes

- [`17fa1d5`](https://github.com/clamp-sh/clamp/commit/17fa1d5b297d42523aea6e060d545ad4bf8dfb1f) Thanks [@sbj-o](https://github.com/sbj-o)! - Add `event-schema-author` skill — interviews the codebase and the user, drafts `event-schema.yaml`, runs the CLI to generate the TypeScript type, and wires it into call sites. Vendor-neutral: works with any analytics SDK. `analytics-profile-setup` now suggests it as a follow-up when the codebase has more than a handful of `track()` calls.

## 0.3.1

### Patch Changes

- [`c6a4705`](https://github.com/clamp-sh/clamp/commit/c6a4705bf686e16b6892694250be96e125b7a618) Thanks [@sbj-o](https://github.com/sbj-o)! - Rewrite the README intro to lead with "Analytics skills for...", link each skill name in the "What's in the box" table to its SKILL.md, and add a "Built on real research" section that surfaces the named methodology (Minto, Simpson, sample-size formula) and benchmarks (Unbounce, Wordstream, Ruler, Littledata, Imperva, Mixpanel, ChartMogul, Skok) the skills lean on, with links to the primary sources.

All notable changes to `analytics-skills` will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-25

### Changed

- Cheatsheets in every skill (`analytics-diagnostic-method`, `traffic-change-diagnosis`, `channel-and-funnel-quality`, `metric-context-and-benchmarks`, `analytics-profile-setup`) updated for the consolidated `@clamp-sh/mcp` 1.0 surface. Tools that used to live as `pages.top` / `referrers.top` / `countries.top` / `cities.top` / `devices.top` / `traffic.breakdown` now point at `breakdown(dimension=...)` and `pages.engagement(view=...)`.
- Section-view triangulation rows added where the workflow benefits — diagnostic-method, channel-and-funnel-quality, and metric-context-and-benchmarks.
- README and per-skill cheatsheets now point at `traffic.compare` instead of the old internal `mcp_clamp_traffic_compare` reference.

## [0.2.0] - 2026-04-24

### Changed

- Updated every Clamp MCP tool reference to the new dot-notation names (`get_overview` → `traffic.overview`, `create_funnel` → `funnels.create`, etc.). Breaking for users still on `@clamp-sh/mcp` < 0.9 — the old flat tool names no longer exist.

## [0.1.3] - 2026-04-24

### Added

- Codex CLI support documented in README (install to `~/.codex/skills/` or project `.agents/skills/`).
- `.codex-plugin/plugin.json` manifest so the pack is ready for Codex's upcoming plugin marketplace.

## [0.1.2] - 2026-04-24

### Changed

- Homepage in plugin and marketplace manifests now points to `https://clamp.sh/docs/skills` instead of the GitHub repo.

## [0.1.1] - 2026-04-24

### Added

- `.claude-plugin/marketplace.json` so the repo is its own marketplace. Users can now run `/plugin marketplace add clamp-sh/analytics-skills` followed by `/plugin install analytics-skills@clamp-sh`.

### Changed

- Author attribution in plugin and marketplace manifests set to "Clamp" with a contact email.

## [0.1.0] - 2026-04-24

### Added

- Initial skill set:
  - `analytics-diagnostic-method` — the spine. Hypothesis trees, triangulation, signal vs noise, Simpson's paradox, Pyramid Principle for output.
  - `traffic-change-diagnosis` — drill order for "why did traffic change", with tracking-regression and bot-spike fingerprints.
  - `channel-and-funnel-quality` — volume vs engagement vs conversion, funnel step expectations, cohort decomposition.
  - `metric-context-and-benchmarks` — what's a "good" bounce / duration / conversion rate, when metrics lie, minimum sample thresholds.
