---
name: analytics-diagnostic-method
description: The spine of analytics investigation. Use whenever interpreting analytics numbers, answering "why did X change", reading funnels, comparing cohorts, or presenting findings. Teaches a five-step method (load profile, frame the question, build a MECE hypothesis tree, triangulate, present with Pyramid Principle), how to separate signal from noise, and how to spot Simpson's paradox before it misleads you.
when_to_use: Load at the start of any analytics investigation, before reaching for the specialized skills. Other skills in this pack (traffic-change-diagnosis, channel-and-funnel-quality, metric-context-and-benchmarks) build on this one.
---

# Analytics diagnostic method

The method senior analysts use when they don't know what caused something. It is boring, slow-looking, and dramatically more accurate than the "dashboard hunt" pattern most agents default to.

If you remember one thing: **dashboards describe, they don't explain**. Getting from "traffic dropped 30%" to "the GA4 container got unpublished on Tuesday" requires a method, not a screenshot.

## When to use this

- Any "why did X change?" question.
- Any funnel or cohort comparison.
- Any request for a recommendation based on analytics.
- Any number the user is about to act on.

## When NOT to use this

- Pure retrieval questions ("how many sessions yesterday?"). Just answer.
- Definition questions ("what is engagement rate in GA4?"). Use `metric-context-and-benchmarks`.
- Questions where the user has already diagnosed the cause and wants help implementing a fix. Don't re-diagnose.

## The five steps

### 1. Load the profile and frame the question

First action: check for `analytics-profile.md` in the repo root.

- **If it exists**: read it. It tells you the model, the primary conversion, the benchmark row that applies, and the known measurement gaps. You will reference these repeatedly.
- **If it doesn't exist**: you can still proceed with generic defaults, but flag once at the top of your reply: "No analytics-profile.md found. I'm using cross-industry defaults. Run `analytics-profile-setup` for calibrated answers."

Then restate the user's question in one precise sentence. Vague questions are the #1 cause of bad analytics answers. Convert these:

| User says | You restate as |
|---|---|
| "traffic dropped" | "Weekly sessions dropped from 42k to 28k between week-of-Apr-14 and week-of-Apr-21. Want diagnosis." |
| "signups are down" | "Daily paid-signup events fell from ~80/day to ~40/day starting Apr 18. Want diagnosis." |
| "is LinkedIn working" | "LinkedIn-attributed paid signups over last 30 days vs paid spend, and whether CVR beats direct and paid search." |

If the user's question cannot be made precise (missing metric, missing timeframe, missing segment), ask one clarifying question before proceeding. One. Not four.

### 2. Build a MECE hypothesis tree

MECE = Mutually Exclusive, Collectively Exhaustive. Coined by Barbara Minto at McKinsey (1963, later formalized in *The Minto Pyramid Principle*, 1985/1996). The point: split the possible causes so they don't overlap and no major cause is omitted.

For analytics questions, a MECE split that almost always works:

```
Observed change in metric M
├── Measurement (the data is wrong)
│   ├── Tracking regression (event dropped, container unpublished, script blocked)
│   ├── Attribution shift (UTM change, cookie policy, cross-domain)
│   └── Bot / filter change (filters on or off, bot behavior shift)
├── Audience (who is coming changed)
│   ├── Channel mix shift
│   ├── New vs returning mix shift
│   ├── Geo / device mix shift
│   └── Campaign start/end
├── Experience (what they encountered changed)
│   ├── Deploy / site change
│   ├── Page performance (speed, errors)
│   ├── Content change (copy, pricing, availability)
│   └── Third-party outage (payment, auth, CDN)
└── External (the world changed)
    ├── Seasonality (day-of-week, holiday, industry cycle)
    ├── Competitor action
    ├── Market / news event
    └── Platform change (algo, policy, iOS release)
```

Walk the tree. For each branch, ask: "Is there evidence for or against this?" Don't commit to a hypothesis before ruling out the cheap, measurement-level ones. 80% of "traffic mystery" questions are actually measurement regressions.

The order matters. **Always check measurement first**, because every other branch is meaningless if the data is wrong.

### 3. Triangulate before concluding

A single metric is one data point. Real diagnosis requires 2-3 independent views that agree.

Triangulation patterns that work:

