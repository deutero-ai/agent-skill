# Reading results

## Watching it fill

```
get_study_stats {"study_id": "…"}
list_interviews {"study_id": "…"}
```

`get_study_stats` gives counts and completion. `list_interviews` lists the participants' interviews. Simulated (persona) interviews and **test runs** (the researcher's own interviews through the dashboard's Try Interview / Preview) are left out unless you ask: `simulated` and `test_runs` each take `true` (only those), `false` (leave them out, the default) or `null` (both). Every row carries `simulated` and `test_run`. Keep both out of anything you report, because a number that mixes real participants with personas or with the researcher trying their own study is not a number. `get_study_stats` counts them separately (`simulated_interviews`, `test_interviews`).

Do not poll unprompted. Set the quota, hand over the link, and let the user come back.

## Transcripts

```
get_transcript   {"interview_id": "…"}
get_interview    {"interview_id": "…"}
bulk_transcripts {"study_id": "…"}
search_transcripts {"study_id": "…", "q": "…", "mode": "hybrid"}
```

`get_interview` adds captured values and metadata — including embed metadata with its provenance — alongside the turns. `search_transcripts` has three modes: `string` (full text, supports quoted phrases and `-term`), `semantic` (embedding similarity, finds the same idea in different words) and `hybrid` (default, fuses both). Semantic is the one that earns its keep: people describe the same problem in words you did not think to grep for.

Read whole transcripts, not only the captured values. On structured questions the pick tells you the position and the probing turns around it tell you the condition attached to it, which is the part you can act on.

For interviews run from an Interview Flow, `get_interview_fetches_and_signals` shows what each context-fetch and signal step did.

## Finding one person

When the study was recruited with tagged links (`?participant_id=<your id>`), every interview carries that ID back as `external_participant_id`, and you can go straight to it:

```
find_interviews_by_external_id {"study_id": "…", "external_participant_id": "<your id>"}
```

It returns every attempt that ID made, newest first, in full detail — the direct answer to "did this person finish?". `list_interviews`, `bulk_transcripts` and `search_transcripts` all take the same filter. `find_interviews_by_external_id`, `bulk_transcripts` and `search_transcripts` leave test runs out unless `include_test_runs: true`, just as they leave personas out unless `include_simulated: true`. This is the read side of the reward round trip; the `recruit-participants` skill covers the write side.

## Recordings, quotes and clips

When the study records (`audio_recording` / `video_recording` not `off`), the moment someone said something can be saved and downloaded. `find_quotes` locates the words with their exact place; `create_clip` / `create_clip_from_quote` save the range; `get_interview_recording`, `list_clips`, `download_clip` and `export_media` cover the rest. Only `exact` and `fuzzy` hits are someone's words; a `semantic` hit is similar meaning and needs checking before you quote or clip it. Full workflow, locators, error codes and consent rules: `recordings-and-clips.md`.

## Contact details

When the study ran the contact step (see `recruitment-and-embedding.md`), what people gave is kept apart from everything above: no transcript, search hit, analysis or webhook carries it. `get_interview` says only `contact_status` — `shared`, `declined`, or null when no step ran. To read the details:

```
list_study_contacts   {"study_id": "…"}                 # everyone who shared, newest first
get_interview_contact {"interview_id": "…"}             # one person
```

`list_study_contacts` leaves out declines and test runs unless `include_declined` / `test_runs` is true, filters on `completed`, and pages (`limit` up to 500, `offset`). Each row has the `interview_id` and your `external_participant_id`, so it joins to everything else.

It is personal data. Use it to reach the person — a follow-up round, a diary study, a reward — and never paste it into a summary, a report, a cluster label or anything you share. Every read that returns details is in the organization's audit log. If the user only wants a count, `list_study_contacts` with `limit: 1` gives `total` without you handling a list of addresses.

## Analysis over many participants

```
list_analyzable_questions {"study_id": "…", "category": "text"}   # or "scale" / "options"
get_scale_responses       {"study_id": "…", "question_id": "…"}
get_options_responses     {"study_id": "…", "question_id": "…"}
get_optimal_clusters      {"study_id": "…", "question_id": "…"}
run_clustering            {"study_id": "…", "question_id": "…", "k": 4}
get_latest_clustering     {"study_id": "…", "question_id": "…"}
```

