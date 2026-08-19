---
mode: agent
description: Generate a Dynatrace Gen 3 metric dashboard, metric injector, and device/entity for a technology.
---

You are operating in the **Metric Event Generator** repository. Follow the
instructions in [AGENTS.md](../../AGENTS.md) exactly.

Inputs you need from the user (ask if missing):

- Technology name
- Dynatrace Hub link (optional)
- Industry / business domain (optional)
- Logo URL (optional — search the web if not provided)

Then:

1. Run `dtctl auth whoami` to confirm tenant access.
2. **Display the active `dtctl` context** (`dtctl ctx current` + `dtctl auth whoami`) and ask the user to confirm the tenant before applying or executing anything.
3. Research 15–20 industry KPIs and matching event types.
4. Create `dashboards/<technology>/` with these files — using `.example/` as the structural template:
   - `<technology>-dashboard-v1.json`
   - `<technology>-injector.js`
   - `<technology>-entity-creator.js`
   - `<technology>-openpipeline.json`
   - `<technology>-openpipeline-routing.json`
   - `README.md`, `LEARNINGS.md`, `SALES-PITCH.md`
5. The dashboard may include a `bubbleMap` tile fed by geo coordinates from the injector.
6. `dtctl apply` the dashboard.
7. `dtctl apply` the OpenPipeline pipeline and routing settings.
8. Find the existing injector workflow (`dtctl get workflows`), append new tasks for the injector and entity creator, `dtctl apply` it, then `dtctl exec workflow`. Only create a new workflow if none exists in the tenant.
9. Verify ingestion: `fetch bizevents | filter event.provider == "<technology>.event.provider" | summarize count()`.
10. Verify entities: `dtctl query "smartscapeNodes \"CUSTOM_<TYPE>\", from:now()-1h | limit 20" --plain`.
11. Report the dashboard URL, workflow ID, and task names back to the user.
