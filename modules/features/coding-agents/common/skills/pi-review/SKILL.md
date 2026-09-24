---
name: pi-review
description: Delegate a source-grounded design or code review to a fresh `pi` CLI process using sol or luna, then address verified findings until no blockers remain. Use when explicitly asked to "get a review from pi/sol/luna", 「piにレビューもらって」「レビュー通して」, or to obtain a fresh independent-context review.
---

# Reviews Through pi

Run a fresh pi process so the review does not inherit the calling conversation.
The reviewer inspects the repository; the calling agent verifies findings and
owns any revisions.

## Models

| Model                     | Use for                                                   |
| ------------------------- | --------------------------------------------------------- |
| `openai-codex/gpt-6-sol`  | Adversarial design or diff review; final gate             |
| `openai-codex/gpt-6-luna` | Early drafts, quick checks, and triage between sol rounds |

Use an explicitly requested model. Otherwise use luna for an early pass and sol
for high-risk reasoning or the final pass.

## Prepare the review

Write the change-specific information to a scratch file outside the repository:

```markdown
# Review context

Target: <document or change>
Review range: <git diff, git diff --cached, or base...HEAD; omit for a document>
Revision context: <what changed and why>
Focus: <risks to examine>
Previous findings: <findings and claimed resolutions, or none>
```

For a design, attach the document with `--attach`. For code, let pi inspect the
named Git range and surrounding source instead of copying the diff into the prompt.
The fixed review criteria and output format live in `./references/reviewer.md`,
which the script passes itself.

## Run the review

`./scripts/pi-review` launches pi detached from the calling shell and waits for it
in a separate step, so the review survives a caller whose shell is killed or
timed out. Run it from inside the target repository: it starts pi at the
repository root and refuses to start elsewhere.

```bash
<skill-directory>/scripts/pi-review start --out /abs/scratch/review-1 \
  --context /abs/scratch/review-context.md [--attach /abs/path/design.md] [--model luna]
<skill-directory>/scripts/pi-review wait /abs/scratch/review-1
```

`--model` defaults to sol. `wait` prints the review, saves it to `<out>.md`, and
exits 0 for `PASS`, 1 for `BLOCKED`, and 2 when pi ended without a verdict (its
stderr is in `<out>.err`; that is not a review result). Sol rounds take 13 to 50
minutes and luna 10 to 15.

Where the caller's command timeout is shorter than a review, pass
`wait --timeout <seconds>` below that limit and call `wait` again after exit 124;
the review keeps running in between. Claude Code may instead run `wait` as a
background command and act on its completion notice. `wait` exits 3 when the
event stream has been silent for 15 minutes (`--stall`); then run
`pi-review stop <out>` and start the round once more. Stop a review only through
`stop`, which kills the recorded pid: a `pkill -f` pattern naming the model also
matches the calling shell's own command line.

`PI_REVIEW_WORKER=1` is set by the script: pi then omits this delegation skill
from the child while loading other global and project skills normally.

## Iterate

1. Read the review and verify each cited location and failure mechanism.
2. Fix accepted blockers and run the relevant checks.
3. Start a fresh review with the previous findings and resolutions recorded in the
   new context file. Narrow `Focus` as the remaining risk changes.
4. Continue until the verdict is `PASS`. Do not change the target for a mistaken or
   out-of-scope finding; record the evidence or scope boundary in the next context.
   After three consecutive `BLOCKED` rounds, stop and ask the user whether the
   direction still holds before starting another.
5. Report each round's verdict and the accepted or rejected findings to the user.
