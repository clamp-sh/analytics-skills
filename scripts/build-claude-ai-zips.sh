#!/usr/bin/env bash
# Build one zip per skill for claude.ai upload.
# claude.ai expects each skill as its own archive containing a SKILL.md at the top level.
#
# Usage:
#   ./scripts/build-claude-ai-zips.sh
# Output:
#   dist/<skill-name>.zip

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/skills"
DIST="$ROOT/dist"

if [[ ! -d "$SRC" ]]; then
  echo "error: no skills directory at $SRC" >&2
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "error: 'zip' not found on PATH" >&2
  exit 1
fi

rm -rf "$DIST"
mkdir -p "$DIST"

built=0
for skill_path in "$SRC"/*/; do
  skill_name="$(basename "$skill_path")"
  out="$DIST/$skill_name.zip"

  (cd "$SRC" && zip -qr "$out" "$skill_name")
  size="$(du -h "$out" | cut -f1)"
  echo "built: $out ($size)"
  built=$((built + 1))
done

echo ""
echo "$built zip(s) ready in $DIST"
echo "upload each at https://claude.ai/settings/features (Skills section)"
