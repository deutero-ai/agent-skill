# Recruitment, screening and embedding

Contents:
1. Screening
2. Participant characteristics
3. The share link
4. Tagging arrivals, and acting on a finished interview
5. The embed widget — running the interview inside the user's own product
6. Invitation copy: email and in-app
7. Channels that are dashboard-only
8. Ethics

---

## 1. Screening

Screening questions are multiple choice, asked before the interview. `acceptable_options` lists **who qualifies** — anyone whose answer is not in that list is screened out. It must be a subset of `options`.

```
set_screening_settings    {"study_id": "…", "enabled": true,
                           "disqualification_message": "Thanks for your interest…",
                           "redirect_url": "https://app.prolific.com/submissions/complete?cc=…"}
create_screening_question {"study_id": "…",
                           "question": "Which service did you use most recently?",
                           "options": ["HelloFresh", "Blue Apron", "I have never used one"],
                           "acceptable_options": ["HelloFresh", "Blue Apron"]}
update_screening_question {"study_id": "…", "question_id": "…", "acceptable_options": ["HelloFresh"]}
reorder_screening_questions {"study_id": "…", "question_ids": ["…", "…"]}
get_screening             {"study_id": "…"}
```

Rules that earn their keep:

1. **Three to five questions.** Every extra one loses participants.
2. **Screen on behaviour, not intention.** "Have you cancelled in the last three months" beats "would you ever cancel".
3. **Avoid giveaway phrasing.** If the qualifying answer is obvious, it will be selected.
4. **Keep options short and distinct.** An answer the interviewer cannot match to an option is re-asked once; a second unmatched answer ends the session as disqualified.
5. **Set a redirect** when using a paid panel, so screen-outs are returned correctly and still get paid for their time.

Participants also get an automatic "Prefer not to answer" on every screening question.

> **Known issue (September 2026).** Participants are shown a generic disqualification message; the custom `disqualification_message` is not used. The API's `acceptable_options` is unaffected by the dashboard's "does not equal" logic bug, so `update_screening_question` is the reliable way to repair a question saved with the wrong rule.

## 2. Participant characteristics

`get_characteristics`, `set_characteristics_settings`, `create_characteristic_question` and friends profile the sample without gating it — demographics and segment questions you want alongside the transcript. Useful for a panel study you will later cut by segment. Pointless at n=1, and every question costs completion rate, so ask only what you will actually analyse.

### Contact details

To follow up with participants — a second round, a diary study, a reward you send yourself — turn on the contact step in the same call:

```
set_characteristics_settings {"study_id": "…",
  "contact": {"collect_email": true, "collect_phone": false,
              "timing": "end", "required": false, "message": ""}}
```

Participants get a separate form (email and/or phone, plus a name unless `anonymous` is true) at the `start` (before question 1) or the `end` (before the thank-you). It is optional unless `required` is true; an empty `message` uses the default, in the interview's language. What they give is stored apart from the transcript, so analysis stays anonymous; read it back with `list_study_contacts` / `get_interview_contact` (`reading-results.md`, "Contact details") or on the interview's page in the dashboard. `get_study` reports the current settings as `contact`. Only the fields you send change: omit `contact`, `enabled` or `anonymous` to leave it as it is. It is locked while the study is open.

Ask only when you will use it: a contact form, especially a required one at the start, costs completion rate. To join interviews to people you already know, pass your own id on the link (`?participant_id=`) instead — see `deutero-participant-rewards`.

## 3. The share link

```
get_recruitment    {"study_id": "…"}
update_recruitment {"study_id": "…", "short_url_slug": "mealkit-churn",
                    "max_responses": 50, "redirect_url": "https://example.com/thanks"}
```

`get_recruitment` returns the participation links, quota status and whether screening and characteristics gates are on. `update_recruitment` changes only the fields you pass; `clear_max_responses: true` removes a quota. It stays usable while the study is open.

**The links admit people only while the study is open.** Set everything up on a draft, then `publish_study` before sharing (`publishing.md`). A link shared early turns people away with "not accepting responses". The links themselves never change when the study is published, paused or resumed, so it's safe to put them in an email or embed ahead of time.

