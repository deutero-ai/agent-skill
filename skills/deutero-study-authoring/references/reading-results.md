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

It returns every attempt that ID made, newest first, in full detail — the direct answer to "did this person finish?". `list_interviews`, `bulk_transcripts` and `search_transcripts` all take the same filter. `find_interviews_by_external_id`, `bulk_transcripts` and `search_transcripts` leave test runs out unless `include_test_runs: true`, just as they leave personas out unless `include_simulated: true`. This is the read side of the reward round trip; the `deutero-participant-rewards` skill covers the write side.

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

The multi-phase **thematic analysis** pipeline and its reports are dashboard-only. When a user wants that, point them at the Analyze page rather than reconstructing it from clustering.

## What to report

Lead with what changed your mind. A report that confirms everything the user already believed usually means the questions were too agreeable, and saying so is more useful than a tidy summary.

Then: the finding, how many participants it rests on, and a quote that shows it in their own words. Separate what participants said from what you infer. Where the transcript contradicts behavioural evidence the user already has — analytics, support volume, churn — put the contradiction in front of them rather than smoothing it over. Stated preference and revealed behaviour diverge routinely, and the divergence is usually the most valuable thing in the study.
