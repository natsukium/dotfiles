#!/usr/bin/env python3
"""Analyze .claude/settings.local.json files across repositories to find common permissions."""

import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


def get_ghq_root() -> str:
    result = subprocess.run(["ghq", "root"], capture_output=True, text=True)
    return result.stdout.strip()


def find_settings_files(root: str) -> list[Path]:
    result = subprocess.run(
        ["find", root, "-name", "settings.local.json", "-path", "*/.claude/*"],
        capture_output=True,
        text=True,
    )
    return [Path(p) for p in result.stdout.strip().split("\n") if p]


def categorize_permission(perm: str) -> str:
    if perm.startswith("Bash(nix ") or perm.startswith("Bash(nix-"):
        return "nix"
    if perm.startswith("Bash(git "):
        return "git"
    if perm.startswith("Bash(gh "):
        return "github-cli"
    if perm.startswith("Bash(cargo "):
        return "rust"
    if perm.startswith("Bash(pnpm ") or perm.startswith("Bash(npm "):
        return "javascript"
    if perm.startswith("Bash(deno "):
        return "deno"
    if perm.startswith("Bash(just "):
        return "task-runner"
    if perm.startswith("WebFetch"):
        return "web-fetch"
    if perm.startswith("mcp__"):
        return "mcp"
    if perm.startswith("Read("):
        return "read"
    if perm.startswith("Edit("):
        return "edit"
    if perm.startswith("Skill("):
        return "skill"
    # Read-only shell commands
    ro_cmds = ["ls", "cat", "tree", "head", "tail", "find", "grep", "rg", "wc",
               "file", "which", "type", "echo", "xargs", "fc-list", "fc-match",
               "systemctl status", "systemctl list", "journalctl", "tailscale status"]
    for cmd in ro_cmds:
        if perm.startswith(f"Bash({cmd}"):
            return "read-only-shell"
    if perm.startswith("Bash("):
        return "bash-other"
    return "other"


def is_project_specific(perm: str) -> bool:
    """Check if a permission contains project-specific absolute paths.

    Bash commands with absolute paths (e.g. git -C /path) are NOT marked
    project-specific because they can be consolidated into middle-wildcard
    patterns like `Bash(git * log *)`.
    """
    if perm.startswith("Read(") or perm.startswith("Edit("):
        if "//home/" in perm or "//nix/store/" in perm:
            return True
    return False


def extract_domain(perm: str) -> str | None:
    if perm.startswith("WebFetch(domain:"):
        return perm.replace("WebFetch(domain:", "").rstrip(")")
    return None


# Domains that host untrusted user-generated content — never promote to user-level
UGC_DOMAINS = {
    "github.com",
    "raw.githubusercontent.com",
    "gist.githubusercontent.com",
    "gitlab.com",
    "bitbucket.org",
    "codeberg.org",
    "npmjs.com",
    "pypi.org",
}


def is_ugc_webfetch(perm: str) -> bool:
    """Check if a WebFetch permission targets a domain with user-generated content."""
    domain = extract_domain(perm)
    return domain is not None and domain in UGC_DOMAINS


