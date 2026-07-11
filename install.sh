#!/usr/bin/env bash
# goat-herd installer
# Copies agents into <target>/.claude/agents/. Idempotent: re-running overwrites
# previously installed copies with the current versions.
#
# Usage:
#   ./install.sh /path/to/your-project                        # install all 8 agents
#   ./install.sh /path/to/your-project bug-hunter migrator    # install selected agents
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)/agents"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <target-project-dir> [agent-name ...]" >&2
  echo "Available agents:" >&2
  for a in "$SRC_DIR"/*.md; do
    echo "  - $(basename "$a" .md)" >&2
  done
  exit 1
fi

TARGET="$1"
shift

if [ ! -d "$TARGET" ]; then
  echo "Error: target directory '$TARGET' does not exist." >&2
  exit 1
fi

DEST="$TARGET/.claude/agents"
mkdir -p "$DEST"

install_agent() {
  a="$1"
  if [ ! -f "$SRC_DIR/$a.md" ]; then
    echo "Error: unknown agent '$a'. Run without agent names to list available ones." >&2
    exit 1
  fi
  cp "$SRC_DIR/$a.md" "$DEST/$a.md"
  echo "  installed: $a"
}

echo "Installing into $DEST"
if [ $# -eq 0 ]; then
  for a in "$SRC_DIR"/*.md; do
    install_agent "$(basename "$a" .md)"
  done
else
  for a in "$@"; do
    install_agent "$a"
  done
fi

echo ""
echo "Done. Notes:"
echo "  - Each agent's description consumes a little context; install only what you will use."
echo "  - Read guides/briefing.md before delegating: results depend on the brief."
echo "  - Fresh-context verification and diff review live in goat-fable (verifier, code-reviewer)."
echo "  - Recommended for Opus 4.8 users: /model claude-opus-4-8 and /effort xhigh."
