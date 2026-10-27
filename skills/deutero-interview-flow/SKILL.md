---
name: deutero-interview-flow
description: Decide whether a Deutero study needs an Interview Flow — the branching graph mode where an interview routes on earlier answers instead of running a fixed list — and usually conclude it does not; then, when one is warranted, author, validate and activate it. Use this whenever someone proposes branching, conditional or follow-up questions, a different question set depending on what someone said, a loop over an unknown number of items, typed extraction of answers into variables, a fallback for thin answers, or a webhook or context fetch mid-interview; whenever someone assumes a flow is needed to record a participant's source, their ID or embed metadata (it is not); and whenever the user mentions the flow editor, graph mode, `check_graph`, `set_graph`, or a validator error like `dead_end`, `no_path_to_end`, `var_not_guaranteed` or `no_default`.
---

# Interview Flow

A study runs either a linear question list or a **graph**. The graph routes on what was said: a block of questions that only applies if an earlier answer went a particular way, a loop over an unknown number of items, a value captured mid-conversation and piped into a later question.

## First, decide whether you need one

Usually you do not. Default to the linear question list: it carries every question type, private guidance, `follow_up`, `min_turns` and `max_turns`, it is far quicker to author and revise, and it cannot fail in the ways a flow can. A flow costs authoring time, validation cycles and a class of error the linear list cannot produce, so check the request against this table before proposing one. **None of these needs a flow:**

| Want | Use instead, on the linear list |
|---|---|
| Know where each participant came from | `?source=` on the link, stored on every interview as `web_source` |
| Your own ID for each participant | `?participant_id=` on the link, or `participant_id` in the embed widget's metadata, stored as `external_participant_id` |
| Page, account or user context (plan, seats, page) | the embed widget's `data-metadata`, or signed metadata when the analysis leans on it |
| A follow-up that depends on the answer: "if they mention price, ask what they compared it with", "if they say no, ask what stopped them" | write it in the question's private guidance (`explanation`) |
| Drawing out a short or vague answer, even offering options as a straight choice | guidance, plus `follow_up`, `min_turns` and `max_turns` |
| Keeping the wrong people out, or recording who they are | screening and characteristics questions. Never screen inside a flow: a screened-out person's answers are kept on their interview (`get_interview` → `qualifications`, `termination_reason: "disqualified"`) |
| Keeping what people said when they drop out partway | nothing to build: every turn is saved as it happens, and an abandoned interview stays in `list_interviews` (`completed: false`), `get_transcript` and the analysis tallies. `output_var` is not a data-retention mechanism |
| A few optional questions at the end | put them last and say they are optional; someone who stops there keeps everything they already said |
| A "would you like to leave your email?" opt-in | one question whose guidance says to ask for the address only if they agree |
| Rewarding, notifying or redirecting someone when they finish | the `interview.completed` webhook and `redirect_url` (`deutero-participant-rewards`) |
| Structured answers to tally | the question type itself (`choices`, `scale`, `ranking`, …), read back with `get_options_responses` / `get_scale_responses` |

Link parameters and embed metadata are covered in `deutero-study-authoring/references/recruitment-and-embedding.md`.

The test for conditional logic: could a capable human interviewer handle it from a note on the question? If so, write the note. The interviewer reads every answer before deciding what to say next, and guidance tells it what to do with what it hears.

A flow is warranted only for what guidance cannot do:

- **Hard routing.** Participants must get different **blocks** of questions — several each — that would be wrong or confusing to ask everyone: a block only for people who cancelled, and a different one for those who stayed. If each path would be a single question, it is not hard routing: write one question whose guidance covers each case ("if they connected something, ask how it went; if they stopped or decided against it, ask what stopped them; if they never tried, ask about a recent task they did by hand").
- **Loops.** A question repeats for each of an unknown number of items the participant names.
- **Piping.** A captured answer is inserted into a later question's text.
- **Mid-interview calls.** The interview fetches data from your API, or sends a signal, at a specific point in the conversation.

Count before you commit: a flow whose decisions each lead to one or two questions that then rejoin is a linear list with extra failure modes. So is a flow whose first decisions route people to an `end` step — that is screening.

If the request is a row of the table, say so, build it on the linear list, and do not author a flow. If a flow is warranted and the questions already exist linearly, `import_questions_to_graph` converts them into a straight-line flow, which is the cheapest way to start. A straight line with nothing added is the linear list with extra failure modes, so never activate one.

### When a flow already exists and misbehaves

A report of "branching issues", a step that seems to lead nowhere, or a path that asks the wrong people the wrong thing is a cue to run the test above again before repairing anything. If the flow fails it, rebuild the study on its question list (which is still there) and `deactivate_graph`; tell the user that is what you did and why. Repair the flow only if it passes.

## Then, check the plan

