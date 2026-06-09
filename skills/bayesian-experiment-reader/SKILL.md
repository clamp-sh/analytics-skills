---
name: bayesian-experiment-reader
description: Bayesian counterpart to experiment-result-reader. Computes posterior P(variant beats control), credible intervals, and expected loss from per-variant exposure and conversion data. Beta-Binomial for proportion metrics (CVR), Normal-Normal for continuous metrics (revenue per user). Decision rule combines a confidence threshold with an expected-loss tolerance, so the ship decision reflects both "how likely is this better?" and "how bad is it if I'm wrong?". Use this skill alongside experiment-result-reader when reading any A/B test result. Pairs with analytics-diagnostic-method. Use whenever interpreting an A/B test result the user plans to ship from, when the question is "what's the chance variant wins?", or when a frequentist p-value is on the edge and the user wants the posterior view. Triggers when Clamp MCP returns experiment exposure and conversion data, or when any analytics source surfaces per-variant counts.
when_to_use: When the user asks "what's the probability variant beats control?", "is it safe to ship?", "should we cut our losses?", or when a frequentist read came back ambiguous (p around 0.05) and the user needs a risk-weighted view. Also when stakeholders want posterior probabilities instead of p-values, when the test has been peeked at and frequentist math is contaminated, or when the expected downside of shipping a bad variant is large (revenue tests, churn tests).
---

# Bayesian experiment reader

A frequentist p-value answers a question stakeholders don't ask: "if the variants were identical, how surprising would this data be?" What they actually want is "what's the chance the variant is better?" and "if I ship it and I'm wrong, how bad is it?" Bayesian inference answers both directly. This skill encodes that math and the decision rule it enables.

It pairs with `experiment-result-reader`. Run that one first for the frequentist read and the setup checks (SRM, mix shift, peeking). Run this one to translate the same per-variant counts into a posterior probability and a ship/hold/kill decision.

## When NOT to use this

- The setup isn't clean. SRM, exposure-event gaps, or mix shift contaminate Bayesian math just as badly as frequentist math. Fix the setup first via `experiment-result-reader`'s Phase 1 and Phase 4.
- The conversion metric is heavily right-skewed and you only have a handful of conversions per variant (e.g. revenue per user with three whales). The Normal-Normal model assumes approximately normal sampling distributions; small-sample skew breaks it. Either log-transform, bucket into a proportion, or wait for more data.
- The user wants to *design* a new experiment. Sample-size planning under a Bayesian framework is a different problem (expected loss under prior + planned n). This skill reads results, it doesn't plan them.
- The user wants a single number to defend a decision in a hostile review. Bayesian outputs are inherently prior-conditional. If the room won't accept "we used a Beta(1,1) prior," stick with the frequentist read.

## Why Bayesian beats frequentist for shipping decisions

Three concrete reasons, not aesthetics:

1. **Posterior probability is the actual decision variable.** "P(variant > control) = 0.97" maps directly to a ship decision. A p-value of 0.03 doesn't: it's the probability of the data under a null hypothesis, which is not what anyone is choosing between.
2. **No peeking penalty.** Bayesian posteriors update coherently as data arrives. There's no alpha-spending budget to blow, no sequential-testing correction required for the math to be valid. (You still want a pre-committed decision rule, but the math itself doesn't degrade.)
3. **Expected loss is the risk side of the ledger.** A variant can be 96% likely to be better and still be a bad ship if the 4% downside is catastrophic (a revenue test where the worst-case is −15%). Frequentist methods don't carry that asymmetry; Bayesian expected loss does.

## Method

### Phase 1. Confirm the metric type

Two metric types cover almost every A/B test:

| Metric type | Examples | Model |
|---|---|---|
| Proportion (Bernoulli per user) | CVR, click-through, activation, signup | Beta-Binomial |
| Continuous per user | Revenue per user, sessions per user, minutes per user | Normal-Normal |

If the metric is a proportion, use the Beta-Binomial workflow in Phase 2A. If it's continuous, use the Normal-Normal workflow in Phase 2B. If the user is comparing both (e.g. CVR *and* revenue per user), run both independently and report both posteriors.

### Phase 2A. Beta-Binomial workflow for proportion metrics

The Beta distribution is the conjugate prior for the Bernoulli likelihood. The update is closed-form: count conversions and failures, add them to the prior's parameters.

