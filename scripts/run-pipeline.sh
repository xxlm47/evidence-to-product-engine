#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: ./scripts/run-pipeline.sh <project-slug> [stage]"
  echo
  echo "Stages: research opportunity outline drafting fact-check edit packaging launch all"
  echo "Example: ./scripts/run-pipeline.sh my-book-idea all"
}

SLUG="${1:-}"
STAGE="${2:-all}"
[ -n "$SLUG" ] || { usage; exit 1; }

if [ -d "$ROOT/work/$SLUG" ]; then
  DIR="$ROOT/work/$SLUG"
elif [ -d "$ROOT/projects/$SLUG" ]; then
  DIR="$ROOT/projects/$SLUG"
else
  echo "Project not found in work/$SLUG or projects/$SLUG"
  echo "Run ./scripts/new-project.sh first."
  exit 1
fi

mkdir -p "$DIR"/{research,opportunity,outline,manuscript,fact-check,editing,packaging,launch,metrics,decisions}

write_if_missing() {
  local file="$1"
  local title="$2"
  if [ ! -f "$file" ]; then
    cat > "$file" <<EOF
# $title

Project: $SLUG

Complete this stage using the relevant prompt in the \`prompts/\` directory.

## Evidence / output

- 
EOF
  fi
}

stage_research() {
  write_if_missing "$DIR/research/RESEARCH-BRIEF.md" "Research Brief"
  write_if_missing "$DIR/research/DEMAND.md" "Demand Evidence"
}

stage_opportunity() {
  write_if_missing "$DIR/opportunity/OPPORTUNITY.md" "Opportunity Analysis"
}

stage_outline() {
  write_if_missing "$DIR/outline/OUTLINE.md" "Book Outline"
}

stage_drafting() {
  write_if_missing "$DIR/manuscript/MANUSCRIPT.md" "Manuscript"
}

stage_fact_check() {
  write_if_missing "$DIR/fact-check/FACT-CHECK.md" "Fact Check"
}

stage_edit() {
  write_if_missing "$DIR/editing/EDITORIAL-CHECK.md" "Editorial Check"
}

stage_packaging() {
  write_if_missing "$DIR/packaging/PACKAGING.md" "Packaging"
}

stage_launch() {
  write_if_missing "$DIR/launch/LAUNCH.md" "Launch Plan"
  write_if_missing "$DIR/metrics/METRICS.md" "Metrics"
  cat > "$DIR/launch/READY-TO-PUBLISH.md" <<EOF
# READY TO PUBLISH

This file is a gate, not an automatic publishing command.

## Human approval required

Before publishing, confirm:

- [ ] Demand evidence is documented.
- [ ] Differentiation is documented.
- [ ] Manuscript is complete.
- [ ] Facts and current platform/software claims were checked.
- [ ] Copyright/trademark concerns were reviewed.
- [ ] Cover rights were reviewed.
- [ ] KDP AI disclosure was considered where applicable.
- [ ] Metadata accurately describes the book.
- [ ] Price and royalty implications were checked against current platform terms.
- [ ] Final manuscript was personally reviewed.
- [ ] Publisher explicitly approves publication.

**Publication status: HUMAN APPROVAL REQUIRED**
EOF
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
  *) usage; exit 1 ;;
esac

cat > "$DIR/PIPELINE-STATUS.md" <<EOF
# Pipeline Status

Project: $SLUG
Last requested stage: $STAGE

Generated workspace artifacts. Content generation and publication remain subject to research quality and human review.

## Next action

Open the project's current stage file and complete it using the corresponding prompt under the \`prompts/\` directory.
EOF

echo "Pipeline workspace ready: $DIR"
echo "Stage: $STAGE"
echo "Startup cost: \$0"
echo "Publication: human approval required"
