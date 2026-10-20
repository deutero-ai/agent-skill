# Interview Flow patterns

Call `describe_graph_nodes` before using any of this. It is generated from the validator's own registry and is authoritative; the patterns here are a starting shape, not a schema.

The two-question example in section 6 and the readback pattern in section 5 have both been run through `check_graph` and return `valid: true`, so they are safe to copy and adapt. Re-validate after adapting.

The worked examples are drawn from an agent self-interview, because that study type exercises nearly every pattern in one flow. The structures are general: swap the question text and the same shapes serve a churn study, a customer-development interview or an in-product research prompt. Only the strings change — the node structure is what validates.

Contents:
1. The per-question unit
2. Terse-answer fallback
3. Typed extraction
4. Probe capping and thread anchoring
5. Optional readback confirmation
6. Complete two-question example
7. Validation notes

---

## 1. The per-question unit

Each interview question is four steps, not one:

```
question (open_ended)  →  extract (typed capture, attached "after")
      ↓
decision (llm_classifier: thin / substantive)
      ├─ thin ──────→ question (options, forced choice) ──┐
      └─ substantive (default) ───────────────────────────┴─→ next question
```

The extract node attaches with `"after": "<question id>"` and is never listed in `edges`. The compiler splices it in. Only `start`, `end`, `question` and `decision` steps appear in `edges`; getting this wrong is the most common authoring error.

## 2. Terse-answer fallback

This is the pattern that earns the graph. A linear list asks an open question, receives "no", and moves on with nothing. A classifier decision detects the thin answer and converts the same question into a forced choice between the concrete options you already suspect are in play.

```json
{"id": "d_handback_depth", "type": "decision", "config": {
  "mode": "llm_classifier",
  "classes": ["thin", "substantive"],
  "instructions": "Classify the participant's answer to the previous question. 'thin' if it was a bare yes/no, under roughly ten words, or stated a position with no reason, condition or threshold. 'substantive' if they named a rule, signal, threshold, or gave a reason."
}}
```

The forced-choice node should not re-ask the open question in different words. That reads as not listening. Restate it as a decision with named options and accept whatever comes back:

```json
{"id": "q_handback_choice", "type": "question", "config": {
  "qtype": "options",
  "text": "Let me put it as a straight choice. Next time a sourcing task lands with no product deliverable attached, what do you want by default?",
  "options": ["Hand it back before starting", "Run it, but flag the ownership question first", "Just run it"],
  "guidance": "Fallback after a thin answer. Take the pick and move on. Do not probe further.",
  "follow_up": false,
  "output_var": "handback_choice"
}}
```

Write the options so that every one of them is a real position someone might hold. If two of three are obviously wrong, the question is decoration.

## 3. Typed extraction

The reason to extract rather than read the transcript later is that it forces the interviewer to resolve the answer into a value during the conversation, while the participant is still available to clarify. A transcript read afterwards has no such recourse.

```json
{"id": "x_handback", "type": "extract", "after": "q_handback", "config": {
  "instructions": "Extract the decision rule the participant stated for when this class of task should be handed back rather than executed inline. Capture any signal or threshold verbatim. Return empty if they stated no rule.",
  "output_var": "handback_rule",
  "output_type": "string",
  "on_empty": "skip_consumers",
  "merge": "overwrite"
}}
```

`output_type` accepts `string`, `list[string]`, `number`, `object`. Use `list[string]` when the question can yield several rules, with `merge: "append_unique"`. Use `object` when you want structured fields, and say in `instructions` exactly what keys you want.

These extracted variables are what become the delta. Name each `output_var` after the configuration key it will update, so the mapping from interview to memory edit is mechanical rather than interpretive.

## 4. Probe capping and thread anchoring

The observed failure was a probe that wandered far enough from its parent question that the participant asked what the original question was. Two config fields prevent it.

`max_turns` bounds the probing. Three to four is right for a question anchored to a specific incident; more than that and the interviewer starts inventing angles. Set `min_turns: 1` so a single thin answer still gets one follow-up before the classifier decides.

`guidance` is private and never read aloud. Put the anchoring instruction there:

> Keep every probe tied to this specific incident. If the answer drifts to a general principle, restate the incident in one clause before asking the next thing. Do not open a new topic inside this question.

