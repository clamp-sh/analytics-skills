---
name: traffic-change-diagnosis
description: Diagnose why website traffic changed. Use when the user asks "why did traffic drop/spike", investigates an anomaly, or wants to separate tracking regressions from real behaviour changes. Walks a hypothesis tree (measurement → time-shape → channel → cohort → content), recognises common fingerprints (bot spike, tracking regression, deploy-correlated drop, SEO decay, campaign ramp), and applies sample-size discipline.
when_to_use: Triggered by questions like "why did traffic drop last week", "what's causing this spike", "traffic is down, what happened", or when an alert fires on pageviews/visitors/sessions. Assumes you have also loaded analytics-diagnostic-method.
---

# Traffic change diagnosis

The specialist version of the diagnostic method, applied to one question: why did traffic (sessions, pageviews, unique visitors) move?

Read `analytics-diagnostic-method` first if you haven't. This skill assumes you already know MECE, triangulation, sample size, and Pyramid presentation. It adds the traffic-specific fingerprints and drill paths.

## Opening moves

1. Read `analytics-profile.md` if present. The profile tells you the expected monthly traffic range and known measurement gaps. Both matter: a "spike" from 200 to 400 sessions/day on a <1k/month site is plausibly random; the same shape on a 1M/month site is an event.
2. Restate the question precisely. "Traffic dropped" is not a question. "Daily sessions fell from ~1,400 to ~900 starting April 18, with no corresponding drop in pageviews" is.
3. Decide: is this a real change at all? Apply the sample-size rule from `analytics-diagnostic-method`. Below ~300 observations per bucket, most "changes" are noise.

## The hypothesis tree for traffic

Walk in this order. Cheap checks first.

```
Traffic change
├── 1. Measurement  (check first, always)
│   ├── Tracking regression (script missing, container unpublished, CSP block)
│   ├── Bot filter toggle (inclusion/exclusion changed)
│   └── Attribution shift (referrer policy, cookie policy, cross-domain)
├── 2. Time shape  (what does the curve look like?)
│   ├── Cliff (single hour/day step)           → discrete event
│   ├── Ramp (gradual over days/weeks)         → campaign / SEO / decay
│   ├── Spike (single-day anomaly)             → bot burst, viral, outage resolved
│   └── Cyclic (weekly/monthly pattern change) → seasonality, campaign cadence
├── 3. Channel
│   ├── One channel moved                       → campaign / algo / platform change
│   ├── All channels moved proportionally       → measurement or site-wide issue
│   └── One channel grew, another shrank        → mix shift (use Simpson's check)
├── 4. Cohort
│   ├── New users changed, returning didn't     → acquisition-side change
│   ├── Returning changed, new didn't           → retention / email / loyalty change
│   └── Both changed                            → site-wide or measurement
└── 5. Content / page
    ├── One page moved                          → deploy, SEO page, content change
    ├── Many pages moved proportionally         → site-wide (nav, header, domain)
    └── Entry pages moved, deep pages didn't    → acquisition landing change
```

## Fingerprints: common patterns and what they usually mean

Real diagnostic work is pattern recognition. These are the fingerprints you'll see most often. Recognising the shape narrows the tree in one glance.

### F1. Tracking regression

**Shape**: cliff, single channel-agnostic, usually correlated with a deploy or config change.

**Signals**:
- Sessions drop ~X% but server logs / database row counts are roughly flat.
- The drop appears instantly at a specific time (correlates with a deploy).
- Events linked to the same page still fire at ~prior volume relative to sessions (if the event tag is different from the page tag that broke).
- Realtime dashboard shows fewer sessions than you'd expect at the current hour.

**Fix path**: check recent deploys, CSP/script-src headers, tag manager container version, and adblock-block-rate if your tool exposes it.

**When to suspect it first**: if the drop is >20% and happened in a single hour, measurement regression is the single most likely cause.

### F2. Bot spike (incoming)

**Shape**: spike, usually short (hours to days), often concentrated in one country/ASN/referrer.

**Signals**:
- Traffic up, but engagement rate and conversion rate down proportionally.
- Pages-per-session collapses to 1.0 (they land and leave).
- Most "users" from a single country or data-center IP range.
- User-agent concentration (many sessions from identical or generic UAs).
- A weird referrer is top of list (e.g. `semalt.com`, `darodar.com`, obvious fake domains).
- Session duration ~0 seconds.

**Context**: Imperva's 2023 Bad Bot Report found 27.7% of all 2022 web traffic was bad bots. Roughly another 17% was good bots (search crawlers). So ~45% of raw traffic is non-human by default; your filters shape what you see.

**Fix path**: don't treat bot traffic as a "drop in quality". Filter it out, then re-examine. If the filter just changed (you turned bot exclusion on or off recently), the "change" is entirely a filter event.

### F3. Deploy-correlated drop

