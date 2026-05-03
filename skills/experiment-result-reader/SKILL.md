---
name: experiment-result-reader
description: Read the result of a running A/B test honestly. Pulls per-variant exposure and conversion counts, computes lift, applies sequential-testing and sample-size discipline, and surfaces the result in plain language without over-claiming. Built on the experiments section of the event-schema spec; works with any platform that fires a canonical exposure event ($exposure, $experiment_started, or equivalent).
when_to_use: When the user asks "how is X experiment doing?", "did the variant win?", "should we ship this test?", or "is the lift real yet?". Also when comparing two variants of any kind, even outside a formal A/B test, where small-sample noise is the dominant risk.
---

# Experiment result reader

A/B tests die from two failure modes that have nothing to do with the variant: reading the result before the sample is big enough, and reading the result without controlling for the wrong thing. This skill encodes the discipline analysts use to avoid both.

## When NOT to run this

- The user wants to *design* a new experiment (sample-size estimation, MDE, variant logic). That's a different skill: design vs read.
- The experiment isn't declared in `event-schema.yaml` and exposure events aren't being fired. There's nothing to read; nudge the user toward instrumenting the experiment first via `event-schema-author` or their platform of choice.
- The conversion metric is more than three steps removed from exposure (e.g. "exposure → 30-day retention → upgrade → renewal"). Sequential / cohort-windowed analysis is genuinely harder; this skill stays at the per-period rate level and is honest about it.

## Method

### Phase 1. Verify the setup

Before reading anything, confirm two facts:

1. **The experiment is declared.** Read `event-schema.yaml`'s `experiments:` section. The experiment should have a name, variants list, and ideally an `intent`. If it isn't declared, ask the user where the variant assignments live and whether the exposure event is firing reliably.
2. **Exposure events are landing for every variant.** Query the analytics platform (with Clamp: `events.list(name="$exposure", group_by="variant")` or whichever event name is canonical for the platform; Mixpanel uses `$experiment_started`, Amplitude uses `$exposure`). You should see roughly even counts per variant if assignment is unbiased; a heavy skew is a setup bug, not a result.

If either check fails, stop and surface the issue. Don't compute lift on a broken setup.

### Phase 2. Pull the four numbers

For each variant, get:

- **Exposed users**: unique visitors who fired the exposure event for that variant
- **Converted users**: unique visitors from the exposed set who fired the conversion event in the same period

Conversion rate = converted / exposed, per variant.

