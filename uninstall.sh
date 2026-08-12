#!/usr/bin/env bash
# Removes the codebase-quiz skill from Claude Code's global skills directory.
# Safe to re-run: if it's already gone, it's a no-op.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./uninstall.sh [-h|--help]

  -h, --help    Show this help.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

skill_name="codebase-quiz"
target="$HOME/.claude/skills/$skill_name"

if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    echo "$skill_name isn't installed at $target. Nothing to do."
    exit 0
fi

rm -rf "$target"
echo "Removed $skill_name from $target."
