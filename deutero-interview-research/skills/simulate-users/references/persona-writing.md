# Writing personas

A persona is free text, third person, briefing an actor. There is no schema — but the ones that produce useful runs cover the same ground.

## Structure

- **Occupation and situation** — what they do, where, and what state they are in right now.
- **Demographics** — age, location, household, whatever bears on the answers.
- **Goals** — what they wanted from the product or the domain.
- **Constraints and frictions** — what got in the way. This is where the useful material is.
- **History with the product** — how long, what they tried, what happened. Specific dates and events, because vague history yields vague answers.
- **Voice** — how they talk, how forthcoming they are, what they are sceptical about, what they will not say unprompted.

That last one is the most neglected and the most valuable. Most personas are written as cooperative and articulate, which is precisely the participant an interview never has to handle well.

## A worked example

> Marcus, 38, lives in Denver with a partner and two children under ten. Product manager at a mid-sized insurance company; the job is busy but not frantic. Subscribed to the meal-kit service in January after his partner suggested it, cancelled in early March.
>
> He signed up to stop the Wednesday-evening argument about dinner. What he found was that the recipes assumed forty minutes and a clean kitchen, and on a weeknight he had twenty minutes and neither. He tried the "quick" tier for three weeks; two of those boxes went partly uncooked and he felt bad about the waste, which is what actually triggered the cancellation rather than the money.
>
> He has not replaced it with anything — they are back to a rotation of four meals and a supermarket order on Sundays.
>
> He answers politely and briefly, and will not volunteer the waste guilt unless asked something specific about what happened to the food. He deflects direct questions about money with "it wasn't really the price", which is true. He gets more expansive when asked about the logistics of a weeknight evening, because he has thought about it a lot.

Note what that gives the interviewer to work against: a real trigger that differs from the stated reason, a specific thing he will not say unprompted, and a topic he opens up on. A persona that just says "cancelled because it took too long" tests nothing.

## The persona set depends on the test

Do not write five variations of the ideal participant. Write the set that stresses what you are testing.

**Testing question wording** — three personas:
- *The terse one.* Answers in four words, does not elaborate unless pressed with something specific. Finds every question whose guidance has no terseness handling.
- *The rambler.* Long, tangential, answers a nearby question instead of the one asked. Finds questions with no `max_turns` and probes that lose the thread.
- *The misunderstander.* Reads an ambiguous question the other way, confidently. Finds the wording problem you cannot see because you wrote it.

**Testing an Interview Flow** — one persona per branch, each written so their answer to the deciding question is unambiguous. For a classifier decision, write one persona that answers thinly and one that answers substantively; that is the branch you most want to confirm fires.

**Testing for leading questions** (essential before customer development) — three:
- *The enthusiast.* Has the problem badly and likes the idea. Their transcript is the control: it should sound positive.
- *The sceptic.* Has the problem, thinks it is not worth solving, is happy with the workaround. Their transcript should stay sceptical. If it does not, your questions are leading.
- *The non-customer.* Does not have the problem at all and was screened in by accident. Their transcript should show that clearly. If they come out sounding like a prospect, the instrument cannot distinguish a customer from a polite stranger, which means the real study cannot either.

**Testing length and cost** — the rambler and the terse one bracket the range; the real interviews land between them.

**Testing a `present_images` question** — the persona sees the images, so write personas that stress how the question handles them:
- *The literal reader.* Comments on surface details (a colour, a typo, a cropped edge) instead of the concept. Finds guidance that does not steer the interviewer back to what the images are meant to test.
- *The one who cannot tell them apart.* Says two of the images look the same to them. Finds labels and stimuli that are too similar for anyone to compare.
- *The refuser.* Likes none of them and says why. Finds a question that assumes one option must win.

Do not read their preferences as a ranking of the images. Which concept a persona picks is not evidence of which one people will pick.

## generate_personas

```
generate_personas {"study_id": "…", "count": 3, "save": true}
```

Drafts from the study's own context — type, description, research question, objectives, target population — so **write the study details well before generating**, or you get cardboard. Up to 10 per call; call again for more. `save: false` returns drafts with no ids and stores nothing, which is the right default when you intend to edit.

Generated personas cluster around the obvious participant, which makes them a fine base layer and a poor test set. The practical approach: generate three for coverage, then hand-write the terse one, the sceptic and the non-customer, since those are the ones that find bugs and the generator will not produce them unprompted.

Generated personas are marked **AI Generated** and can be edited afterwards.

## Lifecycle notes

- Personas belong to a study and are reused across runs within it.
- Editing a persona does not rewrite past runs — those keep the text they ran against, which is what makes a before/after comparison meaningful.
- Deleting a persona keeps the interviews already simulated with it.
- When you change the instrument and re-run, re-run the *same* personas. Changing the persona and the questions at once tells you nothing about which change mattered.
