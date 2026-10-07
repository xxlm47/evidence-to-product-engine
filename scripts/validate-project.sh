#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

info() { echo "INFO: $1"; }
error() { echo "ERROR: $1"; ERRORS=$((ERRORS+1)); }

check_dir() {
  if [ ! -d "$1" ]; then
    error "Missing directory: $1"
  fi
}

check_file() {
  if [ ! -f "$1" ]; then
    error "Missing file: $1"
  fi
}

info "Checking system directory architecture..."
check_dir "$ROOT/prompts"
check_dir "$ROOT/templates"
check_dir "$ROOT/docs"
check_dir "$ROOT/scripts"
check_file "$ROOT/config/settings.json"
check_file "$ROOT/new-project.sh"

if [ ! -d "$ROOT/work" ] && [ ! -d "$ROOT/projects" ]; then
  error "Missing workspace directory (neither work/ nor projects/ found)"
fi

info "Checking shell script syntax..."
for script in "$ROOT"/scripts/*.sh "$ROOT/new-project.sh"; do
  if [ -f "$script" ]; then
    if ! bash -n "$script"; then
      error "Syntax error in $script"
    fi
  fi
done

info "Running functional launcher test..."
TEST_SLUG="val-test-project-$$"
TEST_DIR="$ROOT/work/$TEST_SLUG"

if "$ROOT/new-project.sh" -t "$TEST_SLUG" -a "Test Audience" -o "Test Outcome" -m research >/dev/null 2>&1; then
  if [ -f "$TEST_DIR/project.json" ] && [ -f "$TEST_DIR/research/RESEARCH-BRIEF.md" ]; then
    info "Launcher execution test: PASSED"
  else
    error "Launcher execution created incomplete workspace structure"
  fi
  if [ -f "$TEST_DIR/project.json" ]; then
    if "$ROOT/scripts/run-pipeline.sh" "$TEST_SLUG" launch >/dev/null 2>&1; then
      READY="$TEST_DIR/launch/READY-TO-PUBLISH.md"
      if [ -f "$READY" ] && grep -q "NOT CLEARED" "$READY"; then
        info "Pipeline readiness default: PASSED"
      else
        error "Pipeline did not create an explicitly uncleared readiness review"
      fi

      printf '\nVALIDATOR_SENTINEL: preserve this user review note\n' > "$READY"
      if "$ROOT/scripts/run-pipeline.sh" "$TEST_SLUG" launch >/dev/null 2>&1 && grep -q "VALIDATOR_SENTINEL" "$READY"; then
        info "Pipeline preserves existing readiness review: PASSED"
      else
        error "Pipeline overwrote an existing readiness review"
      fi
    else
      error "Pipeline launch scaffolding failed"
    fi
  fi

  if "$ROOT/scripts/run-pipeline.sh" "../$TEST_SLUG" research >/dev/null 2>&1; then
    error "Pipeline accepted a path-traversal project slug"
  else
    info "Pipeline rejects unsafe project slugs: PASSED"
  fi

  rm -rf "$TEST_DIR"
else
  error "Launcher execution test failed"
fi

if [ "$ERRORS" -ne 0 ]; then
  echo "Validation failed with $ERRORS error(s)."
  exit 1
fi

echo "Evidence-to-Product Engine structure & functionality: OK"
echo "Startup-cost policy: \$0"
echo "Publication gate: human approval required"
