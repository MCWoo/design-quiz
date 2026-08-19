---
name: codebase-quiz
description: >
  Reads a codebase, extracts the design principles actually embodied in it (algorithms,
  data structures, design patterns, platform/language idioms, architecture choices, etc.),
  writes them to a durable markdown file, and then quizzes the user on them with open-ended
  questions that adapt in difficulty as the user answers. Use this whenever the user wants to
  learn from, study, understand, or be quizzed/tested on a codebase's design — phrases like
  "quiz me on this codebase", "help me understand the design decisions here", "test my
  understanding of this repo's architecture", "what design patterns are used here and can you
  teach me about them", or "I want to learn from how this project is built" should all trigger
  this skill, even if the user doesn't name it directly. Also use it when picking back up a
  previous quiz session (a progress file will already exist).
---

# Codebase Quiz

Turn a codebase into a personal, adaptive study session. Two phases: (1) extract the design
principles the codebase actually demonstrates into a markdown reference file, (2) use that file
to run an open-ended, orally-graded quiz whose difficulty adapts to the user in real time.

The point isn't to test trivia about this specific repo — it's to use the repo as a concrete
anchor for teaching transferable concepts (a particular caching strategy here is really a lesson
about cache invalidation in general; a particular class hierarchy here is really a lesson about
when composition beats inheritance). Keep that in mind throughout: the codebase is the example,
not the syllabus.

Reading a codebase this closely — during extraction and during the back-and-forth of a quiz —
sometimes surfaces something that isn't a *teaching* point at all but a genuine flaw: a bug, an
inconsistency between two places that should agree, a missed best practice. That's a different
kind of finding from "the user doesn't know this yet," and it gets logged separately — see
"Surfacing codebase improvements" below.

## Phase 1: Extract design principles

### Locate or create the principles file

Check for an existing principles file first, at `.claude/codebase-quiz/DESIGN_PRINCIPLES.md`
relative to the repo root being studied. This file is meant to be committed and to persist
across sessions — regenerating it from scratch every time throws away a discoverable history of
what's already been covered and wastes the read-through work.

The file's header records the git commit SHA it was extracted at (see File format below). Use
that to decide how much work a refresh actually needs:

- **If it doesn't exist**: do a full extraction pass (below) and write it fresh, stamped with
  the current `git rev-parse HEAD` (short SHA is fine).
- **If it exists and the repo is a git repo**: run `git diff --name-only <stored-sha> HEAD` (or
  `git log <stored-sha>..HEAD --stat` if you want commit context too) to see exactly what
  changed since the file was last written. Only re-read those files/directories and merge in
  principles for what changed — no need to re-scan the whole tree. If the stored SHA no longer
  exists in history (e.g. after a rebase/force-push), fall back to the no-git heuristic below.
  Update the stamped SHA to current `HEAD` once the merge is done.
- **If it exists but there's no git repo, or the SHA isn't available**: fall back to
  spot-checking a handful of the files/paths the file references — if they still exist and
  roughly match, reuse the file as-is aside from folding in anything obviously new; if paths
  don't resolve at all, treat it as a full regeneration.
- **Either way**, keep the old progress log (see Phase 2) intact across a refresh — it tracks
  the user's learning, not the code, so it shouldn't reset just because the codebase moved on.

### How to extract

Read the whole codebase, not a sample of it. Start with directory structure and entry points to
orient yourself, but then actually work through every source file (excluding generated code,
vendored dependencies, build output, and binary/data assets) — not just the files that look
interesting from their names or the ones with the most git churn. A subtle but important design
decision can live in a 40-line file nobody would guess to open, and "I read the obviously
important-looking files" quietly turns into "I only found what I already expected to find."
You're looking for decisions, not just facts. "This file has a `UserService` class" is not a
design principle. "This codebase separates data access from business logic via a repository
pattern, and the reason appears to be X" is.

For anything beyond a small codebase, reading every file yourself in one linear pass is slow and
prone to fatigue-skimming toward the end. Prefer fanning the work out to a handful of subagents in
parallel, each assigned a distinct slice of the tree (by module/package/directory — pick a split
that keeps slices roughly balanced in size). Give each one the same extraction criteria as this
section and have it report back principle candidates (with file/line references, category, and
difficulty) plus any improvement-idea candidates, rather than writing files directly — you merge
their findings into the one `DESIGN_PRINCIPLES.md` yourself afterward, so the final file reads as
one coherent document instead of stitched-together fragments with inconsistent voice or
duplicated principles found by more than one subagent. On a refresh where only a few files changed
(see above), this fan-out usually isn't necessary — a direct read of the diff is faster.

