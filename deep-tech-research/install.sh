#!/usr/bin/env bash
# Installs the deep-tech-research skill for Claude Code (personal scope).
# Run from inside the unzipped bundle directory.
set -euo pipefail

DEST="$HOME/.claude/skills"
NAME="deep-tech-research"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/deep-tech-research-source"

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "error: $SRC/SKILL.md not found — run this from inside the unzipped bundle" >&2
  exit 1
fi

if [ -e "$DEST/$NAME" ]; then
  echo "A skill named $NAME already exists at $DEST/$NAME"
  read -r -p "Overwrite it? [y/N] " reply
  case "$reply" in
    [yY]*) rm -rf "$DEST/$NAME" ;;
    *) echo "aborted"; exit 1 ;;
  esac
fi

mkdir -p "$DEST"
cp -r "$SRC" "$DEST/$NAME"

echo "installed -> $DEST/$NAME"
echo
echo "next:"
echo "  1. start a NEW session:  claude"
echo "  2. confirm it loaded:    /skills"
echo "  3. check context budget: /doctor      <- do this before any trigger test"
echo "  4. run the tests in test-order.md"
