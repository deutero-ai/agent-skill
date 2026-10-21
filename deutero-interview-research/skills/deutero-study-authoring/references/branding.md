# Branding the interview pages

Participants take a Deutero interview on hosted chat, voice and video pages. Those pages carry the organization's name and logo, and can also carry its look: colours for light and dark mode, fonts and weights, corner style, the mode the page opens in, and on Pro and Team, custom CSS. The start screen can carry its own title, button labels, footer and a hero image.

Two tools set the look and two set the hero image. The start screen's copy rides on `set_welcome`.

| Tool | Does |
|---|---|
| `get_theme` | The organization's theme, or one study's with `study_id`. |
| `set_theme` | Sets the theme and/or custom CSS for the organization, or for one study with `study_id`. |
| `set_welcome` | The welcome message, plus the optional start-screen copy (below). |
| `upload_welcome_hero` / `delete_welcome_hero` | The start screen's hero image (or a large logo). |

## Organization first, studies only when they differ

The organization's theme applies to every study. A study's theme is an **override**: send only the keys that differ, and they are laid over the organization's. Top-level keys replace. The `light` and `dark` colours merge key by key, so a study can change just `light.accent`.

Set the organization's theme once, and override a study only when it has a reason to look different (a co-branded campaign, a client's study run under your account). **Only an organization admin can set the organization's theme**; anyone else gets 403 and can still set a study's.

The theme is **not** locked while a study is open: appearance can change at any time. The welcome copy and hero image **are** locked like the rest of the welcome (`publishing.md`).

## The theme

Every key is optional. Unset keys keep Deutero's default.

```json
{"theme": {
  "light": {"accent": "#c2410c", "bg": "#fff8f0"},
  "dark":  {"accent": "#fb923c"},
  "font_body": "Source Sans 3", "body_weight": 400,
  "font_display": "Fraunces", "display_weight": 600,
  "radius": "soft",
  "default_mode": "light"}}
```

