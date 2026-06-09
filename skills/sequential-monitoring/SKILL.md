---
name: sequential-monitoring
description: Always-valid sequential inference for honest peeking at running A/B tests. Applies mSPRT (mixture Sequential Probability Ratio Test) or confidence sequences so the false-positive rate stays at the nominal alpha even when the test is checked daily. Use this skill when the user asks if it's safe to call an A/B test early, or to peek-check a running test. Pairs with experiment-result-reader and bayesian-experiment-reader, and with analytics-diagnostic-method for the framing discipline. Triggers when Clamp MCP returns mid-experiment exposure and conversion counts, or when a user references peeking, early stopping, sequential testing, alpha-spending, mSPRT, or confidence sequences. Vendor-neutral methodology; works with any analytics source, with Clamp MCP as the canonical integration. Use whenever interpreting an in-flight experiment where the planned horizon has not been reached but the user wants a stop/continue decision.
when_to_use: When the user asks "can we stop the test now?", "the variant looks like it's winning, is it safe to ship?", "I've been peeking, did I break the test?", "what's the sequential p-value here?", or "how do I check a running test without inflating false positives?". Also when an agent is mid-loop on a running experiment and needs to decide whether to call it.
---

# Sequential monitoring

A fixed-horizon A/B test promises a 5% false-positive rate at one planned read. The moment you check the result daily and stop "when it looks good", the actual false-positive rate climbs to 20-30%. Sequential testing fixes this: it lets you check as often as you like and stop the moment the evidence is strong enough, with the type-I error still controlled at the nominal alpha. This skill encodes when to apply mSPRT versus confidence sequences, how to read the boundaries, and when sequential math will not rescue an underpowered test.

## When NOT to use this

- The test has fewer than ~400 exposed users per variant. Sequential methods do not manufacture power. At n<400 the boundaries are nowhere near being crossed and the honest answer is "wait, do not peek".
- The conversion metric has strong seasonality (B2B day-of-week, retail weekday/weekend, SaaS payday cycles) and the test has not run a full cycle. Sequential boundaries can cross on a Tuesday and uncross by Sunday; the math is valid but the decision is fragile.
- The user wants to *design* the test (sample size, MDE, variant logic) rather than read a running one. Different skill.
- The experiment was already declared with a fixed analysis plan and the team agreed to read it only at the end. Switching to sequential mid-flight is a governance decision, not a stats one; flag it and ask.

## The peeking problem

A fixed-horizon test computes a p-value under the assumption you look once, at the planned end. Each additional peek is another chance to cross the 5% threshold by noise alone.

| Peeks across the test | Actual false-positive rate (nominal 5%) |
|---|---|
| 1 (end only) | 5% |
| 2 | ~8% |
| 5 (weekly) | ~14% |
| 10 (twice weekly) | ~19% |
| Daily over a month | ~25-30% |

If the user has been "checking how the test is doing" every morning, the nominal 5% threshold is meaningless. They need either a sequential method (always-valid) or alpha-spending (pre-commit to a peek schedule and inflate the threshold).

## Method

### Phase 1. Decide which sequential framework fits

Two practical options. Pick by the decision the user is actually making.

| Question the user is asking | Use | Output |
|---|---|---|
| "Should we ship treatment or not?" (binary call) | **mSPRT** | Log-likelihood ratio crosses upper or lower boundary → ship or reject |
| "What is the lift, with a CI I can trust at any time?" | **Confidence sequences** | Always-valid CI on lift; ship when the CI excludes 0 (or excludes a minimum effect) |
| "I just want to peek without breaking alpha" | Either; mSPRT is simpler to read | See above |

Both methods are always-valid: the false-positive rate stays at alpha no matter how often you look. mSPRT is Statsig's default; confidence sequences are GrowthBook's default. The choice is taste plus what the user wants to read.

### Phase 2. Verify the setup before peeking

Same prerequisites as `experiment-result-reader`:

1. The experiment is declared (variants, intent, exposure event firing reliably).
2. Per-variant exposure counts are roughly balanced (no sample ratio mismatch). SRM contaminates sequential reads just as badly as fixed-horizon ones.
3. The conversion event is attributable to the exposure session (or windowed appropriately).
4. The smaller arm has n ≥ 400. Below that, sequential math is honest but uninformative.

