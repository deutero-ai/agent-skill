---
name: agent-self-interview
description: Run a structured self-improvement interview in which an agent elicits its own operating preferences from its principal via Deutero, then turns the answers into proposed memory updates with a diff against the previous run. Use this whenever the user asks for an agent check-in, a self-check, a retro on how the agent is working, a calibration or feedback interview, wants to update the agent's operating defaults or behavior rules, asks some version of "how should I be working with you" or "how am I doing", or wants a Deutero study built about agent behavior. Also use when writing or revising any interview guide whose subject is how an AI agent should behave. This skill runs only on explicit request, never on a schedule.
---

# Agent Self-Interview

A way for an agent to ask its principal how it should operate, and turn the answers into memory changes rather than a transcript nobody reads.

The value sits almost entirely in question design. An interview built from broad questions about the agent's performance returns broad answers, and broad answers cannot be turned into behavior. An interview built from specific incidents and enumerated choices returns rules you can apply the same day.

## When to run this

Only when the user asks. There is no cadence and no proactive trigger. If you notice something worth interviewing about, say so in one line and let the user decide.

Agree the scope in one exchange before building anything. A study can carry several objectives comfortably, so the question is what the objectives are, not how few of them there can be. Interviews are durable and resumable, so the participant can answer across several sittings without losing state. Design for the questions that matter rather than for a time budget.

## Step 1: Read your current configuration, then gather incident evidence

This is the step that most determines whether the run is worth doing, and the one most likely to be skipped.

Start with the rules you are actually operating under. Read whatever holds your behavior defaults, in whatever form your setup keeps them, and note the current wording of anything the interview will touch. You need this twice over: to write questions that ask about the real rule rather than a paraphrase of it, and to recognize afterwards when an answer has overturned one. Without it a reversal reads as a new preference and the most valuable finding gets filed as an addition.

Then the incidents. Abstract questions get abstract answers. A question about how the agent should handle a category of work gets a category-level answer that still needs interpreting. A question about a specific thing that happened gets a specific answer, because the participant is recalling rather than theorizing.

Mine your own history on the chosen topics: past conversations, session logs, plan files, commit history, notes. Look for corrections the user made, tasks you handed back, moments you asked permission, outputs the user did not end up using, and work the user redid themselves. Aim for a handful of incidents with enough detail to name the task, roughly when it happened, and what the outcome was.

If you cannot find real incidents on a topic, say so and ask whether to keep it. A question with no incident behind it is the kind that returns nothing.

Favor incidents where you suspect you did badly, and note anywhere the user's stated preference and their actual behavior have diverged. That divergence is usually the most useful thing you can put in front of them.

## Step 2: Pick the question type before writing the question

This is the main lever, and Deutero gives you eight types (`deutero-study-authoring/references/question-types.md` has the config for each). Reaching for open-ended by default is what produces one-word answers, because an open question about an enumerable choice asks the participant to do work the instrument should have done.

**When you can enumerate the plausible answers, use a structured type.** If the real question is whether to stop at the first flag or finish the run, that is a `choices` question with those options and an escape hatch, not an open prompt. Write options that are positions a reasonable person might actually hold, include a "something else" or "depends on X" option so it is not a false dichotomy, and set `follow_up: true` so the interviewer probes the reason behind the pick. The pick gives you the rule, the follow-up gives you the condition attached to it.

`scale` works for questions of degree, like how aggressive a particular default should be. `multi_select` fits "which of these should I be doing". `ranking` fits priority ordering when tradeoffs are the point. `card_sort` fits sorting task types into buckets, which suits scope and ownership questions well. `slots` elicits several named values inside one natural conversation and is cleaner than splitting a multi-field answer across four questions.

**Reserve open-ended for genuine open ground.** Wins and losses over the last period, anything whose answer you could not have anticipated, and anything where the reasoning matters more than the position. These are worth keeping. They are just not the default.

Every structured question can still fall through to open probing once the answer is captured, so choosing a structured type costs nothing in depth.

## Step 3: Write the question text and the probing guidance

Anchor each question to its incident, then ask for a decision. "On the 14th you asked me to source permit data for Austin and I ran it end to end. Two days later you re-did the join keys yourself. Should I have handed that back at the start, or was the problem the execution rather than the ownership?" is answerable in a sentence, and the answer is directly actionable because it names a concrete judgment the participant can reject.

**One decision per question.** Compound questions get half-answered and the missing half goes unnoticed.

**Assume full technical depth.** The participant knows the domain better than the interviewer does. Do not explain concepts, define terms, or soften anything.

**Be literal rather than figurative.** What to avoid is not technical vocabulary but idiom and shorthand with an unstated referent. Say "upstream of a deliverable you need" rather than "blocking". Prefer the concrete noun to the metaphor. A term the participant has to ask about costs a repair turn and interrupts the thread.

**Use the guidance field.** Every question carries private probing guidance that is never read aloud (`explanation` on the linear question list, `guidance` on a graph node). Internal shorthand, incident background, and probe targets belong there, which keeps the spoken text clean.

