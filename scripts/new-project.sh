#!/usr/bin/env bash
# ==============================================================================
# EVIDENCE-TO-PRODUCT ENGINE — PROJECT LAUNCHER
# Version: 2.0
#
# Purpose:
#   Turn a book idea into a structured, evidence-first project workspace.
#
# Design:
#   - $0 startup cost
#   - Android/Termux friendly
#   - No mandatory API
#   - No cloud database
#   - Human approval before major gates
#   - Machine-readable project state
#   - Safe to resume
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

ENGINE_NAME="Evidence-to-Product Engine"
ENGINE_VERSION="2.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/scripts/new-project.sh" ]]; then
    DEFAULT_ROOT="$SCRIPT_DIR"
else
    DEFAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
ROOT_DIR="${BOOK_ENGINE_ROOT:-$DEFAULT_ROOT}"
WORK_DIR="$ROOT_DIR/work"

# ------------------------------------------------------------------------------
# Terminal helpers
# ------------------------------------------------------------------------------

if [[ -t 1 ]]; then
    BOLD='\033[1m'
    DIM='\033[2m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
    RED='\033[31m'
    BLUE='\033[34m'
    RESET='\033[0m'
else
    BOLD=''
    DIM=''
    GREEN=''
    YELLOW=''
    RED=''
    BLUE=''
    RESET=''
fi

info()    { printf "${BLUE}▶${RESET} %s\n" "$*"; }
success() { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}!${RESET} %s\n" "$*"; }
error()   { printf "${RED}✗${RESET} %s\n" "$*" >&2; }
die()     { error "$*"; exit 1; }

# ------------------------------------------------------------------------------
# Cleanup / error handling
# ------------------------------------------------------------------------------

TMP_FILES=()

cleanup() {
    local file
    for file in "${TMP_FILES[@]:-}"; do
        if [[ -n "$file" && -f "$file" ]]; then
            rm -f "$file"
        fi
    done
}

trap cleanup EXIT

on_error() {
    error "Launcher failed on line $1."
    error "Project files already created have been preserved."
}

trap 'on_error $LINENO' ERR

# ------------------------------------------------------------------------------
# Utilities
# ------------------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

slugify() {
    local value="$1"

    value="$(printf '%s' "$value" |
        tr '[:upper:]' '[:lower:]' |
        sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"

    printf '%s' "$value"
}

timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

today() {
    date -u '+%Y-%m-%d'
}

require_command() {
    command_exists "$1" || die "Required command not found: $1"
}

write_file() {
    local path="$1"
    shift

    mkdir -p "$(dirname "$path")"
    cat > "$path"
}

# ------------------------------------------------------------------------------
# JSON writer
#
# Uses Python when available so arbitrary user input cannot corrupt JSON.
# ------------------------------------------------------------------------------