If any check fails, stop and surface the issue.

### Phase 3. Apply mSPRT (binary ship / no-ship)

mSPRT (Johari et al., 2017) generalises Wald's 1945 SPRT to the case where the effect size is unknown. The trick: instead of testing a single point alternative (e.g. "lift = 2pp exactly"), test a *mixture* over plausible alternatives, weighted by a prior. This gives a single log-likelihood ratio statistic that can be checked at every observation.

For a two-proportion test (conversion rate, control vs treatment):

1. **Define alpha and the mixture variance.** Standard choice: alpha = 0.05, mixture variance tau² ≈ MDE² (e.g. if you cared about detecting a 1pp lift, tau ≈ 0.01).
2. **Compute the running log-likelihood ratio.** At each new observation:
   ```
   logLR(n) = log( (1 / sqrt(1 + n·V/tau²)) ·
                   exp( (n·V·(diff)²) / (2·(tau² + n·V)) ) )
   ```
   where `n` is the per-arm sample size, `V` is the pooled variance of the proportion, and `diff` is the observed control-treatment difference.
3. **Boundaries.** Upper boundary = log(1/alpha) ≈ 3.00 for alpha = 0.05. Lower boundary is symmetric (log(alpha)) for two-sided rejection, or use 0 if you only stop for "treatment wins".
4. **Stopping rule.** If logLR > upper boundary → reject H0, ship treatment. If logLR < lower boundary → accept H0, kill treatment. Otherwise, continue.

Empirical validation from Statsig's deployment: across 50,000 A/A tests, false-positive rate stayed at ≤1.2% (well under the nominal 5%). Across true-effect tests, 58% of decisive results fired by the half-horizon mark, with ~84% of the power of a fixed-horizon test at the same final n.

In practice you do not hand-roll this; a library or the analytics platform computes logLR for you. Your job is to read it and apply the stopping rule honestly.

### Phase 4. Apply confidence sequences (always-valid CI on lift)

A confidence sequence (Waudby-Smith & Ramdas, 2021) is a sequence of confidence intervals, one per observation, such that the *probability that any of them fails to cover the true parameter* is at most alpha. Contrast with fixed-horizon CIs, where the coverage guarantee holds only at the single planned end.

The intervals are wider than fixed-horizon CIs at the same n (the cost of always-valid), but they tighten with sample size and never widen to uselessness. Practical use:

1. **Compute the lift estimate and its always-valid CI at each peek.** Most implementations use an asymptotic confidence sequence based on the empirical Bernstein inequality or a beta-binomial mixture.
2. **Stopping rule.** If the lower bound of the CI on (treatment − control) exceeds 0, ship treatment. If the upper bound is below 0, kill treatment. If the CI contains a meaningful minimum-effect threshold (e.g. 0.5pp), declare practical equivalence.
3. **Reading the CI.** Width is the honest signal. A CI of [+0.2pp, +4.1pp] after two weeks means "directionally positive but the magnitude is still anywhere from trivial to large". Do not paste the midpoint as the answer.

Confidence sequences shine when the user cares about *effect size*, not just direction. mSPRT shines when the user just wants "ship or not".

### Phase 5. Edge cases that break the math

Even with the correct framework, three patterns can produce misleading sequential reads:

1. **Multi-arm tests without correction.** Running control vs treatment_A vs treatment_B and applying mSPRT to each pairwise comparison inflates alpha across the family. Either use a multi-arm sequential test (one against all), or Bonferroni-correct alpha across the pairwise comparisons.
2. **Switching the metric mid-test.** mSPRT and confidence sequences guarantee alpha only for the metric you committed to. If the user defined the primary metric as "signups" but is now reading "revenue per exposed", the alpha guarantee is gone. Treat the new read as exploratory.
3. **Stopping based on a sliced result.** "It crossed the boundary for mobile users" is a slice, not the primary analysis. The alpha guarantee is on the overall comparison. Slices are hypothesis-generating; do not ship on them.

### Phase 6. Present the verdict

