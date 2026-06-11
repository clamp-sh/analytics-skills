---
name: causal-query-classifier
description: Pearl's three-rung causal hierarchy as a query classifier. Tags every analytics question as rung-1 (association, P(Y|X)), rung-2 (intervention, P(Y|do(X))), or rung-3 (counterfactual, P(Y_x|Y',X')) before answering. Refuses to escalate a rung-1 observational finding into a rung-2 ship/kill recommendation without naming an identification strategy (back-door, instrumental variable, DiD, RDD, synthetic control). Use this skill whenever interpreting an analytics question that asks why or what-if, to classify it on Pearl's causal hierarchy before answering. Pairs with analytics-diagnostic-method. Triggers when Clamp MCP returns a comparison or trend that the user is about to act on, so the agent labels the claim's rung explicitly instead of laundering correlation into causation. Works with any observational source; Clamp MCP is the canonical integration via traffic.compare, funnels.list, and cohorts.compare.
when_to_use: When the user asks "did X cause Y", "what if we ship Z", "would CVR have moved if we hadn't launched", "is the lift from the new page real", or any question shaped as a counterfactual or intervention. Also when the user is about to act on a comparison or trend that came back from Clamp MCP (or any analytics tool) and wants a yes/no recommendation rather than a description.
---

# Causal query classifier

Most analytics arguments lose at the question, not at the data. Someone shipped a new pricing page, CVR went up the same week, and the deck says "the page lifted CVR by 18%." The data says nothing of the sort — it says CVR was higher the week after launch. Pearl's three-rung causal hierarchy gives you a vocabulary for catching that slide before it happens.

This skill makes the rung explicit. Every question is classified before it's answered. Rung-1 questions get rung-1 answers. Rung-2 questions get either a real identification strategy or a refusal to make the claim.

## When NOT to use this

- The user is asking a purely descriptive question with no decision attached: "what's our checkout CVR this month?". That's rung-1 by construction; classification is overhead. Just answer it.
- A randomized experiment is already running and you're reading its result. Randomization handles identification; load `experiment-result-reader` instead.
- The user wants help designing an experiment. Use experiment-design tooling; this skill is for interpreting questions, not specifying tests.
- You're inside a forecasting task (rung-1 prediction of the future), not a causal one. Predictions are rung-1; "what would the metric have been if we'd done X instead" is rung-3.

## Background: Pearl's three rungs in plain language

Judea Pearl's hierarchy ranks queries by what they require of the data. Each rung subsumes the one below.

### Rung 1 — Association: P(Y | X)

What is the relationship between two observed variables, exactly as the world has shown them to us. No intervention, no counterfactual. Pure observation.

- "What's our checkout CVR?" → P(checkout | session)
- "How does CVR vary by device?" → P(checkout | device)
- "Mobile CVR is 1.8%, desktop is 3.6%." → joint distribution, descriptive only.

Rung-1 claims are always defensible from the data. They are also always silent about *why* the pattern holds. Mobile users may convert lower because mobile is worse, or because mobile attracts top-of-funnel browsers, or because the checkout form is broken on Safari. Rung-1 cannot distinguish these.

### Rung 2 — Intervention: P(Y | do(X))

What would Y look like if we *forced* X to a specific value, holding everything else as it would have been. `do(X)` is Pearl's notation for an external setting of X — surgery on the causal graph that severs X from its usual causes.

- "If we ship the new pricing page to everyone, what happens to CVR?" → P(CVR | do(new_page))
- "If we double ad spend on Google, what's the lift on signups?" → P(signups | do(spend=2x))
- "Does adding social proof on the homepage move CVR?" → P(CVR | do(social_proof=on))

