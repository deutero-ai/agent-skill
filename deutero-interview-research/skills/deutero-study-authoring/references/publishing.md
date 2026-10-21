# Publishing, pausing and the edit lock

A study admits participants only while its `status` is `open`. Every study starts as `draft`, and a link shared before the study is published turns people away with "not accepting responses". Building a study and publishing it are two separate acts, and publishing is the one the user sees from outside.

| `status` | Admits participants | Configuration editable | Reached by |
|---|---|---|---|
| `draft` | no | yes | creation |
| `open` | **yes** | **locked** | `publish_study` |
| `paused` | no | yes | `pause_study` |
| `closed` | no | yes | automatically, when completed (non-simulated) interviews reach `max_responses` |

`get_study` and `list_studies` return `status` on every study. Links (`get_recruitment`) never change with status.

## Tools

```
get_publication_status {"study_id": "…"}
validate_study         {"study_id": "…"}
publish_study          {"study_id": "…",
                        "acknowledge_validation_run_id": null,     # optional
                        "acknowledge_credit_shortfall": false}     # optional
pause_study            {"study_id": "…"}
```

- **`get_publication_status`** costs nothing and changes nothing. Call it before publishing to see whether it will work. It returns `status`, `plan_tier`, `open_limit` (null means unlimited) and `open_count`, and a `credit_check` with `per_interview` (worst-case credits for one interview), `remaining_responses`, `estimated_total`, `net_available`, `floor_denial` and `covers_remaining`. It also returns `latest_validation` (`outcome`, `issues`, and `current`, which is true when that run matches the present configuration and publishing will reuse it) and `changed_since_publish`.
- **`validate_study`** is the full pre-publish review: the questions or compiled flow, the welcome, and the screening, characteristics and snowball texts. It is a model call, so allow up to a minute and tell the user you're validating. The result is recorded, and `publish_study` reuses it without another model call while the configuration is unchanged (`reused: true`). This is **not** `validate_questions`, which is a quick check on the questions alone and does not count toward publishing.
- **`publish_study`** opens a `draft`, `paused` or `closed` study. If the study is already open it does nothing (`already_open: true`). It validates the study itself if no current run exists, so `validate_study` first is optional. It's still worth calling first when you want to fix issues before the user sees a refusal.
- **`pause_study`** stops new admissions and unlocks editing. `in_flight_count` is the number of interviews still running, which finish on the configuration they started with. `in_flight_source` is `temporal` (exact) or `database` (an estimate).

## The checks, in order

`publish_study` refuses with an HTTP error. `detail.code` is stable, `detail.message` is readable, and the rest of `detail` carries the numbers.

| `code` | HTTP | Meaning | What to do |
|---|---|---|---|
| `plan_limit_reached` | 402 | The plan's open-study limit is used up. `detail.open_studies` lists `{id, alias}` for the studies holding the slots, plus `limit` and `plan_tier`. | Ask the user which study to pause, or suggest upgrading. **Never pause another study on your own initiative.** It turns away that study's participants. |
| `flow_not_on_plan` | 402 | The study runs an Interview Flow (`interview_mode: graph`), which only Pro and Team include. `detail.plan_tier` names the plan. | Tell the user. Most flows flatten into the question list, which is still there: `deactivate_graph` switches back to it on any plan. Or they upgrade. |
| `payment_required` | 402 | The subscription is past due, or there is an outstanding balance. | Billing is dashboard-only. Send the user to `/billing`. |
| `insufficient_credits` | 402 | The balance cannot cover even one worst-case interview (`per_interview` vs `net_available`). | Top up or upgrade (dashboard), or make the study cheaper: a lower tier, fewer questions, or voice/video turned off. |
| `credit_shortfall` | 409 | The balance covers at least one interview but not every remaining response. | Report `remaining_responses`, `estimated_total` and `net_available`. **Ask the user.** On a yes, call again with `acknowledge_credit_shortfall: true`. Participants beyond the balance will be turned away. |
| `validation_blocking` | 422 | The study cannot run: `no_questions`, `graph_not_active`, `flow_not_on_plan`, `model_not_on_plan`, `image_question_denied`. | Fix it. These cannot be acknowledged. |
| `validation_ethical` | 422 | The ethics check failed. | Fix what `issues` says, then publish again. This can't be acknowledged, and the verdict stands until the configuration changes, so retrying unchanged gets the same refusal. |
| `validation_issues` | 409 | Methodological findings only (wording, leading questions, redundancy, quality). `detail.validation_run_id` identifies the run. | Show the user the issues and **ask** whether to fix them or publish anyway. To publish anyway, call again with `acknowledge_validation_run_id` set to that id. It only matches that exact run. |
| `validation_unavailable` | 503 | The validator gave no verdict. A failed check is never treated as a pass. | Retry after a moment. |
| `study_changed` | 409 | Someone edited the study while it was being validated. | Retry. |
| `invalid_transition` | 409 | A `closed` study is still at its `max_responses`. | Raise `max_responses` (`update_recruitment`), then publish. |