Mirror the `experiment-result-reader` Pyramid format, with sequential-specific fields:

```
VERDICT: <ship | kill | keep running, and why>

METHOD: <mSPRT | confidence sequence>

NUMBERS:
- control:    n=<exposed>, conversions=<converted>, rate=<rate>%
- treatment:  n=<exposed>, conversions=<converted>, rate=<rate>%
- observed lift: <pp>pp absolute, <%> relative
- sequential statistic: <logLR value | always-valid CI on lift>
- boundary / threshold: <value>
- days run / planned horizon: <X> / <Y>

CAVEATS:
- <SRM check>
- <seasonality / day-of-week if relevant>
- <metric-switch / multi-arm caveat if applicable>

WHAT TO DO NEXT:
- <ship treatment | kill treatment | keep running until <date or n>>
```

If the boundary has not been crossed, the answer is "keep running, do not over-read the direction". Sequential testing does not promise an early answer; it promises an honest one.

## Worked example: mSPRT, mid-flight peek at day 14

```
User: We launched a checkout copy test 14 days ago, planned 4 weeks.
      Treatment looks like it's converting at 13% vs control at 10%.
      Can we ship now or do we need to finish the 4 weeks?

Agent: [Phase 1: framework]

  Binary ship/no-ship call. Use mSPRT.

[Phase 2: setup verification]

  events.list(name="$exposure", group_by="variant", window=14d):
    - control:   8,012
    - treatment: 8,043
  SRM check: 49.95% / 50.05%, p>0.5, no mismatch.

  Conversion event confirmed as purchase_completed,
  attributed to exposure session.

  Smaller arm n = 8,012, well above the 400 threshold. Proceed.

[Phase 3: mSPRT applied]

  - control:    800 conv / 8,000 exposed = 10.00%
  - treatment: 1,040 conv / 8,000 exposed = 13.00%
  - observed absolute lift: +3.00pp
  - observed relative lift: +30.0%

  Mixture variance tau² set at MDE² = (0.01)² (test was designed
  to detect a 1pp lift).

  Running logLR over the 14-day window:
    - day 1:  logLR =  0.4
    - day 5:  logLR =  1.8
    - day 9:  logLR =  3.1  ← crossed upper boundary (log(1/0.05) ≈ 3.00)
    - day 14: logLR =  6.7

  Upper boundary was crossed on day 9 and has only widened since.

[Phase 4: confounders]

  Channel mix per variant (last 14d):
    - control:   organic 38%, paid 34%, direct 28%
    - treatment: organic 39%, paid 33%, direct 28%
  No meaningful mix shift.

  No metric switch (purchase_completed is the declared primary).
  Two-arm test, no multiple-comparison correction needed.

[Phase 5: verdict]

  VERDICT: Ship treatment. mSPRT crossed the upper boundary on day 9
  and has stayed above it for 5 consecutive days. Continuing the
  test to day 28 buys no additional decision quality; it costs 14
  more days of running an inferior variant on half the traffic.

  METHOD: mSPRT, alpha=0.05, tau²=(0.01)²

  NUMBERS:
  - control:   n=8,000, conv=800, rate=10.00%
  - treatment: n=8,000, conv=1,040, rate=13.00%
  - lift: +3.00pp absolute, +30.0% relative
  - logLR: 6.7 (boundary: 3.00)
  - days run / planned: 14 / 28

  CAVEATS:
  - No SRM, no channel mix shift, no metric switch.
  - 14 days covers two full weekly cycles; seasonality not a concern.

  WHAT TO DO NEXT:
  - Ship treatment. Document the early-stop decision and the sequential
    method used (alpha protection holds).
  - The 19 days of horizon saved is real; redeploy that traffic to
    the next test in the queue.
```

## Worked example: confidence sequence, ambiguous mid-flight read

