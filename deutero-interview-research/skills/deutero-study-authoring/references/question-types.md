# Question types

`create_question` appends to the study's list; `generate_questions` appends a generated set (see `generate_questions` below). `reorder_questions` takes every question id in the desired order; `update_question` does partial updates; `delete_question` renumbers the rest and removes recorded answers to it.

The type is inferred from which config fields you send (`scale` → scale, `options` → choices, `slots` → slots, `expected_image` → image_upload, otherwise text), but **pass `qtype` explicitly** so intent is on the record and a later edit cannot silently change the type.

Valid values: `text`, `scale`, `choices`, `slots`, `image_upload`, `multi_select`, `ranking`, `card_sort`.

Shared fields on every type: `explanation` (private probing guidance), `follow_up` (default true), `min_turns`, `max_turns`.

---

## text

The default, and the one to stop over-using. Right for the story, the reasoning, the thing you could not have anticipated. Wrong for a question whose plausible answers you could have listed, because then you are asking the participant to do the instrument's work and they will answer in four words.

```json
{"question": "Walk me through the last time you gave up on it and did something else instead.",
 "qtype": "text",
 "explanation": "Get the specific occasion, not the general pattern. What were they trying to do, what did they switch to, and did they come back. Three probes is enough.",
 "min_turns": 1, "max_turns": 4}
```

## choices

Single pick. The workhorse. Always include an escape option ("Something else", "It depends on …") so it is not a false dichotomy, and leave `follow_up: true` so the reason behind the pick gets probed. Write options that are all positions a reasonable person might actually hold — if two of three are obviously wrong, the question is decoration.

```json
{"question": "When a run trips a warning forty minutes in, what would you want by default?",
 "qtype": "choices",
 "options": ["Stop and tell me", "Finish, then report both", "Depends on whether it touched output"],
 "follow_up": true}
```

## multi_select

Several picks from a set. `min_select` and `max_select` bound it; 0 or null means unbounded. Good for "which of these apply" and "which of these should happen without asking". Bad as a disguised ranking — if the order matters, use `ranking`.

```json
{"qtype": "multi_select", "options": ["…", "…", "…"], "min_select": 1, "max_select": 3}
```

## scale

Degree. Label both ends with concrete behaviours rather than agreement wording, so the number still means something when you read it a month later.

```json
{"qtype": "scale",
 "scale": {"minScale": 1, "maxScale": 5,
           "minLabel": "Always check with me first", "maxLabel": "Never check, just do it"}}
```

Note the field names here are `minScale` / `maxScale` / `minLabel` / `maxLabel`. Graph mode names them differently — see the interview-flow skill.

## ranking

Order a set. Use it when the tradeoff *between* items is the actual question, not when you only want to know which one is first — for that, `choices` is shorter and clearer.

```json
{"qtype": "ranking", "options": ["Price", "Setup time", "Support", "Integrations"]}
```

## card_sort

Assign each item to a bucket: `options` are the cards, `groups` are the buckets. A strong fit for scope, ownership and prioritisation questions — put the things on the cards and the decision on the groups.

```json
{"qtype": "card_sort",
 "options": ["Weekly report", "Data cleanup", "Vendor chase", "Board deck"],
 "groups": ["I do this myself", "I'd delegate it", "Nobody should do it"]}
```

## slots

Several named values elicited inside one natural conversation. Cleaner than splitting a multi-field answer across four questions, and the interviewer fills the slots from ordinary conversational answers rather than interrogating for each one.

```json
{"qtype": "slots", "slots": ["current tool", "what triggered the switch", "who decided", "what it cost"]}
```

## image_upload

Asks the participant for a picture. `expected_image` describes what you want. **Needs a vision-capable interview model** (standard or premium), which in practice means **a paid plan** — on Hobby the only tier is open-weights, which is text-only, and the question is rejected with 403. Check the plan before designing a study around it. The fallback is a `text` question whose guidance names the details the picture would have shown.

```json
{"qtype": "image_upload", "expected_image": "A photo of the setup as it looks right now, mess included"}
```

---

## Writing the `explanation`

Private, never read aloud. It is where the interviewer gets its brief.

- **Background.** What prompted the question, what happened, what the outcome was.
- **Probe targets.** What a complete answer contains. Name the thing: "if they mention cost, get the number they compared against".
- **Vocabulary constraints.** List internal shorthand the interviewer must not say aloud and give the plain replacement. The constraint is on idiom and unstated referents, not on technical depth — assume the participant knows their own domain and do not explain their job to them.
- **Terseness handling.** Where a short answer is likely: which aspect to press on, what a sufficient answer looks like, and when to accept and move on. For example: "A bare yes or no leaves the condition unstated. Ask once what would have to be true for the opposite answer. If they decline again, take the position as given and continue."

## generate_questions

```
generate_questions {"study_id": "…", "n_questions": 8,
                    "additional_instructions": "Anchor to their last rota change. Include one ranking question on what they would give up."}
```

Writes `n_questions` (3–20, default 10) from the study's `research_question`, `objectives`, `methodology` and `target_population`, in the study's language, and **appends them** — if questions exist, it extends the set rather than repeating it, and nothing is replaced. Returns only the questions it added, with ids and `question_number`, plus `skipped_image_questions`. Thirty seconds to two minutes, depending on `n_questions`.

What comes back, and what to check:

- **A mix of types** chosen for the study, all of the eight above. Hold each against the rule of thumb in the skill: generators lean on `text` for things you could have enumerated.
- **`explanation` on open questions** — usually "probe for detail" level. Rewrite it into the probe targets, vocabulary constraints and terseness handling above.
- **Turn ranges.** Open-text and image questions get `min_turns` from the generator (default 2) and `max_turns` of at least 4; structured types get a range only when `follow_up` is true.
- **`image_upload`** is proposed only when the study's `model_tier` can read images, and dropped on plans that cannot (counted in `skipped_image_questions`, never saved).

A 502 means the model's answer could not be used; nothing was saved, so call again. Run `validate_questions` on the result before recruiting, same as a hand-written set.

## validate_questions

Runs clarity, leading/biased wording and ethics checks over the set — the same review the dashboard's Validate button runs. Run it before recruiting. It catches the double-barrelled question and the question that tells the participant which answer you want, both of which are easy to write without noticing.