While reading, if something looks less like "a decision worth teaching" and more like an actual
flaw — a real bug, two places that quietly disagree, a spot where the codebase's own stated
pattern isn't followed — don't fold it into a principle entry. Log it per "Surfacing codebase
improvements" below instead, and keep reading; extraction isn't the place to go fix it.

For each principle found, capture:
- **What it is** — the concept in general terms (e.g. "Strategy pattern", "B-tree indexing",
  "eventual consistency via event sourcing"), not just where it lives.
- **Where it shows up** — concrete file/line references in this codebase, so the quiz can
  point back to real code.
- **Category** — see below. Don't force-fit a fixed taxonomy; if the codebase's dominant
  characteristic doesn't cleanly fit "algorithms / data structures / platform specifics / design
  patterns", make a category for it (e.g. "concurrency model", "API design", "build tooling").
  The categories should reflect what's actually there.
- **Difficulty** — see the rubric below. Rate where genuine understanding of *why this choice
  was made and what it trades off* would land, not where reciting its name would land. Knowing
  what a hash map is is basic; knowing why this codebase chose an LRU cache over a simple hash
  map for this particular workload is early-professional or higher.

#### Difficulty rubric

| Level | What it means here |
|---|---|
| `basic` | Recognizing the concept exists and roughly what it does. |
| `coding-bootcamp` | Can explain how it works and implement a simple version. |
| `bachelors-degree` | Understands the underlying theory (complexity, correctness, formal tradeoffs). |
| `early-professional` | Has seen it used and misused in real systems; knows common pitfalls. |
| `experienced-professional` | Can weigh this choice against alternatives for a specific context and defend it. |
| `subject-matter-expert` | Knows the edge cases, the history of why the field converged here, and where it breaks down. |

#### Categories

Treat this as a starting vocabulary, not a fixed enum — add or rename categories to fit what the
codebase actually shows:
- Algorithms
- Data structures
- Design patterns
- Platform/language specifics
- Architecture / system design
- Concurrency & performance
- API & interface design
- Testing & tooling

### File format

Write `.claude/codebase-quiz/DESIGN_PRINCIPLES.md` with one section per category, and one entry
per principle:

```markdown
# Design Principles: <repo name>

_Last extracted at commit `<short-sha>` (<date>). On future sessions, diff against this SHA to
find what changed rather than re-scanning everything — see SKILL.md._

## <Category>

### <Principle name> — `difficulty: <level>`
<1-3 sentence explanation of the principle and why it's used here.>
**Where:** `path/to/file.ext:123`, `path/to/other.ext`
```

Group loosely related principles under the same category heading; order within a category
roughly from `basic` to `subject-matter-expert` so it doubles as a reading path if the user ever
opens the file directly.

## Phase 2: Run the quiz

### Pick a category

Ask the user interactively which category to study, using the categories actually present in
the principles file (plus an "all categories" option). Don't assume — present the discovered
list as a multiple-choice-style question so the user picks from what's really there rather than
a generic list you made up. If the user names a category directly in their invocation (e.g.
"quiz me on the concurrency stuff"), skip the question and use that.

### Check for prior progress

Look for `.claude/codebase-quiz/progress.md`. If it has an entry for this category, resume near
the recorded level rather than starting over — tell the user briefly where you're picking up
("Last time you were solidly at early-professional on design patterns, so let's start there").
If there's no entry, start at `bachelors-degree` (the middle of the six levels) as a neutral
opening guess.

### Ask questions, adapt, keep going until told to stop

This is an open session, not a fixed-length quiz — keep going until the user says they're done,
wants to switch category, or wants to stop. Don't preannounce a question count or wrap things up
prematurely; let the user set the pace.

For each question:

1. **Pick a target difficulty, then a principle at that difficulty**, from the current category,
   that hasn't been asked yet this session (check the progress log for recently-covered
   principles too, so repeat sessions don't retread the same ground back-to-back). See "Sampling
   difficulty around the current level" below for how the target difficulty isn't simply "always
   the current adaptive level" — and favor a principle nobody's touched yet over one that's
   merely at the target difficulty when you have a choice: a study session that only ever
   revisits the same well-worn principles at incrementally shifting difficulty teaches less than
   one that actually works through the file.
2. **Ask an open-ended question** that requires explaining the *why*, not just naming the
   concept — e.g. not "what pattern is used in `cache.py`?" but "this codebase evicts cache
   entries with an LRU policy in `cache.py` — why might that be a better fit here than a simple
   TTL expiry, and when would TTL actually be the better choice?" Ground it in the real file
   when it helps, but the question should teach the transferable idea, not just the local trivia.
