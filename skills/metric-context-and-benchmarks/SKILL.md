---
name: metric-context-and-benchmarks
description: Interpret analytics metrics with correct context. Use when the user asks "is this good", "what's a normal X", or quotes a rate without denominator. Covers realistic ranges for bounce rate, engagement, session duration, pages per session, conversion rate by model type, SaaS unit economics (LTV:CAC, CAC payback, MRR churn, activation, retention), plus when each metric lies and minimum sample sizes.
when_to_use: Triggered by "is 2% conversion good", "our bounce rate is 70%", "what's a healthy session duration", "is $70 CAC too high", "what's normal churn", or any raw metric quoted without context. Assumes you have also loaded analytics-diagnostic-method.
---

# Metric context and benchmarks

The reference skill for answering "is this number good, bad, or noise?" correctly. Almost every wrong answer to that question comes from quoting a cross-industry average when the user's industry-specific number is 3× different, or quoting a benchmark without checking if the sample size even supports the comparison.

Read `analytics-diagnostic-method` first. Sample-size discipline applies here more than anywhere: benchmarks are meaningless if your data is noise.

## How to use this skill

1. Load `analytics-profile.md`. The profile's model + industry row picks the right benchmark.
2. Check the sample size. If the user's number is computed on too few observations, the comparison to any benchmark is moot. Say so and stop.
3. Look up the relevant benchmark with its qualifiers (year, source, population, definition).
4. Answer in the form: "Your X is Y. Benchmark for [specific population] is Z [from source, year, n=]. Your number is [above / at / below] benchmark by W percentage points."
5. Flag metric-specific traps (e.g. GA4 bounce rate is not UA bounce rate; last-click CVR is not the full story).

## The honesty rule

Never quote a benchmark as if it's a target. Benchmarks describe populations; they don't tell you what *your* number should be. A business can have a below-benchmark CVR and a healthy LTV:CAC if their AOV or retention is elevated. A business can have a 3× benchmark CVR and still be unprofitable. Always connect the benchmark back to the user's actual unit economics.

## Metric-by-metric

### Bounce rate / engagement rate

**GA4 definition (authoritative, from support.google.com/analytics/answer/12195621)**:
- **Engaged session** = session lasting longer than 10 seconds, OR with a conversion (key) event, OR with 2+ page/screen views.
- **Engagement rate** = engaged sessions / total sessions.
- **GA4 bounce rate** = 100% − engagement rate.

**Critical**: GA4 bounce rate is NOT the same as Universal Analytics bounce rate. UA bounce rate was single-pageview sessions. In GA4, a single-pageview session with >10s dwell is engaged (not bounced). So pre-2023 blog posts quoting "50% bounce rate is average" are measuring a different thing.

**Realistic GA4 engagement rate ranges** (by content type, rough):

| Page type | Healthy engagement rate |
|---|---|
| Long-form blog / documentation | 60–85% |
| Product / pricing pages | 50–75% |
| Landing pages (ad-driven) | 35–60% |
| Homepage | 45–65% |
| Search results / category pages | 40–60% |

Above-range: possibly bot sessions with artificial dwell, or a content page being used as a reference (people open and keep the tab).

Below-range: misaligned expectation (wrong ad creative → wrong page), or slow page load.

### Section views (when tracked)

