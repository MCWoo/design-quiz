# codebase-quiz

A Claude Code skill that turns any codebase into a personal, adaptive study session on the
design decisions actually baked into it — algorithms, data structures, design patterns,
platform idioms, architecture choices, and whatever else the code demonstrates.

## How it works

Two phases, both handled by the skill:

1. **Extract.** Claude reads the target codebase and writes what it finds to
   `.claude/codebase-quiz/DESIGN_PRINCIPLES.md` in that repo, one entry per principle: what it
   is, where it shows up in the code, its category, and a difficulty rating. On later runs, if
   the target is a git repo, Claude diffs against the commit SHA stamped in that file instead of
   re-scanning everything from scratch.
2. **Quiz.** Claude asks open-ended questions grounded in the extracted principles, grades the
   user's free-text answers out loud, and adjusts difficulty one level at a time based on how the
   answer landed. Progress per category is tracked in `.claude/codebase-quiz/progress.md` so
   sessions pick back up near where the last one left off. Any answer that was partial or weak
   gets a short pointer logged to the target repo's own `LEARNING_NOTES.md`, under a
   `## Codebase Quiz — to review` section, so there's a durable "what to study next" list.

Sessions are open-ended — they run until the user says to stop, not for a fixed number of
questions. If the user asks a question of their own mid-quiz instead of answering, Claude answers
it in full before returning to the original question — it's treated as engagement, not scored
either way.

Explaining *why* a design choice was made is exactly the kind of scrutiny that sometimes turns up
a real problem rather than a teaching moment — a bug, an inconsistency, a pattern the codebase
claims to follow but doesn't everywhere. When that happens, Claude logs it to
`.claude/codebase-quiz/IMPROVEMENT_IDEAS.md`, kept deliberately separate from `LEARNING_NOTES.md`
since one tracks gaps in the code and the other tracks gaps in the user's understanding.

The full behavior lives in [`dotclaude/skills/codebase-quiz/SKILL.md`](dotclaude/skills/codebase-quiz/SKILL.md);
this README won't duplicate it.

### Difficulty levels

`basic` → `coding-bootcamp` → `bachelors-degree` → `early-professional` →
`experienced-professional` → `subject-matter-expert`

### Categories

Categories are discovered from the codebase being studied, not fixed — but common ones include
algorithms, data structures, design patterns, platform/language specifics, architecture, and
concurrency & performance.

## Install / Uninstall

The skill is developed here and installed into Claude Code's global skills directory
(`~/.claude/skills/`). Both platforms' scripts default to a **symlink**, so edits made in this
repo take effect immediately without reinstalling. All four scripts are idempotent — safe to
re-run.

**Windows (PowerShell):**

```powershell
./install.ps1              # symlink install
./install.ps1 -Force       # overwrite an existing install (e.g. a stale copy)
./install.ps1 -Copy -Force # install as a plain copy instead of a symlink
./uninstall.ps1
```

**macOS / Linux / git-bash:**

```bash
./install.sh                  # symlink install
./install.sh -f                # overwrite an existing install
./install.sh -c -f             # install as a plain copy instead of a symlink
./uninstall.sh
```

If a copy install is used (`-Copy`/`-c`), future edits in this repo won't show up until you
re-run install with `-Force`/`-f` (and `-Copy`/`-c` again). Symlink installs need Developer Mode
enabled on Windows (Settings > Update & Security > For developers) or an elevated shell — if
symlink creation fails, the install scripts fall back to a copy automatically and say so.

Run `-Help`/`-h` on any script for full flag details.

## Usage

Once installed, invoke it from any project by just asking — no special syntax required:

> "Quiz me on this codebase's design patterns"
> "Help me understand the design decisions in this repo"
> "Test my understanding of this project's architecture"

Claude will extract/refresh the design principles file if needed, ask which category to study
(picking from what it actually found in the codebase), and start the adaptive quiz.
