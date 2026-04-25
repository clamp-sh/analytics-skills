#!/usr/bin/env bash
# Symlink each skill in this repo into ~/.claude/skills/.
# Running `git pull` in the repo then updates every installed skill atomically.
#
# Usage:
#   ./scripts/install-personal.sh         # install for current user (~/.claude/skills)
#   ./scripts/install-personal.sh --dry   # print what would happen, change nothing

set -euo pipefail

DRY=0
if [[ "${1:-}" == "--dry" ]]; then
  DRY=1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/skills"
DEST="$HOME/.claude/skills"

if [[ ! -d "$SRC" ]]; then
  echo "error: no skills directory at $SRC" >&2
  exit 1
fi

mkdir -p "$DEST"

installed=0
skipped=0

for skill_path in "$SRC"/*/; do
  skill_name="$(basename "$skill_path")"
  target="$DEST/$skill_name"

  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "skip: $skill_name (exists as a real directory, refusing to overwrite)"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -L "$target" ]]; then
    current="$(readlink "$target")"
    if [[ "$current" == "$skill_path"* ]]; then
      echo "ok:   $skill_name (already linked)"
      continue
    fi
  fi

  if [[ $DRY -eq 1 ]]; then
    echo "dry:  would link $skill_name -> $skill_path"
  else
    ln -sfn "$skill_path" "$target"
    echo "link: $skill_name -> $skill_path"
    installed=$((installed + 1))
  fi
done

echo ""
if [[ $DRY -eq 1 ]]; then
  echo "dry run complete. rerun without --dry to apply."
else
  echo "installed: $installed, skipped: $skipped"
  echo "restart Claude Code or run /reload-plugins to pick up new skills."
fi
