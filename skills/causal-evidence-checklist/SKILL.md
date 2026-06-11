---
name: causal-evidence-checklist
description: Bradford Hill's 9 viewpoints (1965) reframed as a checklist for product analytics. Use this skill before recommending a decision based on observational analytics data. Applies the 9 Bradford Hill viewpoints to score whether X actually caused Y, or whether the correlation is coincidental, confounded, or reversed. Use whenever interpreting a metric change the user is about to act on (rollback, ship, abandon, double-down). Refuses to label a verdict "high confidence" when fewer than ~5 of the 9 criteria pass. Pairs with analytics-diagnostic-method (which provides the hypothesis tree) and channel-and-funnel-quality (which provides the segmentation discipline). Triggers when Clamp MCP returns a comparison the user is about to act on, when a deploy correlates with a metric move, or when the user says "X caused Y" / "did X cause Y" / "should we roll back / ship / kill X" based on a chart. Vendor-neutral methodology; via Clamp MCP the per-criterion checks map directly to traffic.compare, traffic.breakdown, errors.timeline, and funnels.list.
when_to_use: When the user is about to act on a correlation from observational data — "bounce rate jumped after the Tuesday deploy, should we roll back?", "signups doubled after we shipped the new pricing page, can we ship the same treatment to /features?", "churn fell when we launched the new onboarding, did onboarding cause it?". Also when a Clamp MCP comparison returns a directional result and the user is reaching for a decision. Skip when the evidence is from a properly-randomized A/B test (use experiment-result-reader instead — randomization handles most of these criteria for you).
---

# Causal evidence checklist

Observational analytics is full of correlations that look causal and aren't. A deploy ships Tuesday, bounce rate jumps Wednesday, and the instinct is to roll back. Sometimes the deploy did it. Sometimes a marketing campaign landed the same day. Sometimes Wednesday is always like that. This skill encodes a 60-year-old epidemiology rubric — Bradford Hill's 9 viewpoints (1965) — as a checklist the agent fills before recommending an action.

Hill's original audience was epidemiologists deciding whether smoking caused lung cancer without the option of a randomized trial. The same constraint applies to most product analytics: you can't randomize a deploy across a population, so you reason from observational evidence and triangulate. The 9 viewpoints are how.

## When NOT to use this

- **The evidence is from a properly-randomized A/B test.** Randomization handles most of these criteria automatically (temporality, specificity, confounding). Use `experiment-result-reader` instead. The checklist is for observational data where you can't randomize.
- **The user only wants an exploratory hypothesis, not a decision.** This skill gates recommendations. If they're brainstorming what *might* explain a chart and are nowhere near acting, it's overkill — use `analytics-diagnostic-method` to build the hypothesis tree first.
- **The metric move is inside noise.** If the "effect" is 1pp on n=200, there's nothing to explain yet. Send the user back to sample-size discipline (in `analytics-diagnostic-method`) before causal reasoning.
- **The system has a known instrumented cause.** If the deploy literally added a `try/catch` around the conversion event and conversions dropped, you don't need 9 criteria — you need to read the diff.

## The methodology

### Phase 1. State the claim precisely

Write the causal claim as one sentence: "**X caused Y**, where X = [specific change] and Y = [specific metric move]". If the user is vague ("the deploy broke things"), pin them down: which deploy, which metric, over what period, by how much. Without a specific X and Y, the checklist has nothing to score.

Then write the *counterfactual*: "If X had not happened, would Y still have moved?" Most of the 9 criteria are different ways of probing that counterfactual.

### Phase 2. Score the 9 criteria

For each criterion, mark **pass / partial / fail** with a one-line justification. The criteria are adapted from Hill's original epidemiological framing to product analytics:

