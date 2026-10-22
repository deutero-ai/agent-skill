# Changelog

## 1.8.9

What the branding tools now reach, as the interviewer catches up with them.

- `branding.md`: the embed widget wears the study's theme (colours for both modes, fonts, weights, corners, default mode), but not custom CSS or the start-screen copy. Custom CSS is now applied on the hosted pages, and their Content-Security-Policy blocks any outside load a sanitiser misses (images only from Deutero and the logo host, fonts only from Google Fonts). The welcome turn in the thread, transcript, messaging channels and speech is the message with its Markdown stripped (links as "text (url)"). Voice and video show the start-screen title, message, hero, time estimate, footer and `continue_label`. Two new common mistakes.
- `recruitment-and-embedding.md`: widget colour no longer has to be matched by hand. The site's `theme` (or its own `--dtro-*` CSS) still wins, with the full property list; new `data-study-theme="false"` / `useStudyTheme: false` opts out. Also lists `data-language` and `data-language-picker`, and what a strict site CSP costs.

## 1.8.8

- `recruitment-and-embedding.md` covers the whole signed-token flow, not just minting: a TypeScript (`jose`) example next to the Python one, the signed script tag, the single-page-app case (fetch the token from your own endpoint, set `data-signed-token` before appending the script), and a checklist for a rejected signed bootstrap (expiry, `kid` / wrong secret, lost secret and key rotation, origin, study scope, revocation, metadata limits). It points to the dashboard's Signed Metadata help article for developers working without an agent.

## 1.8.7

The branding tools are documented across the skills, not just in passing.

- New `deutero-study-authoring/references/branding.md`. It covers organization vs study themes, every theme key, the readability rule and how to fix an `invalid_theme` refusal, how `set_theme` replaces the stored theme, custom CSS (what is stripped, the stable `data-part` hooks), the start-screen copy fields and limits, the hero image, translated copy, and common mistakes.
- `deutero-study-authoring`: the description covers branding and `invalid_theme`, and Step 5 points to the new reference.
- `deutero-setup`: the tool inventory lists `get_theme`, `set_theme`, `upload_welcome_hero` and `delete_welcome_hero` (93 tools). The error table adds the org-admin 403 and `invalid_theme`. `plan-limits.md` adds custom CSS (Pro and Team) and the brand theme (every plan). `python-sdk.md` gives the REST routes for the branding tools, which SDK 0.2 lacks.
- `publishing.md`: the hero tools are under the edit lock; `set_theme` is not. `recruitment-and-embedding.md`: the embed widget's colours are set on the host, not by the theme.

## 1.8.6

- `set_theme` takes `body_weight` as well as `display_weight`. Each must be a weight the font it applies to comes in (the default fonts when none is set), and a refusal lists the weights that font has. Font names must match a Google Fonts family exactly.

## 1.8.5

Brand theming and a richer start screen for the participant pages.

- New tools `get_theme` / `set_theme`: brand colours (light and dark), Google Fonts, corner style and default mode, for the organization or one study (`study_id`). Unreadable colour pairs are refused with `invalid_theme` and each problem listed. `custom_css` is Pro and Team only (403 `upgrade_required` otherwise) and is returned sanitised, with `css_stripped`. Appearance is not locked while a study is open.
- `set_welcome` takes optional start-screen copy (`title`, `time_estimate`, `footer`, `continue_label`, `consent_yes_label`, `consent_no_label`, `hero_alt`). Fields left out keep their value. `message` is limited Markdown on the web start screen, and `warnings` lists what will not render. New `upload_welcome_hero` / `delete_welcome_hero`. Welcome translations take `fields`. `deutero-study-authoring` Step 5 covers it.

## 1.8.4

Interview Flow is enforced as a Pro-and-Team feature, and the skills say what a flow is not needed for in the cases that led agents to build one anyway.