Guidance is also where terseness gets handled. If a question is likely to draw a short answer, say so and tell the interviewer what to do about it: which aspect to press on, what a complete answer would contain, and when to accept the short answer and move on. Some answers are short because the matter is settled, and pressing on those wastes the participant's time.

Draft the set, then show it to the user before building. One exchange, and it catches mis-scoped questions before they cost an interview.

## Step 4: Build it in Deutero

`deutero-study-authoring` has the mechanics — tool sequence, question type config, guidance writing, `validate_questions`. `references/self-interview-setup.md` here covers only what is different at n=1, which is mostly what to *skip*.

Default to the linear question list. It supports every question type and all the probing controls, and it is faster to author and revise. Expect short answers — a principal answering questions about their own agent usually gives them — and handle them in each question's guidance: name what to press on, and when the answer is thin, offer the positions you suspect as a straight choice. That works on the linear list. Reach for graph mode (`deutero-interview-flow`) only when the interview cannot work without it: a block of questions that must not be asked unless an earlier answer went a particular way, or captured rules you want resolved into typed values and read back for confirmation. Graph mode needs a **Pro or Team plan**, so check before proposing it; below that the linear list is not a compromise you chose, it is the only option, and say so.

Fill `research_question`, `objectives` and `target_population` honestly, since they steer the interviewer. Set `anonymous: true` and `max_responses: 1`, and `survey_type: "customer_development"` fits most agent check-ins.

**Ask the user which `model_tier` to use, and wait for the answer** — it is their cost decision on every study, this one included. Recommend `premium`: probing quality is the entire product on a single-participant study, and one interview at the premium rate is a rounding error against the user's own time. But recommend it, do not assume it.

Once the study exists, give the user its `dashboard_url` from the `create_study` response so they can see what you built.

Set a short welcome message. If the answers will feed your persistent memory or behavior defaults, say so plainly and set `consent: true`.

Skip screening and characteristics. They exist for panel recruitment and add nothing when you know exactly who is answering.

A study admits nobody until it is published, so ask the user whether to open it, then `publish_study`. On Hobby and Solo it takes the plan's one open-study slot, and `plan_limit_reached` means another study holds it. Ask which to pause rather than choosing. Then get the participation link with `get_recruitment`, hand it to the user, and stop. Do not chase or check progress unprompted. With `max_responses: 1` the study closes itself when the interview completes, which frees the slot. `deutero-study-authoring/references/publishing.md` has the refusal codes.

## Step 5: Read the transcript and propose changes

When the user says it is done, pull the interview with `list_interviews` and `get_transcript`, and read it yourself. If they took it through the dashboard's **Try Interview** or **Preview** rather than the participation link, it is a test run, and `list_interviews` leaves those out by default. Pass `test_runs: null` to see both. Structured answers come back as captured values, but the reasoning that qualifies them lives in the probing turns around each pick, so read the whole thing rather than just the values.

Skip clustering and cross-case synthesis. They are built for many participants and have nothing to say about one.

Produce three things.

**The delta.** Proposed edits expressed in the vocabulary of your own configuration, not a generic schema. Each one names the exact location it targets, quotes the current value there, gives the proposed replacement, and cites the transcript turn it came from. Read your config to get those names right rather than reconstructing them from memory; the current value has to be quoted accurately or the user cannot check the change, and a reversal cannot be detected at all. Anything without a clear target is not a delta, so put it in the summary as an open question.

**The diff.** Compare against the record of the previous run on the same topics, and separate reversals from additions. A reversal means a rule you have been applying confidently is wrong, which is usually the highest-value thing an interview produces, since a quietly wrong rule does not announce itself in normal operation. If there is no previous run, say so in a line and move on.

**The summary.** Short prose on what changed and what is unresolved. Not bullets. Assume expert-level knowledge, skip the recap of what you asked, and go easy on em-dashes.

Then wait. Do not write to any store that shapes your future behavior until the user has approved the delta. These edits change how you act, which makes silent application the wrong default. Apply only what is approved.

Then record the run wherever your persistent notes already live, in whatever format that store uses. What the record has to carry is what the next diff will need: the topics covered, what was proposed, what the user approved or rejected, where each approved change landed, and anything left open. Do not invent a separate file format for this if your setup already has somewhere such things go.

## What these answers are

Stated preference, captured at one moment. The gap between what people say they want and what they approve when the moment arrives is real, and it does not close because the respondent is technical or the questions are good.

Two consequences. When a stated preference and your own observation disagree, surface the contradiction rather than deferring to the transcript. And when you later act on one of these rules and get corrected, the correction outranks the interview answer; log it as incident evidence for the next run.

## References

- `references/self-interview-setup.md` — the n=1 settings, what to skip, and how to record a run so the next diff works
- `deutero-study-authoring` — question types, guidance writing, the full tool sequence
- `deutero-interview-flow` — branching, the terse-answer fallback, typed extraction

Everything about where deltas land and how runs are recorded comes from the host setup rather than from this skill, so it stays portable across agent frameworks. The skill assumes only that you can read your own behavior defaults and write notes somewhere durable.
