---
name: channel-and-funnel-quality
description: Judge whether traffic is actually valuable and whether funnel drop-off is real or expected. Use when comparing marketing channels, reading a conversion funnel, or deciding where to invest. Covers volume × engagement × conversion as a matrix, vanity-traffic detection, expected step drop-off by funnel type, cohort decomposition, and mix-shift (Simpson's paradox) handling.
when_to_use: Triggered by questions about channel performance, "which channel is best", funnel conversion rates, "is this step dropping too much", or any comparison between segments. Assumes you have also loaded analytics-diagnostic-method.
---

# Channel and funnel quality

The specialist skill for judging quality, not just volume. Most "which channel is best" answers get the wrong channel because they look at sessions or even conversion rate in isolation. The right answer is a matrix.

Read `analytics-diagnostic-method` first if you haven't. This skill assumes you know MECE, triangulation, sample size, and Simpson's paradox. It adds channel-specific and funnel-specific mechanics.

## Opening moves

1. Read `analytics-profile.md`. The model (B2B SaaS vs ecom vs lead gen) dictates which benchmark table applies and what "quality" even means.
2. Nail down the primary conversion event. Volume of "users who clicked the CTA" and volume of "paid signups" are not the same question.
3. Decide the time window. Recent-7-days is too short for most B2B funnels (sales cycle is longer than the window). Use 30 or 90 days for B2B; 7-14 days is fine for high-velocity consumer funnels.

## The quality matrix

A channel or segment is never "good" or "bad" alone. It has three dimensions and you need all three:

```
              Volume       Engagement         Conversion
              (sessions)   (pages/session,    (CVR to primary
                           duration, depth)   event, revenue/visitor)

Direct        high         high               high        → flagship; defend
Organic       high         high               medium-high → compound invest
Referral      medium       high               medium-high → cultivate
Paid search   medium       medium             medium      → maintain, scale only if CAC allows
Email         medium       high               very high   → feed the list
Paid social   high         low                low         → vanity unless targeted well
Affiliates    varies       low-medium         low-medium  → audit for fraud, gate payouts
Unknown bots  high         very low           zero        → exclude, not a channel
```

Use this as a default sorting key, not a verdict. A specific channel in a specific business can land anywhere in the matrix. The point is: a channel with high volume and low engagement is vanity traffic; a channel with low volume and high conversion is probably underinvested.

## Vanity-traffic fingerprints

Traffic you shouldn't be proud of, even if the session count is high:

- **Pages per session near 1.0**: they landed and left.
- **Median session duration under ~10 seconds**: they didn't read anything.
- **Engaged-session rate (GA4) under ~20%**: low intent.
- **Near-zero conversion rate to any downstream event**: they never did anything measurable.
- **Heavy geo concentration in a region you don't serve** (e.g. a US B2B tool with 60% of sessions from India).
- **UA / device concentration on a narrow band** (e.g. one browser version dominates in a way humans don't).
- **Referrer list contains suspicious domains** (crypto scams, SEO spam, semalt-style fake referrers).

Treat vanity traffic as a measurement problem before a marketing problem. Filter it; then re-read the channel matrix. The new matrix is usually very different.

## Channel benchmarks (cite with context, never bare)

Use these for sanity-checking orders of magnitude, **always qualified by the business model row** from the user's profile. Never quote a single cross-industry number as "the benchmark"; the variance is too large to be useful without context.

### Landing page conversion (Unbounce *Conversion Benchmark Report 2024*, 57M conversions, 41k+ pages)

| Traffic source | Median CVR |
|---|---|
| Email | 19.3% |
| Paid social (blended) | 12% |
| Paid search | 10.9% |
| All sources, cross-industry median | 6.6% |
| Google (vs Bing / Yahoo) | 11.3% (Bing 41% worse, Yahoo 95% worse) |
| Instagram / Facebook | 17.9% / 13% |
| YouTube / TikTok / X | 6–9% |
| LinkedIn | roughly 4× worse than Meta for landing-page CVR |

**Important caveat**: Unbounce measures "conversion on the landing page" (form fill, demo request, download). Not paid signup. Numbers are much higher than primary-conversion CVR because a form submit is upstream of revenue.

### Lead CVR by source (Ruler Analytics *2025 Conversion Benchmark Report*, 100M+ data points, 14 industries)

Overall average MQL CVR: **2.9%**. By source:

| Source | Avg lead CVR |
|---|---|
| Direct | 3.3% |
| Paid search | 3.2% |
| Referral | 2.9% |
| Organic search | 2.7% |
| Email | 2.6% |
| Paid social | 2.0% |
| Organic social | 1.5% |

B2B Tech is much harder: all sources roughly 1.5%, organic social as low as 0.3%. If the profile says B2B Tech, anchor on the B2B Tech row, not the cross-industry average.

### Paid ads (Wordstream 2025)

- Google Ads average: CVR 7.52%, CPL $70.11.
- Meta Ads average: CVR 7.72%, CPL $27.66.

Wide industry variance: Finance/Insurance Google Ads CPL ~$116; Business Services CVR ~5%; Automotive Repair ~14%.

### Ecom (Littledata *Shopify Benchmarks 2023*, ~2,800 sites)

- Average CVR 1.4%, top 20% >3.2%, top 10% >4.7%.
- Mobile 1.2% vs desktop 1.9%.
- Add-to-cart rate 4.6%; checkout completion 45% (top 10% >66%).
- AOV $101.

### Activation (Mixpanel *Product Benchmarks*)

Cross-industry new-user activation rate: ~25% median, >65% top quartile, <10% bottom quartile. Activation is the metric to fix before any channel-scaling conversation.

## Funnels: expected drop-off by step type

Not every step is supposed to convert at the same rate. Judge each step by its *type*, not by a blanket "every step should do X%".

Rough typical ranges (use to sanity-check, never quote as hard targets):

| Step type | Typical drop-off | Reasoning |
|---|---|---|
| Landing → view pricing | 15–40% of sessions progress | Most visitors are exploratory |
| View pricing → start signup | 10–30% | High-intent moment; still most bounce |
| Start signup → complete signup | 50–85% | Abandonment usually means friction |
| Signup → first key action (activation) | 20–70% | Highest-variance step; product matters most |
| Trial → paid | 10–30% (self-serve SaaS) | Trial design and value delivery matter |
| Add to cart → checkout (ecom) | 30–50% of carts proceed | Littledata: ~45% checkout completion average |
| Checkout → paid | 55–75% (ecom) | Littledata: ~66% top 10% |
| Demo booked → demo held | 60–85% (B2B) | No-show rate is the obvious loss |
| Demo held → opp | 30–60% (B2B) | Fit-dependent |
| Opp → closed-won | 15–35% (B2B) | Standard B2B sales conversion |

A step converting well above its expected range isn't always "a win". It can indicate the step is too permissive (e.g. your trial asks nothing, so everyone "completes" it, but the next step collapses). Always evaluate steps in pairs.

## Funnel diagnostics: find the real leak

Three things to check for every funnel:

### 1. Is the absolute drop-off actually worse than expected?

Apply the ranges above. A step converting at 40% looks bad in isolation but is normal for many step types. Only the steps outside their expected range deserve investigation.

### 2. Is the leak concentrated in one segment?

Split every step by the obvious segments:
- Channel (paid social often leaks harder than direct at the signup step).
- Device (mobile vs desktop; mobile signup is always worse).
- Geo (language/localization gaps).
- New vs returning.
- Entry page (cold-from-Google vs warm-from-email).

If the leak is channel-specific, the fix is upstream (targeting, ad creative, landing page per channel). If it's device-specific, the fix is UX. If it's geo-specific, it's localization. Don't apply a UX fix to an audience problem.

### 3. Is the step actually being measured correctly?

Before declaring a leak, verify:
- The step event fires consistently (not just for some users).
- The funnel order matches what users actually do (not the order the PM imagined).
- You're measuring sessions, not users, for the right step (or vice versa, depending on funnel type).
- Out-of-funnel paths aren't being counted as drop-off (e.g. users who signed up via a different page).

## Simpson's paradox for channel comparisons

The classic channel-comparison trap. Example:

> "LinkedIn Ads has 2% CVR. Direct has 5% CVR. Cut LinkedIn."

But: LinkedIn brings 10k cold sessions; Direct brings 2k warm sessions where most visitors already know the brand. Split LinkedIn-attributed direct revisits from fresh direct and the picture changes completely: LinkedIn probably drove 30% of the "direct" conversions through branded follow-up search, invisibly.

**Rules**:

- Always check if "Direct" is eating credit from another channel. Branded search, direct re-visits after paid touchpoints, and email-link-copied-to-browser all land in Direct.
- Never make a kill decision on a channel based on last-click CVR alone. Look at assist data if available.
- Run mix-shift checks: if aggregate CVR changed, is it because channel mix shifted, or because per-channel CVR actually moved? They demand different actions.

## Quality > volume: scoring channels when in doubt

If you need a single number per channel, use **revenue per visitor** (or, for lead-gen, qualified-lead per visitor):

```
RPV = total revenue attributed to channel / total visitors from channel
```

This collapses volume × conversion × deal-size into one number and compares channels fairly. A channel with low volume but high RPV is under-invested. A channel with high volume but low RPV is vanity.

For LTV:CAC alignment:

- If LTV:CAC for a channel < 1, it's unprofitable; reduce spend.
- If LTV:CAC ~ 3, it's healthy (David Skok's SaaS benchmark).
- If LTV:CAC > 5, you're underinvesting; scale cautiously.
- CAC payback under 12 months is healthy for SMB SaaS; 12–24 months for mid-market/enterprise (Bessemer *State of the Cloud*).

## Worked example

```
User: which channels are actually working? We're considering cutting
LinkedIn Ads.

Agent:

[Profile]
B2B SaaS self-serve + sales-assist, ~40k sessions/month, primary
conversion = paid signup, secondary = demo booked. LinkedIn UTMs
flagged as "messy".

[Matrix, last 30 days]
                Sessions   Engaged%   Signup CVR   Demo CVR   RPV (est)
Direct          12k        58%        5.2%         1.1%       $48
Organic         10k        54%        3.9%         0.8%       $31
Paid search      8k        48%        3.5%         0.7%       $22
LinkedIn Ads    10k        22%        1.1%         0.4%        $6
Organic social   2k        40%        2.2%         0.3%       $11

[Benchmark context]
Ruler 2025 B2B Tech: direct ~1.5%, paid search ~1.5%, organic social
0.3%. The site is outperforming the industry on direct, organic, and
paid search, and underperforming on paid social.

[Vanity-traffic check on LinkedIn]
- Engaged-session rate 22% (vs site average ~50%). Weak.
- Median duration on LinkedIn-landing pages: 11 seconds.
- 42% of LinkedIn sessions bounce within 5 seconds.
- No geo or UA anomaly (so it isn't straightforward bot traffic).
This looks like low-intent traffic, not fake traffic. Humans, but not
your ICP.

[Simpson's check before deciding]
Can LinkedIn be driving "assist" traffic to Direct? Checking branded
search volume: branded search impressions up ~30% in the past 60 days,
correlated with the LinkedIn campaign start. Direct CVR (5.2%) is
elevated vs prior period (4.1%). Some of the "direct" uplift may be
LinkedIn-assisted.

[Funnel step-by-step]
LinkedIn → landing page: normal.
Landing → pricing view: 9% (vs 22% for direct). Weak intent.
Pricing → start signup: 12% (vs 19% for direct). Also weak.
Start → complete signup: 74% (within normal range).

The weakness is at the top of the funnel (intent), not the bottom. This
is a targeting/creative problem, not a product problem.

VERDICT: Don't cut LinkedIn blind. Its direct CVR of 1.1% looks bad
against other channels but is in line with B2B Tech benchmarks, and
there's evidence LinkedIn is lifting branded/direct traffic. The real
problem is weak intent-per-click: audience targeting or ad creative is
attracting the wrong viewers.

WHAT TO DO NEXT:
- Narrow LinkedIn targeting to tighter job titles / company-size bands
  that match the paid-signup ICP. Expect CPC to rise; optimize on
  signup CVR, not click volume.
- Add a signup-quality metric (e.g. activation within 14 days) and
  optimize LinkedIn on that downstream metric, not on clicks or raw
  signups.
- Run a 30-day hold-out: pause LinkedIn for one matched cohort and
  measure the delta in branded search and direct. That gives a clean
  read on its assist value.
- Don't touch paid search. It's performing at or above benchmark with
  no warning signs.

CAVEATS:
- UTM quality on LinkedIn is flagged as poor, so per-channel CVR numbers
  may under- or over-represent LinkedIn by up to ~20%.
- 30-day window is short for demo-attributed revenue (sales cycle often
  exceeds this). Demo CVR numbers are directional only.
- RPV estimates assume current blended deal-size; actual channel-level
  LTV may differ by >30%.
```

## Traps to avoid

- **Comparing channels on CVR alone**. CVR × volume × deal-size (or at least CVR × volume) is the minimum.
- **Ignoring attribution quality**. If UTMs are broken (common on LinkedIn, TikTok, some affiliate networks), channel CVR is garbage.
- **Quoting cross-industry benchmarks at a user whose industry-specific row is 3× different**. B2B Tech at 1.5% is not "below the 2.9% benchmark"; it's at benchmark for B2B Tech.
- **Judging a funnel step without knowing its type**. A 25% step drop is catastrophic for some steps and normal for others.
- **Calling a channel "bad" based on last-click only**. Assist matters, especially for B2B.
- **Not checking mix shifts**. An aggregate funnel CVR moving can be entirely mix.
- **Treating vanity traffic as a marketing problem**. First filter out bots and wrong-geo; then read the matrix.

## Clamp MCP cheatsheet

| Check | Clamp tool |
|---|---|
| Channel list and volumes | `get_top_referrers` |
| Per-channel engagement | `get_page_engagement` + `get_breakdown` by referrer |
| Country/device splits | `get_countries`, `get_cities`, `get_devices` |
| New vs returning split | `get_breakdown` |
| Build / inspect a funnel | `create_funnel`, `get_funnel` |
| Campaign period comparison | `mcp_clamp_compare_periods` |
| Revenue by channel (if Stripe wired) | `get_revenue` + `get_breakdown` |
| Path analysis: what do they actually do? | `get_session_paths` |

Other tools (GA4, Amplitude, PostHog) have direct analogues; translate.
