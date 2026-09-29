# Study fields, tiers and delivery settings

## Creating

```
create_project {"name": "…", "description": "…"}
create_study   {"project_id": "…", "name": "…", "survey_type": "user_experience"}
update_study   {"study_id": "…", "research_question": "…", "objectives": "…",
                "target_population": "…", "methodology": "…",
                "model_tier": "standard", "max_responses": 50}
get_study      {"study_id": "…"}
```

`create_study` returns `dashboard_url` — `https://dashboard.deutero.ai/survey-details?survey_id=<study id>`. Hand it to the user straight away; they cannot review anything you built without it.

## Drafting the details

```
draft_study            {"survey_type": "customer_development", "language": "English",
                        "problem_hypothesis": "…", "customer_segment": "…"}
draft_study_from_site  {"url": "https://example.com", "language": "English"}
```

Both return fields named as `create_study` takes them (`name`, `description`, `research_question`, `objectives`, `target_population`, plus `survey_type` and `language`) and **store nothing** — nothing exists until you call `create_study` with a `project_id`. Each is a model call of twenty to forty seconds.

`draft_study` reads only the brief fields of the `survey_type` you pick; the required ones are refused with 400 before any model call if missing:

| survey_type | Required | Optional |
|---|---|---|
| `sociology` | `research_question`, `population_of_interest` | `context_or_setting`, `key_concepts`, `scope_and_boundaries` |
| `customer_development` | `problem_hypothesis`, `customer_segment` | `solution_concept`, `key_assumptions`, `success_criteria` |
| `user_experience` | `business_context`, `research_need` | `target_users`, `research_type` (`exploratory` / `evaluative` / `generative`), `constraints` |
| `polling` | `research_question` | `population_segment`, `geographic_scope`, `survey_context` (`exploratory` / `validation` / `tracking` / `comparative`), `data_quality_requirements` |

`language` is both the language the draft is written in and the study's interview language — one of English, Spanish, French, German, Italian, Portuguese, Russian, Japanese, Korean, Chinese.

`draft_study_from_site` always drafts a `user_experience` study. When the page is an error or login page, or says too little about the product, it returns `is_valid: false`, `draft: null` and a `rationale` naming what was missing — try the product's main page rather than a sub-page. Drafts are limited to **5 per site per user** (`generations_used` / `generations_limit`; `http` vs `https` and a trailing slash are the same site), then 429. A page that could not be fetched does not count.

A draft is generic where the brief was. Before `create_study`, put in what only the user knows: the real numbers, the decision the study informs, inclusion criteria a stranger could apply. The model tier is still asked for, never taken from a draft.

## Reading a study

`get_study` is the one to call when you want to know where a study stands: configuration plus per-stage status (welcome set? screening enabled and how many questions? how many main questions?) plus the participation links. Call it before editing something you did not create in this session.

## survey_type

`sociology`, `user_experience`, `customer_development`, `polling`. It steers the interviewer's manner and framing, so pick the one that matches the work rather than the one that sounds most impressive.

## The four fields that steer everything

**research_question** — the central inquiry, specific and answerable.

- Bad: "Study about remote work"
- Good: "How do remote work policies affect employee productivity in mid-sized tech companies?"

**objectives** — three to five, specific, aligned to the research question.

- Bad: "Understand employee satisfaction"
- Good: "Measure satisfaction with the current remote collaboration tooling; identify the tasks people still come into the office to do; document what breaks in cross-timezone handoffs"

**target_population** — who should participate, with inclusion and exclusion criteria a stranger could apply.

- Bad: "People who work from home"
- Good: "Full-time employees at companies of 100–1000 people who work remotely at least three days a week"

**description** — context, why the study matters, what is expected to come out of it.

**methodology** — optional. Settable at creation and over the API; the Details page does not show it for editing afterwards, so set it over the API if you want it.

These are read by: the interviewer during every interview, the persona generator, the recruitment strategy drafter, the welcome drafter, and thematic analysis. Thin details produce thin everything.

## Model tier and what it costs

**Ask the user which tier to use; never choose one silently.** Show them this table, name the tier you would pick and why, and wait. A 10× cost spread is not an implementation detail.

Offer only tiers the organization's plan includes — the Plans column below is the gate, and selecting a tier outside it is refused with 403 at reservation time, not at creation. Infer the plan from `get_credit_balance`'s `base_limit` (15 Hobby, 100 Solo, 400 Pro, 1500 Team) or ask. On Hobby there is nothing to ask about: `open_weights` is the only tier, so say so rather than presenting a choice that does not exist.

Credits are Deutero's unit of compute. Rates are per five interview questions.

| Tier | Model | Rate | Plans |
|---|---|---|---|
| `open_weights` | DeepSeek V4 Flash | 1 credit / 5 questions | all, including Hobby |
| `standard` | Kimi K2.7 | 3 credits / 5 questions | Solo, Pro, Team |
| `premium` | Claude Sonnet 5 | 10 credits / 5 questions | Pro, Team |

`frontier` is a deprecated alias for `premium`.

Open weights is text-only: it cannot read image uploads, so `image_upload` questions are rejected on plans limited to that tier. Scale and multiple-choice questions with no follow-up are not counted toward the block size.

Multipliers: **simulated interviews cost 2×** the live rate and are unavailable on Hobby. **Thematic analysis with deliverables costs 2×**, charged per interview analysed at the study's per-five-question rate.

Modalities are plan-gated before they are priced: **voice needs a paid plan (Solo and up)**, **video and WhatsApp need Pro or Team**, and **Hobby is text chat only**. Enabling a modality the plan does not cover fails when a participant tries to use it, not when you set the flag, so check the plan rather than the toggle.

Voice and video add a surcharge on top of the base rate, charged once per interview: **voice +1 credit flat**, **video +1 credit per started 5 minutes** with a 1-credit minimum, billed on completion against actual length. Text chat carries no surcharge. A participant who switches modality mid-interview is charged where the time was spent, voice and video are never billed together (the larger wins, since video includes its audio), and a switch that the balance cannot cover leaves the interview running in its current modality rather than cutting it short.

Call `get_credit_balance` before committing to a plan of work, and say the number out loud to the user when it is tight. Its `base_limit` also tells you which plan you are on; `deutero-setup/references/plan-limits.md` has the full feature matrix.

## Delivery settings

Set with `update_study` (or on the Details page):

- **max_responses** — the quota that closes the study. `update_recruitment` can also set it; `clear_max_responses: true` removes it.
- **voice_enabled / video_enabled** — which modalities participants may use. Enabling them exposes extra participation URLs.
- **redirect_url** — where participants land after finishing. Essential with a paid panel.
- **Session recording** — off by default.

> **Known issue (September 2026).** Session recording does not work in production: every upload fails and participants are told recording has stopped. Transcripts are unaffected. Leave the toggles off, and do not promise participants a recording in consent text.

> **Known issue (September 2026).** The Voice Interview URL on the Recruit page uses the short slug (`/voice?s=slug`), which the voice interviewer rejects. Share `https://app.deutero.ai/voice?survey_id=<study id>` instead. Text and video links are unaffected.
