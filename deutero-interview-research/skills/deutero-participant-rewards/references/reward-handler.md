# A worked reward implementation

One study, one reward per person who completes it. Everything here is the shape rather than the framework — the decisions are what carry over.

Contents:
1. The pieces
2. Minting the tag and the link
3. The embed variant
4. The receiver
5. Issuing exactly once
6. The reconciliation job
7. Testing it before recruiting
8. Partial completions and screen-outs
9. Choosing who to invite

---

## 1. The pieces

| Piece | Lives | Why |
|---|---|---|
| `participant_tag` | your DB, per invited user | joins the webhook back to a person |
| `DEUTERO_PARTICIPANT_SALT` | your secret manager | makes tags unguessable |
| `DEUTERO_WEBHOOK_SECRET` | your secret manager | verifies deliveries; shown once at `create_webhook` |
| `DEUTERO_API_KEY` | your secret manager | the reconcile sweep's credential — §6; MCP is not available to your server |
| `DEUTERO_EMBED_SIGNING_SECRET` | your secret manager | only for an embedded study: `dtro_sk_…`, shown once at `create_embed_key` |
| the grant record | your DB | the idempotency record, and the audit trail when someone disputes |

Four secrets for an embedded rewarded study, three without it. None of them is the publishable key, which is a browser value and not a secret.

```sql
create table reward_grants (
  id            bigserial primary key,
  user_id       text not null,
  study_id      text not null,
  interview_id  text not null,
  webhook_msg_id text not null,
  status        text not null default 'pending',   -- pending | issued | failed
  issued_at     timestamptz,
  unique (user_id, study_id),          -- one reward per person per study
  unique (webhook_msg_id)              -- one row per delivery
);
```

Two unique constraints, doing two different jobs:

- `(user_id, study_id)` stops a person being paid twice however many interviews they start. It also collapses a redelivery, a reconcile sweep racing the webhook, and a second interview after an abandoned one — all three become the same losing insert.
- `(webhook_msg_id)` stops one *delivery* being processed twice. It is only load-bearing when the reward is **per interview** rather than per person — paying for each of three diary-study sessions, say. For one reward per person per study the first constraint already covers every case, and this row changes no outcome.

Let the database enforce whichever you keep — an `if already_paid` check in application code loses the race when two deliveries land together.

**If your system already has a system of record for payouts** — a credit ledger, a usage table, an entitlements row — the grant usually belongs *there*, keyed so the uniqueness falls out (`research-reward-{study_id}-{user_id}` as the charge/reference id, for instance). A side table buys an audit trail the host system already has, and splits the reward off from the machinery that reports, refunds and revokes it. Write `reward_grants` when there is nothing to put the grant in.

## 2. Minting the tag and the link

```python
import hmac, hashlib, os
from urllib.parse import urlencode

SALT = os.environ["DEUTERO_PARTICIPANT_SALT"]
STUDY_SLUG = "mealkit-churn"

def participant_tag(user_id: str) -> str:
    return hmac.new(SALT.encode(), str(user_id).encode(), hashlib.sha256).hexdigest()[:32]

def study_link(user_id: str, source: str = "email") -> str:
    query = urlencode({"s": STUDY_SLUG,
                       "participant_id": participant_tag(user_id),
                       "source": source})
    return f"https://app.deutero.ai/chat?{query}"
```

The tag is derived rather than stored, so the reverse lookup is a scan unless you also persist it. For anything above a few hundred invitations, store `participant_tag` on the user row with an index — the receiver does that lookup on every delivery.

`source` is optional and free: it tags the channel (`web_source` on the interview), which is how you find out that the in-app prompt converts four times better than the email.

## 3. The embed variant

An embedded study has no link to hang the parameter off; the metadata bag carries the tag instead, under the key `participant_id`. Page-supplied metadata is editable in dev tools, so when finishing pays out, mint a **signed token** server-side and let the widget pass that.

The minting code, the full claim table and the metadata limits live in one place — `deutero-study-authoring/references/recruitment-and-embedding.md` §5 — and that is the copy to follow. Two of its rules are the ones a rewards implementation gets wrong:

- **`exp - iat` may not exceed 900 seconds**, and that ceiling is enforced on Deutero's side, not merely advised. 5–10 minutes is the sane default; mint one token per page load rather than stretching the lifetime.
- **`kid` is the publishable key.** It is how Deutero finds the signing secret, so a token minted without it fails before the signature is ever checked. `alg` must be `HS256`; `typ: "JWT"` is conventional and not enforced, so its absence is not the cause of a rejection you are debugging.

The widget takes the token as `data-signed-token` instead of `data-publishable-key`. Verified values override page-supplied ones of the same name, and `get_interview` reports which was which — so you can check, afterwards, that the IDs you paid on were the signed kind.

