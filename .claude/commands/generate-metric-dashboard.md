---
description: Generate a Dynatrace Gen 3 metric dashboard, Smartscape entities, and a 30-minute injector for a technology.
argument-hint: <technology> [hub-link] [industry] [logo-url] [duration-days]
---

Use the repository's canonical generation instructions in `AGENTS.md` to
create and deploy a dashboard pack for **$ARGUMENTS**. Before any tenant
mutation, show the active `dtctl` context and identity and get explicit tenant
confirmation. Use the Zscaler reference pack for lifecycle patterns, adapt the
schema to the requested technology, create an `asset-manifest.json`, use the
shared injector workflow, and run the full live validation before reporting
success.
