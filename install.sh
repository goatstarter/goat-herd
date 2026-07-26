#!/usr/bin/env bash
# goat-herd installer
#
# Installs skills into <target>/.claude/skills/.
# Idempotent: re-running overwrites previously installed copies with the current versions.
#
# This script only ever writes inside the target directory you name. It touches nothing in
# your home directory and needs no elevated permissions.
#
# Usage:
#   ./install.sh /path/to/your-project                  # everything
#   ./install.sh /path/to/your-project <skill> [...]    # selected skills
#   ./install.sh --list                                 # show available skills
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SRC/skills"

list_skills() {
  for s in "$SKILLS_DIR"/*/; do
    [ -d "$s" ] || continue
    name="$(basename "${s%/}")"
    desc="$(sed -n 's/^description: *//p' "$s/SKILL.md" 2>/dev/null | head -1 | cut -c1-86)"
    printf '  %-24s %s\n' "$name" "$desc"
  done
}

if [ "${1:-}" = "--list" ]; then
  echo "goat-herd skills:"
  list_skills
  exit 0
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 <target-project-dir> [skill-name ...]" >&2
  echo "       $0 --list" >&2
  echo "" >&2
  echo "Available skills:" >&2
  list_skills >&2
  exit 1
fi

TARGET="$1"
shift

if [ ! -d "$TARGET" ]; then
  echo "Error: target directory '$TARGET' does not exist." >&2
  exit 1
fi

SKILL_DEST="$TARGET/.claude/skills"
mkdir -p "$SKILL_DEST"

install_skill() {
  s="$1"
  if [ ! -d "$SKILLS_DIR/$s" ]; then
    echo "Error: unknown skill '$s'. Run with --list to see available ones." >&2
    exit 1
  fi
  rm -rf "${SKILL_DEST:?}/$s"
  cp -R "$SKILLS_DIR/$s" "$SKILL_DEST/$s"
  rm -rf "${SKILL_DEST:?}/$s/evals"
  echo "  installed skill: $s"
}

if [ $# -eq 0 ]; then
  for s in "$SKILLS_DIR"/*/; do
    [ -d "$s" ] || continue
    install_skill "$(basename "${s%/}")"
  done
else
  for s in "$@"; do
    install_skill "$s"
  done
fi

echo ""
echo "Done. Notes:"
echo "  - The eight agent definitions under agents/ already carry output contracts. Read one before briefing it."
echo "  - fan-out first, brief-subagent second. Deciding not to delegate is a valid outcome."
echo "  - Two agents editing one file is the work you were trying to delegate."
echo "  - Skills auto-trigger from their descriptions, in English or Turkish, or invoke them"
echo "    manually with /<skill-name>."
echo "  - Each installed skill's description costs a little context. Install what you will use."
echo "  - Recommended for Opus 4.8 users: /model claude-opus-4-8 and /effort xhigh."