def main():
    ghq_root = get_ghq_root()
    if not ghq_root:
        print("Error: ghq root not found", file=sys.stderr)
        sys.exit(1)

    settings_files = find_settings_files(ghq_root)
    if not settings_files:
        print("No settings files found", file=sys.stderr)
        sys.exit(1)

    # Collect all permissions with their source repos
    perm_repos: dict[str, list[str]] = defaultdict(list)
    repo_count = 0

    for path in settings_files:
        # Skip worktree copies
        if ".worktree" in str(path):
            continue
        repo_count += 1
        repo_name = str(path.parent.parent.relative_to(ghq_root))

        try:
            data = json.loads(path.read_text())
        except (json.JSONDecodeError, OSError):
            continue

        perms = data.get("permissions", {})
        for perm in perms.get("allow", []):
            # Deduplicate: only count each repo once per permission
            if repo_name not in perm_repos[perm]:
                perm_repos[perm].append(repo_name)

    # Read current user-level settings
    user_settings_path = Path.home() / ".claude" / "settings.json"
    user_perms = set()
    if user_settings_path.exists():
        try:
            user_data = json.loads(user_settings_path.read_text())
            user_perms = set(user_data.get("permissions", {}).get("allow", []))
        except (json.JSONDecodeError, OSError):
            pass

    # Categorize and analyze
    categories: dict[str, dict[str, list[str]]] = defaultdict(dict)
    for perm, repos in sorted(perm_repos.items()):
        cat = categorize_permission(perm)
        categories[cat][perm] = repos

    # Output report
    print(f"## Permission Analysis Report\n")
    print(f"### Summary")
    print(f"- Scanned: {repo_count} repositories")
    print(f"- Total unique permissions: {len(perm_repos)}")
    print(f"- Current user-level permissions: {len(user_perms)}")
    print()

    # Detailed breakdown by category
    print(f"### Breakdown by Category\n")
    for cat in sorted(categories.keys()):
        perms = categories[cat]
        print(f"#### {cat}")
        print(f"| Permission | Repos | Count | Project-specific | In user settings |")
        print(f"|-----------|-------|-------|-----------------|-----------------|")
        for perm, repos in sorted(perms.items(), key=lambda x: -len(x[1])):
            count = len(repos)
            specific = "Yes" if is_project_specific(perm) else ""
            in_user = "Yes" if perm in user_perms else ""
            repos_str = ", ".join(sorted(set(repos)))
            # Truncate long permission strings for display
            display_perm = perm if len(perm) <= 80 else perm[:77] + "..."
            print(f"| `{display_perm}` | {repos_str} | {count} | {specific} | {in_user} |")
        print()

    # Generate recommendations
    recommended = []
    already_covered = []
    project_specific = []

    for perm, repos in sorted(perm_repos.items()):
        if is_project_specific(perm):
            project_specific.append(perm)
            continue

        if is_ugc_webfetch(perm):
            project_specific.append(perm)
            continue

        if perm in user_perms:
            already_covered.append(perm)
            continue

        cat = categorize_permission(perm)
        count = len(repos)

        # Strong candidates: 3+ repos or read-only with 2+ repos
        if count >= 3:
            recommended.append((perm, count, "appears in 3+ repos"))
        elif count >= 2 and cat in ("read-only-shell", "web-fetch", "nix", "git"):
            recommended.append((perm, count, "read-only, appears in 2+ repos"))

    print(f"### Recommended additions to claude-code module\n")
    print("Edit `modules/home/coding-agents/claude-code/default.nix`,")
    print("add to `settings.permissions.allow`:\n")
    if recommended:
        print("```nix")
        for perm, _, _ in recommended:
            print(f'"{perm}"')
        print("```\n")
        for perm, count, reason in recommended:
            print(f"- `{perm}` — {reason} ({count} repos)")
    else:
        print("No new recommendations — current user settings already cover common patterns.")
    print()

    print(f"### Already in user-level settings\n")
    if already_covered:
        for perm in sorted(already_covered):
            print(f"- `{perm}`")
    else:
        print("None of the local permissions overlap with user settings.")
    print()

    print(f"### Remaining project-specific permissions\n")
    if project_specific:
        for perm in sorted(project_specific):
            print(f"- `{perm}`")
    else:
        print("No project-specific permissions found.")
    print()

    # Suggest wildcard consolidation
    print(f"### Wildcard consolidation suggestions\n")
    print("Consider these wildcard patterns to cover multiple specific entries:\n")

    # Extract the base command (first word) from a Bash permission
    def extract_base_cmd(perm: str) -> str | None:
        if not perm.startswith("Bash("):
            return None
        inner = perm[5:].rstrip(")")
        # Strip legacy :* suffix
        if inner.endswith(":*"):
            inner = inner[:-2]
        return inner.split()[0] if inner else None

    # Known compound subcommand prefixes — the word after these is still
    # part of the subcommand (e.g. `nix flake check`, `gh issue view`,
    # `npm run test`, `pnpm run lint`).
    COMPOUND_PREFIXES: dict[str, set[str]] = {
        "nix": {"flake"},
        "gh": {"issue", "pr", "run", "search", "api", "workflow", "release"},
        "npm": {"run"},
        "pnpm": {"run"},
        "docker": {"compose"},
        "systemctl": set(),  # subcommand is always 1 word
        "git": set(),        # subcommand is always 1 word
        "cargo": set(),
        "deno": set(),
        "just": set(),
    }

    # Extract the subcommand (the semantic verb) from a Bash permission.
    # For `git -C /path log --oneline`, the subcommand is `log`.
    # For `nix flake check`, the subcommand is `flake check`.
    # For `gh issue view 42`, the subcommand is `issue view`.
    def extract_subcommand(perm: str, base: str) -> str | None:
        if not perm.startswith("Bash("):
            return None
        inner = perm[5:].rstrip(")")
        if inner.endswith(":*"):
            inner = inner[:-2]
        words = inner.split()
        if not words or words[0] != base:
            return None

        compound_prefixes = COMPOUND_PREFIXES.get(base, set())

        # Skip flags and paths to find the first subcommand word
        subcmd_parts = []
        for w in words[1:]:
            if w.startswith("-"):
                continue
            if w.startswith("/") or w.startswith("~"):
                continue
            if w.startswith('"') or w.startswith("'"):
                continue
            if not subcmd_parts:
                # First real word = primary subcommand
                subcmd_parts.append(w)
                if w not in compound_prefixes:
                    break
            else:
                # Second word only if first was a compound prefix
                subcmd_parts.append(w)
                break
        return " ".join(subcmd_parts) if subcmd_parts else None

    # Commands with subcommands — prefer per-subcommand wildcards to avoid
    # granting overly broad access (e.g. `git * log *` instead of `git *`
    # to avoid accidentally allowing `git push`)
    SUBCMD_TOOLS = {"git", "gh", "nix", "nix-build", "cargo", "pnpm", "npm",
                    "deno", "just", "docker", "systemctl", "journalctl"}

    # Group by base command
    bash_by_base: dict[str, list[str]] = defaultdict(list)
    for perm in perm_repos:
        base = extract_base_cmd(perm)
        if base:
            bash_by_base[base].append(perm)

    for base, perms in sorted(bash_by_base.items()):
        if len(perms) < 2:
            continue

        # Group by subcommand
        by_subcmd: dict[str, list[str]] = defaultdict(list)
        no_subcmd: list[str] = []
        for p in perms:
            sub = extract_subcommand(p, base)
            if sub:
                by_subcmd[sub].append(p)
            else:
                no_subcmd.append(p)

        if base in SUBCMD_TOOLS and by_subcmd:
            # For subcommand tools, always suggest per-subcommand patterns
            for sub, sub_perms in sorted(by_subcmd.items()):
                # Use middle wildcard if any entry has flags/paths between
                # the base and subcommand (e.g. git -C /path log)
                needs_middle_wild = any(
                    extract_subcommand(p, base) == sub
                    and not p.startswith(f"Bash({base} {sub}")
                    for p in sub_perms
                )
                if needs_middle_wild:
                    pattern = f"Bash({base} * {sub} *)"
                else:
                    pattern = f"Bash({base} {sub} *)"

                if len(sub_perms) >= 2:
                    print(f"- `{pattern}` could cover:")
                    for p in sorted(sub_perms):
                        print(f"  - `{p}`")
                else:
                    print(f"- `{pattern}` could cover `{sub_perms[0]}`")

            if no_subcmd:
                print(f"- Remaining `{base}` entries (no subcommand detected):")
                for p in sorted(no_subcmd):
                    print(f"  - `{p}`")
        else:
            # For simple commands, suggest broad wildcard
            if not by_subcmd:
                print(f"- `Bash({base} *)` could cover:")
                for p in sorted(perms):
                    print(f"  - `{p}`")
            else:
                print(f"- `Bash({base} *)` could cover all {len(perms)} entries:")
                for p in sorted(perms):
                    print(f"  - `{p}`")


if __name__ == "__main__":
    main()
