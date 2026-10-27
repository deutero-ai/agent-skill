---
name: deutero-study-authoring
description: Build a Deutero study end to end over MCP or the `deutero` Python SDK — project, study details (written or AI-drafted), interview questions of the right type, welcome and consent, screening, recruitment, branding the participant pages (colours, fonts, hero image, custom CSS), publishing (open, pause, the edit lock) and reading results. Use this whenever the user wants to create, edit, review or fix a Deutero study, add or rewrite questions, set up screening or a participation link, make the interview look like their brand, publish, pause or resume a study, or hits `study_locked`, `invalid_theme` or a publish refusal, or asks what question type to use. It is the mechanical reference under the other Deutero skills (product research, customer development, simulation, interview flow, agent self-interview), which decide what to ask and hand the building to this one. Reach for it too when someone wants to turn a research goal, a survey draft or a topic list into an AI-conducted interview.
---

# Authoring a Deutero study

A Deutero study is an interview an AI conducts with each participant, one at a time, in chat, voice or video. You write the questions; the interviewer asks them, probes the answers, and keeps the conversation on the objectives you gave it.

That single fact should change how you write. You are not authoring a form to be filled in — you are briefing an interviewer. Each question carries private guidance the participant never sees, and the interviewer uses it to decide what to press on. A question with good guidance and a mediocre wording outperforms the reverse.

## Things that are not yours to decide or withhold

1. **The model tier is the user's choice, every time.** Ask before creating the study and wait for an answer — never default, never create on a guess and offer to change it. The tiers cost 1, 3 and 10 credits per five questions, so this is a real spending decision. Recommend one, but let the user pick it. Offer only the tiers their **plan** allows, which means establishing the plan first.
2. **The dashboard link goes to the user the moment the study exists.** `create_study` returns `dashboard_url`; put it in your next message, in full. Same for a study you created earlier in the session and are still working on — re-share the link rather than making them hunt for it.
3. **Opening and closing the study to participants is the user's call.** Don't publish a study the user hasn't agreed to open, and don't pause a live one without saying that pausing turns new participants away. The two things `publish_study` asks to be acknowledged, methodological validation issues and a credit shortfall, are theirs to accept, not yours.

## Know the plan before you design the study

The plan gates features outright, independently of the credit balance: a Hobby organization gets **text chat interviews on the open-weights model only** — no simulations, no Interview Flow, no image questions (neither showing images nor asking for one), no voice or video, one open (published) study at a time. Solo adds the standard tier, simulations, voice and image questions. Pro adds the premium tier, Interview Flow, video and WhatsApp. Team adds unlimited text interviews.

`get_credit_balance` does not name the plan; `base_limit` does — **15 Hobby, 100 Solo, 400 Pro, 1500 Team** — or just ask the user. Do this before choosing a tier, before proposing a branching flow, and before writing an image question (`present_images` or `image_upload`), because each of those is a 403 on some plan and the refusal comes after you have done the work. `deutero-setup/references/plan-limits.md` has the full matrix and the fallback for every gate.

## The shape of the work

```
project  →  study  →  details  →  questions  →  welcome/consent  →  screening  →  recruit  →  publish  →  read
```

Not every study needs every stage. Screening exists for panel recruitment and is dead weight when you know exactly who is answering. Characteristics profile a sample and are worth nothing at n=1.

## Step 1: Project and study

`list_projects`, then `create_project` if nothing fits. Then `create_study` with `project_id` and `name`. Everything else can be set now or later with `update_study`.

**Always give the user the study's dashboard link as soon as it is created.** `create_study` returns `dashboard_url` (`https://dashboard.deutero.ai/survey-details?survey_id=<study id>`) — paste it into your next message, in full and clickable, rather than only naming the study. The user cannot see anything you built until they can open it, and the link is how they check your work while you carry on with questions and screening.

Pick `survey_type` deliberately — it sets the interviewer's role and how it probes, and it is locked once the study is open: `user_experience` (how people use a product), `customer_development` (whether a problem is real, before building), `customer_satisfaction` (why existing customers are or are not satisfied), `customer_preferences` (how customers choose between options), `sociology` (academic social research), `polling` (public opinion). `create_study`'s `survey_type` description says what the interviewer does differently for each.

## Step 2: Details carry more weight than they look like they do

