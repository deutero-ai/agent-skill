# Deutero Agent Skills: AI user research, customer interviews and qualitative studies for AI agents

**Let your AI agent run real user research.** These agent skills, plus the Deutero MCP server, let Claude Code, Claude Desktop, Cursor, Windsurf, Codex and other MCP-capable agents **design, run and analyse AI-moderated interviews with real people**. That covers user interviews, customer discovery, product research, concept tests and feedback studies, with no human moderator in the loop.

[Deutero](https://deutero.ai) is an AI-conducted qualitative research platform. An AI interviewer talks to each participant one at a time over chat, voice or video. It asks your questions, probes the answers and stays on your research objectives. Your agent gets the transcripts, coded responses and thematic clusters back over MCP.

```bash
# Any agent (Claude Code, Cursor, Codex, Windsurf, Aider…) via openskills
npx openskills install deutero-ai/agent-skill

# Hermes Agent
hermes skills install deutero-ai/agent-skill/skills/deutero-setup

# Claude Code plugin (skills + MCP server in one step)
/plugin marketplace add deutero-ai/agent-skill
/plugin install deutero@deutero
```

---

## What your agent can do with these skills

- **Run user research from analytics.** Point the agent at a funnel drop, churn cohort, unused feature or support-ticket spike from PostHog, Amplitude, Mixpanel, GA4, a warehouse query or a CSV. It works out the questions only humans can answer, builds the interview study and recruits the exact users the data points at.
- **Validate a startup idea with customer discovery.** Give it a pitch deck, business plan or one-liner. It pulls out the riskiest assumptions, writes "Mom Test"-style interview questions that can actually disconfirm them, defines a findable target population and screener, and plans recruitment for people you don't have a list of yet.
- **Build interview studies end to end.** It sets up the project, study goals, all nine question types (open-ended, single and multi-select, scale, ranking, card sort, structured slots, image presentation, image upload), welcome and consent text, screening questions, participation links and an embeddable in-product interview widget, then validates and publishes the study.
- **Pilot a study with AI personas before recruiting anyone.** It writes or generates synthetic personas and runs simulated interviews to catch leading questions, broken wording, branches that never fire, and overruns on length or cost.
- **Author branching interview flows.** It builds conditional logic, per-segment question sets, loops, typed variable extraction, fallbacks for thin answers, and mid-interview webhooks. Every graph is validated before it goes live.
- **Pay participants automatically.** It tags participants with your own user ID, subscribes to the signed `interview.completed` webhook, verifies the signature, issues the gift card, credit or reward exactly once, and reconciles any missed deliveries.
- **Analyse the results.** It reads transcripts, does full-text search across interviews, pulls scale and multiple-choice distributions, and runs thematic clustering, all over MCP.
- **Interview its own user.** In an agent self-interview, the agent asks its principal how it should behave and turns the answers into proposed memory and rule changes, with a diff against the last run.

### Typical prompts that trigger these skills

> "Interview 20 users who dropped off at onboarding step 3 and tell me why."
> "I have a startup idea. Help me run customer discovery interviews to test it."
> "Turn this survey draft into an AI-moderated interview."
> "Embed a user feedback interview in our app for churned customers."
> "Dry-run my interview guide against a few personas before we recruit."
> "Send each participant a $20 gift card when they finish the interview."
> "Summarise the themes across all completed interviews in this study."

---

## Skills included

| Skill | Use it for |
|---|---|
| [`deutero-setup`](deutero-interview-research/skills/deutero-setup/SKILL.md) | Signing up, connecting the MCP server by OAuth or API key, checking credits and plan limits, and the Python SDK for code that runs without an agent. **Start here** if tools are missing or return 401/403. |
| [`deutero-study-authoring`](deutero-interview-research/skills/deutero-study-authoring/SKILL.md) | The hub: projects, study details, question types, welcome and consent, screening, recruitment links, the embed widget, reading results. |
| [`deutero-product-research`](deutero-interview-research/skills/deutero-product-research/SKILL.md) | User research driven by product analytics: funnel drops, churn, feature adoption, support spikes. Works with any analytics platform. |
| [`deutero-customer-development`](deutero-interview-research/skills/deutero-customer-development/SKILL.md) | Customer discovery and idea validation from a business idea, deck or plan: assumption mapping, problem interviews, willingness to pay, recruiting strangers. |
| [`deutero-simulation`](deutero-interview-research/skills/deutero-simulation/SKILL.md) | Synthetic-persona dry runs that test the interview instrument, plus a straight answer on what simulated participants can and can't tell you. |
| [`deutero-interview-flow`](deutero-interview-research/skills/deutero-interview-flow/SKILL.md) | Branching and conditional interviews (graph mode), validator errors, and patterns that work. It also tells you when not to branch. |
| [`deutero-participant-rewards`](deutero-interview-research/skills/deutero-participant-rewards/SKILL.md) | Incentives and payouts: external participant IDs, completion redirects, webhook verification, idempotent rewards, reconciliation. |
| [`agent-self-interview`](deutero-interview-research/skills/agent-self-interview/SKILL.md) | An agent interviews its own user about how it should work, then proposes memory updates. |

Each skill has a `references/` folder with detailed docs that load only when needed. Skills refer to each other's references by path (for example `deutero-study-authoring/references/question-types.md`), so install them together.

---

## Installation

### Option 1: Claude Code plugin (recommended for Claude Code)

This installs all eight skills and registers the Deutero MCP server.

```bash
/plugin marketplace add deutero-ai/agent-skill
/plugin install deutero@deutero
```

The first time a Deutero tool is called, Claude Code opens an OAuth sign-in. No API key goes into any file.

### Option 2: openskills (Claude Code, Cursor, Windsurf, Codex, Aider and any `AGENTS.md` agent)

```bash
npx openskills install deutero-ai/agent-skill          # project: ./.claude/skills
npx openskills install deutero-ai/agent-skill --global # user-wide: ~/.claude/skills
npx openskills sync                                     # write the skill list into AGENTS.md
```

openskills installs the skills only. It doesn't configure MCP, so add the server yourself (see below).

### Option 3: Any Agent Plugins client

Point the client at [`deutero-interview-research/`](deutero-interview-research). It finds the skills in `skills/` and the MCP server in `mcp.json`.

### Connect the Deutero MCP server

Endpoint: `https://dashboard.deutero.ai/mcp` (streamable HTTP). It has 93 tools, and every tool is also a REST route.

**OAuth** is preferred wherever the client supports remote MCP authorization:

```json
{
  "mcpServers": {
    "deutero": { "type": "http", "url": "https://dashboard.deutero.ai/mcp" }
  }
}
```

**API key** is for headless machines, CI and clients without OAuth. Generate one in the Deutero dashboard under **Settings → Generate API Key**.

```bash
# Claude Code
claude mcp add --transport http deutero https://dashboard.deutero.ai/mcp \
  --header "X-API-Key: $DEUTERO_API_KEY"
```

```json
// Cursor (~/.cursor/mcp.json), Windsurf (~/.windsurf/mcp.json), Claude Desktop (claude_desktop_config.json)
{
  "mcpServers": {
    "deutero": {
      "url": "https://dashboard.deutero.ai/mcp",
      "headers": { "X-API-Key": "${env:DEUTERO_API_KEY}" }
    }
  }
}
```

No account yet? Sign up at [dashboard.deutero.ai/login](https://dashboard.deutero.ai/login), or ask your agent to "set up Deutero" and the `deutero-setup` skill will walk through it. That includes an agent creating its own account from a programmable inbox.

---

## MCP tools at a glance

| Area | Tools |
|---|---|
| Projects & studies | `create_project`, `draft_study`, `draft_study_from_site`, `create_study`, `update_study`, `get_study`, `list_studies` |
| Questions | `generate_questions`, `create_question`, `update_question`, `reorder_questions`, `validate_questions`, `upload_question_image` |
| Screening & consent | `set_screening_settings`, `create_screening_question`, `generate_welcome`, `set_welcome`, `upsert_welcome_translation` |
| Publishing | `validate_study`, `publish_study`, `pause_study`, `get_publication_status` |
| Recruitment & embedding | `get_recruitment`, `update_recruitment`, `create_embed_key`, `get_embed_snippet` |
| Interview Flow (branching) | `describe_graph_nodes`, `check_graph`, `set_graph`, `patch_graph`, `activate_graph` |
| Personas & simulation | `create_persona`, `generate_personas`, `run_simulation`, `get_simulation` |
| Results & analysis | `list_interviews`, `get_transcript`, `bulk_transcripts`, `search_transcripts`, `get_scale_responses`, `get_options_responses`, `run_clustering` |
| Webhooks & rewards | `create_webhook`, `rotate_webhook_secret`, `list_webhook_deliveries`, `find_interviews_by_external_id` |
| Account | `get_credit_balance`, `health_health_get` |

The full inventory is in [`deutero-setup/references/mcp-clients.md`](deutero-interview-research/skills/deutero-setup/references/mcp-clients.md).

---

## FAQ

**Is this a survey tool?**
No. A survey collects fixed answers. Deutero runs a *conversation*: an AI moderator asks follow-up questions and probes vague answers the way a trained user researcher would. It still supports structured question types (scales, multiple choice, ranking) inside the interview when you need numbers.

**Who are the participants?**
Real people you recruit: your own users by email, link or in-product widget, or a population you screen for. AI personas exist only to test the interview before launch. The `deutero-simulation` skill is explicit that simulated answers aren't evidence about real users.

**Which analytics tools does product research work with?**
Any of them. The skill works from PostHog, Amplitude, Mixpanel, Google Analytics 4, Heap, a SQL or warehouse query, or a pasted CSV.

**Does my plan matter?**
Some features are plan-gated. Simulations and image questions need Solo or above, and branching Interview Flow needs Pro or above. The skills detect your plan and offer a fallback instead of failing. The details are in [`plan-limits.md`](deutero-interview-research/skills/deutero-setup/references/plan-limits.md).

**What isn't available to agents?**
Thematic analysis in the dashboard, Prolific recruitment, the Slack and Discord connectors, billing (including topping up when a publish is refused for credits), Chat with Data, and the **Preview** link for trying a draft yourself are dashboard-only. The skills say so where it matters.

**Can my backend use this without an agent?**
Yes. Every MCP tool is a REST route at `https://dashboard.deutero.ai/study-api/api/v1/`, authenticated with `X-API-Key`.

---

## Repository layout

```
.claude-plugin/marketplace.json        Claude Code marketplace ("deutero")
deutero-interview-research/            The plugin
  .claude-plugin/plugin.json           Claude Code plugin manifest (+ MCP server)
  plugin.json, mcp.json                Agent Plugins manifest and MCP declaration
  skills/<skill>/SKILL.md              One folder per skill (openskills discovers these)
  skills/<skill>/references/*.md       Loaded on demand
  CHANGELOG.md
```

## Links

- Website: [deutero.ai](https://deutero.ai)
- Dashboard and help: [dashboard.deutero.ai/help](https://dashboard.deutero.ai/help)
- REST API docs: [dashboard.deutero.ai/study-api/api/v1/docs](https://dashboard.deutero.ai/study-api/api/v1/docs)
- Changelog: [CHANGELOG.md](deutero-interview-research/CHANGELOG.md)

## License

Apache-2.0

<!-- Keywords: AI user research, user interviews, AI-moderated interviews, AI interviewer, qualitative research, customer discovery, customer development, idea validation, Mom Test, product research, UX research, user feedback, churn interviews, concept testing, synthetic personas, interview simulation, research participant incentives, MCP server, Model Context Protocol, Claude Code plugin, Claude skills, agent skills, openskills, Cursor, Windsurf, Codex -->
