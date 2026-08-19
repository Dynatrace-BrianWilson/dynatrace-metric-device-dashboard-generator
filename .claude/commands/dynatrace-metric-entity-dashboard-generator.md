---
description: Generate a Dynatrace Gen 3 metric dashboard, metric injector, and device/entity for a technology.
argument-hint: <Technology name> [dynatrace hub link] [industry] [logo-url]
---

Generate a Dynatrace Gen 3 metric dashboard, Smartscape entities (via OpenPipeline), and 30‑minute metric injector for the technology **$ARGUMENTS**.

Follow `AGENTS.md` in this repository exactly. In particular:

1. Verify `dtctl auth whoami` succeeds before doing anything else.
2. **Show the active `dtctl` context to the user** (`dtctl ctx current` + `dtctl auth whoami`) and get explicit confirmation that the tenant is correct before any `dtctl apply` or `dtctl exec`.
3. Mirror the structure of files in `.example/`.
4. Output goes into `dashboards/<Technology>/`:
   - `<technology>-dashboard-v1.json`
   - `<technology>-injector.js`
   - `<technology>-entity-creator.js`
   - `<technology>-openpipeline.json`
   - `<technology>-openpipeline-routing.json`
   - `README.md`, `LEARNINGS.md`, `SALES-PITCH.md`
5. The dashboard may contain a `bubbleMap` map tile, a split logo+title header, section dividers, KPI tiles (`h:2`), and charts (`h:4`+).
6. `dtctl apply` the dashboard JSON to capture the dashboard ID.
7. `dtctl apply` the OpenPipeline settings before running the workflow.
8. Look up the existing injector workflow with
   `dtctl get workflows -o json --plain | jq '.[] | select(.title | test("Metrics Dashboard Generator|injector"; "i"))'`.
   - If found: append new tasks `<technology>_v1` and `<technology>_entities_v1` and `dtctl apply` the workflow.
   - If not found: create from `.example/example_data_injector.workflow.json`. Never create a second injector workflow.
9. `dtctl exec workflow <id>` and confirm SUCCESS.
10. Verify events landed: `fetch bizevents | filter event.provider == "<technology>.event.provider" | summarize count()`.
11. Verify entities: `dtctl query "smartscapeNodes \"CUSTOM_<TYPE>\", from:now()-1h | limit 20" --plain`.
12. Report dashboard URL, workflow ID, and task names back to the user.
