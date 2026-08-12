# Learning Notes

Concepts and tools encountered while building this project. Updated in the same commit as the
code/infra changes that introduced them.

## Explicitly asked about

### Claude Code Skills — anatomy and progressive disclosure

A "skill" is a packaged instruction set Claude loads on demand, not all at once. It has three
loading tiers:

1. **Metadata** (the `name` + `description` in the YAML frontmatter) — always in context, cheap
   (~100 words), and it's the *only* thing Claude uses to decide whether to trigger the skill at
   all. This is why skill descriptions are written a bit "pushy" — listing lots of concrete
   trigger phrases — rather than a terse one-liner: undertriggering is the more common failure
   mode than overtriggering.
2. **SKILL.md body** — pulled into context only once the skill actually triggers. Kept under
   ~500 lines by convention; if it grows past that, split detail out into `references/*.md` and
   leave pointers in the body telling Claude when to go read them.
3. **Bundled resources** (`scripts/`, `references/`, `assets/`) — loaded/executed only as needed,
   effectively unlimited size. Scripts can run without ever being read into context, which is
   useful for deterministic/repetitive work (e.g. a script that packages the skill itself).

This is a similar tradeoff to lazy-loading in software generally (e.g. dynamic imports, or
paginated API responses) — you pay context/latency cost only for what you actually use.

**Compare to something familiar:** it's a lot like how a well-organized codebase has a top-level
README (always read), module-level docs (read when you touch that module), and deep
implementation details (read only if you're debugging that specific thing) — skills just make
that discipline mandatory rather than optional, because the "reader" (the model's context
window) is a genuinely scarce resource.

### Claude Code plugin marketplaces

`/plugin marketplace add <owner>/<repo>` registers a GitHub repo as a source of installable
plugins (each plugin can bundle skills, agents, hooks, etc.), and `/plugin install <plugin>@<marketplace>`
installs one. This session used `anthropics/skills` as the marketplace and installed the
`skill-creator` plugin from it, which is itself a skill for building other skills — a
meta-tool. Conceptually this is close to a package registry (think npm/pip, or a Terraform
module registry) but scoped to "packages" that extend the coding agent's own behavior rather
than a runtime library.

## Learned along the way (not explicitly asked, but relevant)

### Adaptive testing / difficulty calibration

The quiz design in `codebase-quiz` uses a simple one-step-at-a-time adaptive ladder: move one
difficulty level up on a strong answer, one down on a weak one, hold on a partial. This is a
lightweight version of the same idea behind adaptive standardized tests (e.g. the GRE) —
converge on a user's true skill level faster than a fixed-question exam by adjusting difficulty
based on responses, rather than asking everyone the same fixed set.

### Git SHA-based staleness detection

Instead of re-scanning an entire codebase on every run, `codebase-quiz` stamps its generated
`DESIGN_PRINCIPLES.md` with the git commit SHA it was written at, and on the next run does
`git diff --name-only <old-sha> HEAD` to see exactly what changed. This is the same principle
behind incremental builds (only recompile what changed) and behind how tools like `dbt` or
Terraform decide what to re-plan — cheap, precise change detection beats an expensive full
re-derivation when you already have a reliable "as-of" marker to diff against.