write_project_json() {
    local output="$1"
    local topic="$2"
    local audience="$3"
    local outcome="$4"
    local slug="$5"
    local mode="$6"

    if command_exists python3; then
        TOPIC="$topic" \
        AUDIENCE="$audience" \
        OUTCOME="$outcome" \
        SLUG="$slug" \
        MODE="$mode" \
        CREATED="$(timestamp)" \
        VERSION="$ENGINE_VERSION" \
        python3 - "$output" <<'PY'
import json
import os
import sys

output = sys.argv[1]

data = {
    "engine": {
        "name": "Evidence-to-Product Engine",
        "version": os.environ["VERSION"]
    },
    "project": {
        "slug": os.environ["SLUG"],
        "topic": os.environ["TOPIC"],
        "audience": os.environ["AUDIENCE"],
        "primary_outcome": os.environ["OUTCOME"],
        "mode": os.environ["MODE"],
        "created_at": os.environ["CREATED"],
        "startup_cost_usd": 0
    },
    "pipeline": {
        "current_stage": "INTAKE",
        "status": "active",
        "completed_stages": []
    },
    "gates": {
        "research_approved": False,
        "opportunity_approved": False,
        "outline_approved": False,
        "draft_approved": False,
        "fact_check_approved": False,
        "package_approved": False,
        "launch_approved": False
    },
    "metrics": {
        "units_sold": 0,
        "revenue_usd": 0,
        "reviews": 0,
        "conversion_rate": None
    }
}

with open(output, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    else
        die "python3 is required for safe project-state generation."
    fi
}

# ------------------------------------------------------------------------------
# Project discovery
# ------------------------------------------------------------------------------

find_existing_project() {
    local slug="$1"
    [[ -d "$WORK_DIR/$slug" ]] || return 1
}

# ------------------------------------------------------------------------------
# Intake
# ------------------------------------------------------------------------------

TOPIC="${TOPIC:-}"
AUDIENCE="${AUDIENCE:-}"
OUTCOME="${OUTCOME:-}"
MODE="${MODE:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in

        --topic|-t)
            [[ $# -ge 2 ]] || die "--topic requires a value"
            TOPIC="$2"
            shift 2
            ;;

        --audience|-a)
            [[ $# -ge 2 ]] || die "--audience requires a value"
            AUDIENCE="$2"
            shift 2
            ;;

        --outcome|-o)
            [[ $# -ge 2 ]] || die "--outcome requires a value"
            OUTCOME="$2"
            shift 2
            ;;

        --mode|-m)
            [[ $# -ge 2 ]] || die "--mode requires a value"
            MODE="$2"
            shift 2
            ;;

        --resume)
            [[ $# -ge 2 ]] || die "--resume requires a project slug"
            RESUME_SLUG="$2"
            shift 2
            ;;

        --help|-h)
            cat <<'HELP'
Evidence-to-Product Engine — Project Launcher

USAGE

  ./new-project.sh

  ./new-project.sh \
      --topic "Budget Travel" \
      --audience "People traveling on a tight budget" \
      --outcome "Plan a useful trip without overspending"

OPTIONS

  -t, --topic       Book topic
  -a, --audience    Target reader
  -o, --outcome     Primary reader outcome
  -m, --mode        research | outline | book | full
      --resume      Resume an existing project
  -h, --help        Show this help

EXAMPLES

  Interactive:
      ./new-project.sh

  Automated:
      ./new-project.sh \
          -t "AI for Small Businesses" \
          -a "Solo business owners" \
          -o "Use AI to automate repetitive work"

  Resume:
      ./new-project.sh --resume ai-for-small-businesses

HELP
            exit 0
            ;;

        *)
            die "Unknown option: $1"
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Resume mode
# ------------------------------------------------------------------------------

if [[ -n "${RESUME_SLUG:-}" ]]; then

    PROJECT_DIR="$WORK_DIR/$RESUME_SLUG"

    [[ -d "$PROJECT_DIR" ]] ||
        die "Project not found: $PROJECT_DIR"

    printf '\n'
    printf '%b%s%b\n' "$BOLD" "$ENGINE_NAME" "$RESET"
    printf '%s\n\n' "Resume Project"

    if [[ -f "$PROJECT_DIR/project.json" ]]; then
        if command_exists python3; then
            python3 - "$PROJECT_DIR/project.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    p = json.load(f)

project = p.get("project", {})
pipeline = p.get("pipeline", {})

print(f"Topic:    {project.get('topic', '')}")
print(f"Audience: {project.get('audience', '')}")
print(f"Outcome:  {project.get('primary_outcome', '')}")
print(f"Stage:    {pipeline.get('current_stage', '')}")
print(f"Status:   {pipeline.get('status', '')}")
PY
        fi
    fi

    printf '\n'
    success "Project ready: $PROJECT_DIR"
    printf '\n'
    exit 0
fi

# ------------------------------------------------------------------------------
# Dependency validation
# ------------------------------------------------------------------------------

require_command sed
require_command tr
require_command date
require_command mkdir
require_command python3

# ------------------------------------------------------------------------------
# Interactive intake
# ------------------------------------------------------------------------------

printf '\n'
printf '%b%s%b\n' "$BOLD" "$ENGINE_NAME" "$RESET"
printf '%s\n\n' "Evidence-first publishing project launcher"

if [[ -z "$TOPIC" ]]; then
    read -r -p "What is the book about? " TOPIC
fi

if [[ -z "$AUDIENCE" ]]; then
    read -r -p "Who is it for? " AUDIENCE
fi

if [[ -z "$OUTCOME" ]]; then
    read -r -p "What should the reader be able to do after reading it? " OUTCOME
fi

[[ -n "$TOPIC" ]] ||
    die "Topic cannot be empty."

[[ -n "$AUDIENCE" ]] ||
    die "Audience cannot be empty."

[[ -n "$OUTCOME" ]] ||
    die "Outcome cannot be empty."

if [[ -z "$MODE" ]]; then
    printf '\n'
    printf '%bChoose starting mode:%b\n' "$BOLD" "$RESET"
    printf '  1) Research only\n'
    printf '  2) Research + outline\n'
    printf '  3) Research + outline + draft scaffold\n'
    printf '  4) Full pipeline\n'
    printf '\n'

    read -r -p "Selection [4]: " MODE_CHOICE
    MODE_CHOICE="${MODE_CHOICE:-4}"

    case "$MODE_CHOICE" in
        1) MODE="research" ;;
        2) MODE="outline" ;;
        3) MODE="book" ;;
        4) MODE="full" ;;
        *) die "Invalid selection." ;;
    esac
