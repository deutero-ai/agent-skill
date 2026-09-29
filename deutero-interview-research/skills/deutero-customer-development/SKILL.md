---
name: deutero-customer-development
description: Turn a business idea, startup concept, pitch deck or business plan into a Deutero customer discovery study that tests whether the problem is real before anything gets built — extract the risky assumptions, write an interview that can actually disconfirm them, define and screen a findable target population, and plan recruitment for people you do not yet have. Use this whenever someone wants to validate an idea, test demand, do customer discovery or "mom test" interviews, talk to potential customers, size a problem before building, check willingness to pay, or has a plan/deck/one-pager and wants research on it. Also use it when someone asks what information they need to supply to get a good discovery study built.
---

# Customer development from an idea

The point of a discovery interview is to find out whether the problem is real and painful enough that people are already spending money, time or attention on it. It is not to find out whether people like the idea. They will say they like it, because they are being polite to someone who is visibly hoping they will.

So the whole design problem is this: **write an interview whose questions the participant could not answer agreeably without lying about their own past.** Questions about what happened cannot be flattered. Questions about the future can, and will be.

## Step 1: Intake — what the user must supply

A high-quality study needs a real brief. `references/intake-brief.md` is the full checklist with examples of adequate and inadequate answers; work through it conversationally rather than pasting it at the user.

The five things that actually change the study:

1. **Who has the problem.** Not the market — the person. A role, a situation, and something they do that you could verify. "Ops managers at 3PL warehouses who still build shift rotas in Excel" is workable; "logistics companies" is not.
2. **What they do today.** The current solution, including the ugly manual one. If the answer is "nothing", the study has to test whether the problem is felt at all, which is a different and harder study.
3. **The problem, as a cost.** What it costs them now in money, hours, errors or risk — and how the user knows that, versus assumes it.
4. **The riskiest assumption.** The one that, if false, kills the idea. Push for this; most people name the second-riskiest because the first is uncomfortable.
5. **The decision waiting on the answer.** Build, don't build, pivot the segment, change the pricing model. A study with no decision behind it produces a document.

A deck or plan usually contains items 1–3 and almost never states 4 or 5 honestly. Read what they give you, extract what is there, and ask for the rest.

**When the brief is thin, say so and build anyway** under stated assumptions — but name which findings will be unreliable because of it. Refusing to start until the brief is perfect helps nobody; pretending a thin brief produced a solid study is worse.

## Step 2: Extract and rank the assumptions

From the brief, write out the assumptions as falsifiable claims, then rank them by *risk × cost of being wrong*. Test the top two or three. An interview that tries to test eight assumptions tests none of them.

The four that are usually riskiest, in this order:

- **Problem existence** — does this actually happen to them, recently, more than once?
- **Problem severity** — have they already spent money, time or political capital trying to fix it? Existing spend is the strongest signal available in an interview.
- **Segment** — is the person you can reach the person with the problem and the person who can buy?
- **Solution shape** — of the ways this could be solved, does yours fit how they work?

Notice that "will they pay $X" sits below all of these. Pricing research on an unvalidated problem is precision on top of noise.

## Step 3: Write questions about the past

`references/discovery-questions.md` has the full question set with types and guidance, organised by assumption. The principles behind it:

- **Ask about the last time it happened**, not whether it happens. "When did this last come up?" gets a date or an admission that it does not.
- **Ask what they did about it.** Effort already spent is the measurement of pain. Money already spent is better.
- **Ask about the workaround in detail.** The workaround is the competitor, and its shape tells you what the product must beat.
- **Enumerate where you can.** Which tools, which triggers, who decided — these are `choices` or `multi_select` questions with an escape option, and the follow-up carries the reasoning. Spending open-ended questions on things you could have listed is what produces four-word answers.
- **Do not describe the idea until the end, if at all.** Once the participant knows what you are hoping for, everything after it is contaminated. Where you must test solution fit, put it last and frame it as a choice between real alternatives rather than a reaction to yours.
- **Never ask "would you use this" or "what would you pay".** Both are hypotheticals about a product that does not exist. Ask what they pay now, what budget it would come out of, and who signs.

Build the set with `deutero-study-authoring` — types, config, guidance, `validate_questions`. Ask the user which `model_tier` to run on before creating the study, and hand them the `dashboard_url` from `create_study` as soon as it exists. Set `survey_type: "customer_development"`, and write `research_question` and `objectives` as the assumptions under test, in those words. The interviewer reads them, and an interviewer that knows it is testing "whether they have already paid to solve this" probes for it.

`draft_study` takes a `customer_development` brief — `problem_hypothesis`, `customer_segment`, `solution_concept`, `key_assumptions`, `success_criteria` — which maps straight onto the intake above, and will draft the study details from it. Useful when the user hands you a deck and wants something to react to; rewrite its `research_question` and `objectives` into your ranked assumptions before `create_study`. Do not use `generate_questions` for the discovery set: it writes a plausible general interview, not one built on questions about the past and the two assumptions you ranked. `references/discovery-questions.md` is the set.

## Step 4: Find and qualify the population

This is the part people underestimate, because unlike product research you have no user list — you are recruiting strangers who may not exist in the shape you imagine. `references/population-and-recruiting.md` covers it properly: turning a market description into a findable population, choosing between panels, communities, professional networks and personal introductions, and what each one does to your sample.

The essential moves:

- **Define the population by behaviour you could verify**, not by attitude or by firmographics alone. "Ran a rota change in the last 30 days" is screenable; "cares about efficiency" is not.
- **Screen on behaviour, in three to five questions**, with `acceptable_options` listing who qualifies. Never make the qualifying answer obvious — if the incentive is real, people will select whatever gets them in.
- **Watch for the two sampling traps.** Your own network agrees with you, and a paid panel contains professional respondents who will claim any qualification. Mixing sources and screening on specifics is the defence against both.
- **Decide who the buyer is**, and whether you are interviewing them or the user. In B2B these are different people with different answers, and a study that conflates them produces an idea that users love and nobody buys.

Eight to twelve interviews per segment is the usual target. Stop when new interviews stop surprising you, which is both the honest criterion and usually sooner than you feared.

## Step 5: Test the instrument before spending on strangers

A discovery interview that asks leading questions returns validation no matter what the truth is, and you will not notice from inside it. Run it against personas first — one enthusiast, one sceptic, one who genuinely does not have the problem. If the sceptic and the non-customer both come out sounding encouraging, the questions are leading and need rewriting before a single real participant sees them. See `deutero-simulation`.

This is the highest-value use of simulation on the platform, and it costs a fraction of what a wasted round of real interviews costs.

## Step 6: Report against the assumptions, not the themes

Go back to the ranked assumptions and mark each one: supported, contradicted, or untested. Give the count and a quote for each.

Be straight about disconfirmation. The user hopes the idea is validated, and an agreeable report is worse than no report, because it costs them the next year. If the interviews did not support the core assumption, lead with that and say precisely which evidence points that way. If the interviews were too agreeable to tell — a real outcome — say that instead of manufacturing a conclusion.

Watch particularly for: enthusiasm without any past behaviour behind it (the classic false positive); a problem that is real but ranks tenth on their list; and a segment where the person with the problem has no budget. All three look like validation in a summary and none of them is.

## References

- `references/intake-brief.md` — what to ask the user for, with adequate and inadequate examples, and how to mine a deck or plan for it
- `references/discovery-questions.md` — the question set by assumption, with types and guidance, plus the questions never to ask
- `references/population-and-recruiting.md` — defining a findable population, screening design, recruitment channels and their biases