`research_question`, `objectives`, `target_population`, `description` and `methodology` are read by the interviewer during every interview, by the persona generator, by the recruitment strategy drafter, and by thematic analysis afterwards. Thin details are the single most common cause of vague output downstream — including vague probing, which shows up as a transcript full of pleasant nothing.

Write them as you would for a real study, and be specific enough that a stranger could tell who is in scope and who is not. `references/study-fields.md` has the field-by-field guidance, the model tier and cost table, quota and modality settings, and worked good/bad examples.

**Or have them drafted.** `draft_study` turns a short brief into a name, description, research questions, objectives and target population — the dashboard's Create Study wizard. `draft_study_from_site` does the same from a product landing page, aimed at what a founder most needs to learn. Neither stores anything: read the draft, fix what is generic, then pass its fields to `create_study`. A draft is worth having when the user arrives with a sentence rather than a brief; it is not a substitute for the specifics only the user has — the real numbers, the decision waiting on the answer, the exact population — so ask for those and edit them in. Both take twenty to forty seconds, so say you are drafting rather than going quiet. `references/study-fields.md` has the brief fields for each `survey_type`.

**Never pick `model_tier` on the user's behalf — always ask.** It is the largest cost lever in the platform (a 10× spread) and the largest quality lever, so it is the user's call every time, including when they have told you to go ahead and build the whole study. Ask before or at creation, present the three tiers with their rates and your recommendation, and wait for an answer rather than creating on a default and offering to change it later.

`open_weights` (1 credit / 5 questions) is fine for most user and market research and is the only tier on Hobby; `standard` (3×) and `premium` (10×) probe more deftly. On a study where probing quality *is* the product — a handful of expert interviews, a self-interview, anything nuanced — premium is usually cheap relative to the participant's time, and that is worth saying as a recommendation. Check `get_credit_balance` and the plan first so you only offer tiers the user can actually run.

## Step 3: Choose the question type before writing the question

This is the main quality lever in the whole platform, and reaching for open-ended by default is what produces one-word answers. An open question about an enumerable choice asks the participant to do work the instrument should have done.

Nine types: `text`, `choices`, `multi_select`, `scale`, `ranking`, `card_sort`, `slots`, `present_images`, `image_upload`. The rule of thumb:

- **You can name the plausible answers** → `choices`, with an escape option and `follow_up: true`. The pick gives you the position, the follow-up gives you the reason.
- **Degree** → `scale`, with both ends labelled by concrete behaviours rather than agreement wording.
- **"Which of these"** → `multi_select`.
- **Tradeoffs are the point** → `ranking`.
- **Sorting things into buckets** → `card_sort`.
- **Several named values inside one natural exchange** → `slots`.
- **A reaction to something you can show** — concepts, logos, packaging, screenshots → `present_images`, with one to four labelled images. Paid plans only.
- **Something only the participant can show you** — their setup, their workaround → `image_upload`. Paid plans only.
- **Genuine open ground** — the story, the reasoning, anything you could not have anticipated → `text`.

Every structured type still falls through to open probing once the answer is captured, so choosing structure costs nothing in depth. `references/question-types.md` has the exact config for each type, the field names, and what each one is bad at.

Questions get better when they are anchored. A question about a category of experience gets a category-level answer; a question about a specific thing that happened gets a specific answer, because the participant is recalling rather than theorising. Where the study has real events to point at — a session, a cancellation, a support ticket, a purchase — point at them.

**One decision per question.** Compound questions get half answered and the missing half goes unnoticed.

## Step 4: Write the guidance, not just the question

`explanation` on each question is private and never read aloud. Three things belong in it:

- **Background** — what prompted this question, so the interviewer can hold the thread without the spoken text carrying all of it.
- **Probe targets** — what a complete answer contains. "If they say cost, get the number they compared against" is useful; "probe for detail" is not.
- **Terseness handling** — where a short answer is likely, name the aspect worth pressing on and say when to accept the answer and move on. Some answers are short because the matter is settled, and pressing wastes the participant's time.

Conditional follow-ups belong here too: "if they mention price, ask what they compared it with", "if they say no, ask what stopped them", "if the answer is thin, offer these three positions as a straight choice". The interviewer reads each answer before deciding what to say next, so a note covers most of what looks like branching. An Interview Flow is for hard routing, loops, piping and mid-interview calls, not for this — see `deutero-interview-flow`, "First, decide whether you need one".

