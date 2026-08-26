---
name: pi-review
description: Delegate a source-grounded design or code review to a fresh `pi` CLI process using sol or luna, then address verified findings until no blockers remain. Use when explicitly asked to "get a review from pi/sol/luna", 「piにレビューもらって」「レビュー通して」, or to obtain a fresh independent-context review.
---

# Reviews Through pi

Run a fresh pi process so the review does not inherit the calling conversation.
The reviewer inspects the repository; the calling agent verifies findings and
owns any revisions.

## Models

| Model                       | Use for                                                   |
| --------------------------- | --------------------------------------------------------- |
| `openai-codex/gpt-5.6-sol`  | Adversarial design or diff review; final gate             |
| `openai-codex/gpt-5.6-luna` | Early drafts, quick checks, and triage between sol rounds |

Use an explicitly requested model. Otherwise use luna for an early pass and sol
for high-risk reasoning or the final pass.

## Prepare the review

Run pi from the target repository root. Write the change-specific information to
a scratch file outside the repository:

```markdown
# Review context

Target: <document or change>
Review range: <git diff, git diff --cached, or base...HEAD; omit for a document>
Revision context: <what changed and why>
Focus: <risks to examine>
Previous findings: <findings and claimed resolutions, or none>
```

For a design, attach the document as another `@file`. For code, let pi inspect the
named Git range and surrounding source instead of copying the diff into the prompt.

The fixed review criteria and output format live in
`./references/reviewer.md`. Resolve that file to an absolute path before invoking pi.

## Run the review

Use a foreground command with a timeout of at least 30 minutes:

```bash
PI_REVIEW_WORKER=1 pi \
  --model openai-codex/gpt-5.6-sol --thinking high \
  --tools read,grep,find,ls,bash --print --no-session \
  "@<skill-directory>/references/reviewer.md" \
  "@/absolute/path/to/review-context.md" \
  "@/absolute/path/to/design.md" \
  "Follow reviewer.md and review-context.md. Inspect the repository in the current working directory." \
  > /absolute/path/to/review-1.md 2>&1
```

Omit the design attachment for a code review. Change the model ID for a luna pass.
Keep `PI_REVIEW_WORKER=1`: pi then omits this delegation skill from the child while
loading other global and project skills normally. Print mode may stay silent until
completion, so an empty output file does not indicate a hang. Treat the process as
hung when it exceeds the harness's 30-minute wall-clock timeout, then terminate it
and retry once. A nonzero exit is not a review result.

## Iterate

1. Read the review and verify each cited location and failure mechanism.
2. Fix accepted blockers and run the relevant checks.
3. Start a fresh review with the previous findings and resolutions recorded in the
   new context file. Narrow `Focus` as the remaining risk changes.
4. Continue until the verdict is `PASS`. Do not change the target for a mistaken or
   out-of-scope finding; record the evidence or scope boundary in the next context.
5. Report each round's verdict and the accepted or rejected findings to the user.