Also use `guidance` for the vocabulary constraints. List the internal shorthand the interviewer must not say out loud, and give the plain replacement. The constraint is on idiom and vague metaphor, not on technical depth; assume the participant knows the domain.

## 5. Optional readback confirmation

A final question that reads the captured rules back and asks for confirmation turns the interview into a self-validating instrument, and catches extraction errors while the participant is still there.

```json
{"id": "q_confirm", "type": "question", "config": {
  "qtype": "options",
  "text": "Before I write these down: I have '{{handback_rule}}' as the rule on handbacks. Right?",
  "options": ["Yes, that's it", "Close, but needs a correction", "No, that's wrong"],
  "on_missing": "skip",
  "output_var": "confirm_handback"
}}
```

`on_missing: "skip"` matters. If the extract returned empty, or an earlier branch meant the variable was never set, the validator will otherwise reject the flow with `var_not_guaranteed`. A captured answer can only be used by steps guaranteed to run after the step producing it.

Weigh this against length. On a four-question study a readback is worth one extra step; on a six-question study it pushes past the ten-minute target.

## 6. Complete two-question example

```json
{"flow": {
  "nodes": [
    {"id": "start", "type": "start"},

    {"id": "q_handback", "type": "question", "config": {
      "qtype": "open_ended",
      "text": "On the 14th you asked me to source permit data for Austin and I ran it end to end. Two days later you re-did the join keys yourself. Should I have handed that one back at the start, or was the problem the execution rather than the ownership?",
      "guidance": "Incident: Austin permit sourcing, the 14th. Agent executed inline; participant redid join keys two days later. Probe for whether the boundary is about ownership or about quality. If ownership, get the signal the agent should have noticed up front. Say 'upstream of a deliverable you need' rather than 'blocking'. Keep every probe tied to this incident.",
      "follow_up": true,
      "min_turns": 1,
      "max_turns": 4,
      "output_var": "handback_raw"
    }},
    {"id": "x_handback", "type": "extract", "after": "q_handback", "config": {
      "instructions": "Extract the stated rule for when this class of task should be handed back rather than executed inline. Capture any threshold verbatim. Empty if no rule was given.",
      "output_var": "handback_rule",
      "output_type": "string",
      "on_empty": "skip_consumers"
    }},
    {"id": "d_handback_depth", "type": "decision", "config": {
      "mode": "llm_classifier",
      "classes": ["thin", "substantive"],
      "instructions": "Classify the previous answer. 'thin' if bare yes/no, under roughly ten words, or a position with no reason or condition. 'substantive' otherwise."
    }},
    {"id": "q_handback_choice", "type": "question", "config": {
      "qtype": "options",
      "text": "Let me put it as a straight choice. Next time a sourcing task lands with no product deliverable attached, what do you want by default?",
      "options": ["Hand it back before starting", "Run it, but flag the ownership question first", "Just run it"],
      "guidance": "Fallback after a thin answer. Take the pick and move on.",
      "follow_up": false,
      "output_var": "handback_choice"
    }},

    {"id": "q_escalate", "type": "question", "config": {
      "qtype": "open_ended",
      "text": "Twice last month I hit a bad cast mid-run and finished the pipeline before telling you. Both times you'd have preferred to hear about it earlier. Is stopping at the first flag always right, or are there runs where you'd rather I finish and report both outcomes?",
      "guidance": "Probe for the exception, not the rule. The participant has already stated a stop-on-flag preference; the useful signal is where that breaks down. Concrete cost framing works better than abstract policy framing.",
      "follow_up": true,
      "min_turns": 1,
      "max_turns": 4,
      "output_var": "escalate_raw"
    }},
    {"id": "x_escalate", "type": "extract", "after": "q_escalate", "config": {
      "instructions": "Extract any stated exception to stopping at the first flagged issue. Return a list of exception conditions, empty if none were given.",
      "output_var": "escalate_exceptions",
      "output_type": "list[string]",
      "on_empty": "skip_consumers",
      "merge": "append_unique"
    }},
    {"id": "d_escalate_depth", "type": "decision", "config": {
      "mode": "llm_classifier",
      "classes": ["thin", "substantive"],
      "instructions": "Classify the previous answer. 'thin' if bare yes/no, under roughly ten words, or a position with no reason or condition. 'substantive' otherwise."
    }},
    {"id": "q_escalate_choice", "type": "question", "config": {
      "qtype": "options",
      "text": "Straight choice then: a warning trips forty minutes into an hour-long run. What do you want?",
      "options": ["Stop immediately and tell me", "Finish the run, then report both", "Depends on whether it touched output"],
      "follow_up": false,
      "output_var": "escalate_choice"
    }},

    {"id": "end", "type": "end"}
  ],
  "edges": [
    {"from": "start", "to": "q_handback"},
    {"from": "q_handback", "to": "d_handback_depth"},
    {"from": "d_handback_depth", "to": "q_handback_choice", "class": "thin", "priority": 0},
    {"from": "d_handback_depth", "to": "q_escalate", "default": true, "priority": 1},
    {"from": "q_handback_choice", "to": "q_escalate"},

    {"from": "q_escalate", "to": "d_escalate_depth"},
    {"from": "d_escalate_depth", "to": "q_escalate_choice", "class": "thin", "priority": 0},
    {"from": "d_escalate_depth", "to": "end", "default": true, "priority": 1},
    {"from": "q_escalate_choice", "to": "end"}
  ]
}}
```