- The plan gate the skills described is now real. Below Pro, every flow-authoring tool (`describe_graph_nodes`, `check_graph`, `set_graph`, `patch_graph`, `import_questions_to_graph`, `upload_flow_image`, `activate_graph`) answers 403 with `detail.code: "upgrade_required"`, and `publish_study` refuses a study in graph mode with `flow_not_on_plan` (402). `get_graph`, `get_flow_signals` and `deactivate_graph` stay open on every plan, so a study left in graph mode can switch back to its question list. `deutero-interview-flow` and `publishing.md` list both codes.
- `deutero-interview-flow`'s table adds four rows that do not need a flow: screening (never screen inside a flow; a screened-out person's answers are on their interview), keeping what people said when they drop out (every turn is saved; `output_var` is not a retention mechanism), optional questions at the end, and an opt-in for contact details.
- "Hard routing" now means routing to different *blocks* of questions. If each path would be a single question, write one question whose guidance covers each case. Count before committing: decisions that lead to one or two questions and rejoin, or that route people to an `end` early, are a question list or screening.
- New in `deutero-interview-flow`: when an existing flow misbehaves, run the test again before repairing it, and rebuild on the question list if it fails.
- `deutero-study-authoring`: screened-out answers are kept (Step 6), abandoned interviews are part of the results and of the tallies unless `completed=true` (Step 9), and switching probing off on every question turns the interview into a form (Step 4).
- Flows now come back with advisory `warnings` from `check_graph`, `set_graph`, `patch_graph`, `import_questions_to_graph`, `get_graph` and `activate_graph`: `screening_in_flow`, `optional_block_in_flow`, `single_question_branch`, `parallel_paths`, `flow_not_needed` and `interview_as_form`. They never stop a save. `validate_study` reports them as methodological issues on location kind `flow` (and `interview_as_form` on a question list too), so publishing needs them fixed or acknowledged. `compiled.length` gives the questions and estimated minutes on the shortest and longest paths. `deutero-interview-flow` says what each warning means and what to do.

## 1.8.3

Interview Flow is for interviews that cannot work without it, and every step of a flow must lead onward to an end.

- `deutero-interview-flow` now opens with whether a flow is needed at all, before the plan check. A table lists what does not need one and what to use instead: `?source=` and `?participant_id=` on the link, embed metadata, answer-dependent follow-ups in the question's guidance, `follow_up` / `min_turns` / `max_turns` for thin answers, screening and characteristics questions, the `interview.completed` webhook and `redirect_url`, and the question types themselves for tallies. A flow is reserved for hard routing, loops, piping and mid-interview calls. The description no longer reads as a trigger to build a flow for any conditional question.
- The terse-answer fallback starts in guidance. Built as a flow, it is for when the forced choice must be recorded as its own structured answer, or the study is a flow anyway. `graph-patterns.md` and `agent-self-interview` say the same; neither calls it "the pattern that earns the graph" any more.
- New section "Every step leads onward to an end" in `deutero-interview-flow`, and matching notes in `graph-patterns.md`. A step with no outgoing edge is an error (`dead_end`), not an implicit end, so the last question on each path connects to `end` explicitly. It also covers `fanout`, `unreachable`, `no_path_to_end` (a loop-back edge is not a way out), `no_default` (a classifier class with no path of its own goes down the default), side steps that follow a question with no edge onward, `remove_node` not reconnecting neighbours, and the editor's new `unconnected_path` for an unwired Branch path.
- `deutero-study-authoring` (Step 4 and `recruitment-and-embedding.md`), `deutero-participant-rewards`, `webhook-events.md` and `plan-limits.md` say where their features work without a flow: link parameters, embed metadata, conditional follow-ups and completion webhooks.

## 1.8.2

The skills cover randomising option order and reading the tallies correctly, and install cleanly through a security scanner.

