# Question sets for common analytics triggers

Starting sets, not scripts. Adapt the wording to the product and always replace the guidance with the real context — guidance copied unedited is the fastest way to a bland interview.

Every set below assumes: `survey_type: "user_experience"`, the real numbers in `research_question` and `objectives`, and `validate_questions` run before recruiting.

Field reference: `deutero-study-authoring/references/question-types.md`.

---

## 1. Funnel drop-off

Segment: entered step N, did not reach step N+1, within the window.

**Q1 — the occasion (text)**

> "Think about the last time you started [flow] and didn't finish. What were you trying to get done that day?"

> `explanation`: Get the surrounding task, not the flow itself — what were they doing before they arrived and what would have happened next if it had worked. Do not mention that we know they dropped off. If they cannot recall a specific occasion, ask about the most recent time they used [flow] at all and mark that in the answer. Three probes maximum.

**Q2 — what stopped them (choices, escape option, follow_up)**

> "What got in the way that time?"
> Options: "I couldn't find something I needed", "It asked for something I didn't have", "It wasn't clear what would happen next", "It was taking longer than it was worth", "I got interrupted and never came back", "Something else"

> `explanation`: The pick is the category; the follow-up is the whole value. If they say they couldn't find something, get what and where they looked. If they got interrupted, find out what would have brought them back — that is a different fix from the others and easy to miss.

**Q3 — the substitute (text)**

> "What did you end up doing instead?"

> `explanation`: The substitute is the real competitor and is often a spreadsheet, a colleague, or nothing. If nothing, find out what the cost of nothing was — that tells us how urgent the job actually is.

**Q4 — the counterfactual (text, 2–3 turns)**

> "What would have had to be different for you to have finished it that day?"

> `explanation`: Take the first answer, then ask once whether that alone would have been enough. People name the last blocker they hit, not the biggest one.

---

## 2. Churn

Segment: cancelled or lapsed within the window. Reachability is the constraint — run this within weeks of cancellation, not quarters.

**Q1 — the decision moment (text)**

> "When did you first start thinking about stopping, and what was going on then?"

> `explanation`: Separate the trigger from the cancellation — they are usually weeks apart, and the trigger is the actionable one. Get the month and the circumstance.

**Q2 — what changed (choices + follow_up)**

> Options: "The work it was for stopped or changed", "We found something that fit better", "It stopped being worth the price", "It never really got adopted on the team", "The person who championed it left", "Something else"

> `explanation`: These are different problems with different fixes. On "something better", get the name and the one thing it does that we do not. On price, get what they compared against — a competitor, an internal build, or doing nothing.

**Q3 — the last straw vs. the long-running thing (text)**

> "Was there a specific incident, or was it an accumulation?"

**Q4 — the return condition (choices + follow_up)**

> "What would have to be true for you to come back?"
> Options: "A specific feature or fix", "A different price", "A change in how we work", "Nothing — it's settled", "Something else"

> `explanation`: "Nothing, it's settled" is a real and useful answer; do not press against it. On a feature, get whether they would have stayed for it or only return for it, which are different claims.

---

## 3. Feature shipped, nobody uses it

Segment: in the target audience, has not fired the feature's events. Ask this in-product, because awareness is the first hypothesis and you cannot test awareness in an email that describes the feature.

**Q1 — awareness, without prompting it (text)**

> "When you need to [job the feature does], how do you do it today?"

> `explanation`: This tests awareness without revealing the feature. If they describe a workaround, they did not know. Do not name the feature until Q3 under any circumstances.

**Q2 — is the job real (scale, labelled concretely)**

> "How often does that come up?"
> minLabel: "Hardly ever", maxLabel: "Most weeks"

**Q3 — the reveal (choices + follow_up)**

> "There's a [feature] that does this — had you come across it?"
> Options: "Never seen it", "Seen it, never tried it", "Tried it once", "I use it"

> `explanation`: Each answer goes somewhere different. "Seen it, never tried it" is the most informative: find out what they expected it to do and why that was not worth a click. This is the answer that separates a discovery problem from a value problem, which is the whole point of the study.

---

## 4. Support ticket spike

Segment: filed a ticket on the flow within the window. You have their ticket, so do not make them repeat it.

**Q1 — expectation (text)**

> "Before you contacted us — what did you expect [the thing] to do?"

> `explanation`: The gap between expectation and behaviour is the finding. We already have what went wrong from the ticket; we need what they thought would happen and where that belief came from.

**Q2 — the give-up point (text)**

> "What did you try before deciding to contact us?"

> `explanation`: Everything they tried first is a place the product could have answered them. Get the order.

**Q3 — cost (choices + follow_up)**

> "What did it cost you while it was stuck?"
> Options: "Nothing much, just annoying", "Lost an hour or two", "Missed something that mattered", "Had to explain it to someone else", "Something else"

---

## 5. Unexpected power use

Segment: top decile on some usage dimension, or firing events in an order nobody designed. Small n, high value — recommend the premium tier here, since the probing is the whole product, and let the user make the call. Premium needs a Pro or Team plan; below that, `standard` with much fuller guidance.

**Q1 — the job (text, 4 turns)**

> "Walk me through what you're actually using it for. Start from what happens before you open it."

> `explanation`: Get the whole workflow including the parts outside our product. The steps on either side are where the product opportunity is, and they are invisible to analytics. Probe for the tools they move data between.

**Q2 — the workaround (text)**

> "What are you doing that you suspect isn't the way it's meant to be used?"

> `explanation`: Ask this directly and lightly. Power users usually know their hacks are hacks and enjoy explaining them, but only if it is clear we are not about to take them away.

**Q3 — the missing piece (ranking)**

> "If we could only fix one of these, which matters most?"
> Options drawn from what the team is considering.

> `explanation`: Ranking, not multi-select — the tradeoff is the question. Probe the top and bottom, not the middle.