- **Metric agreement**: sessions dropped AND pageviews dropped AND events dropped in roughly the same proportion → the *traffic* really dropped. Sessions dropped 30% but events only dropped 5% → the *tracking* partially broke.
- **Source agreement**: the analytics tool shows -30% AND server logs show roughly stable request volume → it's a tracking issue, not a real drop.
- **Channel agreement**: the drop is concentrated in one channel → look there first. The drop is spread proportionally across all channels → look for a measurement or site-wide cause.
- **Cohort agreement**: new users behave like old ones → not a tracking change. New users suddenly behave wildly differently → likely attribution or audience shift.
- **Time-shape agreement**: drop is a cliff (single hour/day) → discrete event (deploy, outage, blocklist). Drop is a ramp → growing issue (bot filter drift, SEO decay, competitor ramp).
- **View vs. action agreement** (when section-view data is available): section views distinguish *people didn't see it* from *people saw it and didn't act*. If both the section views and the downstream action are weak, the section is the leak. If section views are weak but downstream conversion is normal, the section is below-fold redundancy — not a problem.

If you only have one view, say so. "Based on a single channel-level slice, it looks like paid search. I can't confirm without also checking the server-side and cohort views."

### 4. Separate signal from noise

Before claiming a change is real, check sample size. Agents routinely declare "conversion rate dropped 20%!" on 50 sessions.

Rule of thumb for proportions (95% CI, p=0.5 worst case):

| Observations in the smaller group | Margin of error (±) |
|---|---|
| 100 | 10% |
| 400 | 5% |
| 1,000 | 3% |
| 10,000 | 1% |

So a change from 5% to 4% CVR:

- On 50 sessions (~2.5 converted): meaningless noise.
- On 500 sessions (~25 converted): possibly real, confidence is weak.
- On 5,000 sessions (~250 converted): real.

Also always check:

- **Day-of-week effect**: comparing Monday to Sunday is a trap. Compare week-over-week or at least same-day-of-week.
- **Multiple comparisons**: if you slice 20 ways, one slice will look "significant" by chance. If you only discovered the segment after you saw it change, weight that finding down.
- **Baseline volatility**: if the metric normally swings ±25% week-over-week, a 30% move is a ~1σ event, not a crisis.

### 5. Present with the Pyramid Principle

Answer first. Reasoning second. Data third. Most analysts do it backwards and lose the user's attention.

Template:

```
VERDICT (one sentence): <what changed and why>

SUPPORTING FINDINGS (2-3 bullets):
- <finding 1 with the one number that proves it>
- <finding 2 with the one number that proves it>
- <finding 3 if needed>

WHAT TO DO NEXT (1-3 bullets):
- <action ranked by impact>

CAVEATS:
- <sample-size or measurement caveats>
```

If you cannot produce a one-sentence verdict, you haven't finished diagnosing. Don't publish the draft.

## Simpson's paradox: the trap that catches most agents

Edward Simpson (1951) showed that a trend visible in aggregated data can *reverse* once you split by a subgroup. Three canonical cases:

- **UC Berkeley admissions, 1973**: overall, men were admitted at 44% vs women at 35%. Apparent bias. But broken down by department, women had equal or higher admit rates in most departments. Women applied disproportionately to more competitive departments. (Bickel et al., 1975, *Science*.)
- **Kidney stone treatment study**: Treatment A had higher success for small stones *and* for large stones, but lower success overall. A was used more on hard cases.
- **Jeter vs Justice batting averages, 1995-1996**: Justice hit higher in each individual year; Jeter hit higher combined.

For analytics, the recurring version is:

> "Our overall conversion rate dropped from 5% to 4%. But every channel's CVR went up. What happened?"

Answer: the channel mix shifted. A low-CVR channel (social, display) grew as a share of total; the weighted average dropped even though every component improved.

**Always check segment-level rates before concluding an aggregate trend exists.** If the aggregate moves but segments don't, the story is a mix shift, not a performance change. The fix for mix shifts is not the same as the fix for performance drops.

## How to use the other skills

This skill is the spine. When a question narrows, reach for the specialized skill:

| Question | Use |
|---|---|
| Why did traffic / sessions / pageviews change? | `traffic-change-diagnosis` |
| Is this channel / funnel / step any good? | `channel-and-funnel-quality` |
| Is this number good, bad, or noise? | `metric-context-and-benchmarks` |
| Haven't set up yet? | `analytics-profile-setup` |

All three specialist skills assume you've loaded this one's method. They won't re-explain MECE or sample sizes; they apply them.

## Worked example

