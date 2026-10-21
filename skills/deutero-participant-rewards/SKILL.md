---
name: deutero-participant-rewards
description: Wire a Deutero study to the user's own systems so that finishing an interview does something — issue a reward, credit an account, mark a panel task complete, unlock a feature, notify a CRM. Covers tagging each participant with the researcher's own ID (`?participant_id=` on the link, or the embed metadata bag), handing that ID back on the completion redirect, subscribing to the `interview.completed` webhook with `create_webhook`, verifying the signature, paying out exactly once, and reconciling anything missed. Use this whenever someone wants to pay, reward, thank, credit or unlock something for people who complete a study, asks how to know who finished in their own terms, wants a webhook, callback or notification when an interview ends, is writing a Deutero webhook receiver or reconciliation job with the Python SDK, mentions `interview.completed`, `external_participant_id`, incentives, gift cards, vouchers, panel callbacks or study payouts, or asks how to join Deutero interviews back to their own users.
---

# Implementing participant rewards

A study that owes people something when they finish needs to answer one question from the outside: **which of my own users just completed an interview?** Deutero's interview IDs are no help — the researcher's system has never seen them.

The answer is a round trip you set up before recruiting:

```
1. tag the link      ?participant_id=<your id>     → stored as external_participant_id
2. send them back    redirect_url with {{external_participant_id}}
3. hear about it     interview.completed webhook, signed, carries the same id
4. reconcile         find_interviews_by_external_id, for anything missed
```

All four work on a plain linear study. None of them needs an Interview Flow, so do not build one to carry a participant ID or to learn that someone finished.

Steps 1 and 3 are the load-bearing ones. Two negatives decide whether this works at all, and both are cheaper to read now than to discover after the study has run:

- **Never pay from the redirect.** A redirect is a URL the participant can replay, and will. Step 2 is for the participant's experience; the payout hangs off step 3, the signed event.
- **Never identify a participant by anything the interview collected** — a name, an email, a free-text answer, the time they started. The only join key is the ID *you* put on the link before they arrived (step 1). Matching on interview content produces silent mispayments that look like a working system.

## Step 0: choose the ID before anything else

`external_participant_id` is free text you choose, and money makes it a security decision rather than a labelling one. Two constraints pull in opposite directions and both must hold:

- **Pseudonymous.** It travels in a URL the participant can read, sits in the interview record, appears in exports, and comes back on the redirect. Never an email address, a name, or anything else identifying. A hash of your own user ID, a panel token, a row key.
- **Unguessable.** Anyone holding the link can edit the parameter. If your IDs are sequential — `user-1041` — a participant can complete the study four times under three other people's IDs and claim their rewards. Use an HMAC of your user ID with a server-side secret, or a one-time token you issued to that person.

```python
import hmac, hashlib

# PARTICIPANT_SALT = os.environ["DEUTERO_PARTICIPANT_SALT"]   # server-side secret, never shipped to the client
def participant_tag(user_id: str) -> str:
    return hmac.new(
        PARTICIPANT_SALT.encode(), str(user_id).encode(), hashlib.sha256
    ).hexdigest()[:32]
```

Keep the mapping (tag → your user) on your side. Deutero stores only the tag.

Say the quiet part to the user when they propose an email address or a raw account ID: the first is a privacy problem, the second is a fraud problem, and both are cheap to avoid now and expensive to fix after the study has run.

## Step 1: set the ID on the way in

Which mechanism depends on how people arrive. All three land in the same place — `interviews.external_participant_id`.

| Arrival | How the ID is set | Trustworthy? |
|---|---|---|
| Link you send (email, DM, panel) | `…/chat?s=<slug>&participant_id=<tag>` | Only as much as the tag is unguessable |
| Embed widget, page-supplied | `data-metadata='{"participant_id":"<tag>"}'` | No — a visitor can edit it in dev tools |
| Embed widget, signed token | `participant_id` inside the signed JWT's `metadata` claim | **Yes** — minted by your server |

Build one link per person; `&source=<campaign>` alongside it tags the channel (`web_source`) if you also want to know where they came from. For an embedded study where finishing pays out, use the **signed token** — page-supplied metadata is a value the visitor controls, which is exactly the thing you cannot afford here. Money is not the only reason to sign: sign the metadata whenever the *analysis* depends on it too (cutting results by plan, page type, city), and a signed bag with no `participant_id` at all is a legitimate shape — logged-out visitors have no ID to carry, and the context is still worth trusting. `deutero-study-authoring/references/recruitment-and-embedding.md` has the minting code and the claim table.

## Step 2: hand the ID back on the redirect

```
update_recruitment       {"study_id": "…", "redirect_url": "https://you.example/thanks?pid={{external_participant_id}}"}
set_screening_settings   {"study_id": "…", "enabled": true,
                          "redirect_url": "https://you.example/screened-out?pid={{external_participant_id}}"}
```

Set the screen-out redirect before the study is published. Screening is locked while the study is open (409 `study_locked`), though the completion `redirect_url` isn't.

`{{external_participant_id}}` is the only placeholder either URL understands; it expands to the ID the interview arrived with, or to nothing when it arrived bare. Set the screening one too if you screen people out — a panel has to be told who bounced as well as who finished, and a screen-out never produces a completion webhook.

Use the landing page to *acknowledge* ("thanks — your voucher is on its way"), and let the webhook do the paying. If the page issues the reward, refreshing it issues another.

Serve that page `Cache-Control: no-store`. The redirect URL is identical for every participant and the page renders one person's outcome, so a shared or intermediary cache is one config away from showing the last participant's result to the next one.