A signed bag carrying **no** `participant_id` is a legitimate use too: logged-out visitors have no ID of yours to carry, and signing `{page_type, city, entry}` still means the analysis can be cut by values the page could not forge.

## 4. The receiver

```python
import os
from flask import Flask, request, abort, jsonify
from standardwebhooks import Webhook, WebhookVerificationError

app = Flask(__name__)
wh = Webhook(os.environ["DEUTERO_WEBHOOK_SECRET"])
STUDY_ID = os.environ["REWARDED_STUDY_ID"]

@app.post("/hooks/deutero")
def deutero_hook():
    try:
        # raw bytes: a re-serialised body will not match the signature
        event = wh.verify(request.get_data(), dict(request.headers))
    except WebhookVerificationError:
        abort(400)

    if event.get("type") != "interview.completed":
        return jsonify(ok=True)                       # not ours; ack and move on

    data = event.get("data") or {}
    if not data.get("completed") or data.get("survey_id") != STUDY_ID:
        return jsonify(ok=True)

    tag = data.get("external_participant_id")
    if not tag:
        # someone reached the study without a tagged link — real, and not a
        # reason to guess at who they were
        app.logger.info("completion with no participant tag: %s", data.get("interview_id"))
        return jsonify(ok=True)

    user = users.find_by_participant_tag(tag)
    if user is None:
        app.logger.warning("unknown participant tag %s", tag)
        return jsonify(ok=True)

    claim_reward(user, data, msg_id=request.headers["webhook-id"])
    return jsonify(ok=True)                           # fast; the work is queued
```

Every branch that decides not to pay still returns 2xx. A non-2xx tells Deutero the delivery failed, and since there are no retries it buys nothing but a misleading entry in `list_webhook_deliveries`.

## 5. Issuing exactly once

```python
def claim_reward(user, data, msg_id: str) -> None:
    try:
        with db.begin():
            db.execute(
                "insert into reward_grants (user_id, study_id, interview_id, webhook_msg_id) "
                "values (%s, %s, %s, %s)",
                (user.id, data["survey_id"], data["interview_id"], msg_id),
            )
    except UniqueViolation:
        # already claimed — a redelivery, or this person's second interview
        return
    queue.enqueue(issue_voucher, user.id, data["survey_id"])
```

The insert is the claim. Whichever caller wins it owns the payout; everyone else returns quietly.

**Queue only what needs queueing.** `issue_voucher` is off-request here because it calls a third party that can hang or fail, and the queue is the right place for those retries — your voucher provider is the flaky part, not Deutero. When the reward *is* a local write (credits added, a flag flipped, a ledger row), the insert above is the whole payout: do it inline in the handler, well inside the 10-second timeout, and do not add a queue for it. A lost job is an unpaid person, which is a worse failure than the one the queue was protecting you from.

Rows left `pending` or `failed` are the ones to alert on. They are also the answer when a participant writes in.

## 6. The reconciliation job

Deutero attempts each delivery once, so a sweep — nightly while a study is open, and on demand when someone says they were not paid — is the only thing standing between a missed delivery and an unpaid participant.

**Your server cannot call MCP.** MCP tools are an agent-time surface; a nightly job or a request handler needs the REST API the same tools are generated from. It is the same routes under `https://dashboard.deutero.ai/study-api/api/v1/`, authenticated with an API key in the `X-API-Key` header (`DEUTERO_API_KEY` in your secret manager — created in the dashboard, see `deutero-setup`). The MCP tool name is the route *function's* name, not its path, so the paths are worth having written down:

| Tool | Route |
|---|---|
| `list_interviews` | `GET /studies/{study_id}/interviews` |
| `find_interviews_by_external_id` | `GET /studies/{study_id}/interviews/by-external-id?external_participant_id=…` |
| `get_interview` | `GET /interviews/{interview_id}` |
| `list_webhook_deliveries` | `GET /webhooks/{webhook_id}/deliveries` |

```bash
curl -sS -H "X-API-Key: $DEUTERO_API_KEY" \
  "https://dashboard.deutero.ai/study-api/api/v1/studies/$STUDY_ID/interviews/by-external-id?external_participant_id=$TAG"
```

```python
import os, requests

API = "https://dashboard.deutero.ai/study-api/api/v1"
SESSION = requests.Session()
SESSION.headers["X-API-Key"] = os.environ["DEUTERO_API_KEY"]

def completed_interviews(study_id: str, tag: str | None = None) -> list[dict]:
    params = {"completed": True, "limit": 500}
    if tag:
        params["external_participant_id"] = tag
    # `simulated` defaults to false — real interviews only. Persona runs are
    # the one thing a sweep could pay that the webhook never would, so leave
    # this default alone rather than passing `simulated=null` for "both".
    r = SESSION.get(f"{API}/studies/{study_id}/interviews", params=params, timeout=15)
    r.raise_for_status()
    return r.json()["interviews"]
```