3. **Let the user answer in free text — but if they respond with a question of their own instead
   of an answer** (e.g. "wait, why not just use a hash map here?"), treat it as a genuine detour,
   not a dodge. Answer it fully and conversationally, drawing on the codebase and the principles
   file, then re-pose the original quiz question so the thread isn't lost. This doesn't count as
   a right or wrong answer either way — it's not scored and doesn't move the difficulty needle.
   A good clarifying question is often a sign the user is engaging seriously with the material,
   so don't rush past it to get back to "the real quiz."
4. **Grade it yourself, out loud.** Say plainly whether the answer was solid, partially right, or
   off — and explain what was missing or what the fuller picture looks like, the way a good
   mentor would after a real conversation. Don't just say "correct" — reinforce or correct the
   underlying concept, since the goal is the user learning it, not scoring a point.
5. **On anything short of a fully solid answer, invite questions before moving on** — something
   as simple as "anything about this you want to dig into before we continue?" A grade-and-move-on
   loop is efficient but it's not actually how people learn something they got wrong; the moment
   right after being told what they missed is when a clarifying question is most useful, and
   waiting for the user to volunteer one on their own (rather than being asked) means a quieter
   or less confident user gets less out of the session than an assertive one would. If they do
   ask something, answer it fully per step 3's detour handling, and let it sharpen the
   `LEARNING_NOTES.md` entry in step 7 — a gap the user actively asked to close is worth recording
   more precisely than one that was only silently noted.
6. **Adjust the current adaptive level** based on the answer — normally by one step: up on a
   strong answer, down on a weak one, hold on a partial. When the question's target difficulty
   wasn't the current level (see below), the adjustment isn't symmetric — see "Sampling
   difficulty around the current level" for how big a swing is warranted and in which direction.
7. **On a partial or weak answer, log it to the repo's `LEARNING_NOTES.md`** (repo root) for the
   user to revisit later — see format below. Don't log strong answers; this section is meant to
   stay a short, high-signal "what to review" list, not a full transcript.
8. **If the discussion — the question, the user's answer, or a detour they asked about — surfaces
   a genuine codebase improvement** rather than just a gap in the user's knowledge, log it per
   "Surfacing codebase improvements" below. This comes up often: explaining *why* a pattern is
   used is exactly the kind of scrutiny that reveals when it's been applied inconsistently or
   when a "principle" the file describes doesn't actually hold everywhere.
9. **Update the progress log** (below) after every question, not just at the end of the
   session — if the session is interrupted, you don't want to lose the record.

### Sampling difficulty around the current level

Adaptive difficulty is a hill-climbing algorithm: it's built to converge on "the one level this
user is comfortable at," and it's good at that. But left alone, that's *all* it optimizes for — a
session that only ever asks at-level questions will spend its whole time in a narrow band around
wherever the user happens to land, quietly never touching the principles well below that band
(assumed already known) or well above it (assumed out of reach). Both assumptions are often
wrong, and a study tool exists to find out, not to assume.

