---
name: event-schema-author
description: Author and maintain an event-schema.yaml file. A portable, typed declaration of every product analytics event the codebase fires (event names, properties, types, intent). The CLI generates a TypeScript type from it so tracking calls are autocompleted and type-checked at build time. Vendor-neutral; works with any analytics SDK (Clamp, GA4, Mixpanel, Amplitude, PostHog, Segment).
when_to_use: When the user says "declare my events", "set up typed events", "make tracking type-safe", "audit what we're tracking", "stop typo'd event names", or equivalent. Also a natural follow-up to `analytics-profile-setup` for any project that has more than a handful of `track()` calls.
---

# Event schema author

A repo without a declared event schema is one where the source of truth for "what events do we fire and what do they carry" is grep. That breaks two things: (1) typo'd event names ship to production and silently fragment your data; (2) AI agents and new teammates have to reverse-engineer intent from call sites.

This skill produces (or updates) `event-schema.yaml` at the repo root, runs the CLI to generate a TypeScript type, and wires it into the tracking call sites. The format is an open spec ([clamp-sh/event-schema](https://github.com/clamp-sh/event-schema)), and the generated type works with any analytics SDK.

## When NOT to run this

- The codebase has zero `track()`-style calls. There's nothing to declare. Nudge the user to instrument first.
- The user fires exactly one event. Hand-rolling a 3-line `type Events = { ... }` at the call site is fine. Schema is for projects with growth ahead, not toy projects.
- The codebase already has an `event-schema.yaml` and the user is asking a different question (e.g. "what should I track next?"). Don't re-author from scratch; answer the actual question.

## Method

### Phase 1. Discover what's already tracked

Before writing anything, build a picture of the existing tracking surface. Run searches that catch the common patterns:

```
# Generic; most analytics SDKs expose a track() function
rg -n "track\(" --type ts --type tsx --type js --type jsx

# Common SDK-specific shapes (broaden as needed)
rg -n "analytics\.track\(|posthog\.capture\(|mixpanel\.track\(|amplitude\.track\(|gtag\(|window\._mtm" --type ts --type tsx --type js
```

Build a table in scratch:

| Event name | Call sites | Properties seen | Required? (in every call) |
|---|---|---|---|
| `signup` | 2 | `plan`, `source` | both |
| `cta_click` | 5 | `location`, `destination`, `variant?` | first two only |

Two important judgments here:

- **Required vs optional**: a property is *required* only if every call site passes it. If 4/5 do, it's optional with examples. Don't mark something required that the codebase doesn't actually guarantee.
- **Property type**: infer from the observed values. `"pro"` is a `string`. `5` is a `number`. `{ amount, currency }` is `money`. A small, fixed set of values like `"free" | "pro" | "growth"` is an `enum`. Don't invent enum values you didn't see.

Also check for an existing schema file (don't overwrite blindly):

```
ls event-schema.yaml event-schema.json 2>/dev/null
```

If one exists, treat this as an *update* pass (Phase 2 reads from it instead of starting blank).

### Phase 2. Draft the schema

Group events into the YAML shape. The format is small: one `version`, a map of `events`, each with optional `intent` and required `properties`:

```yaml
version: "0.1"  # the version string MUST be quoted; unquoted 0.1 parses as a number

events:
  signup:
    intent: |
      Account creation succeeded. Numerator of every funnel that ends at "real user".
    properties:
      plan:
        type: enum
        values: [free, pro, growth]
        required: true
      method:
        type: enum
        values: [email, github, google]
        required: true

  cta_click:
    intent: Top-of-funnel engagement signal. Which CTA earned the click.
    properties:
      location:
        type: string
        required: true
        examples: [hero_primary, nav_signup, final_cta]
      destination:
        type: string
        required: true
```

Property types: `string`, `number`, `boolean`, `enum` (with `values: [...]`), `money` (a `{ amount, currency }` pair). Each property may also declare `description` (carried into the generated JSDoc) and `examples: [...]` (sample values, surfaced as `@example`, purely informational).

### Phase 3. The intent question (do not skip)

You can infer almost everything from the codebase except **intent**. Intent is one sentence on what the event is *for*: the decision it informs, the funnel it belongs to, why it exists. Without it, the schema is just a typed dictionary; with it, the schema is documentation a new teammate or agent can read in 30 seconds.

For each event, decide:

- If the call site has a comment or the event name is self-explanatory (`page_viewed`, `app_opened`), draft the intent yourself.
- If the event name is ambiguous (`feature_used`, `engagement`, `event_42`), **ask the user**. One sentence each, batched in one message: "Quick read on intent (one sentence per event so the schema documents itself): `feature_used` is for ___; `engagement` is for ___; …"

Don't fabricate intent. "Generic engagement event" is worse than no intent at all because it tells the next reader the schema is full of filler.

### Phase 4. Write the file and run the CLI

Write the YAML to `event-schema.yaml` at the repo root. Then run:

```
npx @clamp-sh/event-schema validate
npx @clamp-sh/event-schema generate
```

`validate` checks against the spec's meta-schema and exits non-zero on errors. `generate` writes `event-schema.d.ts` next to the YAML by default. (Use `-o <path>` for a different location, `-o -` for stdout.)

If `validate` fails, fix the schema. Common errors:

- Unquoted version (`version: 0.1` must become `"0.1"`).
- `enum` without `values:`.
- Property type other than the five supported. For `array`, `object`, `date`, use `string` and document the format in `description`.

### Phase 5. Wire the generated type into call sites

The generated type is named `AnalyticsEvents` by default (override with `--type-name`). Pass it as a generic at the call site of whichever SDK the project uses. The pattern depends on the SDK:

- **Clamp SDK**: call `init<AnalyticsEvents>(...)` once at app start, then plain `track("name", { ... })` calls are typed.
- **Generic / no SDK-side generic**: wrap `track` in a tiny typed helper:

  ```ts
  import type { AnalyticsEvents } from "./event-schema"

  function track<K extends keyof AnalyticsEvents>(
    event: K,
    props: AnalyticsEvents[K],
  ) {
    return analytics.track(event, props)  // or whatever the underlying SDK is
  }
  ```

- **Inline at one call site** (no app-wide change): `track<AnalyticsEvents>("signup", { plan: "pro", method: "email" })`.

Pick whichever is least invasive for the codebase. Don't refactor every call site if a one-line helper does the job.

### Phase 6. Suggest CI integration (optional, ask first)

For projects where this matters, propose adding `event-schema validate` to a precommit hook or CI pipeline. This catches schema drift (someone editing the YAML to remove a required property while call sites still pass it) at PR time instead of in production.

Don't push this on every project. Ask: "Want me to wire `event-schema validate` into your CI / precommit so the schema can't silently drift?"

## Vendor neutrality

The spec and the generated TypeScript are tool-agnostic. The same `AnalyticsEvents` type can be used by code that fires events to GA4, Mixpanel, Amplitude, PostHog, Segment, Clamp, or any combination. The CLI knows nothing about analytics destinations; it only validates and generates types.

Two implications:

- Don't mention Clamp in the schema or in code unless the project actually uses Clamp.
- If the project sends events to multiple destinations (e.g. Segment fanning out to Mixpanel and GA4), one schema covers all of them. The schema describes the events the *application* fires, not where they end up.

## Traps to avoid

- **Don't dump every event you find without intent.** A 50-event schema with no intent fields is worse than no schema. It tells the next reader "we don't actually know what these are for". If the user can't explain an event in one sentence, that's a finding, not a reason to skip it.
- **Don't mark properties required that aren't.** "Required in the schema" means "every call site MUST pass it, and TypeScript will refuse to compile if you forget". Be honest about what the codebase actually guarantees.
- **Don't invent enum values you haven't seen.** If `plan` is only ever `"free"` or `"pro"` in the codebase, declare those two. Don't speculatively add `"growth"`, `"enterprise"`, `"trial"` because they "might exist". Add them when they do.
- **Don't ship an unquoted version.** YAML `version: 0.1` parses as a number; the spec requires a string. Use `version: "0.1"`. The validator will catch this; mention it preemptively so the user isn't surprised.
- **Don't over-engineer the wrapper.** If the SDK supports a generic, use it. Only write a wrapper helper when it doesn't. A 3-line helper is fine; a 30-line abstraction is not.

## Worked example

```
User: declare my events properly, tracking is a mess

Agent: [Phase 1: discover]
Scanning for tracking calls...

rg -n "track\(" --type ts --type tsx
→ found 14 call sites across 8 files

Distinct events I see:
- signup_completed (2 sites): { plan, method }, both required in every call
- cta_click (5 sites): { location, destination, variant? }, variant in 3/5
- feature_used (4 sites): { name, via_keyboard? }, name always, via_keyboard in 1
- checkout_completed (2 sites): { plan, total: Money }, both required
- page_section_viewed (1 site): { section }, required

I don't see an existing event-schema.yaml. I'll draft one.

[Phase 3: intent]
Three of these are self-explanatory (signup_completed, checkout_completed,
page_section_viewed). Two are ambiguous; quick one-line intent each so
the schema documents itself:

  cta_click: ?
  feature_used: ?

User: cta_click is top-of-funnel engagement, which CTA earned the click;
feature_used is a core product action being triggered, used for activation
metrics

Agent: [Phase 4: write + run]
Wrote event-schema.yaml at repo root.

$ npx @clamp-sh/event-schema validate
✓ event-schema.yaml is valid (5 events, 12 properties)

$ npx @clamp-sh/event-schema generate
✓ wrote event-schema.d.ts

[Phase 5: wire]
You're using @clamp-sh/analytics, which supports the generic at init():

  // src/analytics.ts
  import { init } from "@clamp-sh/analytics"
  import type { AnalyticsEvents } from "../event-schema"
  init<AnalyticsEvents>("proj_xxx")

That's the only change. Every existing track() call across your 8 files
is now type-checked against the schema. Try renaming a property in the
YAML and `tsc` will surface every broken call site.

[Phase 6: CI]
Want me to add `event-schema validate` to your precommit hook so the
schema can't silently drift?
```

## Cross-references

- **Spec and CLI**: `@clamp-sh/event-schema` on npm; spec at github.com/clamp-sh/event-schema.
- **`analytics-profile-setup`**: captures business context (model, ICP, primary conversion). Run that first if the project is also new to you. Knowing the primary conversion event helps you spot which events in the codebase are load-bearing vs decorative.
- **`channel-and-funnel-quality`**: once events are typed, funnel definitions can reference them by name with property predicates (e.g. `cta_click[location=hero_primary]`). That skill assumes you know what events fire; this skill is what makes that true.
