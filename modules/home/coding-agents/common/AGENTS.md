# Code Documentation Guidelines

- Comments should explain WHY NOT an alternative approach was chosen, rather than WHAT the code does
- Test code should clearly describe WHAT is being tested
- Commit messages must include WHY the change was made

# Language Requirements

- All documentation, comments, and commit messages must be written in English

# Tool Usage Instructions

## ast-grep - AST-based Code Search and Transformation

### Overview

ast-grep is an AST-based tool for searching, linting, and refactoring code across multiple languages. It uses tree-sitter to parse code into Abstract Syntax Trees, enabling precise structural pattern matching.

### Key Pattern Syntax

- `$META` - Matches a single AST node (e.g., `$VAR`, `$FUNC`, `$ARG`)
- `$$$` - Matches zero or more AST nodes (useful for function arguments, statements)
- `$_` - Non-capturing metavariable (matches but doesn't capture)
- Patterns must be syntactically valid code in the target language

### Triggers

AST pattern, structural search, code refactoring, find anti-patterns, migrate code, console.log, deprecated API, function definition, class search, method signature, unused variables, security vulnerabilities, code transformation, pattern matching

### When to Use

- Finding specific code patterns across large codebases
- Refactoring code (replacing deprecated APIs, updating syntax)
- Detecting anti-patterns or potential bugs
- Migrating between library versions
- Enforcing coding standards
- Interactive code rewriting

### Examples

<examples>
  <example>
    <user>I need to find all React components using useState</user>
    <agent>I'll find useState usage in React components: `ast-grep --pattern 'const [$STATE, $SETTER] = useState($$$)'`</agent>
  </example>
  <example>
    <user>Replace && chains with optional chaining for null checks</user>
    <agent>I'll modernize null checks to optional chaining: `ast-grep --pattern '$OBJ && $OBJ.$PROP' --rewrite '$OBJ?.$PROP' --interactive`</agent>
  </example>
  <example>
    <user>Find async functions that don't have error handling</user>
    <agent>I'll search for async functions without try-catch: `ast-grep --pattern 'async function $NAME($$$PARAMS) { $$$BODY }' | grep -v try`</agent>
  </example>
  <example>
    <user>Find all TypeScript interfaces</user>
    <agent>I'll search for TypeScript interfaces: `ast-grep --pattern 'interface $NAME { $$$BODY }' --lang ts`</agent>
  </example>
  <example>
    <user>I want to find potential null pointer exceptions</user>
    <agent>I'll search for property access without null checks: `ast-grep --pattern '$VAR.$PROP' --filter 'not match { $VAR?.$PROP }'`</agent>
  </example>
</examples>

## ghq - Local Repository Management

### Triggers

GitHub repository, clone repo, existing codebase, reference code, local repository

### When to Use

User mentions a GitHub repository, needs to reference existing code, wants to clone repositories for code inspection

### Examples

<examples>
  <example>
    <user>Check the nixpkgs source code for how to configure this</user>
    <agent>I'll check if nixpkgs exists locally and clone if needed: `ghq get NixOS/nixpkgs`</agent>
  </example>
  <example>
    <user>Look at the React source code</user>
    <agent>I'll fetch React locally for reference: `ghq get facebook/react`</agent>
  </example>
</examples>

## gh - GitHub CLI

### TRIGGERS

pull request, PR, issue, GitHub API, release, workflow, repository info, GitHub operations, GitHub URL

### WHEN TO USE

Creating PRs, managing issues, viewing repository information, releases, accessing GitHub URLs

### Examples

<examples>
  <example>
    <user>Create a PR for this repository</user>
    <agent>I'll create a PR using gh command: `gh pr create --title "feat: add new feature" --body "Description of changes"`</agent>
  </example>
  <example>
    <user>Show me recent issues</user>
    <agent>I'll list issues with gh: `gh issue list --limit 10 --state all`</agent>
  </example>
  <example>
    <user>Check the review comments on this PR</user>
    <agent>I'll view PR comments with gh: `gh pr view --comments`</agent>
  </example>
  <example>
    <user>Read the discussion in https://github.com/owner/repo/issues/12345</user>
    <agent>I'll fetch the issue with gh: `gh issue view 12345 --repo owner/repo --comments`</agent>
  </example>
  <example>
    <user>Can you check what's in this PR? https://github.com/owner/repo/pull/42</user>
    <agent>I'll view the PR details with gh: `gh pr view 42 --repo owner/repo`</agent>
  </example>
  <example>
    <user>Check the workflows in this repository</user>
    <agent>I'll list workflows with gh: `gh workflow list`</agent>
  </example>
</examples>