Bound the probing with `min_turns` and `max_turns`. Three to four turns suits an anchored question; beyond that the interviewer starts inventing angles. Switching probing off (`follow_up: false`, `max_turns: 1`) suits a factual question, not a whole study: done everywhere, it turns the interview into a form, and the participant's first answer is all you get.

**A generated first draft.** `generate_questions` writes 3–20 questions from the study details (plus any `additional_instructions`) and appends them to the list, extending rather than repeating what is already there. It is the dashboard's Generate with AI, and it is only as good as the details it reads, so set those first. Treat the result as a draft to hold against Steps 3 and 4: check each type choice, rewrite generic guidance into real probe targets, anchor questions to events, split anything compound, then `update_question` / `delete_question` / `reorder_questions`. Use `additional_instructions` to carry what the details do not — the occasion to anchor to, types you want, vocabulary to avoid. It takes thirty seconds to two minutes. Image-upload questions are proposed only when the study's tier can read images, and are dropped on plans that cannot (`skipped_image_questions`). When a topic skill has already chosen the questions, write those by hand instead — the generator does not know what you decided.

Run `validate_questions` when the set is written. It checks clarity, leading or biased wording, and ethics — the same review the dashboard's Validate button runs. Fix what it flags before recruiting, not after. It is a fast check on the questions alone. The review that gates publishing is `validate_study` (see Step 8).

## Step 5: Welcome and consent

`set_welcome`. Say who is running the study, what it involves, roughly how long it takes, and what happens to the answers. Set `consent: true` whenever the answers will be stored, analysed or used to change something — and say so plainly rather than burying it.

`generate_welcome` drafts that text — the dashboard's Welcome → Generate — and saves nothing. It writes it to be read aloud, introduces the interviewer as an AI working for the researcher, and scales the consent language to `survey_type` (`consent_level`: IRB-style for `sociology`, standard for `polling`, short for `user_experience`, `customer_development`, `customer_satisfaction` and `customer_preferences`). Run it **after** the questions exist, because the length it quotes comes from the question count (about three minutes each; 15 minutes when there are none). It reads `benefits`, `risks` and `support_contact` from the study, and the researcher's name and position from the profile of the account you are connected as, so set the study fields first. Whatever is missing comes back as a bracketed placeholder such as `[Insert researcher name]`, listed in `placeholders`: fill every one in, or ask the user for it, before `set_welcome` — participants hear the text verbatim. Then read the draft against the paragraph above; the generator does not know about a reward, a recording or how the answers will be used unless the study fields say so.

The start screen also takes optional copy on `set_welcome` (`title`, `time_estimate`, `footer`, button labels) and a hero image or large logo (`upload_welcome_hero`). `message` renders as limited Markdown there. **How the pages look** (brand colours, fonts, corners, custom CSS on Pro and Team) is `set_theme`, set once for the organization and overridden per study only when a study should look different. Ask for the brand's colours rather than inventing them. Readability is enforced, so a bright brand colour may be refused for text. `references/branding.md` has the fields, the refusals and how to fix them.

## Step 6: Screening, only if you are recruiting strangers

Screening questions are multiple choice and run before the interview. `acceptable_options` lists **who qualifies**; anyone whose answer is not in that list is screened out.

Three to five questions at most — each one loses participants. Screen on behaviour rather than intention ("have you cancelled in the last three months" beats "would you ever cancel"), and avoid giveaway phrasing, because a qualifying answer that is obvious will simply be selected. `references/recruitment-and-embedding.md` covers the tool calls and the panel-provider redirect.

Screened-out answers are not lost. A screened-out person leaves an incomplete interview with `termination_reason: "disqualified"`, and `get_interview` returns their answers under `qualifications`. So there is no reason to screen inside the interview or in an Interview Flow.

## Step 7: Recruit

`update_recruitment` sets the short-link slug, the response quota and the post-completion redirect; `get_recruitment` returns the participation links. Slugs are unique across all of Deutero.