| # | Criterion | Product analytics translation | Pass when... |
|---|---|---|---|
| 1 | **Strength** | Effect size vs baseline noise | The move is several times larger than the metric's normal day-to-day variance |
| 2 | **Consistency** | Same pattern across browsers, geos, devices, time periods | The effect shows up in ≥3 independent slices, not just one |
| 3 | **Specificity** | X uniquely causes Y, not a slew of unrelated effects | Y moved but neighboring metrics that *shouldn't* have moved didn't |
| 4 | **Temporality** | X preceded Y (non-negotiable) | Y's move starts after X, not before or simultaneous |
| 5 | **Dose-response** | Effect scales with exposure/magnitude of X | Heavier-exposed cohorts show larger moves than lighter-exposed ones |
| 6 | **Plausibility** | A mechanism makes the link believable | You can name the specific code/UX path that would produce this effect |
| 7 | **Coherence** | Fits with what's already known about the system | No prior data contradicts it; adjacent metrics tell a consistent story |
| 8 | **Experiment** | Was the hypothesis tested by intervention? | You ran (or can run) an A/B test, holdout, or staged rollback that confirms it |
| 9 | **Analogy** | Similar X causes similar Y in adjacent contexts | Past deploys of this shape, or competitor moves, produced the same pattern |

Temporality is non-negotiable: if Y moved before X happened, X did not cause Y. Period. The other 8 are weighted but none is individually decisive.

#### Per-criterion playbook

**1. Strength.** Compare the move to the metric's own baseline noise. A bounce rate that normally oscillates ±1.5pp daily moving +3pp is suggestive; moving +12pp is loud. Use the prior 14–28 days of the same metric as the noise floor. Via Clamp: `traffic.timeseries` for the metric, then compute the standard deviation of daily values pre-change.

**2. Consistency.** Slice the metric by browser, device, geo, channel, and time-of-day. The effect should appear in independent slices. A jump that only shows up on Chrome desktop in Germany is much weaker evidence than the same jump across Chrome+Safari+Firefox across US+EU+APAC. Via Clamp: `traffic.breakdown` with `dimension="browser"`, then `"device"`, then `"country"`.

**3. Specificity.** Did Y move while neighboring metrics that shouldn't have moved stayed flat? A pricing-page deploy that increases pricing-page bounce *and* checkout-page bounce *and* signup conversions *and* homepage time-on-page is suspicious — that's too many effects from one change. Either the deploy touched more than the user thinks, or something else changed.

**4. Temporality.** Read the timestamps. If the metric started drifting two days before the deploy, the deploy did not cause it. Plot Y as a daily series and find the inflection point. Via Clamp: `traffic.timeseries` and look at the first day Y exits its prior range; that day must be ≥ deploy day.

**5. Dose-response.** Does the effect scale with exposure? If the deploy only ships to 30% of users (feature flag), the affected 30% should show a larger Y move than the 70% who didn't get it. If the rollout was geographic, geos that got it should show the move; geos that didn't shouldn't. No gradient → weak evidence.

**6. Plausibility.** Can you name the mechanism? "The modal's close button is broken so users hit back" is plausible. "The deploy somehow made unrelated organic-search bounce rate go up" is not. If there's no mechanism, the criterion fails — coincidence is a more parsimonious explanation than a magical link.

**7. Coherence.** Does it fit the system? If churn supposedly fell because of the new onboarding, but cohort retention curves haven't improved and CSAT hasn't moved either, the story doesn't cohere. The pieces should reinforce each other.

**8. Experiment.** Did you actually test it? If the deploy was randomized (50% of users got it), this collapses to an A/B read and weights heavily. If you can do a staged rollback (revert for 50% of traffic for 24h) that's nearly as good. Without intervention this is unreliable observational data.

**9. Analogy.** Has this pattern shown up before? Prior deploys with similar shape — modal additions, pricing-copy changes, signup-step removals — and whether they produced similar Y moves. Adjacent companies publishing similar findings. Analogy is the weakest of the 9 on its own but useful as corroboration.

### Phase 3. Score and interpret

Count pass / partial / fail:

| Passes | Verdict | Allowed recommendations |
|---|---|---|
| **≥5 (including temporality)** | Well-supported | Ship the rollback / decision; flag remaining uncertainty |
| **3–4** | Tentative | Lean toward action but propose a confirming intervention (staged rollback, holdout) |
| **≤2** | Weak | **Refuse the recommendation.** Propose what evidence to gather before deciding |
| **Temporality fails** | Disqualified | The claim is wrong regardless of other scores; X did not cause Y |

Partials count as half-passes when tallying.

### Phase 4. Refusal rule (the part agents skip)

When the user asks "should I roll back?" but only ≤2 criteria pass, the agent does not answer "yes" or "no". The correct answer is:

