---
name: git-commit
description: How to write a commit message that stays meaningful after the session ends — explain WHY, follow the repository's convention, and never reference conversation-local structure like "Phase 2" or "Task 3". Load this BEFORE running `git commit`, whenever creating a commit, amending a commit message, or asked to "commit this". Applies to every commit, including intermediate commits made while working through a multi-step plan.
---

# Writing Commit Messages

Git history outlives the session. Whoever reads the message later — a human running
`git log`, `git blame`, or another agent — has only the repository. The conversation,
the plan, the task list, and the review thread that produced the commit are all gone.
Write every message so it stands on its own in that world.

## What to write

- **WHY, not WHAT.** The diff already shows what changed. The message must carry the
  part the diff cannot: the motivation, the constraint being worked around, or the
  alternative that was rejected and why.
- **Follow the repository's existing style.** Check `git log --oneline -10` before
  writing: conventional-commit prefixes, scope names, tense, and line length should
  match what is already there.
- **Name the goal, not the plan position.** If the commit is one step of a larger
  effort, describe the effort and what this step contributes — the effort's name and
  goal are durable, its decomposition into phases is not.

## What NOT to write

- **Plan- or session-relative references.** "Phase 2", "Task 3", "Step 1 of the
  refactor", "as planned", "per review feedback", "addresses comments" — these point
  at a structure that exists only in the conversation that created the commit. In
  `git log` a year later they carry zero information.
- **How the approach evolved during the session.** Changing direction mid-work is
  normal, but the commit records the result, not the journey. Never write "initially
  implemented with X, then switched to Y", "reworked after the first attempt failed",
  or "changed approach as discussed" — the reader never saw the first attempt, so the
  chronology is noise. Describe the final design as if it had been the intent from the
  start. If the abandoned approach carries a durable lesson, state it as a rejected
  alternative ("X was rejected because ..."), not as a narrative of what you did first.
- **Diff enumeration.** "Update foo.ts, add bar.ts, remove baz.ts" restates what
  `git show --stat` already prints.
- **Process narration.** "Ran formatter", "fix tests" — say why the tests were wrong
  or what the formatting rule is, or say nothing.

<examples>
  <example type="bad">
    <bad>feat: implement Phase 2 of the auth plan</bad>
    <good>feat(auth): refresh sessions in the background so tokens survive browser restarts</good>
  </example>
  <example type="bad">
    <bad>fix: address review feedback on task 3</bad>
    <good>fix(api): reject empty page tokens instead of returning the first page, which silently duplicated results for paginating clients</good>
  </example>
  <example type="bad">
    <bad>feat: add result caching (started with Redis, switched to in-memory mid-implementation)</bad>
    <good>feat: cache results in-memory; Redis was rejected because the deployment has no shared infrastructure and the cache tolerates per-process staleness</good>
  </example>
</examples>

## Mechanics

- Never create an empty commit; if nothing is staged, stop and say so.
- If the commit fails because a pre-commit hook modified files (formatters, linters),
  re-stage the modified files with `git add` and retry the same `git commit` command.
  Do NOT amend — the failed commit was never created.
- Write in English.