```
User: Nudge banner test, 10 days in, planned 21. Treatment looks
      slightly up. Should we call it?

Agent: [Phase 1: framework]

  User asked "is it up", which is an effect-size question.
  Use a confidence sequence on the lift.

[Phase 2-3: pull + compute]

  - control:   n=4,200, conv=210, rate=5.00%
  - treatment: n=4,180, conv=234, rate=5.60%
  - observed lift: +0.60pp absolute, +12.0% relative
  - always-valid 95% CI on lift: [-0.4pp, +1.6pp]

[Phase 5: verdict]

  VERDICT: Do not call it. The always-valid CI on lift is
  [-0.4pp, +1.6pp] and contains 0. Direction is mildly positive
  but magnitude is anywhere from "slightly negative" to "small
  positive". Keep running.

  METHOD: confidence sequence, alpha=0.05

  NUMBERS:
  - control:   n=4,200, rate=5.00%
  - treatment: n=4,180, rate=5.60%
  - lift: +0.60pp, 95% always-valid CI [-0.4pp, +1.6pp]
  - days run / planned: 10 / 21

  CAVEATS:
  - SRM clean, no mix shift.
  - 10 days = ~1.4 weekly cycles; the +12% relative could easily
    be a midweek artifact.

  WHAT TO DO NEXT:
  - Keep running. Re-check at day 17 (two full cycles).
  - If at day 21 the CI still contains 0, the honest call is
    "no detectable effect at MDE"; do not chase a +12% headline.
```

## Traps to avoid

- **Quoting a fixed-horizon p-value next to a sequential one.** They mean different things and confuse the reader. Pick one framework per test and stick with it.
- **Reading the boundary on a slice.** mSPRT and confidence sequences guarantee alpha on the primary comparison. A boundary crossing on "mobile users only" is hypothesis-generating, not a ship signal.
- **Assuming sequential testing rescues underpowered tests.** It does not. At n<400/variant, neither logLR nor the CS width will cross anything decisive. The honest answer at small n is "wait".
- **Switching from fixed-horizon to sequential after seeing the data.** The alpha guarantee assumes the framework was chosen before peeking. Post-hoc framework switching is p-hacking with extra steps.
- **Stopping for "no effect" the moment the CI contains 0.** Confidence sequences widen at small n; a CI containing 0 at n=500 is the default state, not a kill signal. Kill only when the CI excludes the minimum-effect threshold from above (i.e. the upper bound is below your "worth shipping" floor).

## Cross-references

- **`experiment-result-reader`**: fixed-horizon read of a running test. Use that for the "did the variant win at the end?" question; use this skill for the "can we stop early?" question.
- **`bayesian-experiment-reader`**: alternative framework (posterior probability that treatment beats control). Bayesian methods are also always-valid under a different interpretation; pick by the user's mental model.
- **`analytics-diagnostic-method`**: provides the Pyramid Principle reporting template and the sample-size table this skill defers to for the n<400 threshold.
- **`metric-context-and-benchmarks`**: for judging whether the absolute conversion rate the test is producing is even in a plausible range before you trust the lift.

## Sources

- Wald, A. (1945). *Sequential Tests of Statistical Hypotheses*. The original SPRT. Background: [Sequential probability ratio test on Wikipedia](https://en.wikipedia.org/wiki/Sequential_probability_ratio_test).
- Johari, R., Koomen, P., Pekelis, L., Walsh, D. (2017). *Peeking at A/B Tests: Why It Matters, and What to Do About It*. The mSPRT paper: [arXiv:1512.04922](https://arxiv.org/abs/1512.04922).
- Statsig. *Sequential testing on Statsig*. mSPRT in production with empirical FPR validation across 50,000 A/A tests: [statsig.com/blog/sequential-testing-on-statsig](https://www.statsig.com/blog/sequential-testing-on-statsig).
- GrowthBook. *Sequential testing*. Confidence-sequence implementation reference: [docs.growthbook.io/statistics/sequential](https://docs.growthbook.io/statistics/sequential).
- Waudby-Smith, I., Ramdas, A. (2021). *Estimating means of bounded random variables by betting*. The modern confidence-sequence construction underpinning always-valid CIs.

## Tool invocations

The method above is platform-neutral. For the per-variant exposure, conversion, and per-day-rolling-rate queries you need to feed an mSPRT or confidence-sequence calculation, load the tool-map for the active platform: see [`tool-maps/`](../../tool-maps/) and the `tool_map:` field in `analytics-profile.md`. If the field is missing, run `analytics-profile-setup` to set it.
