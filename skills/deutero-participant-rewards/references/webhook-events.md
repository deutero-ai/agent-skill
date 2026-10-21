# Deutero webhooks

Contents:
1. What a delivery looks like
2. The events
3. Verifying a delivery
4. Delivery semantics
5. Managing endpoints over MCP
6. Signals inside an interview (a different thing)
7. Troubleshooting

---

## 1. What a delivery looks like

Every event is an HTTP POST of JSON to your URL, in one envelope whatever the event:

```json
{
  "type": "interview.completed",
  "timestamp": "2026-09-20T14:30:00+00:00",
  "data": { }
}
```

with three headers:

| Header | Use |
|---|---|
| `webhook-signature` | Standard Webhooks signature over the raw body — the only proof the event came from Deutero |
| `webhook-id` | Unique message ID; the key to deduplicate on |
| `webhook-timestamp` | Unix seconds, checked as part of verification to bound replay |

Endpoints belong to the **organization**, not to a study, so one endpoint hears about every study the organization runs. Branch on `data.survey_id` rather than creating an endpoint per study.

## 2. The events

`list_webhook_event_types {}` returns this catalogue live, with the `data_fields` each event carries. Call it rather than trusting a list in a document — an unknown event name is refused by `create_webhook` with a 400, so a stale name fails loudly at subscription time instead of silently at delivery time.

| Event | Fires when | `data` |
|---|---|---|
| `interview.completed` | A participant finished an interview | `interview_id`, `survey_id`, `completed`, `participant_id`, `external_participant_id`, `web_source`, `test_run` |
| `interview.started` | An interview began, before anything is answered | `interview_id`, `survey_id`, `participant_id`, `external_participant_id`, `web_source`, `test_run` |

`test_run: true` marks the researcher's own test through the dashboard's **Try Interview** / **Preview** dialog. It is not a participant, so a reward handler skips it: nobody is owed anything. It is also the event to watch while wiring the handler up, since a test run delivers the same payload as a real completion.
| `analysis.completed` | Thematic analysis finished for an interview | `interview_id`, `survey_id` |
| `simulation.completed` | A persona simulation run finished | `interview_id`, `survey_id` |
| `study.created` | A study was created | `study_id`, `survey_id`, `name`, `project_id`, `created_via` |
| `credits.exhausted` | The organization's credit balance hit zero | `organization_id` |
| `study.full` | A study reached its `max_responses` quota | `survey_id`, `survey_name` |

Notes that matter when you act on these:

- **Two identities on the interview events.** `participant_id` is Deutero's UUID for the person — the one every other MCP call takes. `external_participant_id` is yours, from the entry link's `?participant_id=` or the embed metadata bag's `participant_id` key. Both are null when the interview arrived untagged.
- **`interview.started` is an arrival, not a promise.** An abandoned interview has a `started` with no `completed` after it. Use it to mark an attempt in progress, never to pay.
- **Simulations never fire `interview.completed`.** A persona run fires `simulation.completed`, which carries no external participant ID because nobody arrived on a link.
- **`created_via`** on `study.created` is `dashboard`, `import` or `api` — and `api` covers every MCP client, which is how an agent's own study creations are distinguishable from a person's.
- **An empty `events` list subscribes to everything.** Fine for a receiver that ignores what it does not recognise; a liability for one that assumes everything it receives is a completion.

## 3. Verifying a delivery

Verify over the **raw request body**, before any JSON parsing or framework re-serialisation — a body that has been round-tripped through a JSON decoder will not match the signature.

In Python, the `deutero` SDK's `webhooks.unwrap` verifies and parses in one call, and returns typed events (`InterviewCompletedEvent`, `StudyFullEvent`, …; anything else, including flow signals, as a plain `WebhookEvent`):

```python
from deutero import webhooks

# WEBHOOK_SECRET = os.environ["DEUTERO_WEBHOOK_SECRET"]
try:
    event = webhooks.unwrap(request.get_data(), request.headers,
                            secret=WEBHOOK_SECRET)
except webhooks.WebhookVerificationError:
    abort(400)
# event.type, event.data.external_participant_id, event.webhook_id (dedupe key)
```

It needs no API key. `webhooks.sign(body, secret=…, msg_id=…)` produces valid headers for testing a receiver locally, and `tolerance=None` turns off the 5-minute bound when replaying stored deliveries. `deutero-setup/references/python-sdk.md` §5 has the rest. The generic `standardwebhooks` library works equally well and returns a dict:

```python
from flask import Flask, request, abort
from standardwebhooks import Webhook, WebhookVerificationError

# WEBHOOK_SECRET = os.environ["DEUTERO_WEBHOOK_SECRET"]   # the whsec_… from create_webhook
app = Flask(__name__)
wh = Webhook(WEBHOOK_SECRET)

@app.post("/hooks/deutero")
def deutero_hook():
    try:
        event = wh.verify(request.get_data(), dict(request.headers))
    except WebhookVerificationError:
        abort(400)
    ...
```

The library takes the secret exactly as `create_webhook` returned it, `whsec_` prefix and all, and raises rather than returning false on a bad signature, a missing header or a stale timestamp. In Node the equivalent is the `standardwebhooks` package:

```js
import { Webhook } from "standardwebhooks";
const wh = new Webhook(process.env.DEUTERO_WEBHOOK_SECRET);
// express: mount express.raw({ type: "application/json" }) on this route only
const event = wh.verify(req.body, {
  "webhook-id": req.header("webhook-id"),
  "webhook-timestamp": req.header("webhook-timestamp"),
  "webhook-signature": req.header("webhook-signature"),
});
```

