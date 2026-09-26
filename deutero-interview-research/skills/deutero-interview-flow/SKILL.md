---
name: deutero-interview-flow
description: Author, validate and activate a Deutero Interview Flow — the branching graph mode where an interview routes on earlier answers instead of running a fixed list. Use this whenever a study needs conditional questions, a different question set depending on what someone said, a loop over an unknown number of items, typed extraction of answers into variables, a fallback for thin answers, or a webhook or context fetch mid-interview; and whenever the user mentions the flow editor, graph mode, branching, `check_graph`, `set_graph`, or a validator error like `var_not_guaranteed` or `no_default`. Use it too when someone asks whether their study should branch at all — the answer is often no, and this skill says when.
---

# Interview Flow

A study runs either a linear question list or a **graph**. The graph routes on what was said: a follow-up topic that only applies if an earlier answer went a particular way, a different question set per position, a loop over an unknown number of items, a typed value extracted mid-conversation and used later.

## First, check the plan

Interview Flow is a **Pro-and-above feature**. On Hobby and Solo the graph endpoints refuse with 403 "Upgrade required", so establish the plan before designing a branching interview — `get_credit_balance`'s `base_limit` reads 400 on Pro and 1500 on Team (15 Hobby, 100 Solo), or ask the user.

Below Pro, say so plainly and flatten the design into a linear question list. Most branches survive the flattening better than you would expect: ask the discriminating question, write each follow-up so it reads sensibly for everyone who reaches it, and let the interviewer's own probing adapt the rest. What you genuinely lose is hard routing, typed extraction into variables, loops and mid-interview webhooks — name those as the trade rather than pretending the linear list is equivalent.

## Then, decide whether you need it

Default to the linear list. It carries every question type, private guidance, `follow_up`, `min_turns` and `max_turns` — everything most studies need — and it is far quicker to author and revise. Graph mode costs authoring time, validation cycles and a class of error the linear list cannot produce.

Graph mode earns that cost when the interview genuinely branches. Three real cases: a topic that only applies given a particular earlier answer; a question set that differs by which of three positions the participant took; a loop whose length depends on how many things the participant names. Adaptive *probing* is not a reason — the interviewer already probes every question type adaptively.

If you have already written the questions linearly, `import_questions_to_graph` converts them into a straight-line flow, which is the cheapest way to start.

## Read the registry before you author

```
describe_graph_nodes {}
```

This returns the live config schema for every step type, generated from the validator's own registry, so it cannot drift from what `check_graph` accepts. Call it first. Anything in this skill or its reference is a starting shape; `describe_graph_nodes` is the schema.

## The one structural rule everyone gets wrong

Steps connect two different ways.

- `start`, `end`, `question` and `decision` sit on the interview path and connect with `edges`.
- `extract` and `webhook` attach to a question with `"after": "<question id>"`. `context_fetch` attaches with `"before": "<question id>"`.

Those three **never appear in `edges`** — the compiler splices them into the trajectory. Putting an extract node in `edges`, or leaving one without its `after`, is the most common authoring error and produces `unattached`.

## Node-level naming differs from the linear list

Same concepts, different names. This is the second most common source of rejected calls.

| Concept | Linear (`create_question`) | Graph (node config) |
|---|---|---|
| Single-choice type | `qtype: "choices"` | `qtype: "options"` |
| Private probing guidance | `explanation` | `guidance` |
| Question text | `question` | `text` |
| Scale bounds | `scale.minScale` / `maxScale` / `minLabel` / `maxLabel` | `scale.min` / `max` / `min_label` / `max_label` |
| Capture answer to a variable | — | `output_var` |

`follow_up`, `min_turns`, `max_turns`, `options`, `groups`, `slots`, `min_select` and `max_select` are the same in both.

## Branching

**On a structured answer** — deterministic, no extraction needed, because the question's `output_var` is directly available. A `decision` node with `mode: "deterministic"` and conditions on the edges.

**On free text** — a `decision` with `mode: "llm_classifier"`, a `classes` list and `instructions` describing how to choose. Edges out of it carry `class` labels.

Conditions are a single test, `{"var": …, "op": …, "value": …}`. Operators: `eq`, `neq`, `in`, `contains`, `gt`, `gte`, `lt`, `lte`, `is_set`, `not_set`. For and/or logic, chain two decisions rather than looking for a compound form.

A step with more than one outgoing edge must be a decision, and needs exactly one edge marked `"default": true` — unless its conditions enumerate every possible answer of a choices or scale question. Every step inside a loop needs `max_revisits`, and the loop needs a path out.

## Extraction

Extract when a captured value **drives routing**, or when you want the interviewer to resolve an answer into a value while the participant is still there to clarify. That last point is the real argument for it: a transcript read afterwards has no such recourse.

Extraction purely as a data-capture mechanism duplicates work that reading the transcript already does. Skip it then.

```json
{"id": "x_rule", "type": "extract", "after": "q_rule", "config": {
  "instructions": "Extract the decision rule the participant stated. Capture any threshold verbatim. Return empty if they stated no rule.",
  "output_var": "handback_rule",
  "output_type": "string",
  "on_empty": "skip_consumers"
}}
```

`output_type` accepts `string`, `list[string]`, `number`, `object`. Use `list[string]` with `merge: "append_unique"` when a question can yield several values; `object` when you want structured fields, and then say exactly which keys in `instructions`.

## The pattern that earns the graph

A linear list asks an open question, receives "no", and moves on with nothing. A classifier decision detects the thin answer and converts the same question into a forced choice between the options you already suspect are in play — without re-asking the open question in different words, which reads as not listening.

That fallback, plus typed extraction, probe capping, thread anchoring and an optional readback confirmation, are written out with working JSON in `references/graph-patterns.md`. The two-question example there validates as it stands.

## Validate, then save, then activate

```
check_graph      {"study_id": "…", "flow": {…}}     # iterate until valid: true
set_graph        {"study_id": "…", "flow": {…}, "expected_graph_version": …}
activate_graph   {"study_id": "…"}
```

Nothing saves unless the flow validates, so a failed write leaves the stored flow untouched — but iterating on `check_graph` is faster than reading 422s. When it validates, **read the returned `compiled` block**: it shows the derived captured-answer table and the final execution order with side steps spliced in, which is the only cheap way to confirm the extract nodes landed where you meant.

Saving does not switch the study into graph mode by itself — `activate_graph` does. `deactivate_graph` returns it to the linear list, which is still there.

Pass `expected_graph_version` from your last `get_graph` so a browser edit made meanwhile is refused with a 409 rather than silently overwritten. Prefer `patch_graph` over `set_graph` when revising a flow the user has since rearranged in the editor — it preserves positions and their layout.

## Validator codes worth knowing in advance

- `var_not_guaranteed` — a step uses a captured answer that branching makes optional. The fallback pattern produces this routinely, since a choice variable only exists on one path. Fix with `on_missing: "skip"` or `"fallback"` on the **consuming** step, not by removing the branch.
- `no_default` — a decision has multiple paths and none is marked `"default": true`.
- `unattached` — an extract or webhook is missing `after`, or a context_fetch is missing `before`.

## Testing a flow

A branching interview has paths that never run in ordinary testing. Simulate it: write one persona per path, run them, and read the transcripts to check each branch fired. See the `deutero-simulation` skill — this is the case where simulation is most obviously worth its credits.

## References

- `references/graph-patterns.md` — the per-question unit, terse-answer fallback, typed extraction, probe capping, readback confirmation, and a complete validated two-question flow