- `randomize_options` is documented in `deutero-study-authoring/references/question-types.md` and in the shared-key table of `deutero-interview-flow`: it shows each participant their own order on `choices`, `multi_select`, `ranking` and the cards of a `card_sort`, leaves escape options such as "None of these" where you put them, and `get_options_responses` reports each answer's `presented_order` so you can check whether the option shown first still won.
- `deutero-study-authoring/references/reading-results.md` says what the two tallies count and from whom: real participants only unless you pass `simulated: true` or `test_runs`, `completed: true` to drop abandoned and failed interviews, one recorded answer per interview, and `positions[i]` for rankings so a top-2 share falls out of the response count.
- `deutero-study-authoring/references/study-fields.md` moves the `standard` tier from Kimi K2.7 to Claude Haiku 5.5, still 3 credits per five questions on Solo, Pro and Team.
- The REST examples in `deutero-setup/references/mcp-clients.md` and `deutero-participant-rewards/references/reward-handler.md` send a `<your-api-key>` placeholder instead of interpolating `$DEUTERO_API_KEY` into the `X-API-Key` header. The prose around them still says to keep the key in the environment.
- Where a snippet read a secret inline, the env read is now a comment naming the variable and the snippet uses the plain constant: `DEUTERO_WEBHOOK_SECRET`, `DEUTERO_PARTICIPANT_SALT`, `REWARDED_STUDY_ID`, `DEUTERO_EMBED_SIGNING_SECRET` and `DEUTERO_EMBED_PUBLISHABLE_KEY` stay visible in `deutero-participant-rewards/{SKILL.md,references/webhook-events.md,references/reward-handler.md}` and `deutero-study-authoring/references/recruitment-and-embedding.md`, without a line that reads the environment. Behaviour for a reader is unchanged.
- Scan-driven installers refused the whole set until this: Hermes' skills guard scored `deutero-setup` and `deutero-participant-rewards` as dangerous — a hard block that `--force` cannot override — and `deutero-study-authoring` as caution, so `hermes skills install` refused them. All eight now scan safe.

## 1.8.1

Image questions are now gated by plan, not by model.

- The open-weights model reads images, so every tier can run `present_images` and `image_upload` questions. Both are paid-plan features: on Hobby, creating either is rejected with 403, and `publish_study` reports `image_question_denied`. Previously `present_images` was allowed on Hobby, and `image_upload` was refused on Hobby and could not be published on an open-weights study.
- Simulations show a `present_images` question's images to the persona, so its answers react to what is actually on screen. An image that cannot be loaded reaches the persona as a note saying so.
- `deutero-study-authoring` lists `present_images` among the question types, with `image_upload`, in the rule of thumb, and both under the Hobby plan gate. `plan-limits.md`, `account-signup.md`, `question-types.md` and `study-fields.md` say images are gated by plan.
- `deutero-simulation` covers image questions: what to read their transcripts for (usable labels, probes about the images, a missing image) and why a persona's preference between concepts is not evidence. `persona-writing.md` adds a persona set for testing one.
- `deutero-interview-flow` adds the `images` step config to the linear-versus-graph naming table.

## 1.8.0

Images for **Present Images** questions can be uploaded over MCP, stored exactly as the dashboard's question editor stores them.

- New tools: `upload_question_image` and `delete_question_image` attach and remove the images of a `present_images` question (one image per call, base64 in `image_base64`, JPEG/PNG/WebP up to 10 MB, downscaled to 1024×1024 WebP), and `upload_flow_image` stores an image for an Interview Flow step and returns the `url` for its `images`. All three are locked while the study is open.
- `present_images` is now a valid `qtype` for `create_question` / `update_question`, and `import_questions_to_graph` carries such questions and their images into the flow.
- `question-types.md` documents `present_images`. `mcp-clients.md` lists all 89 tools, `publishing.md` adds the three to the locked list, and `python-sdk.md` gives their REST routes, which SDK 0.2 has no methods for.

## 1.7.0

Studies now have a publication status, and only an **open** study admits participants. Every study starts as a draft, publishing checks the plan's open-study limit, credits and a full validation, and an open study's interview configuration is locked until it is paused.

