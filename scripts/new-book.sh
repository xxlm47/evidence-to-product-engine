#!/usr/bin/env bash
# ==============================================================================
# EVIDENCE-TO-PRODUCT ENGINE — NEW BOOK (COMPATIBILITY WRAPPER)
#
# This script is retained for backward compatibility. It delegates to the
# canonical launcher so every project uses the same directory layout and the
# same machine-readable project.json schema.
#
# Prefer:  ./scripts/new-project.sh
# ==============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

exec "$ROOT/scripts/new-project.sh" "$@"
