# Reading results

## Watching it fill

```
get_study_stats {"study_id": "…"}
list_interviews {"study_id": "…"}
```

`get_study_stats` gives counts and completion. `list_interviews` lists the interviews, including simulated ones, which are flagged so you can separate them — always separate them before reporting anything, because a number that mixes simulated and real participants is not a number.

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

It returns every attempt that ID made, newest first, in full detail — the direct answer to "did this person finish?". `list_interviews`, `bulk_transcripts` and `search_transcripts` all take the same filter. This is the read side of the reward round trip; the `deutero-participant-rewards` skill covers the write side.

## Analysis over many participants

```
list_analyzable_questions {"study_id": "…", "category": "text"}   # or "scale" / "options"
get_scale_responses       {"study_id": "…", "question_id": "…"}
get_options_responses     {"study_id": "…", "question_id": "…"}
get_optimal_clusters      {"study_id": "…", "question_id": "…"}
run_clustering            {"study_id": "…", "question_id": "…", "k": 4}
get_latest_clustering     {"study_id": "…", "question_id": "…"}
```

`run_clustering` saves its result, so it also appears on the study's Analyze page. `get_optimal_clusters` suggests a k; treat the suggestion as a starting point and look at whether the clusters are things you could name.

Clustering is built for many participants. At n=1 or n=2 it has nothing to say — read the transcripts.

The multi-phase **thematic analysis** pipeline and its reports are dashboard-only. When a user wants that, point them at the Analyze page rather than reconstructing it from clustering.

## What to report

Lead with what changed your mind. A report that confirms everything the user already believed usually means the questions were too agreeable, and saying so is more useful than a tidy summary.

Then: the finding, how many participants it rests on, and a quote that shows it in their own words. Separate what participants said from what you infer. Where the transcript contradicts behavioural evidence the user already has — analytics, support volume, churn — put the contradiction in front of them rather than smoothing it over. Stated preference and revealed behaviour diverge routinely, and the divergence is usually the most valuable thing in the study.
