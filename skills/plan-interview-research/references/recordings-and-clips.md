# Recordings and clips

What a study records, how to find the moment someone said something, save it as a clip, and get a file. Fourteen tools: `get_interview_recording`, `find_quotes`, `create_clip`, `create_clip_from_quote`, `list_clips`, `get_clip`, `update_clip`, `delete_clip`, `download_clip`, `download_interview_recording`, `export_media`, and `get_download`, `get_media_export` and `list_media_exports` to collect the result.

Nothing here returns media bytes. A file is always a job that ends in a link which works only with the credentials of the person who asked.

## 1. The study decides what may be recorded

`audio_recording` and `video_recording` on `create_study` / `update_study` are each `off`, `optional` (the participant may decline) or `required` (a condition of taking part). Rules, enforced on every surface:

- video needs audio: video on with audio `off` is refused;
- video `required` with audio `optional` is refused (a required recording cannot depend on an optional one);
- video cannot be combined with PII masking.

The API answers 422 `invalid_recording_policy`; publishing reports `recording_video_without_audio`, `recording_video_required_audio_optional` or `pii_masking_video_recording` as blocking. Both fields are locked configuration: while the study is open, changing them is 409 `study_locked`.

What is actually recorded is the policy **and** the participant's consent. A participant who agreed to audio only has no video anywhere: not in playback, not in a clip, not in a download. Do not promise a participant a recording the study does not take, and say what is recorded in the consent text.

Typed interviews and studies that do not record have no recordings. Everything below then only applies to the transcript.

## 2. What was recorded: `get_interview_recording`

```
get_interview_recording {"interview_id": "…"}
```

Returns the study's `policy`, the participant's `consent`, and the interview's recording **sessions**: a page load or reconnect starts a new one (`seq` 1, 2, …). Each has `status` (`ready` plays; `recording`/`finalizing` are not yet; `failed` is lost, with `error`), `duration_ms` and `has_video`. Sessions lie end to end in `seq` order, and `total_duration_ms` sums the ready ones. Recordings finish when the interview does, so a just-finished interview may still be `finalizing`: wait and ask again. Each read is audited.

`get_transcript {"interview_id": "…", "include_timings": true}` adds each spoken turn's word timings. It is large, so leave it off unless you need exact times for `create_clip`.

## 3. Find the words: `find_quotes`

```
find_quotes {"study_id": "…", "q": "I just wanted the total up front", "mode": "hybrid", "limit": 10}
```

Returns short passages (a sentence or two, not whole turns) with their exact place (`interview_id`, `message_id`, `char_start`, `char_end`), the words around them, and `timing` when they were spoken in a recording. `clip_ready: true` means `create_clip` can clip that span now. At most two per interview.

`mode`: `hybrid` (default: verbatim first, then meaning), `exact` (verbatim and near-verbatim only), `semantic` (meaning only). Check `match` on every hit: `exact` and `fuzzy` are the person's words; **`semantic` says something similar and is not a quote**. Never present a semantic hit as what someone said without reading it against the transcript first. `interview_id` limits the search to one interview.

## 4. Save a clip

A clip is a word-snapped range of **one recording session**, located one of three ways. Give exactly one:

| Locator | Use when |
|---|---|
| `quote` | you have the words. Verbatim or near-verbatim; case, punctuation and number formatting are ignored; a paraphrase does not match. Add `message_id` to look only in that turn |
| `message_id` + `char_start` + `char_end` | you have a `find_quotes` hit or read the transcript. Offsets are Unicode code points into the message; `end_message_id` extends the range over several turns |
| `start_ms` + `end_ms` | you have times (from `include_timings`). On `session_id`'s clock when given, else on the interview's timeline |

```
create_clip {"interview_id": "…", "quote": "I just wanted the total up front", "title": "Price surprise", "tags": ["pricing"]}
create_clip_from_quote {"study_id": "…", "quote": "…"}      # you hold a quote but not its interview
```