| Key | Values |
|---|---|
| `light`, `dark` | Colour maps, each value a hex `#rgb` or `#rrggbb`. Keys: `accent` (buttons, progress bar, links, the participant's bubble), `bg` (page), `surface` (cards, the interviewer's bubble), `fg` (text), `muted` (secondary text), `line` (borders), `bot` / `bot_fg` (interviewer caption bubble and its text), `user` / `user_fg` (participant bubble and its text). |
| `font_body`, `font_display` | A Google Fonts family name **exactly as Google lists it**: `"Source Sans 3"`, not `"Source Sans"` or `"source sans 3"`. |
| `body_weight`, `display_weight` | A weight the font comes in, from 100 to 1000 in steps of 100. Without a font set, the default font decides: Victor Mono (body) has 100–700, Changa (headings) 200–800. |
| `radius` | `rounded` (the default), `soft` or `square`. |
| `default_mode` | `system` (follow the participant's device), `light` or `dark`. A participant who toggles the mode keeps their own choice. |

**Light and dark are separate.** Light colours never carry over into dark mode, which keeps Deutero's dark defaults wherever the theme sets nothing. A brand accent set only under `light` leaves dark mode purple, so set a dark accent too. A slightly lighter version of the brand colour usually reads better on a dark page.

**The participant's bubble follows the accent** unless `user` is set. Its text (`user_fg`) defaults to white, so a pale accent needs a dark `user_fg`, or a darker `user`.

### Readability is enforced

A save is refused when text would be hard to read. Each of these pairs must reach 4.5:1 contrast (WCAG AA), in both modes: `fg` on `bg`, `fg` on `surface`, `user_fg` on `user`, and `bot_fg` on `bot`. Unset colours count as their defaults, and a study is judged laid over its organization. The consent screen depends on this.

A refusal is 422 with every problem listed, so fix them all in one pass:

```json
{"detail": {"code": "invalid_theme", "message": "The theme was not saved.",
  "problems": [
    "light.user_fg on light.user: contrast 3.68:1 is below the 4.5:1 participants need to read it (WCAG AA).",
    "display_weight: 'Changa' has no 900 weight; it has 200, 300, 400, 500, 600, 700, 800."]}}
```

Bright brand colours fail this more often than you'd expect: a mid-orange such as `#e4572e` with white text is only 3.7:1. Darken the accent (`#c2410c` passes), or keep the accent and set a dark `user_fg`. Don't quietly swap in a different colour. Tell the user the brand colour fails for text, and offer both fixes.

## How `set_theme` saves

- `theme` **replaces the whole stored theme** (for a study, its whole override). To change one key, `get_theme`, edit, and send it all back. `null` or `{}` clears it, and a study then follows the organization again.
- `custom_css` is independent: leave it out to keep it, and send `null` to remove it.
- The response is the saved state. `theme` is what's stored, `organization_theme` (for a study) is what it's laid over, `resolved_theme` is what participants see, and `fonts_href` is the Google Fonts stylesheet the pages load.

## Custom CSS (Pro and Team)

For the cases the theme can't express. Send a stylesheet as `custom_css` (at most 50 KB). Below Pro it is 403 `upgrade_required`; removing it is allowed on any plan. It is sanitised before it's stored, and the response's `css_stripped` lists everything removed, one line each with its line number. Read that list back to the user.

- Every selector is scoped to the interview page: `.bubble` becomes `.dtro-themed .bubble`, and `:root[data-theme="dark"] .bubble` keeps its dark-mode condition.
- Removed: `url()` and every other way of loading something (so no background images or custom font files), `@import`, `@font-face`, every at-rule except `@media`, `@supports` and `@keyframes`, and any rule that would hide the start screen's buttons (`display: none`, `visibility: hidden`, `opacity` below 0.5).
- A study's CSS applies after the organization's.
- After a downgrade, CSS is kept but switched off. `custom_css_active` says whether it is applied right now; `custom_css_available` says whether the plan includes it.

Target the stable hooks, which survive markup changes: `[data-part="brand"]`, `"start"`, `"welcome"`, `"bubble-bot"`, `"bubble-user"`, `"composer"`, `"chip"`, `"progress"` and `"done"`. Other class names can change without notice. Reach for CSS only after the theme: colours, fonts and corners belong in `theme`, where they are checked for readability.

## The start screen

`set_welcome` takes these alongside `message` and `consent`. A field you leave out keeps its value, and blank or `null` restores the default.

| Field | Max | Default |
|---|---|---|
| `title` | 200 | the study name |
| `time_estimate` | 100 | none; e.g. `"About 10 minutes"` |
| `footer` | 2000 | none; Markdown **links only**, e.g. `"[Privacy](https://acme.example/privacy)"` |
| `continue_label` | 60 | "Continue" (shown when consent is off) |
| `consent_yes_label` / `consent_no_label` | 60 | "Yes" / "No" |
| `hero_alt` | 300 | none; alt text for the hero image |

`message` is limited Markdown on the start screen: paragraphs, `**bold**`, `*italic*`, bullet and numbered lists, `###` headings and `https:` / `mailto:` links. Images and HTML are not rendered. `warnings` in the response lists anything that won't render, and the welcome is saved anyway, so fix it and save again. Slack, WhatsApp and the spoken greeting get `message` as plain text, and none of the other copy.

Button labels change only what the button says. The interview still records consent as consent, so `"Count me in"` / `"Not today"` is safe.

**Hero image:** `upload_welcome_hero` with `image_base64` (bare base64 or a `data:image/...;base64,` URL; JPEG, PNG or WebP up to 10 MB, stored downscaled to fit 1024×1024 as WebP) and `alt`. It replaces any previous hero. The welcome must exist first, or you get 400. `delete_welcome_hero` removes it. A large logo is just a hero image.

**Translations:** `upsert_welcome_translation` takes `fields`, a map of translated copy keyed by the field names above (`{"title": "…", "consent_yes_label": "…"}`). A field left out shows untranslated, and omitting `fields` keeps what the translation already has.

## Where it shows, and where it doesn't

- The hosted chat, voice and video pages, including the participation link, show the theme, start-screen copy and hero.
- **The embed widget is styled separately**, by the host page (`--dtro-accent` and friends; see `recruitment-and-embedding.md`). Set its colours to match the theme.
- The dashboard has the same controls with a live preview: **Account → Brand** for the organization, and **Appearance** in the study sidebar. Point the user there to see the result, since nothing over MCP renders it.

## Common mistakes

- **Inventing a palette.** Ask for the brand's hex colours, or read them off a site the user names, and say which colours you used. A guessed brand colour is worse than the default.
- **Sending one key and wiping the rest.** `theme` replaces; read with `get_theme` first.
- **Setting `light` only** and leaving dark mode on the default purple.
- **Near-miss font names.** `"Nunito San"` and `"open sans"` are refused. Use the family's exact Google Fonts name.
- **A weight the font doesn't have.** The refusal lists the weights it does have; pick one of those.
- **Theming per study by default.** Brand the organization once; overrides are for studies that should look different.
- **Hiding the consent buttons in CSS.** It's stripped, and an unreadable consent screen is an ethics problem anyway.