The two tallies read real participants only by default: personas and test runs stay out unless you pass `simulated: true` (a pilot's own numbers) or `test_runs`, and `completed: true` drops abandoned and failed interviews — use it when the denominator is "people who finished". The two tallies count one answer per interview, the one the interviewer recorded for the question itself; nothing said in a follow-up is a second vote. `get_options_responses` covers rankings too: `count` is first places and `positions[i]` how many interviews put the option at rank `i + 1`, so a top-2 share is `sum(positions[:2]) / responses`. Every tally lists the `answers` it was built from (interview and message), and `get_transcript` carries the same value on the participant's turn as `recorded_answer`. When a number matters, check a few of those against the participant's own words: a reply that names an option only to reject it should not have counted, and if it did, say so.

`run_clustering` saves its result, so it also appears on the study's Analyze page. `get_optimal_clusters` suggests a k; treat the suggestion as a starting point and look at whether the clusters are things you could name.

Clustering is built for many participants. At n=1 or n=2 it has nothing to say — read the transcripts.

## The thematic analysis report

When the study has been analysed (on the dashboard's Thematic page or with the tools below), read that analysis instead of rebuilding it:

```
get_study_themes      {"study_id": "…"}       # the whole report of the latest completed study analysis
get_interview_themes  {"interview_id": "…"}   # one interview's codes, themes and quotes
get_study_codebook    {"study_id": "…"}       # the codes every interview was coded against
```

Use `get_study_themes` for "what did we find": its findings, themes (with how many interviews raised each, out of what base), closed-question tallies and participants' phrases are already the study's synthesis, and every number in it was computed from the data, not written by a model. Go to `bulk_transcripts` / `search_transcripts` when the question is one the report does not answer, when there is no completed study analysis (404 `no_completed_study_run`: run one, below, if the user wants to pay for it), or to check a finding against the participants' own words. If `newer_run_status` is set, a newer analysis is running or failed and you are reading the earlier one; say so.

Cite a quote by its `cite` (e.g. `Q5.2`: guide question 5, the participant's second turn there) and its `byline`; `get_transcript` with its `interview_id` shows the turn (`message_id`). A quote with `verified: false` could not be matched word for word to the transcript: check it before you lean on it.

Check `report.split` and `report.banner`. Quotes and counts from **simulated** respondents are illustrations of the guide, never evidence about real people: do not present them as what participants said, and do not add them to real counts.

To share the report outside the organization, `create_report_share` freezes it into a link (anyone holding it can read it, unless `access` is `invited`). Shared reports leave out transcript links and participant ids but keep quotes and bylines. A 409 `report_mixes_simulated` or `report_shows_real_quotes` states facts the user must agree to: tell them the `message`, and resend with the matching `acknowledge_*` flag only once they have said yes. `get_report_share_links` lists the links; `refresh_report_share` updates one to the latest analysis on the same URL (and brings back a link revoked because an interview in it was erased, once the analysis has been re-run without it); `revoke_report_share` stops it for good.

## Running the analysis

The Thematic page's whole lifecycle is available as tools. Each interview is analysed on its own first; the study report then reads the analysed interviews.

```
list_interview_analyses     {"study_id": "…"}                    # each interview: not_analysed / queued / running / completed / failed
run_interview_analysis      {"study_id": "…", "interview_ids": [...]}  # up to 50; background, minutes each
get_study_analysis_options  {"study_id": "…"}                    # eligible interviews (>= 3 needed), segment and byline sources, cost
run_study_analysis          {"study_id": "…", "source": "real"}  # background; poll get_study_analysis
get_study_analysis          {"study_id": "…", "run_id": "…"}     # pending / running (stage) / completed / failed
retry_study_analysis        {"study_id": "…", "run_id": "…"}     # a failed one, same settings
```

**Every run costs credits and the user decides.** The first call is refused 409 `credit_confirmation_required`; its `detail` has `estimated_credits`, `available_credits` and, for interviews, `credits_per_interview` and `interviews_to_analyse`. Tell the user, wait for a yes, then resend the same call with `acknowledge_credits` set to `estimated_credits`. A 402 (`insufficient_credits`, `insufficient_credits_trial`, `payment_required`) means the balance cannot cover it: nothing started, nothing was charged — say so and point to Billing. A 403 `upgrade_required` means the tier is not on the plan; `allowed_tiers` lists the ones that are. Omit `model_tier` to use the study's own.

**Interview analyses.** Pass the ids from `list_interview_analyses` (or `list_interviews`). An interview already analysed is left alone and not charged unless you pass `rerun` (a new analysis, charged again — ask first). A `failed` or `stalled` one resumes where it stopped when you start it again, without paying again for the phases done. Interviews with no participant answers come back `skipped`. Poll `list_interview_analyses` every 30–60 seconds with the same `interview_ids` you started, so you read just those rows rather than the whole study; `counts` covers the interviews you named. Each interview takes a few minutes and they run side by side. Unfiltered, it returns 100 interviews a page (`limit` up to 500, `offset`), newest first, with `total`.

**The study report.** `get_study_analysis_options` says which interviews it can read and what it costs. `source` is `real` by default; `simulated` or `both` make a report that says throughout that it rests on personas. `segment_source` splits the counts by a single-select question or a characteristics variable; `byline_sources` (up to 3) credit each quote, e.g. with a role. One study analysis runs at a time (409 `study_run_in_progress`). Poll `get_study_analysis` every 20–30 seconds; read the result with `get_study_themes`.

**The codebook and the report's wording are free.** `consolidate_codebook` runs the merge/split/reword pass the dashboard's Consolidate button runs (it also runs on its own after the third coded interview and before each study analysis). `update_code` rewords a code, adopts or retires it, or moves it under a parent; `merge_codes` folds one code into another. Change codes only when the user asks or agrees: the codebook is their analytic frame. `edit_study_report` rewrites the headline, dek, decision or recommendation; numbers in it must be ones the data supports, or it is refused 422 `edit_rejected`.

## What to report

Lead with what changed your mind. A report that confirms everything the user already believed usually means the questions were too agreeable, and saying so is more useful than a tidy summary.

Then: the finding, how many participants it rests on, and a quote that shows it in their own words. Separate what participants said from what you infer. Where the transcript contradicts behavioural evidence the user already has — analytics, support volume, churn — put the contradiction in front of them rather than smoothing it over. Stated preference and revealed behaviour diverge routinely, and the divergence is usually the most valuable thing in the study.
