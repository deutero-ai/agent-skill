---
name: deutero-simulation
description: Test a Deutero study before spending real participants on it by running it against AI personas — write or generate personas, start runs, poll them to completion, and read the transcripts for what they actually tell you (broken questions, leading wording, branches that never fire, length and cost). Use this whenever someone wants to simulate an interview, dry-run or pilot a study, create or generate personas, check an Interview Flow's branches, estimate how long an interview takes or what it will cost, check how a question that shows images (concepts, logos, screenshots) plays, or asks whether their questions work before recruiting. Use it too when someone proposes using simulated participants as evidence about real people, so they get a straight answer about what simulation can and cannot support.
---

# Simulation with personas

Simulation runs your interview against an AI persona. It is an instrument test, not a source of evidence, and everything useful about it follows from taking that distinction seriously.

It costs **2× the live interview rate** and **needs a paid plan** — Hobby returns "Upgrade required: Simulations are not available on the Hobby plan." Check `get_credit_balance` and the plan before promising a run.

## What it is genuinely good for

- **Catching broken questions** — wording the interviewer misreads, a question that confuses rather than probes, a double-barrelled question that gets half answered, follow-ups that never terminate.
- **Exercising an Interview Flow along each path.** Branches that never fire in casual testing are exactly what simulation finds cheaply. This is the strongest case for it.
- **Detecting leading questions.** Run a sceptic and a non-customer. If they come out sounding encouraging, the instrument is leading and no amount of real recruitment will fix that.
- **Estimating length and cost** before buying participants.
- **Checking a `present_images` question** — whether the labels are clear enough to refer to, whether the interviewer probes the images rather than the abstract idea, and whether an image is missing.

## What it is not

Simulated participants are not evidence about real people. They do not have your customers' memories, they invent specifics that sound right, and they are agreeable in ways real participants are not. A simulated interview that "validates" an idea has validated nothing. The same goes for a concept test: a persona that prefers Concept B is a language model looking at a picture, not a customer, so persona preferences between images say nothing about which one real people will pick.

If someone proposes using simulation as findings, say so plainly and once, then help them with the thing simulation actually does. Do not build a study that will be reported as user research when it is a script test.

## Step 1: Write personas that are worth running

A persona is free text — brief it like an actor, in the third person. Detail is the whole difference: a vague persona produces bland, agreeable answers, which is the failure mode you were trying to detect in the first place.

> "A 38-year-old parent in Denver who cancelled after two months because recipes took too long on weeknights"

beats "a busy customer", by a lot. `references/persona-writing.md` has the structure, worked examples, and the specific set of personas each kind of test needs.

```
create_persona    {"study_id": "…", "content": "…"}
list_personas     {"study_id": "…"}
update_persona    {"study_id": "…", "persona_id": "…", "content": "…"}
delete_persona    {"study_id": "…", "persona_id": "…"}
generate_personas {"study_id": "…", "count": 3, "save": true}
```

`generate_personas` drafts from the study's own context — type, description, research question, objectives, target population — so good study details produce good personas and thin ones produce cardboard. Up to 10 per call. Use `save: false` to preview, edit, then create the ones worth keeping.

Generated personas are a reasonable starting point and a poor finishing point: they cluster around the obvious participant. The ones that find bugs are the awkward ones you write deliberately — the terse answerer, the person who misunderstands the question, the one who does not have the problem at all.

**Design the persona set around what you are testing**, not around the market. For a flow, you need one persona per branch. For leading questions, you need a sceptic and a non-customer. For length, you need a rambler and a minimalist, because they bracket the range.

## Step 2: Run

```
run_simulation  {"study_id": "…", "persona_id": "…", "model_tier": "open_weights"}
get_simulation  {"simulation_id": "…"}
list_simulations {"study_id": "…", "status": "…", "limit": 20}
delete_simulation {"simulation_id": "…"}
```

**Simulations need a paid plan.** On Hobby, `run_simulation` is refused with 403 whatever the credit balance says — there is no workaround, and the honest answer is to say so and fall back to `validate_questions` plus having the user take the interview themselves with the dashboard's **Preview** button, which works while the study is still a draft. Check before writing a panel of personas: `get_credit_balance`'s `base_limit` reads 15 on Hobby (100 Solo, 400 Pro, 1500 Team), or just ask. The `premium` tier needs Pro or Team on top of that, so on Solo the choice is `open_weights` or `standard`.

