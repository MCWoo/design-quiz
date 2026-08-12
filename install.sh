#!/usr/bin/env bash
# Installs the codebase-quiz skill into Claude Code's global skills directory.
#
# Prefers a symlink so edits made in this repo take effect immediately without
# reinstalling. Falls back to a copy if symlinks aren't available.
#
# Safe to re-run: if the skill is already installed and up to date, it's a no-op.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./install.sh [-f|--force] [-c|--copy] [-h|--help]

  -f, --force   Overwrite an existing install (stale copy, or a symlink
                pointing somewhere else).
  -c, --copy    Install as a plain copy instead of a symlink. A copy needs
                -f/--force to pick up future edits.
  -h, --help    Show this help.
EOF
}

force=false
copy=false

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force) force=true; shift ;;
        -c|--copy) copy=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_name="codebase-quiz"
source_dir="$script_dir/dotclaude/skills/$skill_name"
skills_root="$HOME/.claude/skills"
target="$skills_root/$skill_name"

if [ ! -d "$source_dir" ]; then
    echo "Source skill not found at $source_dir. Run this script from the project root." >&2
    exit 1
fi

mkdir -p "$skills_root"

if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source_dir" ] && ! $copy; then
        echo "Already installed (symlink -> $source_dir). Nothing to do."
        exit 0
    fi

    # If it's a plain copy (not a symlink), check whether it already matches the
    # source before demanding -f/--force -- a copy install should be a no-op when
    # it's already up to date, not require force just to confirm that.
    if [ ! -L "$target" ] && diff -rq "$source_dir" "$target" >/dev/null 2>&1; then
        echo "Already installed as an up-to-date copy at $target. Nothing to do."
        exit 0
    fi

    if ! $force; then
        echo "$target already exists and is out of date (or isn't this repo's copy). Re-run with -f/--force to overwrite it." >&2
        exit 1
    fi

    rm -rf "$target"
fi

if $copy; then
    cp -r "$source_dir" "$target"
    echo "Installed $skill_name as a copy at $target."
    echo "Note: edits in this repo won't show up until you re-run './install.sh -f -c'."
    exit 0
fi

# On Windows, git-bash's `ln -s` can exit 0 without lacking privilege and yet
# silently produce a plain copy instead of a real symlink (rather than erroring),
# so check what actually landed before trusting the exit code.
if ln -s "$source_dir" "$target" 2>/dev/null && [ -L "$target" ]; then
    echo "Installed $skill_name as a symlink: $target -> $source_dir"
    echo "Edits to files in this repo take effect immediately."
else
    echo "Warning: couldn't create a real symlink. Falling back to a copy." >&2
    rm -rf "$target"
    cp -r "$source_dir" "$target"
    echo "Installed $skill_name as a copy at $target."
    echo "Note: edits in this repo won't show up until you re-run './install.sh -f -c'."
fi
