# Changelog

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
