#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-}"

if [ -z "$TARGET" ]; then
  echo "Usage: ./scripts/report.sh <slug>"
  echo "       ./scripts/report.sh work/<slug>"
  echo "       ./scripts/report.sh projects/<slug>"
  exit 1
fi

if [ -d "$ROOT/$TARGET" ]; then
  DIR="$ROOT/$TARGET"
elif [ -d "$ROOT/work/$TARGET" ]; then
  DIR="$ROOT/work/$TARGET"
elif [ -d "$ROOT/projects/$TARGET" ]; then
  DIR="$ROOT/projects/$TARGET"
else
  echo "Project not found: $TARGET"
  exit 1
fi

echo "=== EVIDENCE-TO-PRODUCT ENGINE REPORT ==="
echo "Project: $DIR"

if [ -f "$DIR/project.json" ]; then
  echo
  cat "$DIR/project.json"
fi

echo
for section in research opportunity outline manuscript fact-check editing packaging launch metrics decisions; do
  if [ -d "$DIR/$section" ]; then
    count=$(find "$DIR/$section" -type f 2>/dev/null | wc -l | tr -d ' ')
    printf '%-16s %s file(s)\n' "$section:" "$count"
  fi
done

echo
if [ -f "$DIR/manuscript/MANUSCRIPT.md" ]; then
  words=$(wc -w < "$DIR/manuscript/MANUSCRIPT.md" | tr -d ' ')
  echo "Manuscript words: $words"
elif [ -f "$DIR/manuscript/book.md" ]; then
  words=$(wc -w < "$DIR/manuscript/book.md" | tr -d ' ')
  echo "Manuscript words: $words"
fi

echo "Startup cost policy: \$0"
echo "Human approval: required before publication"