Rather than treating "at the current level" as the default and occasionally overriding it with a
scheduled probe, treat every question's target difficulty as drawn from a distribution centered
on the current level — a bell curve, not a fixed point with periodic exceptions. In practice
(there's no literal dice to roll, so approximate this by feel each time rather than computing it):
most questions should land exactly on the current level, a smaller share one level off in either
direction, fewer still two levels off, and the true extremes — `basic`, `subject-matter-expert` —
should show up now and then even for a user who's settled well away from them, just rarely. Vary
this genuinely question to question rather than falling into a mechanical pattern (e.g. always
exactly-on-level except every Nth question) — the point is that reaching away from the current
level is a normal, everyday possibility, not a special scheduled event. Six levels is few enough
that the curve should genuinely feel truncated toward the ends rather than smoothly tapering to
zero — that's fine and expected, not something to correct for. When the current level is already
near an edge (e.g. `experienced-professional` or higher), let more of the curve's mass fall on
the near side rather than trying to preserve symmetry past the boundary.

The *grading consequence* of a question should scale with how far its target difficulty was from
the current level, and it's asymmetric by direction — the same principle the fixed-cadence probes
used, now generalized to apply continuously rather than only on scheduled ones:

- **Clearing a question pulled from above the current level** is real, useful evidence — the
  farther above, the stronger the evidence — and can justify jumping the level up by more than
  the usual one step. Missing one, though, is the expected outcome and shouldn't pull the level
  down at all; treat it like a routine question they simply weren't ready for yet, explain the
  fuller picture as always, but don't grade it harshly against them.
- **Missing a question pulled from below the current level** is a real finding the ordinary
  one-step-at-a-time adjustment would never have surfaced on its own, since it never looks below
  where the user already settled — the farther below, the more it matters, and it can justify
  dropping the level by more than one step. Log it to `LEARNING_NOTES.md` like any weak answer.
  Clearing one, though, is expected and not very informative — just move on normally, no special
  credit.
- **A question at (or one level from) the current level** behaves as described in step 6 above:
  ordinary one-step adjustment, nothing special.

Favor a principle that hasn't come up yet this session (or recent ones, per the progress log)
regardless of which difficulty you're aiming for — reaching away from the current level is most
useful when it's also filling in a genuine coverage gap, not just re-testing a principle you
already asked about at a different difficulty.

### Logging weak answers to LEARNING_NOTES.md

If `LEARNING_NOTES.md` already exists at the repo root, append to it under a `## Codebase Quiz —
to review` heading (create the heading if it's not there yet; don't disturb whatever else is
already in the file, and don't fight with any other convention that file already follows — just
add the section). If the file doesn't exist at all, create it with just that section; don't
invent unrelated content for it.

Each entry should be genuinely useful read cold, weeks later, without the quiz conversation for
context. If the user asked a clarifying question when invited to (step 5 above), let that
sharpen "the gap" — a specific follow-up question usually pinpoints exactly what didn't click
better than the original graded answer alone did.

```markdown
## Codebase Quiz — to review

### <Principle name> (<category>, <difficulty level>) — <date>
**The question:** <what was asked, briefly>
**The gap:** <what the answer missed or got wrong, in one or two sentences>
**Where:** `path/to/file.ext` — see DESIGN_PRINCIPLES.md for the full writeup
```

Keep entries terse — this is a pointer to go study something, not the study material itself
(that's what `DESIGN_PRINCIPLES.md` is for). If the same principle gets logged again in a later
session, update the existing entry's date rather than duplicating it, so the list reflects
current gaps rather than growing forever.

### Surfacing codebase improvements

This is a different bucket from `LEARNING_NOTES.md`: that file tracks gaps in the *user's*
understanding, this one tracks gaps in the *code*. Keep them separate so neither list gets diluted
— a reviewer skimming `LEARNING_NOTES.md` shouldn't have to wade through bug reports to find what
to study, and vice versa.

Log candidates to `.claude/codebase-quiz/IMPROVEMENT_IDEAS.md` (create it if it doesn't exist).
Be conservative about what qualifies — this should stay a short, credible list the user would
actually want to act on, not a running lint report. A good bar: would you bother mentioning this
if you were pair programming and noticed it in passing? If it's a matter of taste rather than a
real inconsistency or defect, it probably doesn't belong here.

```markdown
# Improvement Ideas

_Surfaced while extracting design principles or during quiz sessions — see SKILL.md._

### <short title> — <date>
**What:** <the issue, concretely, in 1-3 sentences>
**Why it matters:** <what actually breaks or degrades because of it>
**Where:** `path/to/file.ext:123`
```

Order newest-first so the most recent finding is easiest to spot. If a later pass finds the same
issue still present, don't duplicate the entry — bump its date instead, same as with
`LEARNING_NOTES.md`. If the user later confirms an idea was fixed or was a non-issue, remove its
entry rather than marking it done in place, so the file stays a live backlog and not a changelog.

Mention new entries when they come up ("by the way, I noticed X while we were talking about Y —
I've logged it") rather than only surfacing them in the end-of-session summary; a codebase issue
found mid-quiz is worth flagging in the moment; but don't stop the quiz to have a full discussion
about the fix unless the user wants to go there.

### Progress log format

Maintain `.claude/codebase-quiz/progress.md`:

```markdown
# Quiz Progress

## <Category>
Current level: <level>
Last session: <date>

Recently covered:
- <principle name> (<date>) — <brief note on how they did>
- ...
```

Keep "recently covered" to a rolling handful of entries per category (e.g. last ~10) rather than
an ever-growing list — its job is to avoid immediate repeats and to give a quick recap, not to be
a permanent transcript.

### Ending a session

When the user stops, give a short honest summary: current level per category touched, one or two
concepts worth revisiting, and confirm the progress file is saved. Don't inflate — if they
struggled, say so plainly and note it's worth another pass, since a false "great job!" undermines
the next session's calibration. If anything was logged to `LEARNING_NOTES.md` or
`IMPROVEMENT_IDEAS.md` this session, mention it explicitly so the user knows to go look — a
silent append is easy to miss, especially for `IMPROVEMENT_IDEAS.md` since those entries may have
only been flagged briefly in passing.