Interview Flow is a **Pro-and-above feature**. On Hobby and Solo every flow-authoring call — `describe_graph_nodes`, `check_graph`, `set_graph`, `patch_graph`, `import_questions_to_graph`, `upload_flow_image`, `activate_graph` — refuses with 403 and `detail.code: "upgrade_required"`, and `publish_study` refuses a study in graph mode with `flow_not_on_plan`. Establish the plan before designing a branching interview — `get_credit_balance`'s `base_limit` reads 400 on Pro and 1500 on Team (15 Hobby, 100 Solo), or ask the user.

Below Pro, say so plainly and flatten the design into a linear question list. Most branches survive the flattening better than you would expect: ask the discriminating question, write each follow-up so it reads sensibly for everyone who reaches it, and let the interviewer's own probing adapt the rest. What you genuinely lose is hard routing, loops, piping and mid-interview calls — name those as the trade rather than pretending the linear list is equivalent.

## Read the registry before you author

```
describe_graph_nodes {}
```

This returns the live config schema for every step type, generated from the validator's own registry, so it cannot drift from what `check_graph` accepts. Call it first. Anything in this skill or its reference is a starting shape; `describe_graph_nodes` is the schema.

## Steps connect two different ways

- `start`, `end`, `question` and `decision` sit on the interview path and connect with `edges`.
- `extract` and `webhook` attach to a question with `"after": "<question id>"`. `context_fetch` attaches with `"before": "<question id>"`.

Those three **never appear in `edges`** — the compiler splices them into the trajectory. Putting an extract node in `edges`, or leaving one without its `after`, is the most common authoring error and produces `unattached`.

## Every step leads onward to an end

This rule has no exceptions. **The interview ends only by reaching an `end` step.** A step with nothing after it is not an implicit end. It is an error, and the flow will not save.

- Every `start`, `question` and `decision` step has an outgoing edge (`dead_end`). The last question on each path connects to `end` explicitly.
- `start` and `question` steps have exactly one outgoing edge (`fanout`). Only a `decision` splits.
- Every step is reachable from `start` (`unreachable`). Delete steps you no longer use rather than leaving them disconnected.
- Every step has a forward path to an `end` (`no_path_to_end`). An edge looping back to an earlier step does not count, so every loop needs a way out that reaches an end.
- Every `decision` has exactly one `"default": true` path (`no_default`). The only exception is a deterministic decision whose conditions cover every possible answer of a choices or scale question. An `llm_classifier` decision always needs one, and a class without a path of its own goes down it.
- An `extract` or `webhook` step runs straight after its question, so that question must itself connect onward (`dead_end`, reported on the side step).
- In the browser flow editor, every Branch path must be connected to a step (`unconnected_path`). Remove a path you do not want rather than leaving it unwired.

Two edits break this without looking like it. `remove_node` drops the step's edges and does not reconnect its neighbours, so add the bridging edge in the same `patch_graph` call. And putting a decision after a question means repointing the question's existing edge at the decision, not adding a second edge from the question (`fanout`).

## Node-level naming differs from the linear list

Same concepts, different names. This is the second most common source of rejected calls.

| Concept | Linear (`create_question`) | Graph (node config) |
|---|---|---|
| Single-choice type | `qtype: "choices"` | `qtype: "options"` |
| Private probing guidance | `explanation` | `guidance` |
| Question text | `question` | `text` |
| Scale bounds | `scale.minScale` / `maxScale` / `minLabel` / `maxLabel` | `scale.min` / `max` / `min_label` / `max_label` |
| Capture answer to a variable | — | `output_var` |
| Images to show (`present_images`) | attached with `upload_question_image` | `images: [{"url", "label"}]` in config — a `url` from `upload_flow_image`, or a public `https://` URL |

`follow_up`, `min_turns`, `max_turns`, `options`, `groups`, `slots`, `min_select`, `max_select` and `randomize_options` are the same in both.

## Branching

**On a structured answer** — deterministic, no extraction needed, because the question's `output_var` is directly available. A `decision` node with `mode: "deterministic"` and conditions on the edges.

**On free text** — a `decision` with `mode: "llm_classifier"`, a `classes` list and `instructions` describing how to choose. Edges out of it carry `class` labels.

Conditions are a single test, `{"var": …, "op": …, "value": …}`. Operators: `eq`, `neq`, `in`, `contains`, `gt`, `gte`, `lt`, `lte`, `is_set`, `not_set`. For and/or logic, chain two decisions rather than looking for a compound form.

Default paths and loop exits follow the rules in "Every step leads onward to an end". Every step inside a loop also needs `max_revisits`; once a step has run that many times the interview takes the default path, which must lead on to an end.

## Extraction

Extract when a captured value **drives routing**, or when you want the interviewer to resolve an answer into a value while the participant is still there to clarify. That last point is the real argument for it: a transcript read afterwards has no such recourse.

Extraction purely as a data-capture mechanism duplicates work that reading the transcript already does. Skip it then. On its own, extraction rarely justifies building a flow; it is worth adding to a flow that is warranted for other reasons.

```json
{"id": "x_rule", "type": "extract", "after": "q_rule", "config": {
  "instructions": "Extract the decision rule the participant stated. Capture any threshold verbatim. Return empty if they stated no rule.",
  "output_var": "handback_rule",
  "output_type": "string",
  "on_empty": "skip_consumers"
}}
```

