# Deutero plugin

Agent Plugins v1.1.0 package for [Deutero](https://deutero.ai), an AI-conducted qualitative research platform. Skills for designing, running and reading research; one MCP server for doing it.

## Install

Point any Agent Plugins client at this directory. The client discovers the skills in `skills/` and the MCP server in `mcp.json`.

The server is declared with no credentials:

```json
{ "type": "streamable-http", "url": "https://dashboard.deutero.ai/mcp" }
```

Authorization is the client's job. Clients that support remote MCP authorization sign in by OAuth on the first tool call; anything else uses an API key in an `X-API-Key` header, configured client-side. The `deutero-setup` skill walks through both, and through creating an account when there is not one yet.

## From code

MCP is for an agent in a session. Code that runs on its own — a webhook receiver, a reconciliation job, a script that builds studies — uses the same API through the [`deutero` Python SDK](https://github.com/deutero-ai/deutero-python) (`pip install "deutero>=0.2"`) or plain REST. `deutero-setup/references/python-sdk.md` maps every MCP tool to its SDK method.

## Skills

| Skill | For |
|---|---|
| `deutero-setup` | Account creation, OAuth or API key, connection and plan checks, and the Python SDK. Start here when tools are missing or returning 401/403. |
| `deutero-study-authoring` | The mechanics: project, study details, question types, guidance, welcome, screening, recruitment, results. The hub the others build on. |
| `deutero-product-research` | Studies driven by analytics and product context — a funnel drop, a churn cohort, a dead feature. Platform-agnostic; covers in-product embedding and recruitment copy. |
| `deutero-customer-development` | Discovery studies from a business idea, deck or plan. Assumption extraction, questions about the past, finding a population you have no list of. |
| `deutero-simulation` | Testing a study against AI personas before spending real participants on it. |
| `deutero-interview-flow` | Branching interviews: the graph mode, its validator, and the patterns worth using. |
| `deutero-participant-rewards` | Making a finished interview *do* something: tagging participants with your own ID, the `interview.completed` webhook, paying exactly once, reconciling misses. |
| `agent-self-interview` | An agent eliciting its own operating preferences from its principal, and turning the answers into proposed memory changes. |

`deutero-study-authoring` holds the shared references; the topic skills decide *what* to ask and hand the building to it. References are addressed across skills by plugin-relative path, e.g. `deutero-study-authoring/references/question-types.md`.

## Not covered over MCP

AI generation of study details, questions and welcome text; thematic analysis; Prolific recruitment; Slack and Discord connectors; billing; Chat with Data. All dashboard-only. The skills say so where it matters rather than sending you looking for a tool.

Webhook endpoints *are* manageable over MCP (`create_webhook` and friends), and were not before 1.3.0 — the dashboard's Settings → Webhooks page and the API manage the same endpoints.
