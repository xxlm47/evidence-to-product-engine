#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage: ./scripts/run-pipeline.sh <project-slug> [stage]

Stages: research opportunity outline drafting fact-check edit packaging launch all
Example: ./scripts/run-pipeline.sh my-project research

This command scaffolds missing files; it does not perform research, complete a
stage, validate demand, or publish anything. Existing files are never replaced.
USAGE
}

SLUG="${1:-}"
STAGE="${2:-all}"

if [[ -z "$SLUG" ]]; then
  usage
  exit 2
fi

# Slugs are directory names, never paths. Reject traversal and unexpected names.
if [[ ! "$SLUG" =~ ^[a-z0-9][a-z0-9-]{0,69}$ ]]; then
  echo "ERROR: Invalid project slug '$SLUG'." >&2
  echo "Use 1-70 lowercase letters, numbers, and hyphens; begin with a letter or number." >&2
  exit 2
fi

case "$STAGE" in
  research|opportunity|outline|drafting|fact-check|edit|packaging|launch|all) ;;
  *) usage; exit 2 ;;
esac

if [[ -d "$ROOT/work/$SLUG" ]]; then
  DIR="$ROOT/work/$SLUG"
elif [[ -d "$ROOT/projects/$SLUG" ]]; then
  DIR="$ROOT/projects/$SLUG"
else
  echo "Project not found in work/$SLUG or projects/$SLUG" >&2
  echo "Run ./scripts/new-project.sh first." >&2
  exit 1
fi

mkdir -p "$DIR"/{research,opportunity,outline,manuscript,fact-check,editing,packaging,launch,metrics,decisions}

write_if_missing() {
  local file="$1"
  local title="$2"
  if [[ ! -f "$file" ]]; then
    cat > "$file" <<EOF
# $title

Project: $SLUG

Complete this stage using the relevant prompt in the prompts/ directory.

## Evidence / output

TODO: Replace this placeholder with the actual work. Do not mark this stage complete until the output has been reviewed.
EOF
    echo "Created: ${file#"$ROOT/"}"
  fi
}

stage_research() {
  write_if_missing "$DIR/research/RESEARCH-BRIEF.md" "Research Brief"
  write_if_missing "$DIR/research/DEMAND.md" "Demand Evidence"
}
stage_opportunity() { write_if_missing "$DIR/opportunity/OPPORTUNITY.md" "Opportunity Analysis"; }
stage_outline() { write_if_missing "$DIR/outline/OUTLINE.md" "Product Outline"; }
stage_drafting() { write_if_missing "$DIR/manuscript/MANUSCRIPT.md" "Product Manuscript"; }
stage_fact_check() { write_if_missing "$DIR/fact-check/FACT-CHECK.md" "Fact Check"; }
stage_edit() { write_if_missing "$DIR/editing/EDITORIAL-CHECK.md" "Editorial Check"; }
stage_packaging() { write_if_missing "$DIR/packaging/PACKAGING.md" "Product Packaging"; }

stage_launch() {
  write_if_missing "$DIR/launch/LAUNCH.md" "Launch Plan"
  write_if_missing "$DIR/metrics/METRICS.md" "Metrics and Feedback"
  # Create the readiness template once; never overwrite user review notes.
  if [[ ! -f "$DIR/launch/READY-TO-PUBLISH.md" ]]; then
    cat > "$DIR/launch/READY-TO-PUBLISH.md" <<EOF
# Publication Readiness Review

Project: $SLUG

**Status: NOT CLEARED — this template is not evidence of readiness.**

Complete every check with links or notes pointing to the actual reviewed artifacts.
An unchecked or undocumented item means publication is not cleared.

## Evidence and product gates

- [ ] Demand evidence is recorded with source URLs, dates, and observed facts.
- [ ] The opportunity decision explains evidence, uncertainty, alternatives, and a go/no-go rationale.
- [ ] The product delivers the promised reader/customer outcome.
- [ ] The complete product artifact exists and has been reviewed.
- [ ] Material factual claims have been checked against reliable, current sources.
- [ ] Rights, licenses, privacy, and trademark concerns have been reviewed.
- [ ] Metadata and marketing claims are accurate and substantiated.
- [ ] Current platform rules, pricing, and disclosure requirements have been checked.
- [ ] A human has reviewed the final package.

## Human approval

- Reviewer:
- Review date:
- Decision and notes:

**Publication status: NOT CLEARED until all applicable checks are completed and a human explicitly approves.**
EOF
  fi
}

case "$STAGE" in
  research) stage_research ;;
  opportunity) stage_research; stage_opportunity ;;
  outline) stage_research; stage_opportunity; stage_outline ;;
  drafting) stage_research; stage_opportunity; stage_outline; stage_drafting ;;
  fact-check) stage_research; stage_opportunity; stage_outline; stage_drafting; stage_fact_check ;;
  edit) stage_research; stage_opportunity; stage_outline; stage_drafting; stage_fact_check; stage_edit ;;
  packaging) stage_research; stage_opportunity; stage_outline; stage_drafting; stage_fact_check; stage_edit; stage_packaging ;;
  launch) stage_research; stage_opportunity; stage_outline; stage_drafting; stage_fact_check; stage_edit; stage_packaging; stage_launch ;;
  all) stage_research; stage_opportunity; stage_outline; stage_drafting; stage_fact_check; stage_edit; stage_packaging; stage_launch ;;
esac

cat > "$DIR/PIPELINE-STATUS.md" <<EOF
# Pipeline Workspace Status

Project: $SLUG
Last scaffold request: $STAGE

**This is a workspace-generation status, not a completion or quality status.**

The command creates missing templates only. It does not perform research, verify evidence, write product content, complete quality checks, or publish.

## Next action

Review the current stage artifact and replace TODO placeholders with work supported by traceable evidence. Do not proceed to full production until the documented opportunity gate passes. Publication always requires a separate human review and explicit approval.
EOF

echo "Pipeline workspace scaffolded: $DIR"
echo "Requested stage: $STAGE"
echo "No research, validation, stage completion, or publication was performed."
echo "Startup-cost target: $0"
echo "Publication: NOT CLEARED until reviewed and explicitly approved"
