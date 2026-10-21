# Plan limits and feature gates

Every Deutero organization sits on one of four plans. The plan decides which model tiers, modalities and features the API will accept — not the credit balance, which is a separate limit. A feature the plan does not cover is refused with **403 "Upgrade required"** no matter how many credits are sitting unused.

Check the plan before designing around a feature. Building a branching flow for a Hobby user, or a premium-tier study for a Solo user, wastes their time and yours.

## The matrix

| | Hobby | Solo | Pro | Team |
|---|---|---|---|---|
| Price | free | $29/mo | $99/mo | $299/mo |
| Credits / month | 15 | 100 | 400 | 1,500 |
| Seats | 1 | 1 | 1 | 5 |
| Open (published) studies at once | 1 | 1 | 3 | unlimited |
| `open_weights` tier | ✓ | ✓ | ✓ | ✓ |
| `standard` tier | — | ✓ | ✓ | ✓ |
| `premium` tier | — | — | ✓ | ✓ |
| Simulations | — | ✓ | ✓ | ✓ |
| Text chat interviews | ✓ | ✓ | ✓ | unlimited* |
| Voice interviews | — | ✓ | ✓ | ✓ |
| Video interviews | — | — | ✓ | ✓ |
| WhatsApp interviews | — | — | ✓ | ✓ |
| Image questions (`present_images`, `image_upload`) | — | ✓ | ✓ | ✓ |
| Interview Flow (graph mode) | — | — | ✓ | ✓ |
| Brand theme (colours, fonts, hero image) | ✓ | ✓ | ✓ | ✓ |
| Custom CSS on the interview pages | — | — | ✓ | ✓ |
| Credit top-ups | — | ✓ | ✓ | ✓ |

\* On Team, text-only interviews keep running after the included credits are spent. Every other plan stops at its balance unless auto top-up is on.

**Hobby is text chat only, on the open-weights model, with no simulations.** That is the single most important line in the table, because it is the plan a new user lands on and it rules out most of what the other Deutero skills want to do.

Enterprise is Team plus unlimited seats, SSO, custom domains and custom credit packages; treat it as Team for feature purposes.

## Working out which plan you are on

`get_credit_balance` does **not** return the plan name. Infer it from `base_limit`, which is the plan's monthly credit allowance:

| `base_limit` | Plan |
|---|---|
| 15 | Hobby |
| 100 | Solo |
| 400 | Pro |
| 1500 | Team |

Anything else means purchased credits or a custom package — ask the user rather than guessing. `is_trial_active: true` means a 14-day trial with its own 100-credit allowance; trial organizations get the features of the plan they are trialling.

Two other honest ways to find out: ask the user directly ("which Deutero plan are you on?"), or discover it from a 403, whose message names the plan needed. Asking costs one exchange and is usually better than authoring on a guess.

## What to do instead, per gate

- **No `standard`/`premium` on this plan** — use `open_weights` and compensate with much more detailed private `explanation` guidance on every question. The cheaper model probes more literally, so enumerate what a good answer covers instead of trusting it to find the thread.
- **No simulations on Hobby** — you cannot dry-run the instrument. Do a careful `validate_questions` pass instead, and have the user take the interview themselves with the **Preview** button in the dashboard, which works on a draft. It is a worse test, but it is a test.
- **No Interview Flow below Pro** — keep the study on the linear question list, which is where most studies belong on any plan. Source and participant IDs, embed metadata and answer-dependent follow-ups need no flow. Most branching can be flattened: ask the discriminating question, then write the follow-ups so they make sense for everyone, and let the interviewer's own probing do the adapting.
- **No image questions** — instead of asking for a picture, ask the participant to describe what they would have shown, in a `text` question with guidance naming the details you want. Instead of showing images, describe each concept in the question text.
- **No custom CSS below Pro**: the brand theme covers colours, fonts and weights, corner style and the default mode on every plan, and it is checked for readability, which custom CSS is not. Most branding requests need nothing more. A downgraded organization keeps its CSS but it is switched off; removing it works on any plan.
- **No voice/video/WhatsApp** — text chat, which is also the one modality with no credit surcharge.
- **Open-study limit** — it limits *publishing*, not creating. Any number of drafts can exist. `publish_study` refuses with 402 `plan_limit_reached` and lists the open studies holding the slots. Only studies that are open and not yet full count. Ask the user which one to `pause_study` (it turns that study's participants away), or suggest upgrading. `get_publication_status` shows `open_count` / `open_limit` before you try. See `deutero-study-authoring/references/publishing.md`.

## A caution about where these numbers come from

This table is the published pricing. The running API enforces its own gates and the two can drift — the `premium` tier in particular is enforced as Pro-and-above in the current code while the pricing page markets it as Team-only. **A 403 is the authority; this table is the plan.** When a call is refused, report exactly what the message said rather than arguing from this page, and when a feature this table says is gated turns out to work, take the API's word for it.
