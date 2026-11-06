# Analytics intake

Platform-agnostic. The same four things are needed whether the source is PostHog, Amplitude, Mixpanel, GA4, Heap, a warehouse query, a product dashboard or a table pasted into chat.

## The intake

### 1. The observation

Get all five parts. A metric without them cannot be turned into a segment.

| Part | Why it matters | Example |
|---|---|---|
| Metric and definition | "Activation" means five different things at five companies | "Completed first import within 7 days of signup" |
| Value and direction | The claim itself | "41% → 29%" |
| Denominator | Decides whether this is worth a study at all | "≈1,400 self-serve signups/week" |
| Time window | Decides who you can still reach and what they remember | "Since the 12 March onboarding change" |
| Comparison | Distinguishes a change from a level | "vs. the eight weeks before" |

Sanity-check before going further. A shift inside the noise band of a small denominator, a definition that changed when the tracking changed, a seasonal pattern, a bot filter that was switched on — these account for a large share of "the metric moved" and none of them is an interview.

### 2. The segment

You need a definition precise enough to (a) target in-product, (b) screen for, and (c) write as `target_population`. Push for the event-level definition, not the label:

- Behavioural: which events they did and did not fire, in what order, in what window.
- Firmographic/demographic: plan, seat count, tenure, industry, region.
- Acquisition: channel, campaign, referral.
- Platform: web, iOS, Android, which app version.

Then ask the question that saves the study: **is this segment still reachable?** Churned users a year out mostly are not, and a study designed around people you cannot contact fails at recruitment rather than at design.

### 3. Product context

- What is the feature for, in the team's own words?
- What changed recently — shipped code, pricing, onboarding, support policy, a competitor's move?
- What does the team already believe is happening? Write it down verbatim. The study must be capable of disconfirming it.
- **What decision is waiting on this?** If there is no decision, say so and ask whether to continue. Often the honest answer is that the team wants reassurance, and that is worth naming.

### 4. What the data already answers

List it. Everything on this list is banned from the interview, because asking people to report facts you hold precisely buys you worse data at the cost of their attention.

## Turning a metric into a study

| Analytics observation | The human question behind it |
|---|---|
| Funnel step drop-off | What were they trying to do, and what did they do instead when it did not work? |
| Churn in a cohort | What changed in their world, and what are they using now? |
| Feature shipped, nobody uses it | Did they know it existed, and does it solve a problem they actually have? |
| Support tickets spiking on one flow | What did they expect to happen, and what made them give up and contact a human? |
| A segment using the product in an unexpected way | What job are they hiring it for, and what are they working around? |
| Two segments with very different retention | What is different about the work, not about the people? |

## If you have programmatic access to the analytics tool

Use it to sharpen, not to replace the conversation with the user.

- Verify the denominator and the window yourself before designing anything around them.
- Pull the *sequence* of events for a sample of the affected users, not only the aggregate. Sequences suggest questions; aggregates do not.
- Get the segment definition into a form the product team can also use for in-app targeting — an event name and property filter — so the embed trigger and the analysis cut are the same population.
- Check whether the segment overlaps something obvious (a single plan, a single country, one app version). A study is wasted on what a 20-minute query would have answered.

If you do not have access, ask for: the funnel or retention chart with its definitions, a per-segment breakdown, and the event names involved. A screenshot plus the event names is usually enough.

## Sample size

For a "why" study you are looking for mechanisms, not proportions. Eight to twelve interviews in one reasonably homogeneous segment is a normal target, and the honest signal that you have enough is that new interviews stop surprising you. If you find yourself wanting a percentage, that is a survey question or an analytics query, not an interview.

Split across two contrasting segments — retained vs. churned, adopted vs. did not — and you want roughly that many in each, because the comparison is the finding.