P(Y | do(X)) is generally **not** equal to P(Y | X). The conditional is "among sessions where the new page was seen, what was CVR" — which is a rung-1 quantity contaminated by selection (the kind of users who saw the new page might differ from the kind who didn't). The interventional is "what would CVR be if we made everyone see the new page" — a counterfactual question about the world as it would be under a forced setting.

Rung-2 queries are answerable from observational data only if you can identify the causal effect through an explicit strategy. Named below.

### Rung 3 — Counterfactual: P(Y_x | Y', X')

What would Y have been for *this specific unit* if X had been different, given what we actually observed. Counterfactuals are unit-level and contrary to fact.

- "What CVR would we have had on the Q4 launch week if we'd held back the new page?" → P(CVR_{no_page} | CVR_observed, page_shipped)
- "Would this specific user have churned if we'd given them the discount?" → unit-level counterfactual
- "How much of the YoY revenue growth is attributable to the rebrand vs. the market?" → counterfactual decomposition

Rung-3 requires the strongest assumptions. It typically needs a structural model (synthetic control, causal forests, structural causal models), and it answers questions about specific units or specific historical moments — not generic policy.

## Decision table: question shape → rung → strategies

| Question shape | Rung | What it actually asks | Identification strategies if observational |
|---|---|---|---|
| "What is X?" / "How does Y vary with X?" | 1 | P(Y|X) | None needed; descriptive |
| "Why did X change?" | 1 or 2 | Depends — diagnostic (rung-1) or causal (rung-2) | If rung-2: requires explicit decomposition |
| "Did X cause Y?" | 2 | P(Y|do(X)) | RCT, back-door adjustment, IV, DiD, RDD, synthetic control |
| "Will X cause Y if we ship it?" | 2 | P(Y|do(X=on)) | RCT (preferred), or identification strategy on observational data |
| "Should we ship X?" | 2 | Decision under P(Y|do(X)) | Same as above plus a decision rule |
| "What would Y have been if we hadn't done X?" | 3 | P(Y_{¬x}|observed) | Synthetic control, structural causal model, DiD with strong parallel trends |
| "How much of Y is attributable to X?" | 3 | Counterfactual decomposition | Structural model, Shapley-style attribution |
| "Would this user have done Y if X?" | 3 | Unit-level counterfactual | Causal forests, structural model — fragile, rarely defensible |

The strategies in the right column are not interchangeable. They each demand a specific data shape.

| Strategy | What it requires | When it fits |
|---|---|---|
| **Randomized experiment** | Random assignment of X | Best case; if available, use it |
| **Back-door adjustment** | All confounders measured | Strong assumption; needs a defensible DAG |
| **Instrumental variable** | A variable that affects X but not Y directly | Rare in product analytics |
| **Difference-in-differences (DiD)** | A treated group, a control group, pre/post data, parallel pre-trends | Marketing launches with sister sites, geo splits |
| **Regression discontinuity (RDD)** | A sharp cutoff that determines X | Pricing thresholds, eligibility cutoffs |
| **Synthetic control** | A pool of donor units to weight into a synthetic control | National launches, brand campaigns, things you can't A/B |
| **Holdback test** | Ability to randomly hold a slice of users out of the rollout | Post-launch validation when an RCT wasn't run upfront |

## The methodology

### Step 1. Restate the question and tag its rung

Before pulling any data, restate the user's question in Pearl's notation and tag it 1, 2, or 3.

- Read the verbs. "Is", "are", "how does", "what's the rate of" → rung 1.
- "Will", "would", "if we shipped", "does X drive" → rung 2.
- "Would have", "if we hadn't", "what would it have been" → rung 3.
- If the user phrases a rung-1 question but is clearly going to *act* on the answer (ship, kill, double down), the underlying question is rung-2. Flag this and reclassify.

Common giveaway: "we shipped X and Y went up — did it work?" is shaped as rung-1 but the user wants a rung-2 answer. Treat it as rung-2.

### Step 2. Check what data is available

For each candidate strategy, check whether the data shape supports it:

- **Randomization?** Was X actually randomized at the user level (RCT) or geo level (geo split)? If yes, rung-2 is in reach via experiment-result-reader.
- **Pre/post + control group?** Did the change roll out to one segment first, leaving a comparable un-treated segment? DiD candidate.
- **Sharp cutoff?** Was there a threshold (price point, account size, date) that deterministically triggered X? RDD candidate.
- **Donor pool?** For a single-unit launch (one site, one brand, one country), are there comparable un-treated units to build a synthetic control from?
- **Only before/after on the same population?** Pre/post with no control group is the weakest shape. Trends, seasonality, and concurrent changes will all bleed into the effect. Not a defensible rung-2 estimate.

### Step 3. Apply the refusal rule

This is the load-bearing step. If the question is rung-2 (or rung-3) and the data is observational with no named identification strategy, **refuse to make a causal claim**. Specifically:

1. Answer the rung-1 version of the question (what happened, descriptively).
2. State explicitly: "this is co-incident with [the change], not a causal estimate."
3. List the strategies that *would* make a rung-2 claim defensible, with what each would require.
4. Recommend the cheapest one as a follow-up.

The refusal is not a hedge. It is the honest answer to the question the user asked. "We don't know if the page lifted CVR" beats "the page lifted CVR by 18%" when the latter is unsupported.

### Step 4. If a strategy is available, name it and run it

If a defensible strategy exists, name it before producing the estimate:

> "Treating this as a DiD: treatment is the US site (got the new page on 2026-04-15); control is the UK site (kept the old page through 2026-05-15). Comparing the change in CVR over the same 30-day window."

Then produce the estimate with its assumptions visible (parallel pre-trends, no concurrent confounds, etc.). If an assumption is shaky, downgrade the claim's confidence.

### Step 5. Report with the rung explicitly tagged

Use this format:

```
QUESTION (as asked): <user's words>
RUNG: <1 | 2 | 3>
WHY: <one sentence>

DATA AVAILABLE: <observational only | RCT | DiD-shaped | RDD-shaped | etc.>

ANSWER:
- Rung-1 description: <what the data shows>
- Rung-2 claim: <either the estimate with strategy named, OR explicit refusal>
- Strategies that would unlock a rung-2 claim: <list if refusing>

NEXT STEP: <run the test | accept descriptive answer | build the synthetic control | …>
```

If the rung escalates during the conversation (user starts asking rung-1, ends up asking rung-2), re-run the classification. Don't carry the earlier framing forward.

## Worked example: "Did the new pricing page lift CVR?"

```
User: We shipped the new pricing page on 2026-04-15. CVR went from 3.2% to
3.8% in the four weeks after. Did the page lift CVR?

Agent: [Step 1: classify]

  QUESTION: "Did the new pricing page lift CVR?"
  RUNG: 2. Verb is "did … lift" — interventional. P(CVR | do(new_page=on))
  vs P(CVR | do(new_page=off)).

  The descriptive observation (3.2% → 3.8%) is rung-1. The claim "the page
  lifted CVR" is rung-2. Those are different statements.

[Step 2: check data]

  Data available: before/after on the same population. No holdout, no
  geo split, no sister site running the old page in parallel.

  - Randomization? No.
  - DiD candidate? Not as-is — there's no untreated control group running
    in the same window.
  - RDD candidate? No sharp cutoff.
  - Synthetic control candidate? Possibly, if there are comparable brands
    or sister sites that didn't change pricing pages in the same window.

[Step 3: refusal rule applies]

  The question is rung-2. The data is observational pre/post with no
  identification strategy. The honest answer is: co-incident, no rung-2
  claim available.

[Step 5: report]

  QUESTION (as asked): "Did the new pricing page lift CVR?"
  RUNG: 2 (interventional). User is asking whether shipping the page
  *caused* the CVR change.

  DATA AVAILABLE: pre/post on the same population only. No control group,
  no randomization, no cutoff, no donor pool identified yet.

  ANSWER:
  - Rung-1 description: CVR moved from 3.2% (28 days before launch) to
    3.8% (28 days after). That's a +0.6pp absolute change, co-incident
    with the launch.
  - Rung-2 claim: REFUSED. Pre/post on the same population conflates the
    page change with concurrent factors — paid spend, seasonality,
    organic traffic mix, any other product change that landed in the same
    month. The data cannot distinguish "page lifted CVR" from "April had
    higher-intent traffic" from "we also shipped a homepage update on
    2026-04-12".
  - Strategies that would unlock a rung-2 claim, in order of cost:
    1. Holdback test: roll back the page for a random 10% of traffic for
       2 weeks; compare CVR. Cheapest, cleanest, ~2 weeks.
    2. DiD against a sister site or geo: if any segment kept the old
       page through the same window, compare the change-in-change.
       Requires parallel pre-trends to be defensible.
    3. Synthetic control: weight a pool of comparable sites/brands into
       a synthetic "no-launch" counterfactual for our CVR series.
       Heaviest lift; appropriate if a holdback isn't possible.

  NEXT STEP: Run the holdback. Two weeks of 10% traffic on the old page
  resolves this. Anything weaker is going to be argued about for months.
```

## Worked example: "Will pricing-page V2 lift CVR?" (forward-looking)

```
User: We're about to ship pricing-page V2. Will it lift CVR?

Agent: [Step 1: classify]

  RUNG: 2. Forward-looking interventional. P(CVR | do(V2=on)).

[Step 2: check data]

  No data yet — the change hasn't shipped. The right rung-2 instrument is
  randomization at launch, not post-hoc analysis.

[Step 5: report]

  QUESTION: "Will V2 lift CVR?"
  RUNG: 2.
  ANSWER:
  - Don't ship to 100%. Ship as an A/B with 50/50 assignment.
  - That converts the rung-2 question into a rung-2 estimate with the
    cleanest possible identification (randomization).
  - At expected CVR ~3.5% and an MDE of +0.5pp, n≈12,000/variant for
    80% power at α=0.05. Plan run length from current traffic.
  - If A/B isn't possible (e.g. SEO-indexed pricing page with one URL),
    fall back to geo split or sequential rollout with a 2-week holdout.

  NEXT STEP: Configure the A/B before rollout. Read with
  experiment-result-reader once exposure events are landing.
```

## Traps to avoid

- **"We shipped X and Y went up, so X caused Y."** The textbook rung-1-to-rung-2 slide. Always check what else was changing in the same window before accepting the causal framing.
- **Calling regression a causal estimate.** A regression coefficient is rung-1 unless the specification is justified by an identification strategy. "Controlling for" five variables doesn't promote a model to rung-2 by itself.
- **Treating "statistical significance" as identification.** A p-value below 0.05 on observational data tells you the association is unlikely under the null of no association. It does not address whether the association reflects an intervention or a confounder. p < 0.05 on rung-1 data is still rung-1.
- **Letting "directional read" do the work of identification.** "It's at least directionally positive" is rung-1 dressed up as rung-2. Either you have a defensible causal estimate or you don't.
- **Overclaiming synthetic control.** Synthetic control is powerful and assumption-heavy. Parallel pre-trends, no concurrent confounds, and a defensible donor pool are not optional. If any of those wobble, the rung-3 claim wobbles with them.
- **Re-running the same descriptive analysis with a fancier name.** Mix-shift decomposition, channel attribution by last-touch, and "uplift modeling" are all rung-1 unless an identification strategy is named.

## Cross-references

- **`analytics-diagnostic-method`**: provides the diagnostic spine. This skill plugs in at the "frame the question" step — classifying the rung is the first move of any honest diagnosis.
- **`experiment-result-reader`**: once a rung-2 question is converted to a randomized experiment, read it there. This skill is for the *upstream* decision about whether the question even admits a rung-2 answer.
- **`channel-and-funnel-quality`**: when the rung-2 question is "did this channel cause the lift", the mix-shift discipline there is the rung-1 floor before any rung-2 claim is attempted.

## Tool invocations

The method is platform-neutral. For specific MCP calls when checking pre/post, control groups, or donor pools (e.g. `traffic.compare` for two periods, `cohorts.compare` for two segments, `funnels.list` to confirm the conversion definition, `traffic.breakdown` to check for concurrent mix shifts), load the tool-map for the active platform: see [`tool-maps/`](../../tool-maps/) and the `tool_map:` field in `analytics-profile.md`. If the field is missing, run `analytics-profile-setup` to set it.

## Sources

- Pearl, J. (2022). *On the interpretation of do(x)*. Causal AI Lab. <https://causalai.net/r60.pdf>
- Dablander, F. *An introduction to causal inference*. <https://fabiandablander.com/r/Causal-Inference.html>
- Pearl, J. & Mackenzie, D. (2018). *The Book of Why: The New Science of Cause and Effect*. Basic Books. <https://www.basicbooks.com/titles/judea-pearl/the-book-of-why/9780465097616/>