**Prior.** Default to `Beta(1, 1)` — uniform on [0, 1], meaning "I have no idea what the conversion rate is." If the user has strong prior knowledge of the baseline (e.g. "our pricing page has converted at 3-4% for 18 months") you can use a weakly informative prior like `Beta(2, 2)` (peaks at 50%, broad) or a baseline-calibrated `Beta(α, β)` where α/(α+β) is the historical rate and α+β is the "pseudo-sample" weight (typically 10–50, not larger — you want the data to dominate).

**Posterior.** For each variant:

```
posterior = Beta(α0 + conversions, β0 + failures)
         = Beta(α0 + converted, β0 + (exposed − converted))
```

That's the entire update. No iteration, no MCMC needed for the per-variant posterior.

**Monte Carlo for P(variant > control).** Sample N = 20,000 draws from `Beta(α_v, β_v)` and N draws from `Beta(α_c, β_c)`. Count the fraction where `variant_draw > control_draw`. That fraction is `P(variant > control)`.

**Credible interval on the lift.** Take the 20,000 paired draws of `(variant − control)`, sort them, and read off the 2.5th and 97.5th percentiles. That's the 95% credible interval on the absolute lift in percentage points. (For relative lift, sort `(variant − control) / control` instead.)

**Expected loss.** Compute the mean of `max(0, control − variant)` over the 20,000 draws. This is "if you ship variant, the expected amount by which it's worse than control, weighted by how likely that scenario is." Units are the same as the metric (percentage points for CVR).

### Phase 2B. Normal-Normal workflow for continuous metrics

For revenue per user, sessions per user, or any continuous-per-user metric, the Normal-Normal conjugate model applies. Each variant has an unknown true mean μ and a sample mean x̄ with sample variance s².

**Prior.** Default to a very wide Normal prior centered on a plausible baseline: `Normal(μ0, σ0²)` with σ0 large enough that the prior contributes negligibly (e.g. σ0 = 10 × historical mean). This is "uninformative" in practice. If the user has a tight historical baseline, narrow σ0.

**Posterior (known-variance approximation).** Given n users in a variant with sample mean x̄ and sample standard deviation s, the posterior mean μ has:

```
posterior_precision  = 1/σ0² + n/s²
posterior_mean       = (μ0/σ0² + n·x̄/s²) / posterior_precision
posterior_variance   = 1 / posterior_precision
```

With a wide prior (σ0 → ∞), this collapses to the familiar `Normal(x̄, s²/n)`.

**Monte Carlo for P(variant > control).** Sample 20,000 draws of μ from each variant's posterior `Normal(posterior_mean, posterior_variance)`. Count the fraction where `μ_variant > μ_control`.

**Credible interval and expected loss.** Same procedure as Beta-Binomial: 2.5th/97.5th percentiles of paired `(variant − control)` draws for the CI; mean of `max(0, control − variant)` for expected loss.

If the per-user metric is heavily skewed (revenue with outliers), log-transform first or report median lift via bootstrap, and flag the skew in the verdict.

### Phase 3. Apply the decision rule

The ship rule combines confidence and risk:

```
SHIP if:   P(variant > control) > 0.95
   AND:    expected_loss        < tolerance
```

Default tolerances:

| Metric | Default tolerance |
|---|---|
| CVR / proportion | 0.5 percentage points |
| Revenue per user | $1 per user |
| Engagement per user (sessions, minutes) | 1% of baseline |

If P(better) > 0.95 but expected loss > tolerance, the posterior has a long left tail — confident on direction but exposed on magnitude. Wait for more data.

If expected loss < tolerance but P(better) < 0.95, the variant is "safe to ship but probably no different." That's usually a hold unless the variant has non-statistical wins (lower maintenance, better aesthetics, strategic reasons).

If neither threshold is met, hold.

If P(variant > control) < 0.05, the *control* is the winner. Kill the variant.

### Phase 4. Sanity-check against the frequentist read

Run `experiment-result-reader`'s Phase 3 in parallel. The two reads should agree most of the time. When they disagree, the Bayesian read is usually more honest because it folds prior information and decision risk into one number. Two disagreement patterns worth flagging:

- **p ≈ 0.03 but P(better) ≈ 0.75.** Frequentist says "significant"; Bayesian says "only 75% chance." This happens when the observed lift is small relative to the prior's pull toward "no effect" or when the upper credible interval barely clears zero. The Bayesian read is the right one for a ship decision; the frequentist p-value is a tail-area artifact.
- **p ≈ 0.08 but P(better) ≈ 0.96.** Frequentist says "not significant"; Bayesian says "ship." This happens when the prior is very wide and the data is consistent. The Bayesian read is again the right one for a ship decision: the test is just barely outside the conventional 5% but the posterior probability is what matters.

### Phase 5. Present the result