```
User: our conversion rate dropped from 5% to 3.8% last week, what happened?

Agent (applying this method):

[Step 1 - profile + frame]
Reading analytics-profile.md. Profile says: B2B SaaS self-serve, primary
conversion = paid signup, ~40k sessions/month, known measurement gap
(LinkedIn UTMs unreliable).

Restated question: "Weekly paid-signup CVR fell from 5.0% to 3.8% between
week-of-Apr-14 and week-of-Apr-21. Diagnose."

[Step 2 - MECE tree, check cheap branches first]
Measurement branch: does server-side signup count agree with the analytics
tool? Yes, both show ~40 fewer signups last week. Rule out tracking.

[Step 3 - triangulate on channels]
Channel split week-over-week:
- Direct:      5.2% → 5.4%   (improved)
- Organic:     4.8% → 5.0%   (improved)
- Paid search: 3.9% → 4.1%   (improved)
- Paid social: 2.1% → 2.0%   (flat)
- Volume by channel:
    Direct:      12k → 11k sessions
    Organic:     10k →  9k sessions
    Paid search:  8k →  7k sessions
    Paid social:  6k → 14k sessions  ← new LinkedIn campaign started Apr 15

Every channel's CVR is stable or improved, but aggregate CVR dropped.

[Step 4 - signal vs noise]
40k sessions/week is well above the 1,000-obs threshold. The changes are
real, not noise.

[Step 5 - Pyramid present]

VERDICT: The aggregate CVR drop is a mix shift, not a performance drop.
Your new LinkedIn Ads campaign (launched Apr 15) doubled paid-social
volume at a 2% CVR, which dragged the weighted average down even though
every channel improved its own CVR.

SUPPORTING FINDINGS:
- Paid social volume went 6k → 14k sessions (+133%) at a 2.0% CVR.
- Every other channel's CVR improved week-over-week.
- The arithmetic: 5.0% → 3.8% aggregate is exactly what you'd predict from
  the new mix at unchanged per-channel rates.

WHAT TO DO NEXT:
- Don't chase "fix the funnel". The funnel isn't broken.
- Decide whether LinkedIn at 2% CVR meets your LTV:CAC bar. If yes, keep
  scaling and accept aggregate CVR will look lower. If no, cut it.
- Track LinkedIn separately in weekly reports so it stops dragging the
  blended number.

CAVEATS:
- Profile flags LinkedIn UTM quality as poor. Some LinkedIn signups may
  be mis-attributed to Direct (inflating Direct CVR). The direction of
  the conclusion doesn't change but the magnitudes might.
```

Textbook Simpson's paradox. An agent that stopped at "aggregate CVR dropped, check the funnel" would have sent the team on a week-long wild goose chase. The method prevents that.

## Traps to avoid

- **Starting with the dashboard**. Dashboards are the last step, not the first. Frame the question before opening anything.
- **Confirming the user's hypothesis instead of testing it**. If the user says "I think it's the redesign", check the redesign branch *and* the other three branches. Confirmation bias is the failure mode.
- **Skipping measurement checks because "we just shipped the redesign, it has to be that"**. No. Check measurement first, always. Redesigns often break tracking at the same time they change the site.
- **Reading too much into small segments**. "Android users in Brazil converted 40% higher this week" on 12 sessions is nothing.
- **Not saying "I don't know"**. If the evidence points in multiple directions or is inconclusive, say so. "Two plausible causes, can't distinguish without a funnel slice" is a real answer. "It's definitely the redesign" when you don't know is not.

## Clamp MCP cheatsheet

If Clamp MCP is connected, these tools map to the method steps:

| Step | Clamp tool |
|---|---|
| Measurement sanity check | `events.list` (is the conversion event firing?), `traffic.overview` (do totals make sense?) |
| Channel split | `breakdown(dimension="referrer_host")` (channel comes back joined per row) or `breakdown(dimension="channel")` |
| Cohort split | `breakdown(dimension="country" \| "device_type" \| "browser" \| ...)` |
| Time shape | `traffic.timeseries` (hourly or daily granularity) |
| Funnel check | `funnels.create` / `funnels.get` |
| Before / after comparison | `traffic.compare` |
| Live check during an incident | `traffic.live` |
| Section-view triangulation | `pages.engagement(view="sections", pathname=...)` paired with the matching CTA-click `events.list` call |

Using a different analytics tool? Same method; translate the tool names.
