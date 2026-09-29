---
name: deutero-product-research
description: Turn product analytics and product context into a Deutero user research study that explains the numbers — take a funnel drop, a churn cohort, a dead feature, a support-ticket spike or a surprising usage pattern, work out the questions only humans can answer, build the study, and recruit the exact people the data points at (in-product via the embed widget, or by email). Use this whenever someone has usage data, an analytics dashboard, a metric that moved, a segment behaving oddly, or a product decision they cannot make from the numbers, and wants to talk to users about it. Analytics-platform agnostic — works from PostHog, Amplitude, Mixpanel, GA4, a warehouse query or a CSV someone pasted. Also use it when the user asks to embed an interview or research copilot in their product, or to write recruitment emails for a user study.
---

# Research from analytics and product context

Analytics tells you what happened and to whom. It cannot tell you what the person was trying to do, what they did instead, or what would have changed their mind. That gap is the only thing this study is for, and keeping it in view is what separates a study that changes a roadmap from one that confirms a dashboard.

The failure mode is writing an interview that asks people to narrate the metric. They cannot. They do not know they are in the drop-off cohort, they do not remember the session, and asked to explain their own behaviour in the abstract they will invent a plausible reason. The study has to ask about the *occasion*, not the pattern.

## Step 1: Intake — what you need from the user

Build `references/analytics-intake.md` into the conversation rather than reciting it. You need four things, and it is worth one exchange to get them:

1. **The observation.** The specific number, with its denominator, its time window and its comparison. "Activation fell" is not usable; "week-2 retention for self-serve signups fell from 41% to 29% after the March onboarding change, n≈1,400/week" is.
2. **The segment.** Who exactly — plan, tenure, platform, acquisition channel, the event they did or did not fire. This becomes `target_population`, the screening rules, and the embed targeting, so vagueness here costs three times.
3. **The product context.** What the feature is for, what changed recently, what the team already believes is going on, and what decision is waiting on the answer. The existing belief matters most: a study that cannot disconfirm it is not worth running.
4. **What is already known from the data.** So you do not spend interview minutes asking people to tell you things the warehouse already knows exactly.

You do not need access to their analytics tool. If you have it — a query tool, an MCP connector, an export — use it to sharpen the segment and check the denominator. If you do not, ask for a pasted table or a screenshot. The study is the same either way; only how you verify the numbers changes.

If the user cannot name the decision waiting on the answer, say so plainly and ask. A study with no decision attached produces a document nobody acts on, and it is cheaper to find that out now.

## Step 2: Separate what the data answers from what only a person can

Write the two lists explicitly before writing a single question. It takes two minutes and it removes half the draft.

**The data already answers** — how many, which segment, in what order, how often, what they did next, whether it correlates with anything you have. Never ask these in an interview: you get worse data and you spend the participant's attention.

**Only a person can answer** — what they were trying to accomplish, what they expected to happen, what they did instead, what they compared you against, what the thing cost them beyond time, what would have to be true for them to have done the other thing, and the part of the story that happens outside your product entirely. That last one is where most of the real answer lives and is completely invisible to analytics.

## Step 3: Design the interview around an occasion

`references/question-patterns.md` has tested question shapes for the five common analytics triggers — funnel drop-off, churn, feature non-adoption, a support spike, and a surprising power-user pattern — each as a small question set with the type and guidance already chosen.

The general moves:

- **Anchor to the event.** "The last time you opened the import screen and didn't finish" beats "how do you find importing". If you have signed metadata in the embed context, the interviewer can anchor precisely; otherwise ask them to recall the most recent occasion.
- **Ask what they did instead.** The substitute is the competitor, and it is frequently a spreadsheet, a colleague, or nothing at all.
- **Enumerate where you can.** Reasons for abandoning a flow are usually a known short list plus a surprise. Make that a `choices` question with an escape option and `follow_up: true`, and spend the open questions on the surprise.
- **Ask about the last time, not the usual time.** "Usually" invites a summary; "last time" retrieves a memory.
- **Never read the metric to the participant.** Telling someone they are in a churn cohort changes what they say next.

Hand the built set to `deutero-study-authoring` for the mechanics — question types, config fields, guidance writing, `validate_questions`. Two things it will not let you skip: ask the user to choose the `model_tier` before the study is created, and give them the study's `dashboard_url` the moment it is.

Set `survey_type: "user_experience"`, and put the real numbers into `research_question` and `objectives`: the interviewer reads them and probes better for knowing what is at stake.

`draft_study_from_site` drafts a user research study from the product's landing page. It knows what the page claims, not what your data shows, so it is a starting point for the description at most — the numbers and the occasion still have to come from Steps 1 and 2. Likewise `generate_questions` will not anchor to your event unless told: if you use it, say the occasion and the known reasons list in `additional_instructions`, then hold the result against `references/question-patterns.md`.

## Step 4: Recruit the people the data points at

This is where an analytics-driven study either works or quietly fails. The segment is defined by behaviour, which means you can reach them precisely — and a generic panel would be worthless here.

**In-product, with the embed widget.** Usually the best channel: the people you want are already identified, already in context, and never have to switch tools. Create an embed key scoped to the study, place the trigger where the behaviour happens, and fire it *after* the moment rather than during it. Pass the segment as **verified** metadata — a signed token, not page-supplied metadata — whenever the interview branches on it or you will cut results by it, because page metadata can be edited in dev tools. Full mechanics, JWT requirements and placement guidance are in `deutero-study-authoring/references/recruitment-and-embedding.md`.

**By email**, when the cohort has left or is not in-product often. The one thing that lifts response rate is naming why this person specifically — "you cancelled in March" — rather than describing the research. Template and the four things the copy must carry are in the same reference.

**Screening** is a backstop, not the mechanism. Where you can target behaviourally you already have the right people; where you cannot, screen on behaviour rather than intention and keep it to three questions.

Whatever the channel, be straight about who is asking and what the answers are for. Research recruitment that reads like marketing gets treated like marketing.

## Step 5: Read it back against the data

The output is not a themes document. It is an answer to the decision named in Step 1, plus the places the interviews and the data disagree.

Take the disagreements seriously and do not smooth them over. When eleven people say the export is the reason they left and the export is used by 4% of the churned cohort, the interesting finding is that discrepancy, not either half of it. Usually it means the stated reason is a proxy for something else — and the transcripts, read closely, generally say what.

Report: the decision, what the interviews support, how many participants each finding rests on, a quote per finding, and what the interviews could not settle. Lead with whatever contradicts what the team believed going in, because that is the only part that changes anything.

`deutero-study-authoring/references/reading-results.md` covers transcript search, clustering and the mechanics.

## References

- `references/analytics-intake.md` — the intake checklist, platform-agnostic, with what to pull from any analytics tool and how to turn a metric into a segment definition
- `references/question-patterns.md` — question sets for the five common triggers: funnel drop-off, churn, feature non-adoption, support spike, unexpected power use