**Shape**: cliff at deploy time, usually affects one section of the site.

**Signals**:
- Drop starts within minutes of a recent deploy.
- One or two URL paths account for most of the delta.
- The pages in question either 404, 500, or changed URL structure without redirects.
- Entry-page metric for those paths collapses.

**Fix path**: check the deploy log, check the affected URLs for status-code changes, check for missing redirects from old paths. Fast to confirm, fast to fix.

### F4. Campaign start/end

**Shape**: step change (up at campaign start, down at end), concentrated in one channel.

**Signals**:
- Paid search or paid social volume moves sharply on a known date.
- UTM source/medium/campaign shows the campaign's parameter.
- Spend data (from the ad platform) matches the traffic shape.
- Other channels are roughly unchanged.

**Fix path**: confirm with the ads team / spend data. "Down" is fine if planned; "down" is bad if they didn't plan to cut.

### F5. SEO decay

**Shape**: gradual ramp down over weeks or months, concentrated in organic search.

**Signals**:
- Organic sessions trending down week-over-week, smoothly.
- Specific landing pages or query clusters losing traffic; others flat.
- Google Search Console shows declining impressions AND declining click-through rate.
- Competitors now rank above you on tracked queries.

**Fix path**: this isn't an emergency, it's a content project. Don't promise a fix in a week.

### F6. Algorithm / platform change

**Shape**: step change or fast ramp, concentrated in one channel (usually organic or one paid platform).

**Signals**:
- Drop starts on a known algorithm/policy update date (Google core update, iOS privacy release, Facebook API change).
- Industry chatter in SEO or ad-platform communities confirms others are seeing the same.
- No obvious site-side change correlates.
- Impressions change as much as or more than clicks (for organic).

**Fix path**: wait ~2 weeks to see if Google rolls back partially (they sometimes do). Don't panic-ship content changes in week one.

### F7. Viral / news event (incoming)

**Shape**: sharp spike, usually a day or two, then decays.

**Signals**:
- One referrer (HN, Reddit, a specific tweet, a news article) dominates.
- Geo concentration matches the source (e.g. HN spike = mostly US + Europe English-speaking).
- Engagement time is actually *higher* than baseline (these are genuinely interested readers, unlike bots).
- Post-spike, a small percentage retains.

**Fix path**: no fix needed. Capture email/signup while the spike is live. Measure the retention tail at 7, 30, 90 days to see what you actually got.

### F8. Seasonality

**Shape**: cyclic or predictable ramp, repeats annually or monthly.

**Signals**:
- Year-over-year overlay shows the same shape.
- Day-of-week pattern is stable (B2B tools drop on weekends; ecommerce often peaks on weekends).
- Holiday calendar explains the move (December for ecom up, for B2B down).

**Fix path**: none. Note it. Don't action it.

## Measurement-first: the cheap checks

Do these before anything else. Each takes seconds:

1. **Realtime check**: is the tool showing live sessions at approximately the rate you'd expect for the current hour? If realtime looks normal but yesterday's number looks broken, the drop may have already self-resolved or may be a processing lag.
2. **Event-to-session ratio**: if the ratio stays constant, tracking is probably intact. If events drop proportionally more than sessions (or vice versa), one of the two tags is broken.
3. **Internal traffic filter**: was it toggled on/off recently? Is office WiFi or VPN traffic now being counted (or excluded) when it wasn't before?
4. **Server-side sanity check**: access log request count, or database signup-row count, or Stripe payment count. If these agree with the analytics numbers, the data is probably real. If they diverge, the tool is lying.

If any of these fail, the branch is "measurement" and you're done with the tree for now. Fix the data, then re-investigate.

## Time-shape reading

The shape of the drop contains most of the information. Always get a timeseries at two granularities: daily for the last ~30 days, and hourly for the last ~72 hours.

| Shape | Likely branch |
|---|---|
| Step down at a specific hour | Deploy, outage, platform policy change, tracking regression |
| Gradual decline over days | SEO decay, audience fatigue, competitor ramp |
| Single-day spike then back to baseline | Bot burst, viral event, alert firing on a stale data point |
| Weekly pattern amplitude changed | Campaign cadence change, seasonality kicking in |
| Absent data for a specific window | Tool outage, pipeline lag, not a real drop |

## Bot filtering check (never skip this)

A non-trivial fraction of raw traffic is bots. Before concluding a real traffic change, verify the filter setup hasn't changed.