## Step 3: subscribe to the completion event

```
list_webhook_event_types {}
create_webhook {"label": "Study rewards", "url": "https://you.example/hooks/deutero",
                "events": ["interview.completed"]}
```

`create_webhook` returns `signing_secret` **once** and it can never be read back. Store it in the receiver's secret manager before you do anything else in the session; if it is lost, `rotate_webhook_secret` mints a new one and the old one stops verifying immediately.

The payload carries both identities:

```json
{"type": "interview.completed",
 "timestamp": "2026-09-20T14:30:00+00:00",
 "data": {"interview_id": "…", "survey_id": "…", "completed": true,
          "participant_id": "…", "external_participant_id": "<your tag>",
          "web_source": "newsletter"}}
```

Endpoints are per **organization**, not per study — one endpoint hears about every study, so branch on `survey_id` in the receiver rather than creating an endpoint per study. `references/webhook-events.md` has the full event catalogue, the delivery semantics and the verification code.

## Step 4: the receiver, in the order that matters

1. **Verify the signature** over the raw body, before parsing. An unverified body is an instruction from a stranger.
2. **Check it is the event you think**: `type == "interview.completed"` and `data.completed is true`.
3. **Check the study**, if this endpoint serves more than one reward scheme.
4. **Resolve your own record** from `external_participant_id`. Missing or unknown means someone reached the study without a tagged link — log it, reward nothing, and do not guess.
5. **Deduplicate on `webhook-id`** before issuing anything, and treat "this tag already got paid for this study" as a second guard.
6. **Return 2xx inside 10 seconds.** If the payout is a local write (a ledger row, a credit grant, an entitlement flag), do it inline — introducing a queue to satisfy a rule buys a new failure mode, a lost job, in exchange for nothing. Queue it when the payout calls somebody else's API (vouchers, gift cards, a CRM), which is the part that is actually slow and flaky.

`references/reward-handler.md` is a complete worked receiver with the idempotency table. In Python, verify with the SDK's `deutero.webhooks.unwrap` — it checks the signature and hands back a typed `InterviewCompletedEvent`.

## Step 5: reconcile, because there are no retries

A Deutero webhook is attempted **once**. If your server was down, restarting does not bring the event back. Reconcile on a schedule, or whenever a participant says they were not paid:

```
find_interviews_by_external_id {"study_id": "…", "external_participant_id": "<tag>"}
list_interviews                {"study_id": "…", "completed": true, "limit": 500}
list_webhook_deliveries        {"webhook_id": "…", "success": false}
```

`find_interviews_by_external_id` returns **every attempt** that tag made, newest first — starting over after abandoning is ordinary, so pay on the first completed one and not once per row. `list_webhook_deliveries` separates "we tried and your server refused it" from "nothing ever fired", which are different bugs: the first is yours, the second usually means the endpoint is disabled or not subscribed to that event.

Both listing calls exclude persona runs and test runs (the researcher's own Try Interview / Preview interviews) by default, so a sweep pays neither unless you ask it to. The parameters differ by surface: `list_interviews` takes `simulated` and `test_runs`, everything else takes `include_simulated` and `include_test_runs`. Check which one you are passing rather than assuming. The webhooks carry `test_run` too, and a handler skips `true`.

**MCP is an agent-time surface, and reconciliation usually has to run on your server.** The same tools are plain REST, wrapped in Python by the `deutero` SDK (`client.interviews.list`, `client.interviews.find_by_external_id`, `client.webhooks.list_deliveries`) — `reward-handler.md` §6 has the sweep, paged, with the env var the key belongs in.

## Things that quietly cost money

- **Trusting the ID as an identity.** It says which of your records to look at. Proof of origin is the signature, nothing else.
- **Paying per webhook rather than per person.** Retries you add, duplicate deliveries, and a participant's second attempt all land as separate events. Idempotency is not optional.
- **Rewarding incomplete interviews.** `data.completed` false, or an interview that never finished, is not a completion. Decide the partial-completion policy deliberately and say it in the welcome text.
- **Forgetting screen-outs.** They generate no completion event. If the panel pays for screen-outs, the screening redirect is the only signal you get.
- **Simulated interviews.** Persona runs fire `simulation.completed`, never `interview.completed`, so rehearsing a study cannot pay anybody — worth knowing before you go looking for the event in a test. The reconcile sweep is the one place they *could* be paid, since it reads the interview list directly; the listing defaults exclude them, so keep the default rather than widening it for convenience.
- **Asking the wrong people.** Who is invited, after how long, and how you avoid asking twice decides whether the study is worth running at all — a churn study mailed to people who never churned is a wasted month. `reward-handler.md` §9 covers the bookkeeping.

## Tell the participant what they are getting

The reward belongs in the welcome text: what it is, what earns it (completing, not starting), and when it arrives. If you draft that text with `generate_welcome`, put the reward in the study's `benefits` first — it is the only field the generator reads it from — and check the draft says all three. A study that pays on completion without saying so gets abandoned interviews from people who did not know there was a reason to finish, and complaints from people who assumed there was.

## References

- `references/webhook-events.md` — every event and its payload, the envelope and signature headers, delivery semantics, verification code, managing endpoints over MCP, and the separate mid-interview flow signals
- `references/reward-handler.md` — worked end-to-end implementation: tagging links, the verified receiver, idempotency, inline vs queued payout, the reconciliation job as a server-side REST call, and choosing who to invite
- `deutero-study-authoring/references/recruitment-and-embedding.md` — links, screening redirects, the embed widget and signed metadata