**Ask the user which `model_tier` to run the simulation on before the first run**, every time — simulated interviews cost **2×** the live rate, so a panel of personas on `premium` adds up fast, and the tier is the user's call rather than yours. Quote the per-run estimate and the panel total at the tier they choose. A simulation does not have to run on the study's own tier: testing wording and flow coverage is usually fine on `open_weights`, while judging how well the interviewer *probes* needs the tier the real study will use. Say which of those the run is for, recommend accordingly, and wait for the answer.

`run_simulation` starts **one** run and returns immediately with an `estimated_credits` figure. To sweep a panel, call once per persona. Poll `get_simulation` until `status` leaves `running`; it ends `completed` or `failed`. A run still unsettled two hours after it started reports `failed` — its worker is gone and its reservation has expired.

Pass `persona_id` for a stored persona, `persona` for ad-hoc text (which overrides the stored text if both are given), or neither for a generic participant.

Credits are reserved up front at the estimate. A run that would exceed the balance is refused with 402 and costs nothing — so a refusal is safe, not a half-charged failure. Tell the user the estimate before sweeping a panel: eight personas on the premium tier is a real amount of money.

`deliver_signals` defaults to **off**, and should stay off. With it off, a simulation records what each "Send a signal" step in an Interview Flow would have sent without sending it. Turn it on only when deliberately testing a webhook receiver — and know that receivers then get exactly what a live interview sends, plus an `X-Deutero-Simulated` header they must be prepared to honour.

Results appear as interviews in the study, flagged as simulated so you can filter them out everywhere else. **Always filter them out before reporting any number.** `delete_simulation` removes the run's bookkeeping row and keeps the interview it produced.

## Step 3: Read the transcripts for the right things

Read them as script diagnostics, not as opinions. What to look for, in order of value:

- **Where the interviewer got confused** — a probe that restates the question, a follow-up on a point nobody made, a question answered in a way the interviewer did not expect. That is your wording problem, and it will hit real participants too.
- **Whether the sceptic stayed sceptical.** If a persona briefed to disagree comes out supportive, the questions are leading. Rewrite before recruiting.
- **Which branches ran.** For an Interview Flow, check each path actually fired. `get_interview_fetches_and_signals` shows what context fetches and signals did.
- **Where probing ran long or stopped short.** Tune `min_turns` / `max_turns` from what you see rather than from a guess.
- **Length.** Turn count and the credit figure give you a real estimate for the live run.

What not to take from them: the content of the answers, any proportion, and any sense that the idea is validated. The personas were written by the same process that wrote the questions, so agreement between them means nothing at all.

### Questions that show images

On a `present_images` question the persona sees the images, as a participant would, and the interviewer refers to them by label. This works on every tier, `open_weights` included. Read those transcripts for:

- **Labels the conversation can use.** If the persona or interviewer falls back on "the second one" or "the blue one", the `label`s are not doing their job. Give each image a short, distinct label ("Concept A — the shelf mock-up").
- **Probes about the images, not the idea.** An interviewer that asks "what do you think of meal kits?" after showing three packaging designs is ignoring the stimulus. Put what to look for in the question's `explanation`.
- **A missing image.** An image that cannot be loaded reaches the persona as a note saying so, and a persona that says it cannot see something is usually reporting that. Check the image is still attached (`list_questions` shows `images`). In an Interview Flow, also check that a self-hosted `https://` URL is public and still serves the file.

Fix the instrument, re-run the one or two personas that exposed the problem, then recruit humans.

## Where this fits

- Before any real recruitment, on any study with more than a handful of questions.
- Always before activating an Interview Flow — see `deutero-interview-flow`.
- Especially before a customer-development study, where leading questions return false validation that is invisible from inside the study — see `deutero-customer-development`.

## References

- `references/persona-writing.md` — persona structure, worked examples, the persona set for each kind of test, and how to get more out of `generate_personas`