- Text: `https://app.deutero.ai/chat?s=<slug>` — slugs are unique across all of Deutero, so a taken one is refused.
- Direct form, useful for testing: `https://app.deutero.ai/chat?survey_id=<study id>`.
- Voice: use `https://app.deutero.ai/voice?survey_id=<study id>` (the slug form is currently broken). Voice needs a paid plan; video and WhatsApp need Pro or Team. Hobby is text chat only, so share the text link and nothing else.

Test both paths before recruiting: one run that qualifies, one that does not.

## 4. Tagging arrivals, and acting on a finished interview

Every participant link takes two optional parameters, appended by whoever builds the link:

- `&source=<campaign tag>` — your own label for where the link was posted (`newsletter`, `reddit`, `panel-b`). Stored on the interview as `web_source`.
- `&participant_id=<your id for this person>` — stored as `external_participant_id`, so an interview can be joined back to the person you invited. Note the parameter is spelled `participant_id`; it is **not** the Deutero `participant_id` UUID of the same name.

```
https://app.deutero.ai/chat?s=mealkit-churn&source=email&participant_id=6f2c…
```

Neither needs an Interview Flow: they work on every study, linear or not, and are stored on the interview whatever the study runs.

Both are visible and editable by whoever holds the link, so they label a row and prove nothing about who answered. Keep the ID pseudonymous — a hash of your own user ID, a panel token, a row key, never an email address or a name. An embedded study sets the same ID through the metadata bag's `participant_id` key instead.

Reading them back: every interview, transcript and search hit carries `external_participant_id` and `web_source`, `list_interviews` / `bulk_transcripts` / `search_transcripts` filter on the ID, and `find_interviews_by_external_id {"study_id": "…", "external_participant_id": "…"}` answers "did this person finish?" directly.

The redirect URL can hand the ID back to your own site:

```
update_recruitment {"study_id": "…",
                    "redirect_url": "https://you.example/thanks?pid={{external_participant_id}}"}
```

`{{external_participant_id}}` is the only placeholder either redirect understands (the screening one takes it too), and it expands to nothing for an interview that arrived untagged. A single-braced `{external_participant_id}` is corrected for you and reported back in `redirect_url_warning`; any other `{{…}}` is stored as sent and named in the same warning, because it will never substitute.

To make finishing *do* something — issue a reward, credit an account, mark a panel task complete — subscribe to the `interview.completed` webhook, which carries `external_participant_id` next to the interview ID and is signed:

```
create_webhook {"label": "Study rewards", "url": "https://you.example/hooks/deutero",
                "events": ["interview.completed"]}
```

Act on the signed event, never on the redirect: a redirect is a URL the participant can replay. The `deutero-participant-rewards` skill covers the whole round trip — choosing an ID that cannot be guessed, the receiver, paying exactly once, and reconciling what a missed delivery lost.

## 5. The embed widget

The widget runs the interview inside the user's own site or app, so people are interviewed in the moment and in context rather than after a context switch to a Deutero link. For product research this is usually the difference between a 3% response rate and a useful one.

```
create_embed_key  {"allowed_origins": ["https://acme.com"], "study_id": "…", "metadata_max_bytes": 8192}
list_embed_keys   {}
update_embed_key  {"key_id": "…", "status": "revoked"}
get_embed_snippet {"study_id": "…", "publishable_key": "dtro_pk_…", "mode": "chat"}
```

`create_embed_key` returns two values **once**: a publishable key `dtro_pk_…` for the browser and a signing secret `dtro_sk_…` for the server. The wildcard `*` is not an allowed origin. Store the signing secret server-side only — anyone holding it can forge verified metadata for the organization's studies.

```html
<script async src="https://app.deutero.ai/widget/v1/deutero-widget.js"
        data-publishable-key="dtro_pk_…"
        data-survey-id="<study uuid>"
        data-mode="chat"
        data-title="Quick question?"
        data-position="bottom-right"
        data-metadata='{"plan":"pro"}'></script>
```