`output_type` accepts `string`, `list[string]`, `number`, `object`. Use `list[string]` with `merge: "append_unique"` when a question can yield several values; `object` when you want structured fields, and then say exactly which keys in `instructions`.

## Thin answers: guidance first

An open question that receives "no" or "not really" is a guidance problem before it is a routing one. Put the fallback in the question's guidance: "If the answer is a bare yes/no or under about ten words, don't re-ask the question in other words. Offer these three positions as a straight choice: … Take the pick and move on." The interviewer applies that to whatever it hears, on the linear list.

Build the fallback as a flow — a classifier decision that detects the thin answer and routes to a separate forced-choice `options` question — only when that choice must be recorded as its own structured answer (tallied with `get_options_responses`, or used to route or pipe later), or when the study is already a flow for another reason. That pattern, with typed extraction, probe capping, thread anchoring and an optional readback confirmation, is written out with working JSON in `references/graph-patterns.md`. The two-question example there validates as it stands.

## Validate, then save, then activate

```
check_graph      {"study_id": "…", "flow": {…}}     # iterate until valid: true
set_graph        {"study_id": "…", "flow": {…}, "expected_graph_version": …}
activate_graph   {"study_id": "…"}
```

Nothing saves unless the flow validates, so a failed write leaves the stored flow untouched — but iterating on `check_graph` is faster than reading 422s. When it validates, **read the returned `compiled` block**: it shows the derived captured-answer table and the final execution order with side steps spliced in, which is the only cheap way to confirm the extract nodes landed where you meant.

Then **read `warnings`**. A valid flow saves regardless, but each warning names a shape that usually means the study does not need a flow, and `validate_study` reports them as methodological issues the user must acknowledge before publishing:

- `screening_in_flow` — an early Branch ends the interview for some people. Move that to screening questions.
- `optional_block_in_flow` — a late Branch lets people finish early. Put the optional questions last on the question list.
- `single_question_branch` — every path is at most one question before they rejoin. One question with guidance covering each case does the same.
- `flow_not_needed` — every Branch is one of those, and there is no loop, piping, fetch or signal. Build on the question list instead.
- `parallel_paths` — several paths of one Branch go to the same step. One path with `"op": "in"` does it.
- `interview_as_form` — half or more of the open questions allow at most one follow-up (`follow_up: false`, or `max_turns` 1 or 2). The interviewer takes first answers and moves on, so it runs as a survey. Tell the user; if it isn't meant as a quick factual check, set `max_turns` 3–4 on the open questions.

`validate_study` also reads the questions in path order. A question that re-asks what the one straight before it already drew out comes back first, as `sequential_overlap`. Rework it (merge the two, or fold the second into the first one's guidance) rather than acknowledging it.

`compiled.length` gives the questions and estimated minutes on the shortest and longest paths (a loop counts once). Hold the longest against what the welcome message and the user promised participants.

Saving does not switch the study into graph mode by itself — `activate_graph` does. `deactivate_graph` returns it to the linear list, which is still there.

All of these writes are refused with 409 `study_locked` while the study is open to participants. Build and activate the flow on a draft, then publish. To revise a live flow, pause the study first (with the user's go-ahead, since pausing turns new participants away) and publish again after. Publishing refuses a graph study whose flow isn't active (`graph_not_active`). See `deutero-study-authoring/references/publishing.md`.

Pass `expected_graph_version` from your last `get_graph` so a browser edit made meanwhile is refused with a 409 rather than silently overwritten. Prefer `patch_graph` over `set_graph` when revising a flow the user has since rearranged in the editor — it preserves positions and their layout.

## Validator codes worth knowing in advance

- `dead_end` — a step has no outgoing edge, or a side step follows a question that has none. Connect it onward; if it should be the last question, connect it to `end`.
- `no_path_to_end` / `unreachable` — a step cannot reach an end (often a loop with no exit), or cannot be reached from `start`.
- `fanout` — a question or start has two outgoing edges. Put a decision between it and its paths.
- `no_default` — a decision has no `"default": true` path, or more than one.
- `unconnected_path` — a Branch path in the browser editor has nothing connected to it.
- `var_not_guaranteed` — a step uses a captured answer that branching makes optional. The fallback pattern produces this routinely, since a choice variable only exists on one path. Fix with `on_missing: "skip"` or `"fallback"` on the **consuming** step, not by removing the branch.
- `unattached` — an extract or webhook is missing `after`, or a context_fetch is missing `before`.

## Testing a flow

A branching interview has paths that never run in ordinary testing. Simulate it: write one persona per path, run them, and read the transcripts to check each branch fired. See the `deutero-simulation` skill — this is the case where simulation is most obviously worth its credits.

## References

- `references/graph-patterns.md` — the per-question unit, terse-answer fallback, typed extraction, probe capping, readback confirmation, and a complete validated two-question flow