Some analytics tools (e.g. Clamp's section-views extension) fire a per-section visibility event. Useful as a triangulating signal alongside engagement and bounce — but interpret by section position, not as a verdict:

| Section position | Healthy % of pageviews that view it |
|---|---|
| Above the fold (hero, top features) | 80–100% |
| Mid-page (after first scroll) | 40–70% |
| Below the fold (final CTA, footer-adjacent) | 15–40% |

A below-fold section with a low view rate is not a leak if the upstream CTAs convert normally — that's redundancy for the audience that needs it. Only flag low section views when downstream conversion is also weak.

### Session duration

Heavily distorted by outliers (one abandoned tab pushes the mean by minutes). **Always use the median, never the mean**, or the tool's "engaged session duration" variant that bounds the tail.

Rough ranges:

| Page / context | Typical median engaged duration |
|---|---|
| Docs / reference | 60–180s |
| Article / blog | 30–90s |
| Marketing / landing | 15–60s |
| App / dashboard | varies wildly |

A median under ~10s on a marketing landing page is usually either a slow-load problem, a bot problem, or a page-content problem (people don't find what they came for).

### Pages per session

- 1.0–1.5: single-page visits dominate (often bot traffic or ad-landing that didn't interest).
- 1.5–3: typical for most B2B / SaaS marketing sites.
- 3–5: typical for content / media / ecommerce sites.
- 5+: usually heavy users (docs diving), or possibly session-window issues.

### Conversion rate (by model)

**Cite the user's model row, not the cross-industry number.**

**Ecommerce (Littledata 2023, n=2,800 Shopify)**:
- Average: 1.4%. Top 20%: >3.2%. Top 10%: >4.7%.
- Mobile: 1.2%. Desktop: 1.9%.
- Add-to-cart: 4.6%. Checkout completion: 45% (top 10% >66%).
- AOV: $101.

**Lead generation (Ruler Analytics 2025, 100M+ data points, 14 industries)**:
Cross-industry average: 2.9% MQL CVR. By source overall:

| Source | CVR |
|---|---|
| Direct | 3.3% |
| Paid search | 3.2% |
| Referral | 2.9% |
| Organic | 2.7% |
| Email | 2.6% |
| Paid social | 2.0% |
| Organic social | 1.5% |

Selected industry rows:

| Industry | Direct | Organic | Paid search | Social |
|---|---|---|---|---|
| B2B Tech | 1.5% | 1.5% | 1.5% | 0.3% |
| B2B Services | 2.7% | 2.5% | 3.4% | 1.2% |
| B2B Ecommerce | 2.1% | 2.0% | 2.4% | 1.1% |

**Landing page CVR (Unbounce 2024, 57M conversions, 41k+ pages)**:
Median across industries: 6.6%. But Unbounce measures "landing page conversion" (form fill / download), which is upstream of primary conversion. Don't compare paid-signup CVR to Unbounce's 6.6%; you'll always look bad.

**Paid ads (Wordstream 2025)**:
- Google Ads: avg CVR 7.52%, avg CPL $70.11.
- Meta Ads: avg CVR 7.72%, avg CPL $27.66.
Industry variance is wide (Finance/Insurance Google CPL ~$116; Business Services CVR ~5%).

### SaaS unit economics

**LTV:CAC ratio** (David Skok / *For Entrepreneurs*, canonical since 2009):
- < 1 : unprofitable; lose money per customer.
- ~ 3 : healthy SaaS.
- > 5 : possibly underinvesting in growth.

**CAC payback period** (Bessemer *State of the Cloud*):
- < 12 months: healthy SMB SaaS.
- 12–24 months: acceptable for mid-market / enterprise.
- > 24 months: capital-efficiency concern.

**Never quote CAC in isolation.** $70 CAC is fine if LTV is $2,000 and terrible if LTV is $150.

### SaaS churn

Before answering "is X% churn high?", the profile must tell you:
- B2B or B2C?
- SMB or enterprise segment?
- Monthly or annual contract?

**ChartMogul SaaS benchmarks**:
- Median gross MRR churn, B2B SaaS: ~3–4% monthly for SMB-focused, ~1% monthly for mid-market/enterprise.
- Top quartile: gross revenue retention >90% annually; net revenue retention >110% (expansion covers churn).

**Recurly** (broader subscription):
- B2C subscription monthly churn: 4–7% typical.
- Streaming / content: 5–7%. SaaS tools: 3–5%. Fitness / wellness: often >8%.

A 5% monthly churn is catastrophic for enterprise SaaS and normal for consumer streaming. Same number, opposite verdicts.

### Activation rate (Mixpanel *Product Benchmarks*)

Cross-industry new-user activation rate:
- Median: ~25%.
- Top quartile: >65%.
- Bottom quartile: <10%.

Activation is the highest-leverage metric in SaaS because it bounds every downstream number (retention, revenue, referral loops). If activation is below median, fix that before scaling paid acquisition.

### Retention curves (Amplitude / Reforge framework)

**Don't quote retention as a single number.** Retention is a curve shape, and the shape reveals whether the product has a core loop.

- **Healthy**: steep initial drop, then flattens. Product has a core loop; the flat part is the loyal user base.
- **Unhealthy**: linear or concave decline. No loop; every cohort eventually leaves.

Rough week-8 retention benchmarks:
- Consumer social: 20–40% healthy.
- B2B SaaS: 60–80% healthy.
- Consumer transactional: 5–15% (infrequent use is normal).

### Bot traffic share

**Imperva 2023 Bad Bot Report (2022 data)**: 27.7% of all web traffic is bad bots. Another ~17% is good bots (crawlers). So ~45% of raw traffic is non-human.

If the user's analytics tool shows near-zero bot volume, either (a) the filter is aggressive (healthy) or (b) the filter is broken (they're mis-attributing bots as humans). Check which.

## Sample-size discipline (restated)

Rule of thumb for proportions, 95% CI, p=0.5:

| Observations in the smaller group | Margin of error |
|---|---|
| 100 | ±10% |
| 400 | ±5% |
| 1,000 | ±3% |
| 10,000 | ±1% |

This means:

- Any conversion-rate comparison on fewer than ~400 observations is weak.
- Any cohort split below ~100 is noise.
- A "20% drop" on 50 sessions is the same thing as no drop.

When answering "is X good", if the sample is below the threshold, lead with that fact: "At your current volume (n=220 sessions on this page), a single percentage point is the detection floor. Your 4.1% CVR is statistically indistinguishable from the benchmark of 6.6% here; you need at least ~1,600 more sessions to call it meaningfully different."

## Common metric traps

### Trap 1: the metric changed definition

- GA4 bounce rate ≠ UA bounce rate. Don't compare across tools or across 2022→2023 cutover.
- "Active user" means different things in Mixpanel, Amplitude, and your own CRM. Define before comparing.
- GA4 "users" and "unique visitors" in Plausible / Fathom / Clamp are computed differently. Cross-tool numbers will disagree.

### Trap 2: the denominator is wrong

- "Signup CVR" as a share of *all* sessions mixes intent-free traffic (blog readers) with intent-heavy traffic (pricing page visitors). Compute CVR at the point of intent, not site-wide.
- "Email CVR" often excludes unopened emails from the denominator, which makes it look better than it is. Clarify.
- "Cart abandonment rate": is the denominator carts or sessions? Very different numbers.

### Trap 3: mix shifts masquerading as trend changes

See `analytics-diagnostic-method` for Simpson's paradox. If an aggregate metric moved and none of its components did, the story is a mix shift, not a performance change.

### Trap 4: attribution decides the answer

Last-click vs first-click vs multi-touch can flip which channel is "best". Always qualify: "Based on last-click attribution, LinkedIn is 2% CVR. If we included branded-search follow-up as assist, the picture changes." Never let an agent quote CVR without naming the attribution model.

### Trap 5: the metric moves for reasons outside the metric

- Bounce rate drops (good!) because you added a chat widget that fires an event ~instantly on every page → every session is now "engaged" by GA4's definition. Nothing actually improved.
- Conversion rate goes up because traffic volume dropped (you cut a low-CVR channel). Aggregate CVR ≠ per-channel CVR.
- Session duration goes up because your site got slower; users are waiting, not engaging.

Whenever a metric moves, ask: "Did this move because of the thing we think it measures, or because of something upstream?"

## Worked example

```
User: our bounce rate is 68% and our CVR is 2.1%. Is this bad?

Agent:

[Profile check]
B2B SaaS self-serve, primary conversion = paid signup, ~40k sessions/
month, analytics tool = GA4.

[Definition check]
GA4 "bounce rate" = 100% − engagement rate. Engaged session = >10s,
OR key event, OR 2+ pageviews. This is NOT the UA definition (which
was single-pageview sessions). Don't compare your 68% to pre-2023
UA-era benchmarks.

68% bounce = 32% engagement rate.

[Sample size check]
At 40k sessions/month, you have ~1,300/day. Well above the 1,000-obs
threshold. Both numbers are real, not noise.

[Benchmark lookup]
Bounce: there's no single "bounce benchmark" in GA4's new definition.
Useful reference points:
- Marketing landing pages: 35–60% engagement rate is typical → 40–65%
  bounce. Your 32% engagement is below typical.
- Long-form blog: 60–85% engagement. If most of your 40k sessions are
  from blog / docs traffic, 32% is very low.

CVR: 2.1% to paid signup, as a share of all sessions.
- Ruler Analytics 2025, B2B Tech: direct 1.5%, paid search 1.5%,
  organic 1.5%. So cross-source average for B2B Tech is ~1.5%. Your
  2.1% is above that.
- But Ruler measures MQL, not paid signup. Paid signup is harder to
  hit. 2.1% paid-signup CVR on all sessions is actually strong for
  B2B Tech self-serve.

VERDICT: Bounce rate is likely worse than it should be; CVR is
probably healthy. The two numbers are telling you different things.

EVIDENCE:
- GA4 engagement rate of 32% is below the 50–65% typical for most
  marketing-site compositions. If your traffic mix is heavy blog /
  docs, this is worse still.
- Paid-signup CVR of 2.1% is above the B2B Tech MQL benchmark (1.5%),
  and paid signup is a harder bar than MQL. This is strong.
- The combination (weak engagement + strong conversion) suggests you
  have a large volume of low-intent pageviews that bounce, with a
  smaller high-intent segment that converts well.

WHAT TO DO NEXT:
- Split bounce rate by entry page. The blog / docs pages are likely
  pulling the average down. If the marketing pages (home, pricing,
  features) have >50% engagement, you don't have a bounce problem, you
  have a blog mix problem and a benchmark-definition problem.
- Don't chase the aggregate bounce number. Chase per-page-type
  engagement against its expected range.
- Keep doing whatever is producing the 2.1% paid-signup CVR.

CAVEATS:
- The Ruler benchmark measures MQL, not paid signup. The comparison is
  directional.
- "CVR on all sessions" is a blended number that mixes high-intent
  pricing visitors with low-intent blog readers. Per-entry-page CVR
  is the decision metric, not aggregate CVR.
- Bounce "benchmarks" under GA4's new definition are not well
  established. Use the engagement-rate ranges cautiously.
```

## Traps to avoid

- **Quoting "6.6% is the benchmark CVR" without qualification**. That's Unbounce's cross-industry landing-page form-fill median. It does not apply to paid-signup CVR, ecom CVR, demo-booking CVR, or B2B Tech in general.
- **Comparing pre-2023 bounce numbers to post-2023 GA4 bounce numbers**. Different definitions. The benchmarks don't translate.
- **Giving a verdict on CAC without LTV**. Meaningless in isolation.
- **Verdict on churn without knowing B2B/B2C and contract length**. Same number, different verdicts.
- **Calling activation "fine" when the profile has never computed it**. If the user doesn't have an activation-event definition, help them pick one before judging it.
- **Answering "is X good" on noise-level sample**. Lead with the sample-size caveat; don't quietly quote benchmarks over top of noise.

## Clamp MCP cheatsheet

| Question | Clamp tool |
|---|---|
| Aggregate metrics (sessions, pageviews, bounce/engagement) | `traffic.overview` |
| Per-page engagement (where is bounce concentrated?) | `pages.engagement(view="engagement")` (use `view="summary"` for a fast top-pages list) |
| Per-section attention (which parts of a page get seen) | `pages.engagement(view="sections", pathname=...)` (requires section-views SDK extension) |
| Conversion / event volume | `events.list` |
| Revenue + ARPU / RPV | `revenue.sum` |
| By-segment rates (device, geo, referrer, new vs returning) | `breakdown(dimension=...)` |
| Trailing trend for noise-range check | `traffic.timeseries` |

Using a different analytics tool? Map to `overview`, `pages`, `events`, `revenue`, `breakdown`, `timeseries` equivalents. The method is identical.