- Is your analytics tool filtering known bots by default? (GA4, Plausible, Fathom, Clamp all do; some server-log setups don't.)
- Did someone recently toggle "include bot traffic" on a report?
- Is there a new referrer in the top 10 that looks suspicious? (Random domains, crypto scam domains, SEO-spam domains.)
- Does the "spike" disappear if you filter to engaged sessions only?

If the answer to any of these is "actually yes, the filter just changed", the traffic change is purely a reporting artifact. Not a real event.

## Signal-vs-noise checks for traffic specifically

Sample size rules from `analytics-diagnostic-method` apply. Two traffic-specific additions:

- **Minimum meaningful daily volume**: below ~300 sessions/day, daily noise is ±30%. Don't diagnose daily swings; look at weekly.
- **Alerting threshold**: whatever your alert threshold is (e.g. "alert if daily sessions drop >20%"), make sure that threshold is outside the historical noise band. If the metric naturally swings ±25% week-over-week, a 20% alert fires on every normal Monday.

## Presenting the diagnosis (Pyramid)

```
VERDICT: <one sentence: what the change is, what caused it>

EVIDENCE:
- <time shape + specific numbers>
- <channel / cohort / page split that localizes the cause>
- <triangulation: second source of data that agrees>

WHAT TO DO NEXT:
- <action, ranked by impact>

CAVEATS:
- <sample size, measurement limits, unresolved alternatives>
```

If the diagnosis is "measurement regression", don't just say "it's broken". Say which page/event/tag, when it broke, what the fix is, and what the actual underlying traffic number is now that you've accounted for the regression.

## Worked example

```
User: pageviews dropped ~40% starting April 19, what's going on?

Agent:

[Measurement first]
- Realtime dashboard: ~60% of normal hourly pageviews right now.
- Event-to-pageview ratio: events dropped only 12% over the same window.
  Pageviews dropped disproportionately more than events. That's suspicious.
- Server access log sanity: request count to app routes is ~flat.
- Deploy log: app deploy on April 19 at 14:02 UTC.

This fingerprints F3 (deploy-correlated drop) with an F1 (tracking regression) overlay.

[Time shape]
Daily chart: cliff at April 19, not a ramp. Hourly chart: drop starts at
14:00-15:00 UTC April 19, exactly aligned with deploy.

[Channel split]
All channels dropped ~proportionally (Direct -42%, Organic -39%,
Paid -38%). Proportional drop across channels means site-wide or
measurement, not a channel issue.

[Page split]
The drop is concentrated on pages under `/blog/*`. Those pages got
restructured in the deploy. Redirects exist but the new page template
is missing the analytics snippet include.

[Triangulation]
- Server logs: blog request volume is normal.
- Database: blog content loads fine.
- Analytics: blog pageviews showing near zero since the deploy.

VERDICT: The April 19 deploy removed the analytics snippet from the new
blog template. Traffic is not actually down; only blog pageview tracking
broke. Real site traffic is roughly flat week-over-week.

EVIDENCE:
- Event-to-pageview ratio shift (events -12%, pageviews -40%) rules out
  a real traffic drop.
- The drop is site-wide in the analytics tool but blog-specific in
  server logs, localizing the break to blog page tracking.
- Timing aligns to the minute with the April 19 14:02 UTC deploy.

WHAT TO DO NEXT:
- Add the analytics snippet back to the new blog template (one-line fix
  in the layout file). ETA: today.
- Backfill the missing blog pageviews from server logs if your reporting
  has to cover this week. Otherwise note the gap.
- Add a post-deploy smoke test: `curl -s <blog page> | grep <analytics
  snippet ID>`. Prevents the next regression.

CAVEATS:
- Non-blog tracking looks healthy, but run the same snippet-presence
  check across all page templates to confirm this is the only break.
```

## Traps to avoid

- **Skipping measurement and going straight to "it must be SEO"**. Most of the time it isn't. Check measurement first, always.
- **Trusting one dashboard**. Triangulate with a second source (server logs, DB counts, payment platform).
- **Diagnosing a spike without filtering bots**. A "50% traffic increase" that's 90% bot is a traffic *decrease* in reality.
- **Comparing Monday to Sunday**. Use week-over-week at the same day-of-week, or 4-week trailing average.
- **Ignoring the shape**. Cliffs and ramps have different causes. Read the curve before reading the numbers.
- **Confirming "it was the redesign"**. Redesigns often break tracking. Split the tracking question from the UX question before blaming UX.
- **Acting on small-sample weirdness**. A 40% change on 80 sessions is noise. Say so.

## Clamp MCP cheatsheet

| Check | Clamp tool |
|---|---|
| Realtime sanity | `traffic.live` |
| Time shape (hourly or daily) | `traffic.timeseries` with appropriate interval |
| Before/after comparison of the drop window | `mcp_clamp_traffic_compare` |
| Channel localization | `referrers.top` |
| Page / landing page localization | `pages.top` |
| Geo / device / new-vs-returning cohorts | `traffic.breakdown` |
| Country-level bot spike check | `countries.top`, `cities.top` |
| Which events still fire | `events.list` |
| Engagement-level bot filter | `pages.engagement` (look for sessions with ~0s duration) |

Using a different tool (GA4, Plausible, Fathom, PostHog)? The method is identical; translate the tool calls.
