# Changelog

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