Note the parameter is spelled differently across surfaces: `list_interviews` takes `simulated` (`false` by default — real only), while `find_interviews_by_external_id`, `bulk_transcripts` and `search_transcripts` take `include_simulated` (`false` by default). Both defaults are safe, and an unrecognised query parameter is ignored rather than rejected — so the wrong spelling leaves the default in place instead of widening the sweep. The only way to pay a persona is to ask for one explicitly.

```python
def reconcile(study_id: str) -> None:
    # everyone who completed, in Deutero's view
    for row in completed_interviews(study_id):
        tag = row.get("external_participant_id")
        if not tag:
            continue
        user = users.find_by_participant_tag(tag)
        if user and not grants.exists(user.id, study_id):
            claim_reward(user, {"survey_id": study_id, "interview_id": row["id"],
                                "completed": True},
                         msg_id=f"reconcile:{row['id']}")
```

For one person rather than the whole study, use `find_interviews_by_external_id {"study_id": "…", "external_participant_id": "<tag>"}` from an agent, or the `by-external-id` route above from your server. It returns **every attempt** that tag made, newest first, with `completed` on each — so "they say they finished" is settled in one call. Someone who abandoned and started again has several rows and is still owed one reward; the `(user_id, study_id)` constraint is what makes that true without extra logic.

`list_webhook_deliveries {"webhook_id": "…", "success": false}` tells you whether the gap was a delivery Deutero attempted and your server refused, or an event that never fired at all.

## 7. Testing it before recruiting

Simulations will not exercise this — persona runs fire `simulation.completed`, never `interview.completed`. Test it as a participant instead:

1. Point the endpoint at a tunnel to your development machine, or subscribe a second endpoint to the same event.
2. Open your own study link with a tag you control: `…/chat?s=<slug>&participant_id=<test tag>`.
3. Complete the interview. It costs the study's ordinary credits.
4. Check the grant row, then **replay the same delivery** (or just run a second interview on the same tag) and confirm nothing is paid twice.
5. Check `list_webhook_deliveries` shows the 2xx.

Step 4 is the one worth not skipping. Duplicate payouts are the failure mode that shows up only in production, and only on the busiest day.

## 8. Partial completions and screen-outs

Neither produces `interview.completed`, so both need a decision made in advance rather than discovered afterwards:

- **Abandoned interviews.** There is a `started` with no `completed`. If the policy is to pay for a genuine attempt, subscribe to `interview.started`, record the attempt, and settle from `list_interviews` after a cutoff — do not pay on the `started` event itself, or you are paying people for opening a link.
- **Screen-outs.** They never reach an interview, so the screening `redirect_url` (with `{{external_participant_id}}` in it) is the only signal Deutero gives you. Panels that pay for screen-outs rely on exactly this. Treat it as "this person bounced", not as proof of anything, and cap what a screen-out can be worth accordingly.

Whatever the policy, put it in the welcome text before anyone starts.

## 9. Choosing who to invite

Tagging and paying are the mechanics; who gets asked decides whether the study was worth running. When the participants are the user's *own* users — the usual case for a rewarded in-product study — four decisions are generic enough to make in advance, and each one is a way to waste the study or annoy a customer.

**Wait before asking.** Someone who signed up an hour ago has no experience to report. A delay per channel, counted from signup or from the behaviour you are asking about, keeps the question answerable — three days to the in-app prompt and a week to the email is a reasonable starting shape.

**Exclude by the behaviour the study is about, and read it off the right table.** A study about why people do not convert, mailed to people who converted, is worse than no study. The trap is where "has paid" is read from: free grants, promotional credits and *the research reward itself* are usually rows in the same table as real purchases, often with `amount = 0`. Exclude on the payment record (a non-zero charge, a subscription row), never on the presence of a credit grant — or the first reward you issue quietly disqualifies that person from every later study, and free-trial users look like customers.

**One ask per person per study, recorded before the ask is delivered.** An invite log keyed `(user_id, study_id)`, written first and upserted (`coalesce(existing_sent_at, now())`), is what stops two tabs, two workers or a retried job double-asking. Recording after delivery loses the race; recording the *intent* first only risks a person not being asked, which is the cheaper mistake.

**Order the channels.** If both an in-app prompt and an email exist, hold the email while a prompt shown minutes ago is still a live offer, and cancel it outright once the interview starts. Two asks for one study reads as spam, and the person who already started is the one most likely to be annoyed by it.

All four are your bookkeeping, not Deutero's — nothing in the study knows who you invited. The link's `&source=` tag is how you find out afterwards which channel actually worked (`web_source` on every interview), which is the input to doing it better next time.