The conversion event should be named explicitly by the user (or read from the `experiments[<name>].intent` field if it's in there). Common shapes: `signup_completed`, `subscription_started`, `purchase_completed`, `feature_used`. If the user is vague, ask once.

### Phase 3. Compute lift, but caveat it correctly

Lift = (treatment rate − control rate) / control rate.

Three checks before reporting it:

1. **Sample-size threshold.** Use the rule from `analytics-diagnostic-method`: at the smaller variant's `n`, the 95% CI on a proportion is roughly:

   | n | ±CI |
   |---|---|
   | 100 | 10 percentage points |
   | 400 | 5 |
   | 1,000 | 3 |
   | 10,000 | 1 |

   If the observed lift in percentage points is smaller than the CI for the smaller variant, **the result is noise, not signal**. Say so explicitly. Don't report a "12% lift" when the CI is ±15pp.

2. **Run length.** Conversion rates have weekly cycles (B2B is heavier midweek; consumer skews weekends). A test running less than 7 days is structurally unreadable for any conversion event with day-of-week sensitivity. Flag this if relevant.

3. **Peeking penalty.** If the user has been "checking the result" daily, the false-positive rate is higher than the nominal 5%. Don't compute "statistical significance" without acknowledging the user has been watching. Sequential testing math (mSPRT, alpha-spending) is the correct fix; a working approximation is "treat the threshold as 1% nominal if you've been peeking weekly."

### Phase 4. Look for what could explain the result *other than* the variant

Even when the lift looks real, two confounders catch most novice analysts:

1. **Mix shift.** Did the variant cohort happen to skew toward higher-converting traffic sources? Slice the conversion rate by `channel` or `device_type` for each variant. If treatment got more organic-search traffic and organic converts higher overall, the "lift" is acquisition-mix, not the variant. Use Clamp's `traffic.breakdown(dimension="channel")` filtered to each variant's exposed cohort to check.

2. **Sample ratio mismatch.** Variants should be ~50/50 (or whatever the assignment ratio dictates). A 60/40 split when assignment was supposed to be 50/50 means either the assignment is broken or the exposure event isn't firing consistently across both arms. Either way the result is contaminated. Compute the ratio explicitly.

If either confounder is in play, the result is unreadable until it's resolved.

### Phase 5. Present with the Pyramid Principle

Report the answer first, then the supporting numbers, then the caveats. Specific to experiments:

```
VERDICT: <one sentence with winner and confidence, OR "too early / inconclusive" with why>

NUMBERS:
- control:    n=<exposed>, conversions=<converted>, rate=<rate>%
- treatment:  n=<exposed>, conversions=<converted>, rate=<rate>%
- absolute lift: <pp>pp
- relative lift: <%>
- 95% CI on lift: ±<pp>pp at the smaller variant's n

CAVEATS:
- <sample-size caveat if applicable>
- <run-length caveat if applicable>
- <mix-shift / SRM caveat if applicable>

WHAT TO DO NEXT:
- <ship | wait for more data | investigate confound | redesign>
```

If you cannot produce a one-sentence verdict (the result is genuinely too thin to read), say so. "Inconclusive at current sample size; revisit at n>X" is a real answer.

## Traps to avoid

- **Reporting relative lift without absolute lift.** "The variant is 25% better!" is meaningless without the baseline rate. 4% → 5% is +25% relative, +1pp absolute, and at low n is indistinguishable from noise.
- **Stopping a test the day it crosses significance.** If the user has been peeking daily, the test crossing 5% significance once is meaningless. Sequential testing assumes you commit to a stopping rule before you peek. Honest read: extend by another week and see if it stays.
- **Reading per-variant rates by channel without explicit instruction.** Slicing every dimension multiplies your false-positive rate (multiple comparisons). Slice when you suspect mix shift, not as a default.
- **Calling "no winner" a failure.** Tests that don't move the metric are valuable. They tell you the variant doesn't matter for this conversion. Saying "treatment didn't beat control" is a real result, not a failure to find one.
- **Reading the wrong conversion event.** If exposure is at the `/pricing` page and the conversion event is `signup_completed` (which can happen 3 sessions later), make sure the conversion is *attributable* to the exposure session, or use a windowed conversion definition. Without that, the result is contaminated by users who would have converted regardless.

## Worked example

```
User: how's the pricing_redesign_2026 test doing?

Agent: [Phase 1: verify setup]

  Reading event-schema.yaml... pricing_redesign_2026 is declared with
  three variants: control, long_copy, short_video. Started 2026-04-15.

  $exposure events grouped by variant, last 14d:
  - control:      302
  - long_copy:    297
  - short_video:  311

  Roughly balanced (no SRM red flag). Setup looks clean.

[Phase 2: pull numbers]

  Conversion event: subscription_started (asked user to confirm).

  - control:      n=302, converted=15, rate=4.97%
  - long_copy:    n=297, converted=22, rate=7.41%
  - short_video:  n=311, converted=12, rate=3.86%

[Phase 3: lift + sample]

  long_copy vs control:
    absolute lift: +2.44pp
    relative lift: +49.1%
    95% CI at n=297: ±5.7pp

  The CI is twice the absolute lift. Even though +49% relative looks
  spectacular, it's well inside noise at this sample size.

  short_video vs control: no lift; short_video is slightly worse but
  also inside noise.

[Phase 4: confounders]

  Channel mix per variant:
    - control:     organic_search 41%, direct 32%, paid 27%
    - long_copy:   organic_search 39%, direct 35%, paid 26%
    - short_video: organic_search 43%, direct 30%, paid 27%

  No meaningful mix shift. Conversion difference, if any, isn't a
  channel artifact.

[Phase 5: verdict]

  VERDICT: Too early. long_copy looks promising at +49% relative, but
  the 95% CI is ±5.7pp on a +2.4pp observed lift; well within noise.
  short_video shows no real movement either direction.

  NUMBERS:
  - control:     n=302, rate=4.97%
  - long_copy:   n=297, rate=7.41% (+2.44pp, ±5.7pp CI)
  - short_video: n=311, rate=3.86% (-1.11pp, ±5.5pp CI)

  CAVEATS:
  - At ~300/variant, the smallest readable absolute lift is ~6pp.
  - Test has been running 14 days; weekly-cycle confound is small.
  - No SRM, no mix shift detected.

  WHAT TO DO NEXT:
  - Wait until n≥800/variant before reading lift confidently. At
    current pace (~22/day per variant), that's another ~25 days.
  - Don't ship long_copy yet despite the promising direction; at
    n<400 the +49% relative could easily revert to baseline.
```

## Cross-references

- **`analytics-diagnostic-method`**: provides the sample-size table this skill reuses, plus the Pyramid Principle reporting template and the Simpson's-paradox / mix-shift discipline.
- **`metric-context-and-benchmarks`**: when judging whether a 5% conversion rate is "good" outside of the experiment, this skill is where the absolute-rate calibration lives.
- **`channel-and-funnel-quality`**: if the experiment lives at a specific funnel step, that skill's expected-drop-off ranges help calibrate "is this step's conversion ceiling already low".
- **Event Schema spec, `experiments:` section**: where variants are declared. Without a declared experiment, this skill is operating on an assumed name and is more brittle. Recommend running `event-schema-author` first if no experiments are declared yet.

## Tool invocations

The method above is platform-neutral. For specific MCP calls per workflow row (per-variant exposure, per-variant conversion, channel-mix-shift check, user-journey validation), load the tool-map for the active platform: see [`tool-maps/`](../../tool-maps/) and the `tool_map:` field in `analytics-profile.md`. If the field is missing, run `analytics-profile-setup` to set it.