The plan limit counts only studies that are open **and not yet full**. Drafts, paused and closed studies are free. See `deutero-setup/references/plan-limits.md` for the limits: Hobby 1, Solo 1, Pro 3, Team unlimited.

Each issue in `issues` has `severity` (`ethical`, `blocking`, `methodological`), a `code`, a `message` and a `location`. `location.kind` is one of `question`, `welcome`, `screening`, `characteristics`, `snowball_message` or `study`. For a question it also has `number` (1-based) and `id`, which is the question id, or your own step id in a flow. Use that to go straight to `update_question` / `patch_graph`.

**The two acknowledgements are the user's decisions, like the model tier.** A credit shortfall means real people get turned away, and methodological issues are a quality call on their research. Report what came back, recommend, and wait. Don't set either flag just to get a publish through.

## The edit lock

While a study is `open`, every tool that changes what participants see is refused with **409**, `detail.code: "study_locked"`:

- questions: `create_question`, `update_question`, `delete_question`, `reorder_questions`, `generate_questions`, `upload_question_image`, `delete_question_image`
- flow: `set_graph`, `patch_graph`, `import_questions_to_graph`, `activate_graph`, `deactivate_graph`, `upload_flow_image`
- welcome: `set_welcome` (including its start-screen copy), `generate_welcome`, `upsert_welcome_translation`, `delete_welcome_translation`, `upload_welcome_hero`, `delete_welcome_hero`
- screening and characteristics: every write, including their settings
- `update_study` when it changes an interview-facing field (description, research question, objectives, target population, methodology, language, model tier, voice/video, recording, anonymity, retrieval/web search, consent-form fields). `detail.changed` names the fields it refused, and nothing in that call is saved.

Still editable while open: the study's `name`, `max_responses`, `redirect_url`, and everything in `update_recruitment`. Also the look of the pages (`set_theme`, theme and custom CSS), embed keys, webhooks, personas, simulations and all reads and analysis.

Changing a live study goes: tell the user that pausing turns new participants away, and get a yes, then `pause_study` → make the edits → `publish_study`. Say how many interviews are in flight. They finish on the old version, so the transcripts will be a mix of versions. Mention it if the edit changes what a question means. Publishing again re-validates only if the configuration changed. Resuming an untouched study reuses the earlier verdict.

## Testing before publishing

Nothing in the MCP surface admits a person to an unpublished study. The dashboard's **Try Interview** dialog (the **Preview** button in the study's status bar, or **Try Interview** on the Questions page) makes a two-hour link that works in any status, unless the ethics check has blocked the study. Point the user there to try a draft themselves. They pick the model tier and the mode: chat, on-device voice, cloud voice or video.

That interview is a **test run**. It never counts toward `max_responses` and never closes the study. `get_study_stats` reports it as `test_interviews`, not in the totals, and its webhooks carry `test_run: true`. `list_interviews`, `bulk_transcripts`, `search_transcripts` and `find_interviews_by_external_id` leave test runs out unless asked (`test_runs` / `include_test_runs`), and every interview, transcript and search hit carries `test_run`. Each study gets 3 free test runs on Hobby and 5 on paid plans, on `open_weights` in chat or on-device voice. Others are billed normally. So "try it yourself first" costs the user nothing on the cheap tier, and saying so removes the usual reason to skip it.

Simulations (`run_simulation`) run on drafts and paused studies too, since they're not gated on status.

## Full studies

When a completed interview brings the count to `max_responses`, the study closes on its own and stops counting against the plan limit. To keep collecting, raise `max_responses` and publish again. Nothing reopens by itself.