`create_clip_from_quote` is for a quote you have without knowing where it came from, such as a thematic analysis supporting quote. Narrow with `interview_id`, `external_participant_id` or `question_id`. A clip stores no text: `text` is derived from the transcript, so it never drifts. `padding_ms` (0–2000) adds lead-in and tail when the clip is downloaded; it is not part of the stored range.

Errors carry a `code` in `detail`:

| Code | Status | What to do |
|---|---|---|
| `quote_not_found` | 422 | Those words are not in the transcript. `near_miss` shows the closest text; quote verbatim or narrow with `message_id`. From `create_clip_from_quote` it comes back as `ambiguous_quote` with similar passages instead: check one, then `create_clip` on its interview |
| `ambiguous_quote` | 409 | More than one place. Retry with a `candidates` entry's `message_id` (and `interview_id`) |
| `no_audio` | 422 | That text was typed, or spoken while nothing was recorded |
| `recording_not_ready` | 409 | Still processing. Retry in a few minutes |
| `spans_sessions` | 422 | A clip comes from one session; split it in two |
| `out_of_range`, `invalid_locator`, `message_not_found` | 422 | Fix the range, or give exactly one locator |

Never turn a semantic hit into a clip by guessing: read it, confirm it says what you mean, then clip by its `message_id` and offsets.

## 5. Manage clips

```
list_clips  {"study_id": "…", "tag": "pricing", "q": "total", "has_video": true}
get_clip    {"clip_id": "…"}          # adds context_before / context_after
update_clip {"clip_id": "…", "title": "…", "tags": [...], "note": "…"}   # or a new locator to re-trim; the id stays
delete_clip {"clip_id": "…"}          # the recording and transcript are untouched
```

`list_clips` filters on `interview_id`, `external_participant_id`, `tag`, `created_by=me`, `q` (titles, notes and quote text) and `has_video`, and pages with `limit` (≤ 200) and `offset`. Tags are lower-cased, at most 20.

## 6. Get files

Asynchronous. Start the job, poll, then fetch the `url` with the **same credentials you called with** (it is not a public link and does not work for anyone else).

```
download_clip                {"clip_id": "…", "format": "mp4", "captions": "burned", "framing": "participant"}
download_interview_recording {"interview_id": "…", "kind": "audio"}      # or session_id for one session
get_download                 {"download_id": "…"}      # status: queued, building, ready, failed, expired
```

- Clips: `format` `mp4` (needs video consent), `m4a`, `vtt` or `srt`; `captions` `none`, `burned` or `file`; `framing` `participant`, `interviewer` or `both` (the video is one side-by-side frame); `speaker_labels` `role` or `name`.
- Recordings: `kind` `video` (needs consent), `audio` (stereo mix) or `master` (the four-channel archive). Omit `session_id` for the whole interview with its sessions joined.
- Video for a participant who agreed to audio only is 422 `video_not_consented`. Ask for `m4a` or `audio` instead.
- Ready files last 24 hours. Anything over 250 MB comes back with `delivery: "email"`: the requester is emailed, and the `media_export.ready` webhook fires.
- At most three active jobs per person.

For many at once, `export_media`:

```
export_media {"study_id": "…", "include": {"recordings": true, "transcripts": true, "captions": true}}
export_media {"study_id": "…", "clip_ids": ["…", "…"], "reel": true}        # clips, optionally joined into one video
get_media_export / list_media_exports
```

An export is one archive: a folder per interview, named by your `external_participant_id`, with a `manifest.json`. It is always built in the background and the requester is emailed (and `media_export.ready` or `media_export.failed` fires). It is deleted 48 hours after it is ready, and an organization may export 20 GB per 24 hours. Anything left out for consent is listed in `omitted[]`: read it before assuming an archive is complete.

## 7. What agents do not do here

- Erasing an interview's media is a dashboard action for an organization admin (it removes every copy and keeps the transcript). It is not an MCP tool; do not offer to do it.
- Media files are personal data. Keep them where the study's consent says they may go, and do not forward the `url`.
- Participant contact details stay out of transcripts, clips and exports; use `get_interview_contact` only when you must reach someone (see `reading-results.md`).
