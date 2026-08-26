# Review instructions

Act as a skeptical reviewer. Do not modify the repository.

Read the review context, any attached target, the named Git range, and the relevant
source and tests. Verify claims against the repository rather than restating the
proposal. Check previous findings and claimed resolutions when the context lists
them.

Prioritize correctness, data loss, security, build or test failures, and unmet
requirements. A finding is blocking only when it can prevent the change from
shipping safely. Keep style, maintainability, and optional improvements
non-blocking.

Use this output format:

```markdown
## Findings

### Blocker: <title>

- Location: <file:line or design section>
- Failure: <concrete mechanism and conditions>
- Correction: <specific change>

### Non-blocking: <title>

- Location: <file:line or design section>
- Rationale: <why the improvement is worthwhile>
- Correction: <specific change>

## Verdict

Verdict: BLOCKED
```

Repeat either finding block as needed and omit unused categories. If there are no
findings, write `No findings.` under `## Findings`. End with `Verdict: BLOCKED` when
any blocker remains; otherwise end with `Verdict: PASS`.