fi

case "$MODE" in
    research|outline|book|full)
        ;;
    *)
        die "Invalid mode: $MODE"
        ;;
esac

# ------------------------------------------------------------------------------
# Create project identity
# ------------------------------------------------------------------------------

SLUG="$(slugify "$TOPIC")"

[[ -n "$SLUG" ]] ||
    die "Could not generate a project slug from the topic."

PROJECT_DIR="$WORK_DIR/$SLUG"

if find_existing_project "$SLUG"; then
    warn "A project with this topic already exists:"
    printf '    %s\n' "$PROJECT_DIR"
    printf '\n'

    read -r -p "Resume existing project instead? [Y/n]: " ANSWER
    ANSWER="${ANSWER:-Y}"

    if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
        exec "$0" --resume "$SLUG"
    fi

    die "Project creation cancelled."
fi

# ------------------------------------------------------------------------------
# Create directory structure
# ------------------------------------------------------------------------------

info "Creating project architecture..."

mkdir -p \
    "$PROJECT_DIR/research" \
    "$PROJECT_DIR/opportunity" \
    "$PROJECT_DIR/outline" \
    "$PROJECT_DIR/manuscript" \
    "$PROJECT_DIR/fact-check" \
    "$PROJECT_DIR/editing" \
    "$PROJECT_DIR/packaging" \
    "$PROJECT_DIR/launch" \
    "$PROJECT_DIR/metrics" \
    "$PROJECT_DIR/decisions"

# ------------------------------------------------------------------------------
# Project state
# ------------------------------------------------------------------------------

write_project_json \
    "$PROJECT_DIR/project.json" \
    "$TOPIC" \
    "$AUDIENCE" \
    "$OUTCOME" \
    "$SLUG" \
    "$MODE"

# ------------------------------------------------------------------------------
# README
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/README.md" <<EOF
# $TOPIC

## Project

- **Audience:** $AUDIENCE
- **Primary outcome:** $OUTCOME
- **Mode:** $MODE
- **Created:** $(timestamp)
- **Startup cost:** \$0

## Current stage

**INTAKE**

## Core rule

Do not write the full book merely because the topic sounds interesting.

First establish:

1. A real reader problem
2. Evidence of demand
3. Existing alternatives
4. A meaningful gap
5. A specific promise
6. A credible reason this book should exist

## Pipeline

