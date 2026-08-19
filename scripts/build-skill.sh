#!/usr/bin/env bash
# Build the redistributable skill bundle at skills/dynatrace-metric-metric-dashboard-generator/
# from the canonical sources (AGENTS.md + .example/). Run this whenever you
# update AGENTS.md or the example files so `npx skills add` consumers get the
# latest content.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_NAME="dynatrace-metric-entity-dashboard-generator"
SKILL_DIR="$ROOT/skills/$SKILL_NAME"
# REF_DIR="$SKILL_DIR/reference"

mkdir -p "$REF_DIR"

# --- SKILL.md = frontmatter + AGENTS.md (with .example/ -> reference/ rewrites)
cat > "$SKILL_DIR/SKILL.md" <<'FRONTMATTER'
---
name: dynatrace-metric-entity-dashboard-generator
description: Generate a Dynatrace Gen 3 **KPI dashboard** (15–20 KPIs, optional map tile, branded section dividers), a relevant dynatrace entity to map metrics and logs to and a matching 30‑minute data injector for a named technology, then deploy both via `dtctl`. Do not use this skill if a user is triggering the generate-kpi-dashboard generator. Triggers include phrases like "generate a metric dashboard", "build a metrics demo for <technology>", "spin up a metrics dashboard + injector", "/generate-technology-dashboard". Requires `dtctl` authenticated to a Dynatrace Gen 3 tenant.
---

FRONTMATTER

# Append AGENTS.md, rewriting `.example/` references to the bundled `reference/` path
sed 's|\.example/|reference/|g' "$ROOT/AGENTS.md" >> "$SKILL_DIR/SKILL.md"

# --- reference/ = copy of .example/
rm -f "$REF_DIR"/*
cp "$ROOT/.example/"* "$REF_DIR/"

echo "Built skill bundle at: $SKILL_DIR"
ls -la "$SKILL_DIR"
echo "---"
ls -la "$REF_DIR"