## 7. Validation notes

Run `check_graph` and iterate until `valid` is true before calling `set_graph`. Nothing saves unless the flow validates, so a failed write leaves the stored flow untouched, but iterating on `check_graph` is faster than reading 422s.

Codes worth knowing in advance:

`var_not_guaranteed` means a step uses a captured answer that branching makes optional. This is the one the fallback pattern tends to produce, since choice variables only exist on the thin path. Fix with `on_missing: "skip"` or `"fallback"` on the consuming step, not by removing the branch.

`no_default` means a decision has multiple paths and none is marked `"default": true`. Every classifier decision needs one.

`unattached` means an extract or webhook is missing `after`, or a context_fetch is missing `before`.

When the flow validates, read the returned `compiled` block. It shows the derived captured-answer table and the final execution order with side steps spliced in, which is the only cheap way to confirm the extract nodes landed where you meant.

Pass `expected_graph_version` from your last `get_graph` when writing, so a browser edit made meanwhile is refused with a 409 rather than silently overwritten.

Prefer `patch_graph` over `set_graph` when revising a flow the user has since touched in the flow editor. It preserves step positions and anything they rearranged.

## 8. Deterministic branching on a structured answer

When the branch depends on a structured question, no extraction is needed — the question's `output_var` is directly available and the decision is deterministic. This example returns `valid: true` from `check_graph`:

```json
{"flow": {
  "nodes": [
    {"id": "start", "type": "start"},
    {"id": "q_escalate", "type": "question", "config": {
      "qtype": "options",
      "text": "A warning trips forty minutes into an hour-long run. What do you want by default?",
      "options": ["Stop immediately and tell me", "Finish the run, then report both", "Depends on whether it touched output"],
      "guidance": "Probe the reason behind the pick, not the pick itself. If they choose the conditional option, get the test they would apply.",
      "follow_up": true,
      "max_turns": 3,
      "output_var": "escalate_default"
    }},
    {"id": "d_escalate", "type": "decision", "config": {"mode": "deterministic"}},
    {"id": "q_escalate_test", "type": "question", "config": {
      "qtype": "open_ended",
      "text": "You said it depends on whether output was touched. How would you want me to make that call mid-run?",
      "guidance": "Only reached when the conditional option was picked. Get an operational test, not a principle.",
      "max_turns": 3
    }},
    {"id": "end", "type": "end"}
  ],
  "edges": [
    {"from": "start", "to": "q_escalate"},
    {"from": "q_escalate", "to": "d_escalate"},
    {"from": "d_escalate", "to": "q_escalate_test",
     "condition": {"var": "escalate_default", "op": "eq", "value": "Depends on whether it touched output"},
     "priority": 0},
    {"from": "d_escalate", "to": "end", "default": true, "priority": 1},
    {"from": "q_escalate_test", "to": "end"}
  ]
}}
```

Note `priority`: edges are evaluated in ascending priority, and the `default` edge should carry the highest number so it is the last resort rather than the first match.

## 9. Piped text

`{{var}}` in question text only works where the variable is guaranteed to exist. If branching means it might not, set `on_missing` to `skip` or `fallback` on the consuming step — that is exactly what `var_not_guaranteed` is telling you.
