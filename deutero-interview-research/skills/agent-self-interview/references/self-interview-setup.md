# Self-interview specifics

Everything mechanical — tool sequence, question type config, guidance writing, graph authoring — lives in `deutero-study-authoring` and `deutero-interview-flow`. This covers only what a single-participant interview about an agent's own behavior does differently.

## Settings for n=1

```
create_study {"project_id": "…", "name": "Agent check-in — <date>",
              "survey_type": "customer_development",
              "research_question": "…", "objectives": "…", "target_population": "…",
              "model_tier": "premium", "max_responses": 1, "anonymous": true}
set_welcome  {"study_id": "…", "message": "…", "consent": true}
```

- **`model_tier` — ask, always.** Recommend `premium`: on a one-participant study the probing *is* the product, and a premium interview of a dozen questions costs a couple of dozen credits against a participant's time worth far more. But the tier is the user's choice on every study, so put the three rates in front of them and wait. `standard` is the sensible step down. Mind the plan gates: `premium` needs Pro or Team, `standard` needs Solo or above, and `open_weights` is all Hobby has — there you compensate with much more detailed guidance on every question.
- **`max_responses: 1`** so a stray share cannot add a second respondent.
- **`anonymous: true`** — there is no useful identity to record here.
- **`consent: true`** whenever the answers will change persistent behavior, and say so in the welcome text rather than burying it.

## What to skip

- **Screening and characteristics.** They gate and profile panel recruits. You know exactly who is answering.
- **Clustering and thematic analysis.** Both are built for many participants and have nothing to say about one. Read the transcript.
- **Simulation.** It tests an instrument against invented participants; here the instrument's whole value is that it is anchored to real incidents an invented participant does not have. The exception is a self-interview built as a branching flow, where one simulated run per branch is worth it to confirm the paths fire.

## Extraction, and when it is worth it

In graph mode, an `extract` node forces the interviewer to resolve an answer into a typed value *during* the conversation, while the participant is still there to correct it. A transcript read afterwards has no such recourse. That is the argument for it at n=1 — not data capture, which reading already does.

Name each `output_var` after the configuration key it will update, so the mapping from interview to memory edit is mechanical rather than interpretive.

A final readback question that quotes the captured rules back and asks for confirmation turns the interview into a self-validating instrument. Weigh it against length: worth one extra step on a four-question study, not on a ten-question one. The pattern, with `on_missing: "skip"` so it survives a branch where the variable was never set, is in `deutero-interview-flow/references/graph-patterns.md` §5.

## Reading it back

```
list_interviews    {"study_id": "…"}
get_transcript     {"interview_id": "…"}
get_interview      {"interview_id": "…"}
search_transcripts {"study_id": "…", "query": "…"}
```

`get_interview` adds captured values alongside the turns. Read the whole transcript anyway: on a structured question the pick gives the position and the probing turns around it give the condition attached to it, and the condition is the part that becomes a usable rule.

## Recording the run

Record it wherever your persistent notes already live, in whatever format that store uses. Do not invent a separate file format if your setup already has somewhere such things go.

What the record must carry, because it is what the next run's diff needs:

- the topics covered and the study id
- what was proposed
- what the user approved and what they rejected — rejections matter as much as approvals, since re-proposing a rejected change is the fastest way to lose the user's patience with this whole exercise
- where each approved change landed
- anything left open

Without the previous record there is no diff, and without a diff a reversal — a rule you have been applying confidently that turns out to be wrong — gets filed as a new preference. That is the single most valuable output this process has, and it is the one that quietly disappears if the bookkeeping is skipped.