- New tools: `get_publication_status`, `validate_study`, `publish_study` and `pause_study`. `get_study` and `list_studies` return `status` (`draft`, `open`, `paused`, `closed`).
- New `deutero-study-authoring/references/publishing.md`: the lifecycle, every `publish_study` refusal code and what to do about it, the two acknowledgements (`acknowledge_validation_run_id`, `acknowledge_credit_shortfall`), exactly which tools answer 409 `study_locked` while a study is open, and how a full study closes itself.
- `deutero-study-authoring` gains Step 8, Publish, between recruitment and reading results. It adds a third rule to "not yours to decide": opening or pausing a study, and accepting a credit shortfall or methodological issues, are the user's calls. `validate_questions` is now described as the quick check it is, with `validate_study` as the one that gates publishing.
- `deutero-setup`: the open-study limit limits *publishing*, not creating studies. `plan-limits.md` previously said to close a study before `create_study`, which was wrong. The limit counts only open, not-yet-full studies. 402 on `publish_study` may be `plan_limit_reached` rather than credits. `mcp-clients.md` lists all 86 tools and adds `study_locked` and publish refusals to troubleshooting. `python-sdk.md` gives the REST routes for the four tools, which SDK 0.2 has no methods for.
- Test runs: the dashboard's **Try Interview** / **Preview** dialog runs the researcher's own interview as a test run, with a free allowance per study (3 on Hobby, 5 on paid plans, open weights in chat or on-device voice). Test runs stay out of `max_responses` and out of `get_study_stats` totals (new `test_interviews` count), and the `interview.started` / `interview.completed` webhooks carry `test_run`. `publishing.md` sends users there to try a draft. `webhook-events.md` tells a reward handler to skip `test_run: true`.
- Reading results: `list_interviews` gains `test_runs` (true / false, the default / null), and `find_interviews_by_external_id`, `bulk_transcripts` and `search_transcripts` gain `include_test_runs`. Every interview, transcript and search hit carries `test_run`. `reading-results.md`, the rewards skill and `python-sdk.md` say test runs are left out by default and how to ask for them. `agent-self-interview` passes `test_runs: null` when the principal took the interview through Try Interview.
- `agent-self-interview` publishes (with the user's agreement) before handing over the link. `deutero-interview-flow` notes that flow writes are locked while open and that publishing refuses an inactive flow. `deutero-participant-rewards` sets the screen-out redirect before publishing. `deutero-simulation` and `plan-limits.md` send a Hobby user to the dashboard's **Preview** instead of the participation link, because a draft's link admits nobody.

## 1.6.0

Study details, interview questions and the welcome text can now be AI-generated over MCP, the same generators the dashboard uses. Nothing in the "not covered over MCP" list is about generation any more.

- New tools: `draft_study` (a study draft from a research brief — the Create Study wizard), `draft_study_from_site` (from a product landing page — Suggest from Site; 5 drafts per site per user) and `generate_questions` (3–20 questions appended to the study's list — Generate with AI) and `generate_welcome` (welcome and consent text — Welcome → Generate). Drafts store nothing; their fields go to `create_study`, and a welcome draft to `set_welcome`.
- `deutero-study-authoring` Step 5 covers `generate_welcome`: run it after the questions exist (it quotes a length from the count), set `benefits` / `risks` / `support_contact` first, fill every entry in `placeholders` before saving, and how `consent_level` follows `survey_type`. `deutero-participant-rewards` says to put the reward in `benefits` before generating.
- `deutero-study-authoring` covers when a draft helps and what it cannot supply, and treats generated questions as a first draft to hold against the type and guidance rules. `study-fields.md` has the brief fields per `survey_type`; `question-types.md` has `generate_questions` and what to check in its output.
- `deutero-customer-development` and `deutero-product-research` say where the generators fit their methods and where they do not.
- `deutero-setup`: the tools are in the inventory, and generation of study details, questions and welcome text is off the "not available over MCP" list. `python-sdk.md` gives the REST routes, since SDK 0.2 has no methods for them.
- Fixed: `mcp-clients.md`'s tool inventory was missing the webhook tools, `find_interviews_by_external_id` and `get_flow_signals`. It now lists all 82 tools, checked against the API's own spec.

## 1.5.0

Covers the `deutero` Python SDK (0.2.0), the supported way for a server or script to do what the MCP tools do.

- New `deutero-setup/references/python-sdk.md`: install (and that 0.1.x targeted a removed API, so code using `studies.generate`, `analysis.run` or `credits.estimate_*` needs porting, not debugging), `DEUTERO_API_KEY`, the async client, a full MCP tool → SDK method table with the renames called out (`run_clustering` → `analysis.cluster`, `bulk_transcripts` → `transcripts.list`, …), `None`-means-unsent semantics, paging, the exception table, and `deutero.webhooks` for verifying deliveries.
- Documented that `PermissionDeniedError` (403, a plan gate) subclasses `AuthenticationError` (401), so catching the latter first misreports a plan limit as a bad key.
- `deutero-participant-rewards`: the worked receiver verifies with `deutero.webhooks.unwrap` and branches on the typed `InterviewCompletedEvent`; the reconciliation sweep uses `client.interviews.list` and now pages through `total` — the previous single `limit=500` request stopped paying at the 501st completion. `webhook-events.md` §3 leads with the SDK and keeps `standardwebhooks` and the stdlib verifier as alternatives.
- `deutero-setup` sends code that runs without an agent to the SDK or REST, and `mcp-clients.md` shows the SDK call beside the curl one.
- `deutero-study-authoring` notes that a study can be built from a script with the same decisions, the model tier still the user's.
- Fixed: `deutero-setup` still listed webhook endpoint management as dashboard-only; it has been available over MCP since 1.3.0.

## 1.4.0

Corrections and additions from implementing `deutero-participant-rewards` against a real codebase.

- `deutero-participant-rewards` now leads with the two negatives that cost the rework — never pay from the redirect, never identify a participant by anything the interview collected — above the steps rather than in a list at the end.
- Reconciliation is written for a server: MCP tools are agent-time only, so `reward-handler.md` §6 has the authenticated REST call (`X-API-Key`, `DEUTERO_API_KEY`) with the route paths behind `list_interviews`, `find_interviews_by_external_id`, `get_interview` and `list_webhook_deliveries`, and notes that persona runs are excluded by default but the parameter is spelled `simulated` on one surface and `include_simulated` on the others. `DEUTERO_API_KEY` and the embed signing secret are in the §1 pieces table.
- `webhook-events.md` §3 gains a "if you are not using the library" block: the `{id}.{timestamp}.{body}` signing string, the `whsec_`-stripped base64 key and its padding, the space-separated `v1,<sig>` header list (which is what makes rotation gapless), and the ±5-minute bound.
- Idempotency advice says which constraint covers which failure: `(user_id, study_id)` collapses redeliveries, reconcile races and second attempts on its own, and `webhook_msg_id` is only load-bearing for a per-interview reward. Added that a payout usually belongs in the ledger, credits or entitlements table the host system already has, rather than a new side table.
- "Queue the payout" is scaled to the payout: inline for a local write, queued for a third-party call. A queue introduced to satisfy a rule adds a lost-job failure mode and pays for nothing.
- The completion page needs `Cache-Control: no-store` — one redirect URL serves every participant and renders one person's outcome.
- The duplicated embed-token snippet is gone, replaced by a pointer to the authoritative claim table plus the two rules a rewards integration gets wrong: the `exp - iat` ≤ 900s cap **is** enforced, and `typ: "JWT"` is **not**, so a missing `typ` is never the cause of a rejection. Both files corrected.
- New `reward-handler.md` §9, "Choosing who to invite": the delay before asking, excluding on the payment record rather than on credit grants (free grants and the reward itself are rows in the same table), one ask per person recorded before delivery, and ordering an in-app prompt against an email.
- `recruitment-and-embedding.md` §5 documents the embed widget properly and fixes a misleading debugging note: the host element carries `data-deutero-widget` and is findable with `querySelector`; the full `data-*` attribute set (`data-title`, `data-position`, `data-open-on-load`, `data-api-base-url`); `init()`-only `container` (inline mount) and `theme`; the instance API and events; `--dtro-accent` / `--dtro-accent-contrast` / `--dtro-z`; the fixed `bottom: 20px` with no offset option; and the doubled-specificity rule (`.dtro-root.dtro-root`) that `adoptedStyleSheets` forces on anyone overriding the widget's CSS.
- Signing embed metadata is documented as an analysis decision as well as a payment one — a logged-out embed that signs page context and carries no participant ID is an ordinary use.
- `deutero-setup/references/mcp-clients.md` no longer claims the MCP tool name is the REST route path (it is the route function's name), and says plainly that a backend uses REST because MCP is not available to it.

## 1.3.0

- New `deutero-participant-rewards` skill: the round trip from tagging a participant with your own ID (`?participant_id=` on the link, or the embed metadata bag's `participant_id` key) to issuing a reward when the signed `interview.completed` webhook fires. Covers choosing an ID that is pseudonymous *and* unguessable, the completion and screen-out redirects, a verified receiver, paying exactly once, and reconciling what a missed delivery lost.
- `references/webhook-events.md` documents every event and its payload, the envelope and signature headers, delivery semantics (one attempt, 10-second timeout, no retries) and the endpoint-management tools — plus the distinction between organization-level events and an Interview Flow's mid-interview signals, whose per-step secrets `get_flow_signals` returns.
- Webhook endpoints are no longer dashboard-only: `list_webhook_event_types`, `create_webhook`, `update_webhook`, `rotate_webhook_secret`, `delete_webhook` and `list_webhook_deliveries` are MCP tools. The README's "not covered over MCP" list is corrected accordingly.
- `deutero-study-authoring` gains the attribution parameters (`&source=`, `&participant_id=`), the `{{external_participant_id}}` redirect placeholder and the `participant_id` embed metadata key in `recruitment-and-embedding.md`, and `find_interviews_by_external_id` in `reading-results.md`, so a study built with that skill can be joined back to the people who were invited to it.
- Fixed: `search_transcripts`' query parameter is `q`, not `query`, in `reading-results.md`.

## 1.2.0

- Subscription plan gates are now respected throughout. New `deutero-setup/references/plan-limits.md` carries the Hobby/Solo/Pro/Team matrix — model tiers, simulations, Interview Flow, modalities, image questions, concurrent studies, credit allowances — plus how to detect the plan (`get_credit_balance`'s `base_limit`: 15/100/400/1500) and the fallback for every gate.
- `deutero-setup` establishes the plan alongside the credit balance before any design work, since the two are separate limits and a gated feature is refused regardless of balance.
- `deutero-simulation` states the Hobby refusal up front and offers the non-simulated fallback instead of failing at `run_simulation`.
- `deutero-interview-flow` opens with the Pro-and-above gate and how to flatten a branching design onto the linear list below it.
- `deutero-study-authoring` offers only tiers the plan allows, and its references gate image-upload questions, voice/video/WhatsApp modalities and the participation links accordingly.

## 1.1.0

- The model tier is now always the user's choice. Every skill that creates a study or starts a simulation asks the user to pick `model_tier` and waits for an answer, instead of defaulting or recommending one and proceeding. Affects `deutero-study-authoring`, `deutero-simulation`, `agent-self-interview`, `deutero-customer-development` and `deutero-product-research`.
- New studies now hand the user their dashboard link. `create_study`'s `dashboard_url` is shared as soon as the study exists, so the user can review what was built while authoring continues.

## 1.0.0

First release as a unified Agent Plugins package.

- Added `deutero-setup` (account creation, OAuth and API key configuration, connection checks).
- Added `deutero-study-authoring` as the shared hub: study fields and credit costs, all eight question types, recruitment including the embed widget and invitation copy, and reading results.
- Added `deutero-product-research` for studies driven by analytics and product context, analytics-platform agnostic.
- Added `deutero-customer-development` for discovery studies from a business idea or plan.
- Added `deutero-simulation` for persona-driven instrument testing.
- Promoted the standalone `graph-patterns.md` into `deutero-interview-flow`, with the deterministic-branching and piped-text patterns folded in.
- Reworked `agent-self-interview` to delegate mechanics to the shared skills and keep only what is specific to a single-participant interview.
- Declared the Deutero MCP server in `mcp.json` with no embedded credentials, so authorization stays client-managed.