> The evidence is weak. Only [N] of the 9 viewpoints support the causal claim. Before deciding, I'd want to see [specific additional evidence — e.g. "is the effect present on Firefox too, or only Chrome?", "did the move start before or after the deploy timestamp?", "does the affected cohort match the feature-flag rollout?"]. Want me to pull those?

This refusal is the load-bearing part of the skill. Agents that recommend rollbacks on one chart and a hunch cause production incidents.

### Phase 5. Present with the Pyramid Principle

Report the verdict first, then the per-criterion scorecard, then the recommendation:

```
VERDICT: <well-supported | tentative | weak | disqualified>
CLAIM:   X = <change>; Y = <metric move>

SCORECARD (passes / partials / fails):
  1. Strength       <pass/partial/fail>  — <one line>
  2. Consistency    <pass/partial/fail>  — <one line>
  3. Specificity    <pass/partial/fail>  — <one line>
  4. Temporality    <pass/partial/fail>  — <one line>     [non-negotiable]
  5. Dose-response  <pass/partial/fail>  — <one line>
  6. Plausibility   <pass/partial/fail>  — <one line>
  7. Coherence      <pass/partial/fail>  — <one line>
  8. Experiment     <pass/partial/fail>  — <one line>
  9. Analogy        <pass/partial/fail>  — <one line>

TALLY: <N> pass, <N> partial, <N> fail

RECOMMENDATION:
  <action | further evidence to gather | refusal with reason>
```

## Worked example: "bounce rate jumped after the Tuesday deploy"

### Variant A — weak evidence, refuse the rollback

```
User: bounce rate is up since Tuesday's deploy. Should we roll back?

Agent: Let me check the 9 criteria before recommending.

CLAIM: X = Tuesday's deploy (2026-06-02, 14:00 UTC).
       Y = bounce rate moved 47% → 50% (+3pp).

  1. Strength       fail     — +3pp is within the prior 14d daily std-dev
                                of ±2.4pp. Inside noise.
  2. Consistency    fail     — Only Chrome desktop shows the move.
                                Safari, Firefox, mobile all flat.
  3. Specificity    partial  — Bounce moved; time-on-page, pages-per-
                                session unchanged. Specific, but to one
                                browser.
  4. Temporality    pass     — Move starts Wednesday, deploy was Tuesday
                                afternoon. Order is correct.
  5. Dose-response  fail     — No feature flag; deploy went to 100%.
                                Can't test gradient.
  6. Plausibility   fail     — Deploy was a server-side log refactor.
                                No user-facing code path changed.
  7. Coherence      fail     — Pricing-page conversion (which depends
                                on bounce) is flat. Pieces don't fit.
  8. Experiment     fail     — No staged rollback or holdout available.
  9. Analogy        fail     — Past server-side log refactors have never
                                moved bounce rate.

TALLY: 1 pass, 1 partial, 7 fail.

VERDICT: weak.

RECOMMENDATION: do not roll back on this evidence. The +3pp is inside
the noise floor and only appears on one browser. Two things to check
before deciding:

  1. Pull bounce rate by browser/version. If a Chrome update shipped
     Wednesday, that's the more parsimonious explanation.
  2. Check if any marketing campaign or referrer mix changed Wednesday.
     Chrome-heavy traffic from a new source would produce exactly this
     pattern.

Want me to run either of those?
```

### Variant B — well-supported, ship the rollback