### If you are not using the library

Thirty lines of stdlib beats a dependency in some codebases. The scheme is Standard Webhooks, and these are the details that decide whether your verifier works:

- **The signed string is `f"{webhook_id}.{webhook_timestamp}.{raw_body}"`** — the header values verbatim, the body as received, no re-serialisation.
- **The key is the secret with `whsec_` stripped, then base64-decoded.** Deutero's secrets are unpadded base64; append `==` before decoding (`b64decode` ignores surplus padding, so this is safe for padded ones too).
- **`webhook-signature` is a space-separated list** of `v1,<base64 signature>` entries, not a single value. Check each `v1` entry and accept on the first match — that list is what makes secret rotation gapless, so comparing the header as a whole both fails today and breaks rotation later.
- **Bound the timestamp yourself.** ±5 minutes is what the library allows. Parse it as `float` before `int`.
- Compare with `hmac.compare_digest`, on bytes.

```python
import base64, hashlib, hmac, time

def verify(raw_body: bytes, headers, secret: str) -> bool:
    msg_id = headers["webhook-id"]
    ts = headers["webhook-timestamp"]
    if abs(time.time() - float(ts)) > 300:
        return False
    key = base64.b64decode(secret.removeprefix("whsec_") + "==")
    expected = hmac.new(
        key, f"{msg_id}.{int(float(ts))}.".encode() + raw_body, hashlib.sha256
    ).digest()
    for part in headers["webhook-signature"].split(" "):
        version, _, sig = part.partition(",")
        if version == "v1" and hmac.compare_digest(expected, base64.b64decode(sig)):
            return True
    return False
```

Verifying is not deduplicating: `webhook-id` still has to be checked against what you have already processed, or replayed inside the 5-minute window.

**The signature is the only authentication.** Everything inside `data` that came off a participant link — `external_participant_id`, `web_source` — is text a participant could have chosen. Verified means "Deutero sent this", not "this person is who the ID says".

## 4. Delivery semantics

- **One attempt.** Failed deliveries are logged, not retried. Anything that must not be missed needs a reconciliation path (`find_interviews_by_external_id`, `list_interviews`).
- **10-second timeout.** Return 2xx first. A local write fits comfortably inline; anything that calls a third party belongs off the request.
- **Success is any status below 300.** A 302 to a login page counts as failure; an endpoint behind SSO will silently never work.
- **Deliveries are logged per endpoint** and readable with `list_webhook_deliveries` — event type, message ID, status code, success, error.
- **Order is not guaranteed** and neither is exactly-once. Dedupe on `webhook-id`.

## 5. Managing endpoints over MCP

```
list_webhook_event_types {}
create_webhook           {"label": "Study rewards", "url": "https://you.example/hooks/deutero",
                          "events": ["interview.completed"]}
list_webhooks            {}
update_webhook           {"webhook_id": "…", "events": ["interview.completed", "study.full"],
                          "enabled": true}
rotate_webhook_secret    {"webhook_id": "…"}
list_webhook_deliveries  {"webhook_id": "…", "success": false, "limit": 50}
delete_webhook           {"webhook_id": "…"}
```

- `create_webhook` returns `signing_secret` **once**. It is never readable again — not by `list_webhooks`, not by anything. Hand it to the user or store it immediately, and say plainly that it will not be shown twice.
- `rotate_webhook_secret` is the only recovery. The previous secret stops verifying the moment it is called, so deploy the new one to the receiver before the next event fires.
- `update_webhook` changes only the fields passed, and a new `events` list **replaces** the old one rather than adding to it. `enabled: false` pauses deliveries without losing the endpoint or its secret — the right move while a receiver is being repaired.
- The same endpoints are managed in **Settings → Webhooks** in the dashboard, and an endpoint made in either place is visible in both.

## 6. Signals inside an interview (a different thing)

An Interview Flow (the `deutero-interview-flow` skill) can also send a webhook **mid-interview**, from a "Send a signal" step placed at a point in the conversation. It is not a lifecycle event and does not come from the endpoints above:

- Configured on the step (`url`, `method`, `body`, `headers`, `signal_type`), not in Settings.
- Signed with a **per-step** secret, minted the first time the step is saved and stable across later saves. `get_flow_signals {"study_id": "…"}` lists every signal step with its URL and that secret — the only place it can be read.
- `get_interview_fetches_and_signals {"interview_id": "…"}` shows what one interview actually sent and whether the receiver accepted it.
- Interview Flow is a Pro-and-above feature, so this route is unavailable on Hobby and Solo.

Use a signal when something must happen *during* the interview (provision a trial, fetch an order, alert a human). Use `interview.completed` when something must happen *because it finished* — a reward almost always belongs in the second category, since a signal fires whether or not the participant goes on to complete. A study that only needs the second never needs an Interview Flow.

## 7. Troubleshooting

- **Nothing arrives.** Check `list_webhook_deliveries`: rows with failures mean Deutero tried and your server refused; no rows at all means nothing fired — confirm the endpoint is `enabled` and its `events` list includes the event (or is empty).
- **Signature always fails.** You are verifying a re-serialised body. Capture the raw bytes. Second most common: the wrong secret after a rotation.
- **Deliveries stop after a deploy.** A redirect to an auth page returns 3xx; Deutero counts that as a failure and there is no retry.
- **Events arrive twice.** Expected. Dedupe on `webhook-id`.
- **`external_participant_id` is null.** The interview arrived on an untagged link, or an embedded study whose metadata bag had no `participant_id` key.