INTAKE
→ RESEARCH
→ OPPORTUNITY
→ OUTLINE
→ DRAFT
→ FACT_CHECK
→ EDIT
→ PACKAGE
→ LAUNCH
→ MEASURE

Every major transition requires evidence and/or human approval.

## First action

Open:

\`research/RESEARCH-BRIEF.md\`

Then complete:

\`research/DEMAND.md\`

Do not begin the manuscript until the opportunity gate is passed.
EOF

# ------------------------------------------------------------------------------
# Research brief
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/research/RESEARCH-BRIEF.md" <<EOF
# Research Brief

## Topic

$TOPIC

## Target reader

$AUDIENCE

## Desired outcome

$OUTCOME

---

## Research questions

### Problem

- What exact problem does the reader have?
- How frequently does it occur?
- What makes the problem difficult?
- What happens if the reader does nothing?

### Demand

- Are people actively searching for solutions?
- What language do they use?
- What questions repeatedly appear?
- What evidence exists outside book marketplaces?

### Competition

- What books already solve this problem?
- What products, videos, courses, websites, or communities compete for attention?
- What do competing books promise?
- What do readers praise?
- What do readers complain about?

### Opportunity

- What is missing?
- Who is underserved?
- Can the topic be made more specific?
- Can the promise be made more useful?
- What would make the book meaningfully different?

### Commercial viability

- Who would pay for this information?
- Why would they buy a book instead of using free information?
- What additional value does a structured book provide?
- What adjacent products could logically follow?

---

## Evidence requirements

Each major claim should eventually have:

- Source
- URL or reference
- Date checked
- Claim supported
- Confidence level

Avoid treating AI-generated claims as evidence.

---

## Initial hypothesis

> The strongest version of this project will solve a specific problem for a clearly defined reader rather than attempting to appeal to everyone.

---

## Research status

- [ ] Problem documented
- [ ] Demand documented
- [ ] Competition documented
- [ ] Reader complaints documented
- [ ] Gap identified
- [ ] Differentiation defined
- [ ] Commercial case documented

**Gate:** DO NOT PROCEED until sufficient evidence exists.
EOF

# ------------------------------------------------------------------------------
# Demand worksheet
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/research/DEMAND.md" <<EOF
# Demand Evidence

## Core problem

Describe the problem in one sentence.

>

## Evidence

| Source | Evidence | Date | Strength |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

## Reader language

Record the exact terminology readers use.

-
-
-

## Repeated questions

1.
2.
3.
4.
5.

## Pain points

-
-
-

## Buying signals

Look for evidence that people spend money attempting to solve this problem.

-
-
-

## Demand verdict

Choose one:

- [ ] Strong
- [ ] Moderate
- [ ] Weak
- [ ] Unknown

## Gate decision

- [ ] PASS
- [ ] HOLD
- [ ] KILL

### Reason

EOF

# ------------------------------------------------------------------------------
# Opportunity analysis
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/opportunity/OPPORTUNITY.md" <<EOF
# Opportunity Analysis

## Reader

$AUDIENCE

## Problem

What specific problem are we solving?

>

## Existing alternatives

1.
2.
3.
4.

## Competitive weaknesses

| Alternative | Strength | Weakness | Opportunity |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

## Differentiation

Why should this book exist?

>

## Unique promise

Complete this sentence:

> This book helps [reader] achieve [specific result] without [major frustration].

## Risk assessment

### Demand risk

Low / Medium / High

### Competition risk

Low / Medium / High

### Execution risk

Low / Medium / High

### Credibility risk

Low / Medium / High

## Opportunity verdict

- [ ] PROCEED
- [ ] REFINE
- [ ] ABANDON

### Reason

EOF

# ------------------------------------------------------------------------------
# Outline
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/outline/OUTLINE.md" <<EOF
# Book Outline

## Working title

$TOPIC

## Reader

$AUDIENCE

## Transformation

Before:

>

After:

>

---

## Chapter 1 — The Problem

Purpose:

Key questions:

-
-
-

Reader takeaway:

>

## Chapter 2 — The Foundation

Purpose:

Key questions:

-
-
-

Reader takeaway:

>

## Chapter 3 — The Method

Purpose:

Key questions:

-
-
-

Reader takeaway:

>

## Chapter 4 — Implementation

Purpose:

Key questions:

-
-
-

Reader takeaway:

>

## Chapter 5 — Troubleshooting

Purpose:

Key questions:

-
-
-

Reader takeaway:

>

## Chapter 6 — Advanced Use

Purpose:

Key questions:

-
-
-

Reader takeaway:

>

## Final Chapter — Action Plan

The reader should finish knowing exactly what to do next.

---

## Outline gate

- [ ] Every chapter advances the reader toward the promised outcome
- [ ] No filler chapters
- [ ] Claims requiring evidence identified
- [ ] Examples identified
- [ ] Exercises/actions identified
- [ ] Reader transformation is measurable
EOF

# ------------------------------------------------------------------------------
# Manuscript
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/manuscript/MANUSCRIPT.md" <<EOF
# $TOPIC

## Promise

$OUTCOME

---

# Introduction

## Who this book is for

$AUDIENCE

## What the reader will accomplish

$OUTCOME

## Why this book exists

>

---

# Chapter 1

> Draft here.

---

# Chapter 2

> Draft here.

---

# Chapter 3

> Draft here.

---

# Chapter 4

> Draft here.

---

# Chapter 5

> Draft here.

---

# Chapter 6

> Draft here.

---

# Final Action Plan

> Draft here.
EOF

# ------------------------------------------------------------------------------
# Fact checking
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/fact-check/FACT-CHECK.md" <<EOF
# Fact Check

Every factual claim that could materially affect the reader should be checked.

| Claim | Source | Checked | Status |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

## High-risk claims

Pay particular attention to:

- Money
- Legal information
- Medical information
- Statistics
- Dates
- Technical specifications
- Platform policies
- Current prices
- Current software behavior
- Current laws/regulations

## Status

- [ ] Not started
- [ ] In progress
- [ ] Complete

## Gate

- [ ] PASS
- [ ] REVISE
EOF

# ------------------------------------------------------------------------------
# Editing
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/editing/EDITORIAL-CHECK.md" <<EOF
# Editorial Check

## Reader value

- [ ] Every section serves the reader
- [ ] No unnecessary repetition
- [ ] No generic AI filler
- [ ] Examples are useful
- [ ] Instructions are actionable

## Accuracy

- [ ] Claims checked
- [ ] Sources reviewed
- [ ] Outdated information removed
- [ ] Unsupported claims removed

## Writing

- [ ] Clear
- [ ] Direct
- [ ] Consistent
- [ ] Easy to scan
- [ ] Appropriate for the target reader

## Commercial quality

- [ ] Strong title
- [ ] Strong subtitle
- [ ] Clear promise
- [ ] Strong opening
- [ ] Useful table of contents
- [ ] Reader knows what they will gain

## Final decision

- [ ] PASS
- [ ] REVISE
EOF

# ------------------------------------------------------------------------------
# Packaging
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/packaging/PACKAGING.md" <<EOF
# Packaging

## Working title

$TOPIC

## Subtitle

>

## One-sentence promise

>

## Short description

>

## Long description

>

## Keywords

1.
2.
3.
4.
5.
6.
7.

## Categories

1.
2.

## Cover concept

>

## Reader-facing differentiator

>
EOF

# ------------------------------------------------------------------------------
# Launch
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/launch/LAUNCH.md" <<EOF
# Launch Plan

## Product

$TOPIC

## Reader

$AUDIENCE

## Core promise

$OUTCOME

## Launch assets

- [ ] Product description
- [ ] Cover
- [ ] Author description
- [ ] Keywords
- [ ] Categories
- [ ] Preview/sample
- [ ] Social posts
- [ ] Launch announcement
- [ ] Distribution page

## Launch channels

- [ ] Amazon KDP
- [ ] Gumroad
- [ ] Payhip
- [ ] Direct website
- [ ] Relevant communities
- [ ] Social media

Only use channels appropriate to the product and audience.

## Launch gate

- [ ] Product is complete
- [ ] Claims are verified
- [ ] Metadata is accurate
- [ ] Purchase path works
- [ ] Reader promise matches actual product
EOF

# ------------------------------------------------------------------------------
# Metrics
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/metrics/METRICS.md" <<EOF
# Metrics

## Baseline

| Metric | Starting value |
|---|---:|
| Units sold | 0 |
| Revenue | \$0 |
| Reviews | 0 |
| Conversion rate | N/A |

## Tracking

| Date | Units | Revenue | Reviews | Conversion | Notes |
|---|---:|---:|---:|---:|---|
| | | | | | |

## Questions

- Is anyone buying?
- Who is buying?
- What are they responding to?
- What objections appear?
- What should be improved?
- Should the product be updated?
- Is there a logical follow-up product?

## Rule

Do not confuse activity with revenue.

Measure outcomes.
EOF

# ------------------------------------------------------------------------------
# Decision log
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/decisions/DECISIONS.md" <<EOF
# Decision Log

Every important project decision should be recorded here.

---

## $(timestamp)

### Decision

Project created.

### Reason

Topic entered:

> $TOPIC

Target reader:

> $AUDIENCE

Desired outcome:

> $OUTCOME

Starting mode:

> $MODE

### Next gate

RESEARCH
EOF

# ------------------------------------------------------------------------------
# Project index
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/PROJECT-STATUS.md" <<EOF
# Project Status

## $TOPIC

**Status:** ACTIVE

**Current stage:** INTAKE

**Created:** $(timestamp)

---

## Pipeline

| Stage | Status |
|---|---|
| Intake | ✅ Complete |
| Research | ⏳ Next |
| Opportunity | ⬜ Waiting |
| Outline | ⬜ Waiting |
| Draft | ⬜ Waiting |
| Fact Check | ⬜ Waiting |
| Edit | ⬜ Waiting |
| Package | ⬜ Waiting |
| Launch | ⬜ Waiting |
| Measure | ⬜ Waiting |

---

## Immediate next action

Complete:

\`research/RESEARCH-BRIEF.md\`

Then gather evidence in:

\`research/DEMAND.md\`

---

## Hard rule

**No evidence → no publication.**

**No meaningful reader problem → no book.**

**No differentiation → revise the idea.**
EOF

# ------------------------------------------------------------------------------
# Root project manifest
# ------------------------------------------------------------------------------

write_file "$PROJECT_DIR/.gitignore" <<EOF
*.tmp
*.bak
.DS_Store
EOF

# ------------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------------

printf '\n'
printf '%b%s%b\n' "$BOLD" "$ENGINE_NAME" "$RESET"
printf '%s\n\n' "Project initialized successfully."

success "Project: $SLUG"
success "Workspace: $PROJECT_DIR"
success "Mode: $MODE"
success "Startup cost: \$0"

printf '\n%bPipeline%b\n' "$BOLD" "$RESET"
printf '  INTAKE → RESEARCH → OPPORTUNITY → OUTLINE → DRAFT\n'
printf '       → FACT CHECK → EDIT → PACKAGE → LAUNCH → MEASURE\n'

printf '\n%bStart here:%b\n' "$BOLD" "$RESET"
printf '  %s\n' "$PROJECT_DIR/research/RESEARCH-BRIEF.md"

printf '\n%bImportant:%b\n' "$BOLD" "$RESET"
printf '  Do not draft the complete book until demand and differentiation are documented.\n'

printf '\n%bNext command candidates:%b\n' "$BOLD" "$RESET"
printf '  ./scripts/run-pipeline.sh %s research\n' "$SLUG"
printf '  ./scripts/report.sh %s\n' "$SLUG"

printf '\n'