Beyond the plain link there are three channels worth knowing: the **embed widget**, which runs the interview inside the user's own product; **email and in-app invitations**, where the copy does most of the work; and **Prolific**, which is dashboard-only. All three are in `references/recruitment-and-embedding.md`, along with the ethics points that apply whenever you recruit strangers.

Append `&participant_id=<your own id for this person>` to the link when the study is going to individually invited people — it is stored as `external_participant_id`, comes back on every result, and is what lets a finished interview be joined to a person you know. If finishing is supposed to *do* something for them (a reward, a credit, an unlocked feature), that ID plus the `interview.completed` webhook is the whole mechanism: see the `deutero-participant-rewards` skill.

## Step 8: Publish

A study only admits participants while it is **open**, and every study starts as a **draft**. A link shared before publishing turns people away. So once the study is built and the user is happy with it, and not before:

1. `get_publication_status` is free and shows whether a publish will go through. It covers the plan's open-study slots (`open_count` / `open_limit`), the credit check, and whether the latest validation is still current.
2. `validate_study` (optional; publishing runs it if needed) is the full review of everything participants read. It takes up to a minute. Fix ethical and blocking issues. Show the user the methodological ones.
3. `publish_study`. If it's refused, `detail.code` says why and what to do. Two refusals can be accepted with the user's agreement: `validation_issues` (call again with `acknowledge_validation_run_id`) and `credit_shortfall` (call again with `acknowledge_credit_shortfall: true`). A `plan_limit_reached` refusal lists the open studies holding the slots. Ask which one to pause, don't pick.
4. Then hand over the link from `get_recruitment`.

**Once open, the study is locked.** Tools that change what participants see (questions, flow, welcome, screening, characteristics, and the interview-facing fields of `update_study`) answer **409 `study_locked`**. The name, `max_responses`, `redirect_url` and `update_recruitment` stay editable. To change anything else, get the user's go-ahead, then `pause_study` → edit → `publish_study`. Interviews already running finish on the version they started with (`in_flight_count`). Check `status` in `get_study` before editing a study you didn't create in this session.

A study that reaches `max_responses` closes by itself. Raise the limit and publish again to collect more.

`references/publishing.md` has every refusal code, the fields each tool returns, and exactly which tools the lock covers.

## Step 9: Read the results

People who drop out partway are part of the data. Every turn is saved as it happens, so an abandoned interview stays in `list_interviews` (`completed: false`) with its transcript, and the tallies below include it unless you pass `completed=true`. Nothing needs building to keep partial answers.

`get_study_stats` for the count, `list_interviews` then `get_transcript` for the detail, `bulk_transcripts` to pull many at once, `search_transcripts` to find an exchange without re-reading everything (string, semantic and hybrid modes).

For structured questions, `get_scale_responses` and `get_options_responses` summarise. For open text across many participants, `run_clustering` groups similar answers — `get_optimal_clusters` first if you want the suggested k. Clustering is built for many participants and has nothing to say about one or two.

`find_interviews_by_external_id` looks one person up by your own ID for them, when the links were tagged.

`references/reading-results.md` has the analysis workflow and what to do with it.

## A caution worth keeping

These are stated preferences and remembered behaviour, captured at one moment. The gap between what people say and what they do is real, and it does not close because the participant is technical or the questions are good. Where a transcript disagrees with the behavioural evidence you already have, say so rather than deferring to the transcript.

## Building from code instead

Everything above is the same over the `deutero` Python SDK — one method per tool (`client.studies.create`, `client.questions.create`, `client.recruitment.update`, …), except the four generators and the four publication tools, which are REST calls until the SDK catches up — for when the study has to be built by a script, a CI job or the user's own product rather than by you in this session. The design decisions do not change; the model tier is still asked for, never hard-coded. `deutero-setup/references/python-sdk.md` has the method map and the conventions that differ from MCP.

## References

- `references/study-fields.md` — study details, model tiers and credit costs, quotas, modalities
- `references/question-types.md` — every question type, its config fields, and where it fails
- `references/recruitment-and-embedding.md` — links, screening, the embed widget, recruitment email and in-app copy, ethics
- `references/publishing.md` — publishing, pausing, refusal codes and acknowledgements, the edit lock, full studies
- `references/branding.md` — brand theme (colours, fonts, weights, corners), custom CSS, start-screen copy and hero image
- `references/reading-results.md` — transcripts, search, clustering, what to report
