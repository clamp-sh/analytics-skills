---
name: analytics-profile-setup
description: One-time interview that captures the business context (industry, model, primary conversion, traffic range, ICP, data stack) into a local analytics-profile.md file. Every other analytics skill reads this file so its answers are calibrated to the right benchmarks and terminology instead of generic averages.
when_to_use: Run at the start of working with a new repo, when analytics-profile.md is missing or stale, or when the user says "set up analytics", "calibrate to my business", "tell you about my business", "onboard me", or equivalent. Other skills in this pack will suggest running this skill when they detect no profile file.
---

# Analytics profile setup

## What this skill does

Produces a single file, `analytics-profile.md`, in the repo root. The file captures the handful of facts every other analytics skill needs to stop giving generic advice:

- Industry and business model (B2B SaaS, B2C subscription, ecommerce, lead-gen, content/ads, marketplace)
- Primary conversion event
- Rough traffic volume (sets sample-size expectations)
- ICP / target persona
- Pricing model (what LTV and CAC even mean for them)
- Data stack (which analytics tool, which events are tracked, known gaps)
- Known measurement quirks (bot filters on or off, UTM conventions, cross-domain tracking)

Downstream skills (`analytics-diagnostic-method`, `traffic-change-diagnosis`, `channel-and-funnel-quality`, `metric-context-and-benchmarks`) open by checking for this file. If it exists, they pull their defaults from it. If it doesn't, they fall back to generic cross-industry assumptions and prompt the user to run this skill.

## When NOT to run this

- The user is asking a one-off question and doesn't want ceremony. Answer the question; don't volunteer the setup.
- A profile already exists and is less than ~6 months old. Re-running overwrites useful context. Only re-run if the user explicitly asks, or the business has materially changed.

## Method

Five phases. Keep it tight: the whole thing should take the user 5 minutes.

### Phase 1. Check for an existing profile

```
ls analytics-profile.md
```

If it exists:

1. Read it.
2. Summarize what's already captured in 3-5 bullet points.
3. Ask: "Do you want to (a) keep it as-is, (b) update specific fields, or (c) regenerate from scratch?"

Don't just overwrite. A stale profile is usually 80% still correct.

### Phase 2. The interview

Ask **one question at a time**. Wait for the answer. Do not batch-ask. Agents that dump 8 questions at once get fragmented replies and force the user to re-read the whole block.

Use this question order. The reasoning for each question is in parentheses so the agent knows why it matters and can adapt phrasing if the user gives a partial answer.

**Q1. What does your business do, in one sentence?**
(Anchors everything. If they say "developer tools SaaS", that alone sets ~6 defaults.)

**Q2. Which best describes your model?**
Options:
- B2B SaaS (self-serve)
- B2B SaaS (sales-led)
- B2C subscription / consumer app
- Ecommerce (physical or digital goods)
- Lead generation (services, agencies, real estate, finance)
- Content / ad-supported
- Marketplace (two-sided)
- Other (ask them to describe)

