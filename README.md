# Business Event Generator

An installable **AI agent** that, for any company you name, generates a
Dynatrace **Gen 3 KPI dashboard** plus a **30‑minute BizEvents injector**,
deploys both with `dtctl`, and verifies events are flowing.

Works with **Claude Code**, **GitHub Copilot**, **Cursor**, or any agent
runtime that respects `AGENTS.md`.

---

## What you get for each technology

```
dashboards/<Technology>/
  asset-manifest.json                    # generator ownership and tenant resource IDs
  <technology>-dashboard-v1.json          # Gen 3 dashboard (logo, KPIs, charts, map)
  <technology>-injector.js               # 30-min BizEvents injector
  <technology>-entity-creator.js         # Workflow task: MINT ingest for metric-entity association
  <technology>-openpipeline.json         # OpenPipeline pipeline (smartscapeNode extraction)
  <technology>-openpipeline-routing.json # OpenPipeline routing rule
  README.md                              # IDs + deploy commands
  LEARNINGS.md                           # DQL/layout notes, entity creation findings
  SALES-PITCH.md                         # 1-page value pitch
```

A single shared workflow `1.BizEvents Dashboard Generator` runs every 30
minutes in your tenant. Each new technology is added as **tasks** inside that
one workflow — the agent never creates a second injector workflow.

Generated workflows can use a finite schedule window. During generation,
provide the number of days to run; the default is 7 days, and `0` means no
automatic expiry. The workflow continues at its 30-minute interval until the
configured end date. Because the workflow is shared, adding a task does not
change an existing workflow's duration unless the user explicitly requests a
schedule change.

### Cleanup generated assets

Each generated technology pack records its tenant resource IDs in
`asset-manifest.json`. Use the cleanup tool to inventory packs and preview a
technology-specific cleanup:

```bash
./scripts/cleanup-technology.sh --list
./scripts/cleanup-technology.sh --technology zscaler-internet-access --dry-run
./scripts/cleanup-technology.sh --technology zscaler-internet-access --confirm
./scripts/validate-asset-manifest.sh dashboards/zscaler-internet-access/asset-manifest.json
./scripts/test-asset-manifest.sh
```

Cleanup removes configuration assets such as dashboards, technology-specific
OpenPipeline settings, logo documents, and the technology's tasks from the
shared workflow. It never deletes the shared workflow. Historical BizEvents
and logs are retained according to tenant retention, and Smartscape entity
removal is reported separately unless the tenant exposes a supported delete
lifecycle.

Discovery is manifest-first by design. A technology folder without an
`asset-manifest.json` is listed as legacy and is not eligible for automatic
deletion until its ownership is reviewed and a manifest is added.

### Reference example: Zscaler Internet Access

The completed [Zscaler Internet Access reference pack](skills/dynatrace-metric-entity-dashboard-generator/reference/zscaler-internet-access/)
is the repository's reference implementation. It shows the full lifecycle:
BizEvents, optional synthetic logs, OpenPipeline Smartscape extraction, shared
workflow tasks, dashboard thresholds, and live validation. Agents should reuse
the implementation pattern while choosing technology-specific entities, event
schemas, KPIs, log fields, and map usage. Zscaler's `site`, `zia_node`, and
policy fields are not universal requirements.

---

## Quick start (macOS / Linux)

Three commands and you're done:

```bash
git clone https://github.com/Dynatrace-BrianWilson/dynatrace-metric-entity-dashboard-generator.git
cd dynatrace-metric-entity-dashboard-generator
./scripts/install.sh
```

The installer takes care of everything:

- Installs `jq` (if missing).
- Installs / updates `dtctl`.
- Installs the `dtctl`, `dynatrace-for-ai`, **and
  `dynatrace-metric-entity-dashboard-generator`** agent skills via `npx skills add`.
- If Claude Code (`claude`) is installed, it also installs the Claude
  plugin so `/generate-metric-dashboard` works **globally** (any cwd) without
  any extra step.

Then authenticate `dtctl` to your tenant and verify:

```bash
dtctl auth login --context my-env --environment "https://<env>.apps.dynatrace.com"
./scripts/check-prereqs.sh
```

You're ready. Skip ahead to [Use it](#use-it).

> **Windows users:** see [Windows install](#windows-install) below.

---

## Use it

Once installed, you can invoke the agent from **any directory** — the
skill is loaded globally.

### Claude Code

```
/generate-metric-dashboard NVIDIA GPU
```

To discover or clean up generated assets:

```text
/cleanup-metric-dashboard
/cleanup-metric-dashboard zscaler-internet-access
```

…or just ask in plain English: *"Generate a metric dashboard for NVIDAI GPU."*

### GitHub Copilot Chat (VS Code)

In agent mode:

```
Generate a metric dashboard for NVIDIA
```

For cleanup, use the reusable prompt `cleanup-metric-dashboard.prompt.md` or
ask: `cleanup metric dashboard` followed by a technology name. Copilot runs a
dry run first and requires explicit tenant and technology confirmation before
deletion.

If you want a slash command in Copilot too, link the prompt file:

```bash
mkdir -p "$HOME/Library/Application Support/Code/User/prompts"   # macOS
ln -sfn "$PWD/.github/prompts/generate-metric-dashboard.prompt.md" \
  "$HOME/Library/Application Support/Code/User/prompts/generate-metric-dashboard.prompt.md"
```

Linux: `~/.config/Code/User/prompts/`. Windows:
`%APPDATA%\Code\User\prompts\`.

### Any other agent

Point your agent at `AGENTS.md`. It is fully self‑contained.

---

## What the agent does

1. Runs `dtctl auth whoami` and `dtctl ctx current`, **shows you the
   tenant**, and waits for confirmation before touching anything.
2. Asks for technology, Dynatrace Hub link (optional), Industry / business domain (optional) logo URL (optional — it'll
   search if you don't provide one).
3. Researches 15–20 industry KPIs and matching event types and optional logs.
4. Writes the dashboard JSON, injector JS, entity creator JS, OpenPipeline JSON files, README, LEARNINGS, and SALES‑PITCH into `dashboards/<Technology>/`.
5. `dtctl apply` the dashboard, captures the ID.
6. `dtctl apply` the OpenPipeline pipeline and routing settings — creates Smartscape entities from BizEvents automatically.
7. Adds two tasks to the **single** shared injector workflow (`1.Metrics Dashboard Generator`): the BizEvents injector and the entity creator. Never creates a duplicate workflow.
8. `dtctl exec workflow <id>` and waits for `SUCCESS`.
9. Verifies events landed and entities are visible in Explorer Classic:
   ```bash
   dtctl query "smartscapeNodes \"CUSTOM_<TYPE>\", from:now()-1h | limit 20" --plain
   ```
10. Verifies BizEvents landed:
   ```dql
   fetch bizevents
   | filter event.provider == "<company>.event.provider"
   | summarize total = count()
   ```
9. Tells you the dashboard URL, workflow ID, and task name.

Full spec: [AGENTS.md](AGENTS.md).

---

## Other install paths

The Quick Start covers 95% of cases. Use these if you need something
different.

### Already have `dtctl` + Dynatrace skills installed?

Just install this one skill (and, optionally, the Claude plugin):

```bash
npx skills add Dynatrace-BrianWilson/dynatrace-metric-entity-dashboard-generator
```

```bash
# The generator plugin provides /generate-metric-dashboard and
# /cleanup-metric-dashboard.
```

Updates: `npx skills update` and `claude plugin update …`.

### Local‑only (developing the skill itself)

If you're editing this repo and want changes to show up immediately
without re‑publishing, symlink the bundle into your global agent dirs:

```bash
mkdir -p ~/.agents/skills ~/.claude/commands
ln -sfn "$PWD/skills/dynatrace-metric-entity-dashboard-generator" \
  ~/.agents/skills/dynatrace-metric-entity-dashboard-generator
ln -sfn "$PWD/.claude/commands/generate-metric-dashboard.md" \
  ~/.claude/commands/generate-metric-dashboard.md
ln -sfn "$PWD/.claude/commands/cleanup-metric-dashboard.md" \
  ~/.claude/commands/cleanup-metric-dashboard.md
```

After editing `AGENTS.md` or the reference assets, regenerate the skill bundle:

```bash
./scripts/build-skill.sh
```

### Windows install

The installer script doesn't run on Windows. Do it manually in PowerShell:

```powershell
# 1. dtctl + login
irm https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.ps1 | iex
dtctl auth login --context my-env --environment "https://<env>.apps.dynatrace.com"

# 2. jq
winget install jqlang.jq

# 3. Skills
npx skills add dynatrace-oss/dtctl
npx skills add dynatrace/dynatrace-for-ai
npx skills add Dynatrace-BrianWilson/dynatrace-metric-entity-dashboard-generator

# 4. (Optional) Claude Code plugin for /generate-metric-entity-dashboard slash command
claude plugin marketplace add Dynatrace-BrianWilson/dynatrace-metric-entity-dashboard-generator
claude plugin install dynatrace-metric-entity-dashboard-generator@dynatrace-metric-entity-dashboard-generator
```

Verify with `bash scripts/check-prereqs.sh` from Git Bash or WSL.

---

## Prerequisites

The Quick Start installer handles all of these. They're listed here for
reference / Windows users / debugging.

| Tool | Why | Check |
|------|-----|-------|
| **`dtctl`** authenticated to a Dynatrace Gen 3 tenant | Deploys dashboards + workflows, runs DQL | `dtctl auth whoami` |
| **`dtctl` agent skill** | Teaches your agent how to operate `dtctl` | folder in `~/.agents/skills/dtctl/` |
| **`dynatrace-for-ai` skills** | DQL, dashboards, notebooks domain knowledge | folders `dt-*` in `~/.agents/skills/` |
| **`dynatrace-metric-entity-dashboard-generator` skill** | This agent | folder `~/.agents/skills/dynatrace-metric-entity-dashboard-generator/` |
| **`jq`** | Manipulates the workflow JSON when adding tasks | `jq --version` |
| **Node.js / `npx`** | Required by `npx skills add` | `node --version` |
| Network access to fetch logo URLs | Header tile branding | — |

> The agent will **not** install or configure `dtctl` for you. If
> `dtctl auth whoami` fails, log in to `dtctl` first.

---

## What you get for each technology

```
dashboards/<Technology>/
  <technology>-dashboard-v1.json          # Gen 3 dashboard (logo, KPIs, charts, map)
  <technology>-injector.js               # 30-min BizEvents injector
  <technology>-entity-creator.js         # Workflow task: MINT metrics for entity association
  <technology>-openpipeline.json         # OpenPipeline settings (smartscapeNode extraction)
  <technology>-openpipeline-routing.json # OpenPipeline routing rule
  README.md                              # IDs + deploy commands
  LEARNINGS.md                           # DQL/layout notes, entity creation findings
  SALES-PITCH.md                         # 1-page value pitch
```

A single shared workflow `1.BizEvents Dashboard Generator` runs every 30
minutes in your tenant. Each new technology is added as **tasks** inside
that one workflow — the agent never creates a second injector workflow.

---

## Hard rules the agent follows

- **Gen 3 dashboard JSON only** (matches `.example/example_dashboard.json`).
- **Map tile is optional** — include a `bubbleMap` or another map only when geographic, regional, site, or location data is meaningful for the technology. If included, drive it with real geo coordinates from the injector and always set `"regions": { "showRegions": false }`; specifying region codes causes "Failed to load map data".
- **`singleValue` `≥` color rules** — lowest threshold first, highest last. Dynatrace applies the last matching rule; reversed order shows the wrong color for every value.
- **Header is two markdown tiles** — logo (`w:6, h:2`) + title (`w:18, h:2`).
- **Charts ≥ `h:4`, KPIs `h:2`.**
- **`makeTimeseries` for time charts**, `summarize` for KPIs — never feed `summarize` into a chart.
- **One injector workflow per tenant.** New technologies = new tasks.
- **Entities via OpenPipeline `smartscapeNode` processors** — the classic entity API (`/api/v1/entity/infrastructure/custom`) is not available on Gen 3 tenants. `CUSTOM_DEVICE` type is blocked; use `CUSTOM_<TECHNOLOGY>_<ENTITY>` instead.
- **Entities appear in Explorer Classic only** — Explorer New requires EF2; do not attempt to register `builtin:monitoredentities.generic.type` entries unless EF2 is in scope.
- 3,000–5,000 events per 30‑minute run, batched in 500‑event POSTs.

---

## Repository layout

```
.
├── AGENTS.md                              # canonical agent instructions
├── README.md                              # this file
├── .claude-plugin/
│   └── marketplace.json                   # Claude Code plugin marketplace manifest
├── plugins/
│   └── dynatrace-metric-entity-dashboard-generator/ # Claude Code plugin commands
├── skills/
│   └── dynatrace-metric-entity-dashboard-generator/ # redistributable skill bundle
│       ├── SKILL.md
│       └── reference/                     # reusable reference assets
├── .github/
│   ├── copilot-instructions.md            # Copilot system prompt
│   └── prompts/generate-metric-dashboard.prompt.md
├── .claude/
│   └── commands/generate-metric-dashboard.md # Claude Code slash command
├── scripts/
│   ├── install.sh                         # macOS/Linux one-shot installer
│   ├── build-skill.sh                     # regenerate skills/<name>/
│   ├── check-prereqs.sh
│   └── cleanup-technology.sh               # discover, preview, and clean assets
└── dashboards/<Company>/                  # generated per company, including asset-manifest.json
```

Where each piece is used:

| File | Used by |
|------|---------|
| [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json) | `claude plugin install` |
| [skills/dynatrace-metric-entity-dashboard-generator/SKILL.md](skills/dynatrace-metric-entity-dashboard-generator/SKILL.md) | `npx skills add` redistributable bundle |
| [AGENTS.md](AGENTS.md) | **Canonical spec** — source for the skill bundle |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | GitHub Copilot (auto‑loaded in this repo) |
| [.github/prompts/generate-metric-dashboard.prompt.md](.github/prompts/generate-metric-dashboard.prompt.md) | Copilot Chat reusable prompt |
| [.claude/commands/generate-metric-dashboard.md](.claude/commands/generate-metric-dashboard.md) | Claude Code slash command source |
| [scripts/build-skill.sh](scripts/build-skill.sh) | Regenerates the skill bundle from `AGENTS.md` + reference assets |

---

## Troubleshooting

- **`dtctl auth whoami` fails** → install or `dtctl auth login` to your tenant before invoking the agent.
- **400 when applying the workflow** → two tasks share the same `position.{x, y}`; give the new task a unique position.
- **Map tile is empty** → the injector did not populate `geo.location.latitude` / `geo.location.longitude` for any event type.
- **Red‑X chart** → query uses `summarize` but the tile is a chart; rewrite with `makeTimeseries`.
- **Dashboard shows "Untitled"** → the JSON was applied without the `name` / `type` wrapper required by `dtctl apply`.
- **MINT 400 "failed to parse metric key"** → dimension separators are semicolons instead of commas. Correct format: `metric.key,dim1=val1,dim2=val2 value timestampMs`.
- **OpenPipeline 400 on routing `requiredDimensions`** → use `$eq(value)` or `$prefix(value)` syntax, not raw strings.
- **OpenPipeline validation error for `CUSTOM_DEVICE` nodeType** → `CUSTOM_DEVICE` is explicitly blocked. Use `CUSTOM_<TECHNOLOGY>_<ENTITY>` instead.
- **Entities not visible in Explorer New** → OpenPipeline entities appear in Explorer Classic only. Explorer New requires EF2; do not attempt `builtin:monitoredentities.generic.type` registration without it.
- **Smartscape Events API 401 from workflow** → The `/platform/ingest/v1/smartscape.events` endpoint is on the non-apps domain and rejects workflow AutomationEngine tokens. Use the OpenPipeline approach instead.