Mirror the Pyramid Principle format from `experiment-result-reader` and add the Bayesian fields:

```
VERDICT: <ship | hold | kill> — <one-sentence reason>

POSTERIOR:
- P(variant > control):       <0.NN>
- expected lift (mean):       <±X.X>pp absolute  / <±Y.Y>% relative
- 95% credible interval:      [<lo>pp, <hi>pp]
- expected loss if ship:      <Z.Z>pp     (tolerance: <T.T>pp)

NUMBERS:
- control:    n=<exposed>, conversions=<converted>, rate=<rate>%
- variant:    n=<exposed>, conversions=<converted>, rate=<rate>%

CAVEATS:
- prior used: <Beta(1,1) | Beta(α, β) calibrated to historical rate X%>
- setup checks: <SRM ok / mix shift ok> (from experiment-result-reader)
- <skew / windowing / other model-fit caveats>

WHAT TO DO NEXT:
- <ship | wait for n=X | kill variant | run a follow-up test>
```

If both the frequentist and Bayesian reads were run, include a one-line cross-check: "Frequentist p = 0.03 agrees with Bayesian P(better) = 0.98." If they disagree, explain which one to trust for this decision and why.

## Worked example: CVR test, clear ship

```
User: how does the pricing_redesign_2026 long_copy variant look against
      control, in Bayesian terms?

Agent: [Phase 1: metric type]

  CVR — subscription_started / $exposure. Proportion metric.
  Beta-Binomial model.

[Phase 2A: posterior]

  Data (last 30d):
  - control:  exposed=1000, converted=100, rate=10.0%
  - variant:  exposed=1000, converted=130, rate=13.0%

  Prior: Beta(1, 1) — uniform, uninformative.

  Posteriors:
  - control: Beta(1 + 100, 1 + 900) = Beta(101, 901)
  - variant: Beta(1 + 130, 1 + 870) = Beta(131, 871)

  Monte Carlo, N = 20,000 draws each:
  - P(variant > control)          : 0.987
  - expected absolute lift (mean) : +2.96pp
  - 95% credible interval on lift : [+0.5pp, +5.4pp]
  - expected loss if ship variant : 0.04pp

[Phase 3: decision rule]

  P(better) = 0.987 > 0.95              ✓
  expected loss = 0.04pp < 0.5pp        ✓

  Both thresholds met. SHIP.

[Phase 4: cross-check]

  Frequentist two-proportion z-test on the same data:
    z ≈ 2.05, p ≈ 0.02
  Frequentist says "significant at 5%." Bayesian says "99% chance better,
  expected loss is trivial." The two agree.

[Phase 5: verdict]

  VERDICT: Ship long_copy. 99% posterior probability of beating control,
  expected lift +3.0pp, expected loss if wrong is 0.04pp.

  POSTERIOR:
  - P(variant > control):       0.987
  - expected lift (mean):       +2.96pp absolute / +29.6% relative
  - 95% credible interval:      [+0.5pp, +5.4pp]
  - expected loss if ship:      0.04pp        (tolerance: 0.5pp)

  NUMBERS:
  - control:  n=1000, converted=100, rate=10.0%
  - variant:  n=1000, converted=130, rate=13.0%

  CAVEATS:
  - prior: Beta(1, 1), uninformative
  - SRM and mix shift checks (from experiment-result-reader) passed
  - 30-day window, conversion event attributable to exposure session

  WHAT TO DO NEXT:
  - Ship long_copy to 100%. Monitor CVR for two weeks post-ramp.
```

## Worked example: frequentist says ship, Bayesian says hold