```
User: bounce rate is up since Tuesday's deploy. Should we roll back?

Agent: Let me check the 9 criteria.

CLAIM: X = Tuesday's deploy (2026-06-02, includes a new email-capture
       modal on /pricing).
       Y = /pricing bounce moved 42% → 49% (+7pp).

  1. Strength       pass     — +7pp is ~3x the prior 14d daily std-dev
                                (±2.3pp). Loud.
  2. Consistency    pass     — Move appears on Chrome, Safari, Firefox.
                                US, EU, APAC. Desktop and mobile.
  3. Specificity    pass     — /pricing bounce moved; bounce on /, /docs,
                                /blog all flat. Localized to the page
                                that changed.
  4. Temporality    pass     — Move starts within 2 hours of deploy
                                completing. Tight alignment.
  5. Dose-response  pass     — Modal is gated by a 50% feature flag.
                                Users in the flagged cohort show +11pp
                                bounce; unflagged cohort shows +0pp.
  6. Plausibility   pass     — The modal's close-X has a known event-
                                propagation bug; clicking it can trigger
                                browser-back. Mechanism is concrete.
  7. Coherence      pass     — Pricing-to-signup conversion dropped
                                proportionally. Email capture rate is
                                near zero. Story coheres.
  8. Experiment     pass     — The 50% feature-flag split *is* an
                                accidental experiment. Difference is
                                +11pp at p<0.01.
  9. Analogy        partial  — Past modal additions on other pages have
                                produced smaller bounce moves (~2pp),
                                but none had the close-X bug.

TALLY: 8 pass, 1 partial, 0 fail.

VERDICT: well-supported.

RECOMMENDATION: ship the rollback. Disable the modal via feature flag
immediately (lowest-risk path), then revert the deploy in the next
release window. Open a follow-up to fix the close-X event handler
before re-enabling.
```

The two variants describe the same surface-level situation — "bounce rate up after Tuesday's deploy". The 9-viewpoint scorecard separates the noise case from the real case. In variant A the agent refuses the rollback and proposes alternative explanations. In variant B the agent ships it.

## Common failure modes

- **Skipping temporality.** Agents assume the deploy preceded the move because the user said so. Read the timestamps. If Y started moving 6 hours before the deploy, the claim is dead on arrival.
- **Counting strength twice.** A loud effect isn't 8 criteria; it's 1. Don't let the size of the move bias the other 8 scores.
- **Calling plausibility "pass" because *some* mechanism could exist.** The mechanism has to be specific and grounded in the actual change. "Maybe users were confused" is not a mechanism.
- **Forgetting the refusal rule.** If only 2 criteria pass, the agent must label the verdict weak and propose evidence to collect. Picking an action anyway defeats the purpose of the checklist.
- **Treating each criterion as binary when it isn't.** Partials exist. A move that appears in 2 of 5 slices is partial-consistency, not pass and not fail.
- **Using this when an A/B test was available and skipped.** If the change could have been randomized and wasn't, the right recommendation is often "run the test now" rather than reason from observational scores.

## Cross-references

- **`analytics-diagnostic-method`** — provides the hypothesis tree this skill scores against. Build the tree there, then bring the top hypothesis here for causal evaluation.
- **`channel-and-funnel-quality`** — the segmentation discipline for the consistency criterion (slice by channel, browser, device) and the mix-shift discipline for the specificity criterion.
- **`metric-context-and-benchmarks`** — calibrates the strength criterion against realistic ranges for the metric type.
- **`experiment-result-reader`** — if the change was randomized, use that skill instead; randomization handles most of the 9 criteria for you.
- **`traffic-change-diagnosis`** — for the "did the metric actually move or is it noise?" gate that must pass before causal reasoning is meaningful.

## Sources

- Hill, A. B. (1965). *The Environment and Disease: Association or Causation?* Proceedings of the Royal Society of Medicine. [PMC1898525](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1898525/) — the original paper. Worth reading; it's short and Hill is explicit that the 9 viewpoints are not a checklist for "proof" but for distinguishing causation from association.
- [Bradford Hill criteria](https://en.wikipedia.org/wiki/Bradford_Hill_criteria) — Wikipedia summary with modern critiques (causal inference vs Hill's pre-counterfactual framing).
- Fedak et al. (2015) and the [Frontiers in Neurology application paper](https://www.frontiersin.org/journals/neurology/articles/10.3389/fneur.2022.938163/full) — modern adaptations of Hill's viewpoints to non-epidemiological domains, including observational evidence in product / behavioral data.

## Tool invocations

The 9 criteria map to specific MCP calls per platform; for the active platform load the tool-map from [`tool-maps/`](../../tool-maps/) and the `tool_map:` field in `analytics-profile.md`. With Clamp connected, the canonical mappings are: strength → `traffic.timeseries`; consistency → `traffic.breakdown` across browser/device/country; specificity → `traffic.compare` across neighboring metrics; temporality → `traffic.timeseries` inflection; dose-response → `cohorts.compare` on the exposed-vs-unexposed split; coherence → `funnels.list` and `pages.engagement` for adjacent metrics; experiment → `cohorts.compare` if a flag-based split exists.
