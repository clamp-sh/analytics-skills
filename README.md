# analytics-skills

Analytics skills for Claude, Cursor, and other AI agents. Read web analytics like a senior analyst: diagnose traffic changes, judge channel quality, read funnels, declare typed events, and read A/B tests without the usual rookie mistakes. Ships with tool-maps for [Amplitude](tool-maps/amplitude.md), [Clamp](tool-maps/clamp.md), [GA4](tool-maps/ga4.md), [Mixpanel](tool-maps/mixpanel.md), and [PostHog](tool-maps/posthog.md); add your own under [`tool-maps/`](tool-maps/). The schema-authoring and experiment-reading skills are built on the open [Event Schema spec](https://github.com/clamp-sh/event-schema).

## What's in the box

| Skill | What it does |
|---|---|
| [`analytics-profile-setup`](skills/analytics-profile-setup/SKILL.md) | One-time interview that captures your business context (model, primary conversion, traffic range, ICP, data stack) into a local `analytics-profile.md`. Every other skill reads this file so answers are calibrated to your industry and scale. Run this first. |
| [`analytics-diagnostic-method`](skills/analytics-diagnostic-method/SKILL.md) | The spine. Five-step method: load profile, frame the question, build a MECE hypothesis tree, triangulate, present with the Pyramid Principle. Covers signal vs noise and Simpson's paradox. Referenced by every other skill. |
| [`traffic-change-diagnosis`](skills/traffic-change-diagnosis/SKILL.md) | Drill path for "why did traffic change". Fingerprints for tracking regressions, bot spikes, deploy-correlated drops, campaign ramps, SEO decay, and platform changes. Measurement checks first, always. |
| [`channel-and-funnel-quality`](skills/channel-and-funnel-quality/SKILL.md) | Volume × engagement × conversion as a matrix. Vanity-traffic detection. Expected drop-off ranges per funnel step type. Mix-shift handling. Industry-specific benchmarks. |
| [`metric-context-and-benchmarks`](skills/metric-context-and-benchmarks/SKILL.md) | What's a good bounce / engagement / duration / CVR / churn / LTV:CAC / activation, by model. When each metric lies. Minimum sample sizes before trusting a rate. |
| [`event-schema-author`](skills/event-schema-author/SKILL.md) | Authors `event-schema.yaml` from existing `track()` calls. A portable, typed declaration of every product analytics event the codebase fires. The CLI generates a TypeScript type so call sites are autocompleted and type-checked at build time. Vendor-neutral; works with any analytics SDK. |
| [`experiment-result-reader`](skills/experiment-result-reader/SKILL.md) | Read a running A/B test honestly. Pulls per-variant exposure and conversion counts, computes lift, applies sample-size and sequential-testing discipline, checks for mix-shift and sample-ratio mismatch, and returns a verdict with caveats instead of a false-positive. Reads the experiment from the `experiments:` section of `event-schema.yaml` when present. |

## Built on real research

Frameworks and benchmarks the skills lean on, with sources:

- **Method**: Minto's MECE and Pyramid Principle (1985), Simpson (1951) for the mix-shift trap, standard 95% CI sample-size rules for noise-vs-signal calls.
- **Benchmarks**: [Unbounce 2024](https://unbounce.com/conversion-benchmark-report/) (57M conversions), [Wordstream 2025](https://www.wordstream.com/blog/ws/2025/05/21/search-advertising-benchmarks), [Ruler 2025](https://www.ruleranalytics.com/blog/insight/conversion-rate-by-industry/) (100M+ data points by industry), [Littledata Shopify 2023](https://www.littledata.io/benchmarks/shopify), [Imperva *Bad Bot Report*](https://www.imperva.com/resources/resource-library/reports/bad-bot-report/), [Mixpanel](https://mixpanel.com/blog/product-benchmarks/), [ChartMogul](https://chartmogul.com/reports/saas-benchmarks-report/), [David Skok SaaS Metrics 2.0](https://www.forentrepreneurs.com/saas-metrics-2/).
- **Definitions**: GA4 metric definitions taken from [Google's docs](https://support.google.com/analytics/answer/12195621) (note: GA4 bounce rate is *not* the UA single-pageview bounce rate).

## Install

Pick whichever fits your setup. All three install the same skills.

### Claude Code, plugin (recommended)

```bash
# Add the marketplace once
/plugin marketplace add clamp-sh/analytics-skills

# Install
/plugin install analytics-skills@clamp-sh
```

Skills become available as `/analytics-skills:<name>` and are auto-invoked when the task matches.

### Any agent (Cursor, Claude Code, Copilot, others)

Install via Vercel's open [skills CLI](https://skills.sh):

```bash
npx skills add clamp-sh/analytics-skills
```

Works with any tool that supports the Agent Skills spec.

### Claude Code, standalone (no plugin machinery)

Clone into your personal skills directory:

```bash
git clone https://github.com/clamp-sh/analytics-skills.git /tmp/analytics-skills
cp -R /tmp/analytics-skills/skills/* ~/.claude/skills/
```

Or run the bundled installer which symlinks each skill (so `git pull` updates them):

```bash
git clone https://github.com/clamp-sh/analytics-skills.git ~/.analytics-skills
~/.analytics-skills/scripts/install-personal.sh
```

For a single project, clone into `.claude/skills/` inside the repo instead.

### Codex CLI

Same SKILL.md format, different location. User-level install:

```bash
git clone https://github.com/clamp-sh/analytics-skills.git /tmp/analytics-skills
cp -R /tmp/analytics-skills/skills/* ~/.codex/skills/
```

For a project, copy into `.agents/skills/` at the repo root instead. Codex auto-detects new skills; restart if needed.

### claude.ai

Build the per-skill zips and upload each via **Settings → Features → Skills**:

```bash
./scripts/build-claude-ai-zips.sh
# Produces dist/analytics-diagnostic-method.zip etc.
```

Pre-built zips for each release are also attached to the GitHub release page.

## Usage

These are model-invoked skills. You don't need to call them by name; just ask real analytics questions and Claude will load the relevant skill.

**First run, on a new project:**

```
Set me up. I want the skills calibrated to my business.
```

This loads `analytics-profile-setup`, walks a 5-minute interview, and writes `analytics-profile.md` to the repo root. Every subsequent question gets industry-aware answers.

**After setup, ask real questions:**

```
Traffic dropped 30% on Tuesday. What happened?
```

Loads `traffic-change-diagnosis`. Walks the hypothesis tree (measurement → time-shape → channel → cohort → content), pulls numbers from your analytics source, returns a diagnosis. Not a screenshot of a chart.

```
Is our signup funnel broken? Pricing → checkout is converting at 14%.
```

Loads `channel-and-funnel-quality` and `metric-context-and-benchmarks`. Compares against expected step drop-off, slices by cohort, flags whether 14% is low, normal, or suspicious given your sample size and model.

```
Our bounce rate is 68%. Is that bad?
```

Loads `metric-context-and-benchmarks`. Handles the GA4 vs UA definition gotcha, looks up the relevant page-type range, flags the sample-size caveat if needed.

## Supported analytics platforms

The skills are platform-neutral; per-platform MCP invocations live in [`tool-maps/`](tool-maps/). One file per supported analytics tool, all covering the same canonical 17-row workflow taxonomy.

| Tool | Tool-map | Surface |
|---|---|---|
| [Amplitude](https://amplitude.com) | [`amplitude.md`](tool-maps/amplitude.md) | `query_amplitude_data` covers most rows; cohorts and experiments are dedicated tools |
| [Clamp](https://clamp.sh) | [`clamp.md`](tool-maps/clamp.md) | dedicated MCP tool per row of the canonical taxonomy |
| [GA4](https://analytics.google.com) | [`ga4.md`](tool-maps/ga4.md) | `run_report` for aggregate rows; funnels and cohort retention not exposed by the wrapper |
| [Mixpanel](https://mixpanel.com) | [`mixpanel.md`](tool-maps/mixpanel.md) | `Run-Query` types (insights, funnels, flows, retention) |
| [PostHog](https://posthog.com) | [`posthog.md`](tool-maps/posthog.md) | Trends/Funnels/Retention/Paths insights plus HogQL |

The full row-by-row coverage matrix is at [`tool-maps/capability-matrix.md`](tool-maps/capability-matrix.md). `analytics-profile-setup` records the active platform in `analytics-profile.md` under `tool_map:`; downstream skills load the matching tool-map automatically.

Using a different analytics source? The method still applies. Add a tool-map for it (see [`tool-maps/README.md`](tool-maps/README.md) for the template).

## Contributing

Issues and PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add a skill and the style conventions we follow.

## License

MIT. See [LICENSE](LICENSE).