Every option is a `data-` attribute on that script tag: `data-mode` (`chat` or `voice`), `data-title` (the panel label, default "Interview"), `data-position` (`bottom-right`, the default, or `bottom-left`), `data-open-on-load="true"`, `data-signed-token` in place of `data-publishable-key`, `data-metadata` as a JSON object — invalid JSON is logged to the console and ignored rather than failing loudly — `data-language` (run the interview in another language: a name, native name or code such as `es`), `data-language-picker="false"` (hide the welcome's language picker), and `data-study-theme="false"` (keep the widget's own look instead of the study's brand theme). `data-api-base-url` overrides the origin the script was served from, which is only needed against a non-production instance.

For anything the attributes do not cover, skip auto-init (omit the key and the token) and call `DeuteroInterview.init({...})` yourself. Two options exist only there: `container`, which mounts the interview **inline** into an element of yours instead of the floating launcher (and opens immediately), and `theme`, a map of CSS custom properties laid over the study's theme. (`useStudyTheme: false` is the `init` form of `data-study-theme="false"`.) The instance it returns has `open()`, `close()`, `toggle()`, `destroy()`, `sendMessage()` and `on(event, handler)` — the events are `ready`, `open`, `close`, `start`, `question`, `message`, `complete`, `error`.

**Styling and placement.** The widget mounts into a shadow root on a host `<div>` appended to `<body>`, and that host carries a `data-deutero-widget` attribute — so `document.querySelector('[data-deutero-widget]')` is the handle for it, both when debugging and when you need to move it. Nodes *inside* the shadow root are genuinely out of reach of page selectors.

- **Colour and type come from the study's brand theme** (`set_theme`, `branding.md`) by default: the widget fetches it as soon as it knows the study (at mount with `data-survey-id`, otherwise once the interview starts) and applies the theme's light and dark colours, fonts, weights, corner style and default mode (else it follows the visitor's device), adding the theme's Google Fonts stylesheet to the page's `<head>`. Custom CSS and the start-screen copy are not applied to the widget. To change the study's theme for every embed, change it with `set_theme`, not per site.
- **A site can still override it.** `init({theme: {accent: "#7c3aed"}})`, or the site's own CSS setting `--dtro-*` properties on `[data-deutero-widget]`, wins over the study's theme — a bare key is prefixed `--dtro-`, and a key already starting `--` is passed through. The properties: `--dtro-accent`, `--dtro-accent-contrast`, `--dtro-bg`, `--dtro-fg`, `--dtro-muted`, `--dtro-border`, `--dtro-bubble-interviewer`, `--dtro-bubble-interviewer-fg`, `--dtro-bubble-participant`, `--dtro-bubble-participant-fg`, `--dtro-font`, `--dtro-font-display`, `--dtro-font-weight`, `--dtro-heading-weight`, `--dtro-radius`, `--dtro-radius-bubble`, `--dtro-radius-pill`, and `--dtro-z` for stacking. An override skips the readability check the theme passed, so keep text readable on whatever background you set. With no theme and no override, the launcher is Deutero purple.
- **A strict site CSP** that doesn't allow `fonts.googleapis.com` / `fonts.gstatic.com` costs only the brand fonts (the widget falls back to system fonts). Opt out with `data-study-theme="false"` to avoid the request entirely.
- **Position is fixed at `bottom: 20px`** with `right`/`left: 20px`, and there is no offset option. On a site with its own sticky footer or cookie bar the launcher lands on top of it; the fix is to raise the host yourself (`querySelector('[data-deutero-widget]').style.bottom = …`, recomputed when your own bar changes height).
- **Overriding the widget's own rules needs doubled specificity** — `.dtro-root.dtro-root { … }` rather than `.dtro-root { … }`. Its stylesheet arrives as `adoptedStyleSheets`, which cascades *after* a `<style>` element you append into the same shadow root at equal specificity, so the obvious version silently loses.

**Where to place it.** Put the trigger where the behaviour you are asking about actually happens, and fire it after the moment rather than during it: after a failed search, on the settings page a segment keeps returning to, at the end of an onboarding step, on the cancellation confirmation. Interrupting someone mid-task to ask about the task both annoys them and changes the answer.

**Untrusted vs verified metadata.** Anything in `data-metadata` comes from the page and a visitor can edit it in dev tools. That is fine for context you only want to read next to the transcript. It is not fine when the interview acts on the value — asking enterprise-only questions, skipping a section for trial users, splitting results by plan. For those, the server mints a short-lived JWT signed with the key's signing secret and the page passes it as `data-signed-token` instead of `data-publishable-key`. Verified values override page-supplied values of the same name.

| Field | Where | Value |
|---|---|---|
| `alg` | header | `HS256` only |
| `typ` | header | `JWT` — conventional; not enforced, so its absence is never the cause of a rejection |
| `kid` | header | the publishable key — this is how Deutero finds the signing secret |
| `sub` | claim | your own stable id for the end user; links repeat interviews |
| `iat` | claim | issued-at, Unix seconds (60s skew tolerated) |
| `exp` | claim | at most 900s after `iat`, enforced — a longer-lived token is refused outright; 5–10 minutes is a good default |
| `metadata` | claim | flat object of verified values |

Sign the metadata whenever the *analysis* leans on it, not only when money does: a logged-out embed that signs `{page_type, city, entry}` and carries no participant ID at all is a perfectly ordinary use of the mechanism, and means results can be cut by values the page could not have forged.

One metadata key has a meaning of its own: **`participant_id`**. Whatever it holds is also stored on the interview as `external_participant_id` — the same field a link's `?participant_id=` sets — which is how an embedded study is joined back to your own users. It stays in the metadata bag as well. When something is paid or unlocked on completion, put it in the **signed** metadata rather than `data-metadata`, since page-supplied values are editable by the visitor.

Metadata limits: at most 32 keys; names matching `^[A-Za-z_][A-Za-z0-9_]{0,63}$`; scalar values only (string ≤ 1 KB, number, bool, null) — no nested objects or arrays; total within the key's byte limit. Anything outside is rejected outright, so validate before signing.

```python
import time, jwt  # PyJWT

# EMBED_SIGNING_SECRET = os.environ["DEUTERO_EMBED_SIGNING_SECRET"]
# EMBED_PUBLISHABLE_KEY = os.environ["DEUTERO_EMBED_PUBLISHABLE_KEY"]   # the kid

def mint_embed_token(user) -> str:
    now = int(time.time())
    return jwt.encode(
        {"sub": str(user.id), "iat": now, "exp": now + 600,
         "metadata": {"plan": user.plan, "seats": user.seat_count}},
        EMBED_SIGNING_SECRET,
        algorithm="HS256",
        headers={"kid": EMBED_PUBLISHABLE_KEY},
    )
```

The same in TypeScript with `jose`:

```ts
import { SignJWT } from "jose";

const secret = new TextEncoder().encode(process.env.DEUTERO_EMBED_SIGNING_SECRET!);

export async function mintEmbedToken(user: AppUser): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({ metadata: { plan: user.plan, seats: user.seatCount } })
    .setProtectedHeader({ alg: "HS256", typ: "JWT", kid: process.env.DEUTERO_EMBED_PUBLISHABLE_KEY! })
    .setSubject(user.id)
    .setIssuedAt(now)
    .setExpirationTime(now + 600)
    .sign(secret);
}
```

**Getting the token onto the page.** A server-rendered page writes it straight into the tag, in place of the publishable key; the rest of the tag is unchanged, and `data-metadata` may sit alongside for values that need no verification (a name in both takes the signed value). `get_embed_snippet` returns this variant too.

```html
<script async src="https://app.deutero.ai/widget/v1/deutero-widget.js"
        data-signed-token="<token minted for this request>"
        data-survey-id="<study uuid>"
        data-mode="chat"></script>
```

A single-page app, or a widget opened on click, has no server render to write into. Add an authenticated endpoint of your own that returns a fresh token, fetch it first, and set the attribute **before** appending the script, because the widget reads the tag's attributes when the script loads:

```js
const { token } = await fetch("/embed/interview-token", { credentials: "include" }).then((r) => r.json());
const s = document.createElement("script");
s.async = true;
s.src = "https://app.deutero.ai/widget/v1/deutero-widget.js";
s.dataset.signedToken = token;   // instead of dataset.publishableKey
s.dataset.surveyId = "<study uuid>";
s.dataset.mode = "chat";
document.body.appendChild(s);
```

Mint one token per page load; never cache it in a cookie or reuse it across users. The signing secret never goes to the browser, so never mint in client code, not even "temporarily".

**When a signed bootstrap is rejected**, it is one of these, roughly in order of frequency:

- **Expired or too long-lived**: `exp` more than 900s after `iat`, or the page was loaded after `exp` (a cached HTML page carrying an old token is the usual cause; don't let a CDN cache pages with a token in them).
- **Bad signature or missing `kid`**: signed with a different key's secret, or no `kid` header. The secret is shown only once, at creation. If it is lost there is no way to read it back: `create_embed_key` again, switch the server to the new pair, then `update_embed_key {"status": "revoked"}` on the old one.
- **Wrong origin**: the page's origin must exactly match one of the key's `allowed_origins` (scheme, host and port; `https://www.acme.com` is not `https://acme.com`).
- **Wrong study**: a study-scoped key rejects a bootstrap naming any other study.
- **Revoked key**: takes effect on the next bootstrap; interviews already collected keep their recorded provenance.
- **Metadata out of limits** (above): rejected outright, not truncated.

The user-facing version of all of this, for a developer who isn't working through an agent, is the dashboard's **Signed Metadata** help article (`/help/doc/embed-signed-metadata`).

Metadata shows up with the interview afterwards, page-supplied and verified values distinguished, and `get_interview` returns it with its provenance — which is what lets you cut results by segment honestly.

Collecting metadata and reading it back needs no Interview Flow, on any study. A flow comes in only when the interview itself must route on a value, such as a section only trial users see.

## 6. Invitation copy

Whatever the channel, the copy does the recruiting. Four things decide whether someone starts:

- **Who is asking and why them.** "You cancelled Pro in March" outperforms "we're doing some research" by a wide margin, because it tells the person their answer is not interchangeable with anyone else's.
- **What it costs them.** Real minutes, stated honestly, and the fact that it is a chat they can pause and come back to rather than a scheduled call. Pausing is a genuine advantage over a call and most people do not know it is possible.
- **What happens to the answers.** One clause. Anonymity if it applies.
- **One link, no preamble.**

Keep it under 120 words, skip the enthusiasm, and never describe the study as something other than what it is.

```
Subject: 10 minutes on why you stopped using [product]?

Hi [name] — you cancelled [product] in March, and we'd like to understand what
happened rather than guess.

It's a text conversation with an AI interviewer, about 10 minutes, and you can
stop and pick it up later. Answers are used to decide what we fix next; we
report them without names.

[link]

If you'd rather not, no follow-up — this is the only email.

[researcher name], [team]
```

For an in-app invitation the same content compresses to a sentence and a button, and the targeting does the work the first paragraph did in email. Send from a person, not a no-reply address, and give people a way to reach the researcher — contact details come from the researcher profile.

## 7. Dashboard-only channels

Not reachable over MCP; tell the user where to go rather than searching for a tool.

- **Prolific** — paid panel recruitment with payment handled through Deutero, including a recommended rate.
- **Slack and Discord connectors** — post recruitment messages into channels on a schedule and run interviews there.
- **Recruitment flyer and QR code** — printable, generated from the participant link.
- **Snowball sampling** — invites finishing participants to pass the study on.
- **Suggest recruitment strategy** — drafts a strategy, a social post and an email template from the study details.

## 8. Ethics

- Say who is running the study and what participation involves, before anyone starts.
- Do not describe the study as something other than what it is, and do not disguise a sales or marketing contact as research.
- Follow the institution's IRB or ethics process where one applies.
- Pay fairly when you pay at all.
- Give people a way to reach a human.
- Where answers will change a product, a policy, or an agent's behaviour, say so and set `consent: true` on the welcome message.
