# analytics-skills

Agent skills that teach Claude, Cursor, and other AI agents to read web analytics like a senior analyst. Diagnose traffic changes, judge channel quality, and read funnels without the usual rookie mistakes. Works with any analytics source; first-class support for [Clamp MCP](https://clamp.sh/mcp).

## What's in the box

| Skill | What it does |
|---|---|
| `analytics-profile-setup` | One-time interview that captures your business context (model, primary conversion, traffic range, ICP, data stack) into a local `analytics-profile.md`. Every other skill reads this file so answers are calibrated to your industry and scale. Run this first. |
| `analytics-diagnostic-method` | The spine. Five-step method: load profile, frame the question, build a MECE hypothesis tree, triangulate, present with the Pyramid Principle. Covers signal vs noise and Simpson's paradox. Referenced by every other skill. |
| `traffic-change-diagnosis` | Drill path for "why did traffic change". Fingerprints for tracking regressions, bot spikes, deploy-correlated drops, campaign ramps, SEO decay, and platform changes. Measurement checks first, always. |
| `channel-and-funnel-quality` | Volume × engagement × conversion as a matrix. Vanity-traffic detection. Expected drop-off ranges per funnel step type. Mix-shift handling. Industry-specific benchmarks. |
| `metric-context-and-benchmarks` | What's a good bounce / engagement / duration / CVR / churn / LTV:CAC / activation, by model. When each metric lies. Minimum sample sizes before trusting a rate. |

## Install

Pick whichever fits your setup. All three install the same skills.

### Claude Code, plugin (recommended)

```bash
# Add the marketplace once
/plugin marketplace add clamp-sh/analytics-skills

# Install
/plugin install analytics-skills
```

Skills become available as `/analytics-skills:<name>` and are auto-invoked when the task matches.

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

## Works best with Clamp MCP

The skills are analytics-agnostic but include Clamp-specific tool call-outs. If you have [Clamp MCP](https://clamp.sh/mcp) connected, the agent knows exactly which tool to reach for at each step of the method (`get_overview`, `get_top_referrers`, `create_funnel`, etc.).

Using a different analytics source? The method still applies; only the tool names change.

## Contributing

Issues and PRs welcome. Skills live under `skills/<name>/SKILL.md`. See the [Agent Skills spec](https://agentskills.io/) for the file format.

Style rules for this repo:

- Front-load the key use case in the skill `description` (first 200 chars decide whether it gets loaded).
- Keep `SKILL.md` under 400 lines. Move long reference tables into sibling `.md` files.
- Methodology first, tool names second. A skill that only works with one analytics product is less valuable than one that works everywhere.
- No em dashes.

## License

MIT. See [LICENSE](LICENSE).