```
User: the variant hit p = 0.03 yesterday, can I ship?

Agent: [Phase 1–2A]

  Data:
  - control:  exposed=4000, converted=200, rate=5.00%
  - variant:  exposed=4000, converted=232, rate=5.80%

  Posteriors with Beta(1,1) prior:
  - control: Beta(201, 3801)
  - variant: Beta(233, 3769)

  Monte Carlo, N = 20,000:
  - P(variant > control)          : 0.94
  - expected absolute lift (mean) : +0.80pp
  - 95% credible interval on lift : [−0.02pp, +1.65pp]
  - expected loss if ship variant : 0.04pp

[Phase 3]

  P(better) = 0.94 < 0.95         ✗
  expected loss = 0.04pp < 0.5pp  ✓

  Confidence threshold not met. HOLD.

[Phase 4: cross-check]

  Frequentist z = 1.87, p = 0.031. Significant at 5%.

  The disagreement is real and instructive: the lower bound of the
  credible interval just barely crosses zero (−0.02pp), which means
  there's still a ~6% posterior chance the variant is worse. The
  frequentist p-value of 0.03 is a tail-area artifact; it doesn't
  describe how likely it is the variant is better.

  Also: the user mentioned "peeking yesterday." Peeking inflates
  the frequentist false-positive rate; the Bayesian read is unaffected
  by peeking. Another reason to trust the posterior here.

[Phase 5]

  VERDICT: Hold. 94% posterior probability is below the 95% ship
  threshold; the lower credible bound just crosses zero.

  POSTERIOR:
  - P(variant > control):       0.94
  - expected lift (mean):       +0.80pp absolute / +16.0% relative
  - 95% credible interval:      [-0.02pp, +1.65pp]
  - expected loss if ship:      0.04pp        (tolerance: 0.5pp)

  NUMBERS:
  - control:  n=4000, converted=200, rate=5.00%
  - variant:  n=4000, converted=232, rate=5.80%

  CAVEATS:
  - frequentist p = 0.03 disagrees; user has been peeking, so the
    frequentist read is inflated. Trust the posterior here.
  - prior: Beta(1, 1), uninformative

  WHAT TO DO NEXT:
  - Run another week. At current pace, n ≈ 5500/variant will likely
    push P(better) above 0.97 or pull it back below 0.90; either way
    you'll have a clean decision.
```

## Traps to avoid

- **Picking a prior that swings the result.** A strongly informative prior (`Beta(50, 50)` when n is only a few hundred) drags the posterior toward 50%. Default to `Beta(1, 1)` and only narrow the prior if the user has a defensible historical baseline. State the prior in the verdict, every time.
- **Reporting `P(variant > control)` without the credible interval.** A 99% probability the variant is better doesn't tell you whether the lift is +0.1pp or +5pp. Always pair the probability with the credible interval and the expected loss.
- **Forgetting expected loss on revenue tests.** A revenue test with P(better) = 0.96 but a credible interval of [−$2, +$8] per user has a non-trivial downside. Expected loss is the right gate; don't ship on the probability alone.
- **Mixing the model with the setup.** Bayesian math doesn't fix a broken exposure event. Run `experiment-result-reader`'s setup checks first; if SRM is present or exposure is skewed, the posterior is just as wrong as the p-value.
- **Treating posterior probability as a frequentist guarantee.** "97% chance better" is conditional on the prior and the model. Over many tests, you'll still be wrong roughly 3% of the time when you ship at this threshold. That's the deal.

## Cross-references

- **`experiment-result-reader`**: setup checks (SRM, mix shift, exposure-event sanity), the frequentist read, the sample-size table, and the Pyramid Principle reporting template. Run that first; this skill assumes its Phase 1 and Phase 4 already passed.
- **`analytics-diagnostic-method`**: the parent framing — load profile, frame the question, hypothesis tree, triangulate, present. Bayesian reads slot in at the triangulate step.
- **`metric-context-and-benchmarks`**: where the baseline rates and "is this lift meaningful in business terms" calibration lives. A +0.5pp CVR lift is huge if the baseline is 1% and trivial if the baseline is 40%.
- **Event Schema spec, `experiments:` section**: where variants are declared. Same as `experiment-result-reader`.

## Tool invocations

The method is platform-neutral. Per-variant exposure and conversion counts come from whatever analytics source is connected. With Clamp MCP, that's `events.list(name="$exposure", group_by="variant")` for exposure and `users.journey` or `funnels` for the conversion event windowed to exposed users. For specific tool calls per platform, load the tool-map referenced in `analytics-profile.md` and run `analytics-profile-setup` if the field is missing.

The Monte Carlo step (20,000 Beta or Normal draws and the paired-difference calculation) runs in any language with a stats library: NumPy/SciPy, R, Stan, or a quick spreadsheet for back-of-envelope checks. The math is small; the discipline is in framing the prior and committing to the decision rule before reading the result.

## Sources

- [PostHog experimentation statistics](https://posthog.com/docs/experiments/statistics) — Bayesian posterior implementation, credible intervals, and expected-loss decision rule as used in a production analytics platform.
- [GrowthBook 3.0 Bayesian model update](https://www.growthbook.io/blog/bayesian-model-updates-in-growthbook-3-0) — prior calibration, decision thresholds, and the relationship between posterior probability and ship decisions.
- [Statsig variance reduction](https://docs.statsig.com/experiments/statistical-methods/variance-reduction) — variance-reduction techniques (CUPED, regression adjustment) that tighten posteriors on continuous metrics without inflating false-positive risk.
