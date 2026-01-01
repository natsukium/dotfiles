---
name: ast-grep
description: AST-based code search and transformation tool using tree-sitter. Use for structural pattern matching, refactoring deprecated APIs, detecting anti-patterns, migrating code between library versions, and enforcing coding standards.
---

# ast-grep - AST-based Code Search and Transformation

ast-grep is an AST-based tool for searching, linting, and refactoring code across multiple languages. It uses tree-sitter to parse code into Abstract Syntax Trees, enabling precise structural pattern matching.

## Key Pattern Syntax

- `$META` - Matches a single AST node (e.g., `$VAR`, `$FUNC`, `$ARG`)
- `$$$` - Matches zero or more AST nodes (useful for function arguments, statements)
- `$_` - Non-capturing metavariable (matches but doesn't capture)
- Patterns must be syntactically valid code in the target language

## Triggers

AST pattern, structural search, code refactoring, find anti-patterns, migrate code, console.log, deprecated API, function definition, class search, method signature, unused variables, security vulnerabilities, code transformation, pattern matching

## When to Use

- Finding specific code patterns across large codebases
- Refactoring code (replacing deprecated APIs, updating syntax)
- Detecting anti-patterns or potential bugs
- Migrating between library versions
- Enforcing coding standards
- Interactive code rewriting

## Examples

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