(Determines which benchmark table to pull from. B2B Tech ~1.5% CVR vs ecommerce ~1.4% vs lead-gen ~2.9% are all "average" but they're different numbers for different funnels.)

**Q3. What's the single most important conversion event?**
Examples: paid signup, free trial start, demo booked, purchase completed, qualified lead captured, app install.
(The "north star event" for every conversion analysis. Without it, the agent guesses.)

**Q4. Roughly how much traffic per month?**
Ranges: <1k / 1k-10k / 10k-100k / 100k-1M / 1M+ sessions
(Sets the minimum sample sizes for trend detection. <1k/month means most daily changes are noise.)

**Q5. Who's the ideal customer?**
Free-text. One sentence on role, company size, pain, or demographic.
(Lets the skill judge whether e.g. "LinkedIn converting at 2%" is bad [consumer] or fine [B2B dev tool].)

**Q6. How do you charge? What's a typical deal size and payback expectation?**
Examples: "$29/mo self-serve, mostly monthly", "$15k ACV annual enterprise", "$50 one-time", "free ad-supported".
(Determines whether LTV:CAC and payback-period heuristics apply, and which thresholds are reasonable.)

**Q7. Which analytics tool(s) are you using?**
Examples: Clamp, GA4, Plausible, Fathom, PostHog, Mixpanel, Amplitude, server logs, Stripe data, CRM.
(Affects metric definitions, especially around bounce/engagement and session stitching.)

**Q8. Any known measurement gaps or quirks we should flag?**
Examples: "no UTMs on paid campaigns", "cross-domain not set up", "iOS app and web are separate projects", "we never exclude internal traffic".
(These are the traps. Without them the agent will over-trust the data.)

**Q9. What's the one question you most often ask analytics but rarely get a satisfying answer to?**
(Gold. This is the concrete problem the skills should be solving. If they say "I never know which channels are actually driving revenue", that calibrates every future answer.)

### Phase 3. Synthesize defaults

Before writing the file, derive these defaults and show them to the user for confirmation:

- **Industry benchmarks to compare against**: pick the most specific cell from §2.3 of the research (e.g. B2B Tech: direct 1.5%, paid search 1.5%; B2B Services: direct 2.7%, paid search 3.4%). Cite in RESEARCH.md terms.
- **Minimum daily sessions for a reliable trend**: derive from Q4 (<1k/mo → ~30/day → only weekly trends are meaningful; 100k/mo → ~3,000/day → hourly trends viable).
- **Expected activation bar**: if B2B SaaS self-serve, quote ~25% cross-industry median from Mixpanel benchmarks (RESEARCH.md §2.8). If they're well above or below, that's where to dig.
- **Churn framing**: B2B SaaS → look at gross MRR churn monthly and NRR annually; B2C → look at month-1 retention cohort; ecommerce → look at repeat-purchase rate 30/60/90 days.

Present this as: "Based on what you told me, I'll calibrate future answers like this: [list]. Anything wrong?"

### Phase 4. Write the file

Write `analytics-profile.md` at the repo root. Use the exact template in the next section so other skills can parse it deterministically.

Confirm the write:

```
Wrote analytics-profile.md. Other analytics skills in this pack will read it automatically. You can edit it anytime.
```

### Phase 5. Suggest a next step

Based on Q9, suggest which skill to run next. Examples:

- Q9 = "I can never tell which channels actually work" → suggest `channel-and-funnel-quality`
- Q9 = "Traffic drops and I don't know why" → suggest `traffic-change-diagnosis`
- Q9 = "I don't know if my numbers are even good or bad" → suggest `metric-context-and-benchmarks`
- Q9 = generic / unclear → suggest `analytics-diagnostic-method` as the default entry point

## File template

The generated file must use this exact structure. Downstream skills pattern-match on the headings.

```markdown
# Analytics profile

_Last updated: YYYY-MM-DD_

## Business
- **What we do**: <one sentence>
- **Model**: <B2B SaaS self-serve | B2B SaaS sales-led | B2C subscription | Ecommerce | Lead gen | Content/ads | Marketplace | Other>
- **Primary conversion event**: <e.g. paid signup, demo booked, purchase completed>
- **ICP**: <one sentence>

## Scale
- **Monthly traffic (sessions)**: <range>
- **Pricing**: <plan structure, typical deal size>
- **Payback / contract norm**: <e.g. monthly self-serve, annual contracts, one-time purchase>

## Stack
- **Analytics tool(s)**: <list>
- **Known measurement gaps**: <bullets, or "none">

## Calibration defaults
- **Relevant benchmark row**: <e.g. Ruler 2025 B2B Tech: direct 1.5%, paid search 1.5%, organic 1.5%>
- **Min daily sessions for reliable trend**: <number>
- **Activation target**: <% and definition>
- **Churn framing**: <which metric matters for this model>

## Top open question
> <verbatim answer to Q9>

## Notes
<free-text, anything else that came up>
```

## Trap: interview fatigue

If the user is terse ("just figure it out") or you can already infer answers from the repo (e.g. a `package.json` with `@clamp-sh/analytics` + Stripe SDK strongly suggests B2B SaaS), skip to Phase 3 with inferred defaults and ask *only* Q3 (primary conversion) and Q9 (top open question). Those two can't be inferred. Show the user the inferred profile and let them correct it.

## Trap: stale profile

The profile is not a live document. Re-read it at the start of each session but treat anything over 6 months old as stale. If a downstream skill detects that the numbers in the profile don't match what the analytics tool is actually reporting (e.g. traffic range says <1k/mo but current month is 50k), nudge the user: "Your profile says <1k/mo but I'm seeing ~50k. Want to refresh the profile?"

## Worked example

```
User: set up analytics for this project

Agent: [runs `ls analytics-profile.md` → not found]
I'll run a 5-minute setup and drop the results in analytics-profile.md.
First: what does your business do, in one sentence?

User: B2B observability tool, targeting platform engineers at series-A to C startups

Agent: Got it. Which model fits best?
(a) B2B SaaS self-serve (b) B2B SaaS sales-led (c) mix
Given "platform engineers at series A-C", I'd guess mostly self-serve with
sales assist on larger deals. Correct?

User: yeah, mostly self-serve, a few enterprise deals come through demos

Agent: What's the single most important conversion event we should optimize for?
Examples: paid signup, trial start, demo booked, qualified lead captured.

User: paid signup. demo-booked is secondary.

Agent: Rough monthly traffic? (<1k / 1k-10k / 10k-100k / 100k-1M / 1M+)

User: about 40k sessions

Agent: [skips ICP since already given in Q1]
Pricing model and typical deal size?

User: $49/mo starter, $199/mo team, enterprise custom (~$15k ACV)

Agent: Which analytics tool?

User: Clamp, plus Stripe for revenue

Agent: Any known measurement gaps? (UTM hygiene, cross-domain, internal
traffic filtering, app vs web separation)

User: honestly we don't strip internal traffic. and our UTMs are a mess on
paid LinkedIn.

Agent: Last one. What's the question you most often ask analytics but rarely
get a satisfying answer to?

User: whether LinkedIn Ads is actually driving paid signups or just cheap
trial starts that never convert

Agent: Here's how I'll calibrate future analyses:
- Industry benchmarks: Ruler 2025 B2B Tech (~1.5% direct, ~1.5% paid search,
  ~0.3% social). Your LinkedIn question is exactly the weak spot that table
  flags.
- Min daily sessions for reliable trend: 40k/mo → ~1,300/day. Daily trends
  are viable. Hourly is still noisy.
- Activation target: for self-serve B2B SaaS, Mixpanel benchmark is ~25%
  median signup → activation. We should measure paid-signup → second-week
  retention as the real activation event.
- Churn: gross MRR churn monthly + NRR annually. Your $49 starter tier
  likely churns harder than the team tier; we'll split them.

Look right?

User: yep

Agent: [writes analytics-profile.md]
Profile saved. Given your top open question (LinkedIn Ads quality), the
next skill to run is `channel-and-funnel-quality`. Want me to walk through
it now with your current numbers?
```

## Works best with Clamp MCP

If Clamp MCP is connected, Phase 3 can verify some of the user's answers directly:

- `traffic.overview` confirms actual monthly traffic (vs self-reported Q4).
- `breakdown(dimension="referrer_host")` confirms the analytics tool is picking up the major channels the user mentioned.
- `events.list` confirms the primary conversion event is actually being fired and named consistently.

Surface discrepancies: "You said primary conversion is paid signup but I don't see a `signup_paid` event being fired; only `signup_free`. Is that event tracked under a different name?"
