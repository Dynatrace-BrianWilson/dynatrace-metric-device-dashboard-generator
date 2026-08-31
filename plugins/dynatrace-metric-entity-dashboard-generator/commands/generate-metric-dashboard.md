---
description: Generate a Dynatrace Gen 3 metric dashboard, Smartscape entities, and a 30-minute injector for a technology.
argument-hint: <technology> [hub-link] [industry] [logo-url] [duration-days]
---

Generate a Dynatrace Gen 3 metric dashboard, Smartscape entities via
OpenPipeline, and a 30-minute metric/log injector for the technology **$ARGUMENTS**.

Follow `AGENTS.md` exactly. Before any tenant mutation:

1. Check `dtctl auth whoami` and display the active context and identity.
2. Ask the user to confirm the tenant.
3. Ask for the workflow duration in days. Default to 7 for a demo; use 0 for
   no automatic expiry. Do not change the duration of an existing shared
   workflow unless explicitly requested.

Use the reference implementation at
`skills/dynatrace-metric-entity-dashboard-generator/reference/zscaler-internet-access/`
for lifecycle and validation patterns, but adapt all fields, KPIs, entities,
logs, and map usage to the requested technology.

Create the technology pack under `dashboards/<technology>/`, including:

- `asset-manifest.json`
- Versioned Gen 3 dashboard
- MINT metrics injector and optional log injector
- OpenPipeline pipeline and routing settings
- Workflow task definition
- `README.md`, `LEARNINGS.md`, and `SALES-PITCH.md`

Use the shared injector workflow rather than creating a second workflow. Test
DQL before deployment, apply the dashboard and settings, execute the workflow,
verify ingestion and entities, validate the live dashboard payload, and report
resource IDs and URLs. A map is optional and should only be used when geography
is meaningful. Do not claim completion without a successful workflow execution
and live verification.
